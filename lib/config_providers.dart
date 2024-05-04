import 'dart:convert';
import 'dart:io';

import 'package:app_dirs/app_dirs.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/settings/themes_pane.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:puppet/config/calculate_window_position.dart';
import 'package:collection/collection.dart';

import 'config/theme.dart';

import 'package:path/path.dart';

void _hotkeyHandler(Config conf, Ref ref) async {
  await hotKeyManager.unregisterAll();
  hotKeyManager.register(
    conf.hotkey,
    keyDownHandler: (_) async {
      final menu = conf.menus.firstWhere((menu) => menu.name == conf.mainMenu);
      final positionCoordinate = await calculateWindowPosition(
          windowSize: menu.size, alignment: menu.alignment, offsets: menu.offsets, display: menu.monitor);
      windowManager.setPosition(positionCoordinate);
      await windowManager.show();
    },
  );
  for (var i = 0; i < conf.menus.length; i++) {
    final menu = conf.menus[i];
    if (menu.hotkey != null) {
      hotKeyManager.register(
        menu.hotkey!,
        keyDownHandler: (_) async {
          final positionCoordinate = await calculateWindowPosition(
              windowSize: menu.size, alignment: menu.alignment, offsets: menu.offsets, display: menu.monitor);
          windowManager.setPosition(positionCoordinate);
          ref.read(menuProvider.notifier).setMenu(menu);
          await windowManager.show();
        },
      );
    }
  }
}

final configProvider = AsyncNotifierProvider<ConfigNotifier, Config>(ConfigNotifier.new);

class ConfigNotifier extends AsyncNotifier<Config> {
  @override
  Future<Config> build() async {
    final configPath = getAppDirs(application: 'puppet').config;
    final File confFile = File('$configPath/config.json');

    if (!confFile.existsSync()) {
      confFile.createSync(recursive: true);
      final defaultConfig = await rootBundle.loadString('assets/config.json');
      confFile.writeAsStringSync(defaultConfig);
    }

    final configString = await confFile.readAsString();
    final displays = await screenRetriever.getAllDisplays();
    final systemBrightness = ref.watch(systemBrightnessNotifierProvider);
    final config = Config.fromJson(jsonDecode(configString), displays.map((e) => e.size).toList(),
        systemBrightness: systemBrightness);

    _hotkeyHandler(config, ref);

    return config;
  }

  Future<void> setMainMenu(String name) async {
    final configPath = getAppDirs(application: 'puppet').config;
    final File confFile = File('$configPath/config.json');

    final configString = await confFile.readAsString();
    final displays = await screenRetriever.getAllDisplays();
    state = AsyncData(
        Config.fromJson(jsonDecode(configString), displays.map((e) => e.size).toList(), mainMenuFromArgs: name));
  }

  Future<void> updateConfig(Config config) async {
    final configPath = getAppDirs(application: 'puppet').config;
    final File confFile = File('$configPath/config.json');

    await confFile.writeAsString(JsonEncoder.withIndent(' ' * 4).convert(config.toJson()));
    state = AsyncData(config);
    stdout.write('config_updated');
  }

  Future<void> rebuild() async {
    final configPath = getAppDirs(application: 'puppet').config;
    final File confFile = File('$configPath/config.json');

    final configString = await confFile.readAsString();
    final displays = await screenRetriever.getAllDisplays();
    final config = Config.fromJson(jsonDecode(configString), displays.map((e) => e.size).toList());

    _hotkeyHandler(config, ref);

    state = AsyncData(config);
  }

  Future<void> updateTheme(String oldName, String newName) async {
    final stateVal = state.valueOrNull;
    if (stateVal != null) {
      for (var i = 0; i < stateVal.menus.length; i++) {
        final menu = stateVal.menus[i];
        if (menu.getThemeName() == oldName) {
          menu.setTheme(newName);
          stateVal.menus[i] = menu;
        }
      }
      updateConfig(stateVal);
    }
  }
}

final menuProvider = AsyncNotifierProvider<MenuNotifier, Menus>(MenuNotifier.new);

class MenuNotifier extends AsyncNotifier<Menus> {
  var _menuHistory = <Menus>[];

  @override
  Future<Menus> build() async {
    final conf = await ref.watch(configProvider.future);

    final mainMenu = conf.menus.firstWhere((element) => element.name == conf.mainMenu);
    _adjustWindow(mainMenu);
    _menuHistory = [mainMenu];

    return mainMenu;
  }

  Future<void> setMenu(Menus menu) async {
    _menuHistory = [menu];
    _adjustWindow(menu);
    state = AsyncData(menu);
  }

  Future<void> changeMenu(Menus menu) async {
    _menuHistory.add(menu);
    _adjustWindow(menu);
    state = AsyncData(menu);
  }

  Future<void> back() async {
    if (_menuHistory.length == 1) {
      // https://github.com/leanflutter/hotkey_manager/issues/20
      Future.delayed(const Duration(milliseconds: 190), () {
        windowManager.hide();
      });
      return;
    }
    _menuHistory.removeLast();
    _adjustWindow(_menuHistory.last);
    state = AsyncData(_menuHistory.last);
  }

  Future<void> _adjustWindow(Menus menu) async {
    windowManager.setSize(menu.size);

    final positionCoordinate = await calculateWindowPosition(
        windowSize: menu.size, alignment: menu.alignment, offsets: menu.offsets, display: menu.monitor);
    windowManager.setPosition(positionCoordinate);
  }
}

final itemsProvider = Provider<List<Items>>((ref) {
  final menu = ref.watch(menuProvider);

  return switch (menu) {
    AsyncData(:final value) => value.items,
    _ => [],
  };
});

final themeProvider = AsyncNotifierProvider<ThemeNotifier, Map<String, ThemeVariants>>(ThemeNotifier.new);

class ThemeNotifier extends AsyncNotifier<Map<String, ThemeVariants>> {
  @override
  Future<Map<String, ThemeVariants>> build() async {
    final themeDir = Directory(getAppDirs(application: 'puppet').config + '/themes');

    //check theme dir is exist
    if (!themeDir.existsSync()) {
      themeDir.createSync(recursive: true);
    }
    final themeFiles = await themeDir
        .list(recursive: false, followLinks: false)
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .toList();

    final themeMap = <String, ThemeVariants>{};
    for (final thmFile in themeFiles) {
      final jsonObj = jsonDecode(await File(thmFile.path).readAsString());
      final fileName = basenameWithoutExtension(thmFile.path);

      Theme? lightTheme = null;
      Theme? darkTheme = null;
      if (jsonObj case {'light': Map<String, dynamic> theme}) {
        lightTheme = Theme.fromJson(theme);
      }

      if (jsonObj case {'dark': Map<String, dynamic> theme}) {
        darkTheme = Theme.fromJson(theme);
      }

      switch ((lightTheme, darkTheme)) {
        case (null, null):
          final t = Theme.fromJson(jsonObj);
          themeMap[fileName] = ThemeVariants(light: t, dark: t);
          break;
        case (Theme lightTheme, null):
          themeMap[fileName] = ThemeVariants(light: lightTheme, dark: lightTheme);
          break;
        case (null, Theme darkTheme):
          themeMap[fileName] = ThemeVariants(light: darkTheme, dark: darkTheme);
          break;
        case (Theme lightTheme, Theme darkTheme):
          themeMap[fileName] = ThemeVariants(light: lightTheme, dark: darkTheme);
          break;
      }
    }

    return themeMap;
  }

  Future<void> createNewTheme() async {
    await update((oldState) {
      var counter = 0;
      var newThemeName = 'New Theme';
      while (oldState.keys.firstWhereOrNull((name) => name == newThemeName) != null) {
        counter++;
        newThemeName = 'New Theme $counter';
      }
      Theme lightTheme = Theme();
      Theme darkTheme = Theme();
      oldState[newThemeName] = ThemeVariants(light: lightTheme, dark: darkTheme);
      _saveToDisk(oldState[newThemeName]!, newThemeName);
      return oldState;
    });
  }

  Future<void> updateTheme(Theme theme, String? themeName, bool isLight) async {
    if (themeName == null) return;
    await update((oldState) {
      oldState[themeName] = oldState[themeName]!.copyWith(
        light: isLight ? theme : null,
        dark: !isLight ? theme : null,
      );
      _saveToDisk(oldState[themeName]!, themeName);
      stdout.write('theme_updated');
      return oldState;
    });
  }

  Future<void> deleteTheme(String themeName) async {
    await update((oldState) {
      final File file = File(getAppDirs(application: 'puppet').config + '/themes/$themeName.json');
      file.delete();
      oldState.remove(themeName);
      ref.read(configProvider.notifier).updateTheme(themeName, '');
      stdout.write('theme_updated');
      return oldState;
    });
  }

  Future<void> changeName(String oldName, String newName) async {
    await update((oldState) {
      final File file = File(getAppDirs(application: 'puppet').config + '/themes/$oldName.json');
      file.rename('${dirname(file.path)}/$newName.json');
      ref.read(configProvider.notifier).updateTheme(oldName, newName);
      final t = oldState.remove(oldName);
      oldState[newName] = t!;
      ref.read(themeDetailProvider.notifier).state = newName;
      stdout.write('theme_updated');
      return oldState;
    });
  }

  bool isNameUnique(String nameValue) {
    final stateVal = state.valueOrNull;
    if (stateVal == null) return false;
    if (stateVal.keys.firstWhereOrNull((key) => key == nameValue) != null) {
      return false;
    }
    return true;
  }

  Future<void> _saveToDisk(ThemeVariants theme, String name) async {
    final File file = File(getAppDirs(application: 'puppet').config + '/themes/$name.json');

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    await file.writeAsString(JsonEncoder.withIndent(' ' * 4).convert(theme.toJson()));
  }
}

class SystemBrightnessNotifier extends Notifier<String> {
  @override
  String build() => 'light';

  void setSystemTheme(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      state = MediaQuery.platformBrightnessOf(context) == Brightness.dark ? 'dark' : 'light';
    });
  }
}

final systemBrightnessNotifierProvider =
    NotifierProvider<SystemBrightnessNotifier, String>(SystemBrightnessNotifier.new);
