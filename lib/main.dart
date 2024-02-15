import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/config/config_repository.dart';
import 'package:puppet/error_page.dart';
import 'package:puppet/settings_page.dart';
import 'package:puppet/wheel.dart';
import 'package:window_manager/window_manager.dart';
import 'package:puppet/config/calculate_window_position.dart';

final configRepositoryProvider = FutureProvider.family<ConfigRepository, String?>((ref, mainMenu) {
  return ConfigRepository.getInstance(mainMenu);
});

final menuProvider = AsyncNotifierProvider.family<MenuNotifier, Menus, String?>(MenuNotifier.new);

class MenuNotifier extends FamilyAsyncNotifier<Menus, String?> {
  @override
  Future<Menus> build(String? menu) async {
    final configRepo = await ref.watch(configRepositoryProvider(menu).future);

    final mainMenu = configRepo.config.menus.firstWhere((element) => element.name == configRepo.config.mainMenu);
    windowManager.setSize(mainMenu.size);

    final positionCoordinate = await calculateWindowPosition(
        windowSize: mainMenu.size, alignment: mainMenu.alignment, offset: mainMenu.offset, display: mainMenu.monitor);
    windowManager.setPosition(positionCoordinate);

    ref.read(itemsProvider.notifier).state = mainMenu.items;

    return mainMenu;
  }
}

final itemsProvider = StateProvider<List<Items>>((ref) => []);

void setWindowMode(bool isSettings) {
  if (isSettings) {
    windowManager.setSize(Size(640, 640));
    windowManager.center();
  } else {
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

    windowManager.setAsFrameless();
    // windowManager.setAlwaysOnTop(true);
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final argParser = ArgParser();
  argParser.addOption('menu', abbr: 'm', help: 'set the menu to show on start');
  argParser.addFlag('settings', abbr: 's', defaultsTo: false, help: 'open settings window', negatable: false);
  final results = argParser.parse(args);

  // final isSettings = results['settings'];
  final isSettings = true;

  setWindowMode(isSettings);

  windowManager.waitUntilReadyToShow(null, () async {
    // if (!isSettings) {
    //   // https://github.com/leanflutter/window_manager/issues/190#issuecomment-1200255947
    //   // windowManager.setSkipTaskbar(true);
    // }
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(ProviderScope(child: isSettings ? SettingsPage() : MainApp(results)));
}

class MainApp extends ConsumerWidget {
  const MainApp(this.args, {super.key});

  final ArgResults args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(configRepositoryProvider(args['menu']));
    conf.whenData((value) {
      print(value.config.toString());
      print('errors: ${value.config.errors}');
      print('warnings: ${value.config.warnings}');
    });
    final menu = ref.watch(menuProvider(args['menu']));
    menu.whenData((value) {
      print(value.toString());
    });

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: switch (conf) {
          AsyncData(:final value) when value.config.errors.isNotEmpty => ErrorPage(value.config.errors),
          _ => switch (menu) {
              AsyncData(:final value) => Menu(menu: value),
              _ => CircularProgressIndicator(),
            }
        });
  }
}

class Menu extends StatelessWidget {
  const Menu({required this.menu, super.key});

  final Menus menu;

  // TODO: generate menu items from plugin and send generated items to menu types
  @override
  Widget build(BuildContext context) {
    return switch (menu) {
      Menus(menuType: MenuType.wheel) => Wheel(maxElement: menu.maxElement, menuName: menu.name),
      Menus(menuType: MenuType.list) => CircularProgressIndicator(),
      Menus(menuType: MenuType.canvas) => CircularProgressIndicator(),
    };
  }
}
