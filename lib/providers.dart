import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/config/path_manager.dart';
import 'package:puppet/list.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:puppet/settings/themes_pane.dart';
import 'package:puppet/wheel.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:puppet/config/calculate_window_position.dart';
import 'package:collection/collection.dart';
import 'package:puppet/config/theme.dart' as t;
import 'dart:math' as math;
import 'package:puppet/src/rust/api/plugin_manager.dart' as bridge;

import 'config/theme.dart';

import 'package:path/path.dart';

bool isSettingsApp = false;

void _hotkeyHandler(Config conf, Ref ref) async {
  if (isSettingsApp) {
    return;
  }
  await hotKeyManager.unregisterAll();
  hotKeyManager.register(
    conf.hotkey,
    keyDownHandler: (_) async {
      final menu = conf.menus.firstWhere((menu) => menu.name == conf.mainMenu);
      ref.read(menuProvider.notifier).setMenu(menu);
      windowManager.show();
    },
  );
  for (var i = 0; i < conf.menus.length; i++) {
    final menu = conf.menus[i];
    if (menu.hotkey != null) {
      hotKeyManager.register(
        menu.hotkey!,
        keyDownHandler: (_) async {
          ref.read(menuProvider.notifier).setMenu(menu);
          await windowManager.show();
        },
      );
    }
  }
}

final configProvider =
    AsyncNotifierProvider<ConfigNotifier, Config>(ConfigNotifier.new);

class ConfigNotifier extends AsyncNotifier<Config> {
  @override
  Future<Config> build() async {
    final configPath = PathManager().config;
    final File confFile = File('$configPath/config.json');

    if (!confFile.existsSync()) {
      confFile.createSync(recursive: true);
      final defaultConfig = await rootBundle.loadString('assets/config.json');
      confFile.writeAsStringSync(defaultConfig);
    }

    final configString = await confFile.readAsString();
    final displays = await screenRetriever.getAllDisplays();
    final systemBrightness = ref.watch(systemBrightnessNotifierProvider);
    final config = Config.fromJson(
        jsonDecode(configString), displays.map((e) => e.size).toList(),
        systemBrightness: systemBrightness);

    _hotkeyHandler(config, ref);

    return config;
  }

  Future<void> setMainMenu(String name) async {
    final configPath = PathManager().config;
    final File confFile = File('$configPath/config.json');

    final configString = await confFile.readAsString();
    final displays = await screenRetriever.getAllDisplays();
    state = AsyncData(Config.fromJson(
        jsonDecode(configString), displays.map((e) => e.size).toList(),
        mainMenuFromArgs: name));
  }

  Future<void> updateConfig(Config config) async {
    final configPath = PathManager().config;
    final File confFile = File('$configPath/config.json');

    await confFile.writeAsString(
        JsonEncoder.withIndent(' ' * 4).convert(config.toJson()));
    state = AsyncData(config);
    stdout.write('config_updated');
  }

  Future<void> rebuild() async {
    final configPath = PathManager().config;
    final File confFile = File('$configPath/config.json');

    final configString = await confFile.readAsString();
    final displays = await screenRetriever.getAllDisplays();
    final config = Config.fromJson(
        jsonDecode(configString), displays.map((e) => e.size).toList());

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

  Future<void> reorderMenuItem(int oldIndex, int newIndex, int menuId) async {
    final stateVal = state.valueOrNull;
    if (stateVal != null) {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = stateVal.menus[menuId].items.removeAt(oldIndex);
      stateVal.menus[menuId].items.insert(newIndex, item);
      updateConfig(stateVal);
    }
  }
}

final menuProvider =
    AsyncNotifierProvider<MenuNotifier, Menus>(MenuNotifier.new);

class MenuNotifier extends AsyncNotifier<Menus> {
  var _menuHistory = <Menus>[];

  @override
  Future<Menus> build() async {
    final conf = await ref.watch(configProvider.future);

    // don't reset menu on config change.
    if (_menuHistory.isNotEmpty) {
      final lastMenuName = _menuHistory.removeLast().name;
      setMenu(conf.menus.firstWhere((element) => element.name == lastMenuName));
      return _menuHistory.last;
    }

    final mainMenu =
        conf.menus.firstWhere((element) => element.name == conf.mainMenu);
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
    var size = menu.size;
    if (menu.menuType == MenuType.list &&
        (menu.height.trim().isEmpty || menu.height == '_')) {
      size = Size(size.width, _calculateListHeight(menu));
    }
    windowManager.setSize(size);

    final positionCoordinate = await calculateWindowPosition(
        windowSize: size,
        alignment: menu.alignment,
        offsets: menu.offsets,
        display: menu.monitor);
    windowManager.setPosition(positionCoordinate);
  }

  t.Theme _getCurrentTheme() {
    final menu = state.valueOrNull;
    final themes = ref.read(themeProvider).valueOrNull;

    if (menu == null) return t.Theme();

    final isLight = switch ((menu.systemBrightness, menu.themeColorScheme)) {
      ('system', _) => menu.systemBrightness == 'light',
      (_, _) => menu.themeColorScheme == 'light',
    };

    final tName = menu.getThemeName();
    return themes?[tName] == null
        ? t.Theme()
        : (isLight ? themes![tName]!.light : themes![tName]!.dark);
  }

  double _calculateListHeight(Menus menu) {
    final theme = _getCurrentTheme();

    final itemNameStyle = TextStyle(
      decoration: TextDecoration.none,
      fontFamily: theme.itemNameFont.value,
      fontSize: switch (theme.itemNameFontSize) {
        t.AONAuto() => kDefaultItemNameFontSize,
        t.AONInt(:final value) => value.toDouble(),
      },
    );

    final descriptionStyle = TextStyle(
      decoration: TextDecoration.none,
      fontFamily: theme.descriptionFont.value,
      fontSize: switch (theme.descriptionFontSize) {
        t.AONAuto() => kDefaultDescriptionFontSize,
        t.AONInt(:final value) => value.toDouble(),
      },
    );

    final itemNameSize = (TextPainter(
            text: TextSpan(text: 'L', style: itemNameStyle),
            maxLines: 1,
            textScaler: ref.watch(textScalerProvider),
            textDirection: TextDirection.ltr)
          ..layout())
        .size;

    final descriptionSize = (TextPainter(
            text: TextSpan(text: 'L', style: descriptionStyle),
            maxLines: 1,
            textScaler: ref.watch(textScalerProvider),
            textDirection: TextDirection.ltr)
          ..layout())
        .size;

    final iconSize = switch (theme.iconSize) {
      t.AONAuto() => kDefaultIconSize,
      t.AONInt(:final value) => value.toDouble(),
    };

    final outlineThickness = switch (theme.outlineThickness) {
          t.AONAuto() => kDefaultBorderWidth,
          t.AONInt(:final value) => value.toDouble(),
        } *
        2;
    final separatorThickness = switch (theme.separatorThickness) {
      t.AONAuto() => kDefaultBorderWidth,
      t.AONInt(:final value) => value.toDouble(),
    };

    final textHeight =
        itemNameSize.height + descriptionSize.height + kTextLineSpacing;

    final maxElement = menu.maxElement > menu.items.length
        ? menu.items.length
        : menu.maxElement;

    return (math.max(iconSize, textHeight) +
            (kItemVerticalPadding * 2) * maxElement) +
        (separatorThickness * (maxElement - 1)) +
        outlineThickness;
  }

  void clearHistory() {
    _menuHistory = [];
  }
}

final itemsProvider =
    NotifierProvider<ItemsNotifier, List<PluginItem>>(ItemsNotifier.new);

class ItemsNotifier extends Notifier<List<PluginItem>> {
  HashMap<String, List<PluginItem>> _cache =
      HashMap<String, List<PluginItem>>();
  @override
  List<PluginItem> build() {
    final menu = ref.watch(menuProvider);

    return switch (menu) {
      AsyncData(:final value) => _getItems(value),
      _ => [],
    };
  }

  List<PluginItem> _getItems(Menus menu) {
    if (_cache.containsKey(menu.name)) {
      return _cache[menu.name]!;
    }
    final List<PluginItem> items = [];

    for (Items item in menu.items) {
      if (item.plugin == 'menu' || item.plugin == 'run') {
        items.add(PluginItem(
          item.name,
          item.description,
          item.icon,
          item.plugin,
          item.shortcut,
          item.repeat,
          item.pluginArgs,
        ));
      }
    }
    _cache[menu.name] = items;
    return items;
  }

  void onClick(PluginItem item) async {
    if (item.plugin == 'menu') {
      final conf = ref.watch(configProvider).unwrapPrevious().valueOrNull;

      if (conf == null ||
          conf.menus.indexWhere((el) => el.name == item.args['menu name']) < 0)
        return;

      ref.read(currentPageProvider.notifier).state = 0;
      ref.read(menuProvider.notifier).changeMenu(conf.menus
          .firstWhere((element) => element.name == item.args['menu name']));
    } else if (item.plugin == 'run') {
      final regExp = RegExp(r'("[^"]+"|\S+)');
      final args = regExp.allMatches(item.args['arguments']).map((match) {
        var item = match.group(0)!;
        // Remove surrounding quotes, if any
        if (item.startsWith('"') && item.endsWith('"')) {
          item = item.substring(1, item.length - 1);
        }
        return item;
      }).toList();
      var env = <String, String>{};
      try {
        final Map<String, dynamic> decodedMap =
            jsonDecode(item.args['environment variables']);
        env.addAll(
            decodedMap.map((key, value) => MapEntry(key, value.toString())));
      } catch (e) {
        env = {};
      }
      var p = await Process.run(
        item.args['command'],
        args,
        environment: env,
        runInShell: item.args['run in shell'] == 'true',
      );
      print(p.stdout);
    }

    if (!item.repeat && item.plugin != 'menu') {
      ref.read(menuProvider.notifier).clearHistory();
      ref.invalidate(menuProvider);
      ref.invalidate(currentPageProvider);
      windowManager.hide();
    }
  }

  void clearCache() => _cache.clear();
}

final themeProvider =
    AsyncNotifierProvider<ThemeNotifier, Map<String, ThemeVariants>>(
        ThemeNotifier.new);

class ThemeNotifier extends AsyncNotifier<Map<String, ThemeVariants>> {
  @override
  Future<Map<String, ThemeVariants>> build() async {
    final themeDir = Directory(PathManager().themes);

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
          themeMap[fileName] =
              ThemeVariants(light: lightTheme, dark: lightTheme);
          break;
        case (null, Theme darkTheme):
          themeMap[fileName] = ThemeVariants(light: darkTheme, dark: darkTheme);
          break;
        case (Theme lightTheme, Theme darkTheme):
          themeMap[fileName] =
              ThemeVariants(light: lightTheme, dark: darkTheme);
          break;
      }
    }

    return themeMap;
  }

  Future<void> rebuild() async {
    final themeDir = Directory(PathManager().themes);

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
          themeMap[fileName] =
              ThemeVariants(light: lightTheme, dark: lightTheme);
          break;
        case (null, Theme darkTheme):
          themeMap[fileName] = ThemeVariants(light: darkTheme, dark: darkTheme);
          break;
        case (Theme lightTheme, Theme darkTheme):
          themeMap[fileName] =
              ThemeVariants(light: lightTheme, dark: darkTheme);
          break;
      }
    }

    state = AsyncData(themeMap);
  }

  Future<void> createNewTheme() async {
    await update((oldState) {
      var counter = 0;
      var newThemeName = 'New Theme';
      while (oldState.keys.firstWhereOrNull((name) => name == newThemeName) !=
          null) {
        counter++;
        newThemeName = 'New Theme $counter';
      }
      Theme lightTheme = Theme();
      Theme darkTheme = Theme();
      oldState[newThemeName] =
          ThemeVariants(light: lightTheme, dark: darkTheme);
      _saveToDisk(oldState[newThemeName]!, newThemeName);
      return oldState;
    });
  }

  Future<void> updateTheme(Theme theme, String? themeName, bool isLight) async {
    if (themeName == null) return;

    await update((oldState) async {
      oldState[themeName] = oldState[themeName]!.copyWith(
        light: isLight ? theme : null,
        dark: !isLight ? theme : null,
      );
      await _saveToDisk(oldState[themeName]!, themeName);
      stdout.write('theme_updated');
      return Map.from(oldState);
    });
  }

  Future<void> deleteTheme(String themeName) async {
    await update((oldState) {
      final File file = File(PathManager().themes + '$themeName.json');
      file.delete();
      oldState.remove(themeName);
      ref.read(configProvider.notifier).updateTheme(themeName, '');
      stdout.write('theme_updated');
      return oldState;
    });
  }

  Future<void> changeName(String oldName, String newName) async {
    await update((oldState) {
      final File file = File(PathManager().themes + '$oldName.json');
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
    final File file = File(PathManager().themes + '$name.json');

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    await file
        .writeAsString(JsonEncoder.withIndent(' ' * 4).convert(theme.toJson()));
  }
}

class SystemBrightnessNotifier extends Notifier<String> {
  @override
  String build() => 'light';

  void setSystemTheme(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      state = MediaQuery.platformBrightnessOf(context) == Brightness.dark
          ? 'dark'
          : 'light';
    });
  }
}

final systemBrightnessNotifierProvider =
    NotifierProvider<SystemBrightnessNotifier, String>(
        SystemBrightnessNotifier.new);

final currentThemeProvider = Provider<Theme>((ref) {
  final menu = ref.watch(menuProvider);
  final themes = ref.watch(themeProvider);

  switch (menu) {
    case AsyncData(:final value):
      {
        final isLight =
            switch ((value.systemBrightness, value.themeColorScheme)) {
          ('system', _) => value.systemBrightness == 'light',
          (_, _) => value.themeColorScheme == 'light',
        };
        final tName = value.getThemeName();
        return switch (themes) {
          AsyncData(:final value) => value[tName] == null
              ? Theme()
              : (isLight ? value[tName]!.light : value[tName]!.dark),
          _ => Theme(),
        };
      }
    default:
      return Theme();
  }
});

// light = true, dark = false
final currentThemeBrightnessProvider = Provider<bool>((ref) {
  final menu = ref.watch(menuProvider);

  switch (menu) {
    case AsyncData(:final value):
      {
        return switch ((value.systemBrightness, value.themeColorScheme)) {
          ('system', _) => value.systemBrightness == 'light',
          (_, _) => value.themeColorScheme == 'light',
        };
      }
    default:
      return true;
  }
});

class TextScalerNotifier extends Notifier<TextScaler> {
  @override
  TextScaler build() => TextScaler.noScaling;

  void setTextScaler(TextScaler scaler) {
    state = scaler;
  }
}

final textScalerProvider =
    NotifierProvider<TextScalerNotifier, TextScaler>(TextScalerNotifier.new);

final pluginProvider =
    NotifierProvider<PluginNotifier, List<Plugin>>(PluginNotifier.new);

class PluginNotifier extends Notifier<List<Plugin>> {
  @override
  List<Plugin> build() {
    final pluginDirPath = PathManager().plugins;
    return getAvailablePlugins(pluginDirPath);
  }

  bridge.PluginConfig? getPluginConfig(
      String name, Map<String, String> config) {
    final plugin = state.firstWhereOrNull((p) => p.name == name);
    if (plugin == null) return null;

    final configWithDefaults = Map<String, String>.fromEntries(
      plugin.args.map((arg) => MapEntry(
            arg.name,
            config[arg.name]?.isEmpty ?? true
                ? arg.defaultValue
                : config[arg.name]!,
          )),
    );

    return bridge.PluginConfig(
      allowedPaths: plugin.allowedPaths,
      allowedHosts: plugin.allowedHosts,
      enableWasi: plugin.wasi,
      config: configWithDefaults.entries.map((e) => (e.key, e.value)).toList(),
    );
  }
}
