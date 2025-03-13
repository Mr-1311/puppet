import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/providers.dart';
import 'package:puppet/settings/settings_page.dart';
import 'package:puppet/src/rust/frb_generated.dart';
import 'package:puppet/wheel.dart';
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:wayland_layer_shell/types.dart';
import 'package:wayland_layer_shell/wayland_layer_shell.dart';
import 'package:window_manager/window_manager.dart';
import 'package:collection/collection.dart';
import 'package:puppet/list.dart';

Future<void> _setWindowMode(bool isSettings) async {
  if (isSettings) {
    windowManager.setTitle('Settings');
    windowManager.setIcon(Platform.isWindows ? 'assets/logo_32.ico' : 'assets/logo_64.png');
    windowManager.setSize(Size(940, 640));
    windowManager.setMinimumSize(Size(940, 640));
    windowManager.center();
  } else {
    if (Platform.isLinux) {
      isWayland = await WaylandLayerShell().initialize(650, 600);
      if (isWayland)
        await WaylandLayerShell().setKeyboardMode(ShellKeyboardMode.keyboardModeExclusive);
        await WaylandLayerShell().setLayer(ShellLayer.layerOverlay);
    }

    windowManager.setBackgroundColor(Colors.transparent);
    windowManager.setResizable(false);
    if (Platform.isMacOS) {
      windowManager.setMovable(false);
      windowManager.setMinimizable(false);
      windowManager.setMaximizable(false);
      windowManager.setVisibleOnAllWorkspaces(true);
      windowManager.setHasShadow(false);
    }
    if (Platform.isWindows) {
      windowManager.setMinimizable(false);
      windowManager.setMaximizable(false);
      windowManager.setHasShadow(false);
    }
    windowManager.setAlwaysOnTop(true);
    windowManager.setAsFrameless();
    windowManager.setPreventClose(true);
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();
  await RustLib.init();

  final argParser = ArgParser();
  argParser.addOption('menu', abbr: 'm', help: 'set the menu to show on start');
  argParser.addFlag('settings', abbr: 's', defaultsTo: false, help: 'open settings window', negatable: false);
  final results = argParser.parse(args);

  // final isSettings = true;
  final bool isSettings = results['settings'];
  isSettingsApp = isSettings;
  mainMenuArg = results['menu'] ?? "";

  _setWindowMode(isSettings);
  // tray icon settings
  if (!isSettings) {
    await tray.trayManager.setIcon(
      Platform.isWindows ? 'assets/logo_32.ico' : 'assets/logo_64.png',
    );
    tray.Menu menu = tray.Menu(
      items: [
        tray.MenuItem(
          key: 'show_window',
          label: 'Open Puppet',
        ),
        tray.MenuItem(
          key: 'show_settings',
          label: 'Open Settings',
        ),
        tray.MenuItem.separator(),
        tray.MenuItem(
          key: 'exit_app',
          label: 'Exit Puppet',
        ),
      ],
    );
    await tray.trayManager.setContextMenu(menu);
  }

  windowManager.waitUntilReadyToShow(null, () async {
    if (!isSettings) {
      // https://github.com/leanflutter/window_manager/issues/190#issuecomment-1200255947
      windowManager.setSkipTaskbar(true);
    }
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(ProviderScope(
      child: isSettings
          ? SettingsPage()
          : Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                return MainApp();
              },
            )));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with tray.TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    tray.trayManager.addListener(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    tray.trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menu = ref.watch(menuProvider);

    // Set the text scaler from MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(textScalerProvider.notifier).setTextScaler(MediaQuery.textScalerOf(context));
    });

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: switch (menu) {
              AsyncData(:final value) => CallbackShortcuts(
                  bindings: {
                    const SingleActivator(
                      LogicalKeyboardKey.escape,
                    ): () {
                      final searchQuery = ref.read(searchQueryProvider);
                      if (searchQuery.isNotEmpty) {
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(searchFocusProvider).previousFocus();
                      } else {
                        ref.read(menuProvider.notifier).clearHistory();
                        ref.invalidate(menuProvider);
                        ref.invalidate(currentPageProvider);
                        windowManager.hide();
                      }
                    },
                  },
                  child: Focus(
                    autofocus: true,
                    child: Menu(menu: value),
                  ),
                ),
              _ => CircularProgressIndicator(),
            }
        );
  }

  @override
  void onTrayIconMouseDown() {
    tray.trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    tray.trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(tray.MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
    } else if (menuItem.key == 'show_settings') {
      String executablePath = Platform.resolvedExecutable;
      Process.start(executablePath, ['--settings']).then((Process process) {
        process.stdout.transform(utf8.decoder).listen((data) async {
          stdout.writeln('settings stdout: $data');
          if (data == 'config_updated') {
            // ref.read(itemsProvider.notifier).clearCache();
            await ref.read(configProvider.notifier).rebuild();
            ref.invalidate(pluginProvider);
          }
          if (data == 'theme_updated') {
            ref.read(themeProvider.notifier).rebuild();
          }
        });
      });
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  @override
  void onWindowBlur() {
    windowManager.hide();
  }
}

class Menu extends ConsumerStatefulWidget {
  const Menu({required this.menu, super.key});

  final Menus menu;

  @override
  ConsumerState<Menu> createState() => _MenuState();
}

class _MenuState extends ConsumerState<Menu> {
  bool _onKey(KeyEvent event) {
    final items = widget.menu.menuType == MenuType.wheel
        ? ref.watch(currentItemsProvider(widget.menu.maxElement))
        : ref.watch(itemsProvider).valueOrNull ?? [];

    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (!ref.read(searchFocusProvider).hasFocus) {
          ref.read(menuProvider.notifier).back();
          return true;
        }
      }

      if (ref.read(searchFocusProvider).hasFocus && !HardwareKeyboard.instance.isControlPressed) {
        return false;
      }

      final key = event.logicalKey.keyLabel;
      var item = items.firstWhereOrNull((item) => item.shortcut?.toUpperCase() == key);
      if (item == null) {
        final num = int.tryParse(key);
        if (num == 0) {
          item = items.last;
        } else if (num != null && num < 10 && num <= items.length) {
          item = items[num - 1];
        }
        ;
      }
      if (item != null) {
        ref.read(searchQueryProvider.notifier).state = '';
        ref.read(itemsProvider.notifier).onClick(item);
        return true;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.menu.menuType == MenuType.list) {
      ref.read(searchFocusProvider).requestFocus();
    }
    return switch (widget.menu) {
      Menus(menuType: MenuType.wheel) => Wheel(maxElement: widget.menu.maxElement, menuName: widget.menu.name),
      Menus(menuType: MenuType.list) =>
        ListMenu(maxElement: widget.menu.maxElement, menuName: widget.menu.name, height: widget.menu.height),
      Menus(menuType: MenuType.canvas) => const CircularProgressIndicator(),
    };
  }
}
