import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:path/path.dart';
import 'package:puppet/config/config_defaults.dart';
import 'package:puppet/config_providers.dart';
import 'package:puppet/config/theme.dart' as conf;

List<String> _errors = [];
List<String> _warnings = [];

class Config {
  String mainMenu = '';
  Map<String, dynamic> shortcut = conf_shortcut;
  HotKey hotkey = conf_hotkey;
  int version = conf_version;
  List<Menus> menus = <Menus>[];

  late List<String> errors;
  late List<String> warnings;

  Config.fromJson(Map<String, dynamic> json, List<Size> screenSizes,
      {String? mainMenuFromArgs = null, String systemBrightness = 'light'}) {
    if (json case {'version': int version}) {
      this.version = version;
    }
    // else {
    //   _warnings.add(
    //       "<version> property is null or empty or not a number, config will be parsed with version 1");
    // }

    if (json case {'shortcut': Map<String, dynamic> shortcut}) {
      try {
        HotKey h = HotKey.fromJson(shortcut);
        this.shortcut = shortcut;
        this.hotkey = h;
      } catch (e) {
        _warnings.add(
            "main menu shortcut is not a valid hotkey, please set a valid hotkey from the settings, until then, it will be <alt+space>");
      }
    }

    if (json case {'menus': List menus}) {
      this.menus = <Menus>[];
      menus.forEachIndexed((index, value) {
        final menu = Menus.fromJson(value, index, screenSizes, systemBrightness);
        if (this.menus.any((m) => m.name == menu.name)) {
          _errors.add("There is a menu named '${menu.name}' in the menus list, every menu must have a unique name");
        } else {
          if (menu.shortcut.isNotEmpty &&
              (DeepCollectionEquality().equals(menu.shortcut, this.shortcut) ||
                  this.menus.any((m) => DeepCollectionEquality().equals(m.shortcut, menu.shortcut)))) {
            _warnings.add("Shortcut on menu '${menu.name}' is already used by another menu, it will be ignored");
            menu.shortcut = {};
            menu.hotkey = null;
          }
          this.menus.add(menu);
        }
      });

      if (this.menus.isEmpty) {
        _errors.add("<menus> is null or empty or not a list, at least one menu is required to show");
      }
    } else {
      _errors.add("<menus> is null or empty or not a list, at least one menu is required to show");
    }

    if (mainMenuFromArgs != null) {
      if (this.menus.any((element) => element.name == mainMenuFromArgs)) {
        this.mainMenu = mainMenuFromArgs;
      } else {
        _warnings.add("There is no menu name equal to given argument '$mainMenuFromArgs' in the menus list");
      }
    }

    if (mainMenu.isEmpty) {
      if (json case {'mainMenu': String mainMenu}) {
        if (mainMenu.isNotEmpty) {
          if (this.menus.any((element) => element.name == mainMenu)) {
            this.mainMenu = mainMenu;
          } else {
            _warnings.add(
                "There is no menu named $mainMenu in the menus list, main menu will be the first menu in the menus list");
            this.mainMenu = this.menus[0].name;
          }
        } else {
          _warnings.add("<mainMenu> property is null or empty, main menu will be the first menu in the menus list");
          this.mainMenu = this.menus[0].name;
        }
      } else {
        _warnings.add("<mainMenu> property is null or empty, main menu will be the first menu in the menus list");
        this.mainMenu = this.menus[0].name;
      }
    }

    errors = _errors;
    warnings = _warnings;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['version'] = this.version;
    data['mainMenu'] = this.mainMenu;
    data['shortcut'] = this.shortcut;
    data['menus'] = this.menus.map((v) => v.toJson()).toList();
    return data;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

enum MenuType { wheel, list, canvas }

class Menus {
  String name = '';
  String type = conf_type;
  MenuType menuType = MenuType.wheel;
  Map<String, dynamic> shortcut = {};
  HotKey? hotkey = null;
  String _theme = conf_theme;
  String themeColorScheme = conf_themeColorScheme;
  String systemBrightness = 'light';
  Size size = Size(640, 640);
  String width = conf_width;
  String height = conf_height;
  String position = conf_position;
  Alignment? alignment = Alignment.center;
  String marginVertical = conf_marginVertical;
  String marginHorizontal = conf_marginHorizontal;
  List<Offset> offsets = [Offset(0, 0)];
  String monitor = conf_monitor;
  int maxElement = conf_maxElement;
  List<Items> items = <Items>[];

  conf.Theme getTheme(WidgetRef ref) {
    final isLight = switch ((systemBrightness, themeColorScheme)) {
      ('system', _) => systemBrightness == 'light',
      (_, _) => themeColorScheme == 'light',
    };
    final themes = ref.watch(themeProvider);
    return switch (themes) {
      AsyncData(:final value) =>
        value[_theme] == null ? conf.Theme() : (isLight ? value[_theme]!.light : value[_theme]!.dark),
      _ => conf.Theme(),
    };
  }

  String getThemeName() {
    return _theme;
  }

  void setTheme(String? themeName) {
    if (themeName == null) {
      _theme = conf_theme;
    } else {
      _theme = themeName == '/default' ? conf_theme : themeName;
    }
  }

  Menus({required this.name, this.systemBrightness = 'light'});

  Menus.fromJson(Map<String, dynamic> json, int index, List<Size> screenSizes, this.systemBrightness) {
    if (json case {'name': String name}) {
      this.name = name;
    } else {
      _warnings.add("Menu #${index + 1} is missing a <name> property");
    }

    if (json case {'type': String type}) {
      if (MenuType.values.asNameMap().containsKey(type)) {
        this.menuType = MenuType.values.byName(type);
        this.type = type;
      } else {
        _errors.add(
            '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has an invalid <type> property, <type> should be one of ${MenuType.values.map((e) => e.name)}');
      }
    } else {
      _errors.add('${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} is missing a <type> property');
    }

    if (json case {'shortcut': Map<String, dynamic> shortcut}) {
      try {
        if (shortcut.isNotEmpty) {
          HotKey h = HotKey.fromJson(shortcut);
          this.shortcut = shortcut;
          this.hotkey = h;
        }
      } catch (e) {
        _warnings.add(
            '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} shortcut is not a valid hotkey, please set a valid hotkey from the settings');
      }
    }

    if (json case {'theme': String theme}) {
      this._theme = theme;
    }

    if (json case {'themeColorScheme': String themeColorScheme}) {
      this.themeColorScheme = switch (themeColorScheme) {
        'system' || 'light' || 'dark' => themeColorScheme,
        _ => 'system',
      };
    }

    // set the default size if width and height are not specified.
    this.size = Size(screenSizes.first.height / 2, screenSizes.first.height / 2);
    if (json case {'height': String height}) {
      this.height = height;
      if (height.endsWith('%')) {
        var percent = int.tryParse(height.substring(0, height.length - 1));
        if (percent != null && percent > 0) {
          percent = percent > 100 ? 100 : percent;
          final h = screenSizes.first.height * (percent / 100);
          // if width is null or 0, use height, checking width will override this in the next if.
          this.size = Size(h, h);
        } else {
          this.height = conf_height;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <height> property. The height should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as width');
        }
      } else if (height != '_') {
        int? px;
        if (height.endsWith('px')) {
          px = int.tryParse(height.substring(0, height.length - 2));
        } else {
          px = int.tryParse(height);
        }
        if (px != null && px > 0) {
          // if width is null or 0, use height, checking width will override this in the next if.
          this.size = Size(px.toDouble(), px.toDouble());
        } else {
          this.height = conf_height;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <height> property. The height should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as width');
        }
      }
    }

    if (json case {'width': String width}) {
      this.width = width;
      if (width.endsWith('%')) {
        var percent = int.tryParse(width.substring(0, width.length - 1));
        if (percent != null && percent > 0) {
          percent = percent > 100 ? 100 : percent;
          final w = screenSizes.first.width * (percent / 100);
          this.size = Size(w, this.height == '_' ? w : this.size.height);
        } else {
          this.width = conf_width;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <width> property. The width should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as height');
        }
      } else if (width != '_') {
        int? px;
        if (width.endsWith('px')) {
          px = int.tryParse(width.substring(0, width.length - 2));
        } else {
          px = int.tryParse(width);
        }
        if (px != null && px > 0) {
          this.size = Size(px.toDouble(), this.height == '_' ? px.toDouble() : this.size.height);
        } else {
          this.width = conf_width;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <width> property. The width should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as height');
        }
      }
    }

    if (json case {'position': String position}) {
      this.position = position;
      if (position == 'mouse') {
        this.alignment = null;
      } else if (position.split('-').length == 2) {
        for (String pos in position.split('-')) {
          switch (pos) {
            case 'top' || 'bottom' when (this.alignment!.y == 0.0):
              this.alignment = Alignment(this.alignment!.x, pos == 'top' ? -1.0 : 1.0);
              break;
            case 'left' || 'right' when (this.alignment!.x == 0.0):
              this.alignment = Alignment(pos == 'left' ? -1.0 : 1.0, this.alignment!.y);
              break;
            default:
              if (pos != 'center') {
                this.position = conf_position;
                _warnings.add(
                    '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has an invalid <position> property. exp: "center-center", "top-left", "top-right", "top-center", "bottom-left", "bottom-right", "bottom-center", "left-top", "left-bottom", "left-center", "right-top", "right-bottom", "right-center"');
              }
          }
        }
      }
    }

    // set the default offset if margins are not specified.
    this.offsets = List.filled(screenSizes.length, Offset(0, 0));
    if (json case {'marginVertical': String marginVertical}) {
      final tmpOffsets = <Offset>[];
      this.marginVertical = marginVertical;
      if (marginVertical.endsWith('%')) {
        var percent = int.tryParse(marginVertical.substring(0, marginVertical.length - 1));
        if (percent != null && percent > 0) {
          percent = percent > 100 ? 100 : percent;
          for (final size in screenSizes) {
            final v = size.height * (percent / 100);
            // if marginHorizontal is null or 0, use marginVertical, checking marginHorizontal will override this in the next if.
            tmpOffsets.add(Offset(v, v));
          }
        } else {
          this.marginVertical = conf_marginVertical;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <marginVertical> property. The marginVertical should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as marginHorizontal');
        }
      } else if (marginVertical != '_') {
        int? px;
        if (marginVertical.endsWith('px')) {
          px = int.tryParse(marginVertical.substring(0, marginVertical.length - 2));
        } else {
          px = int.tryParse(marginVertical);
        }
        if (px != null) {
          // if marginHorizontal is null, use marginVertical, checking marginHorizontal will override this in the next if.
          for (final _ in screenSizes) {
            tmpOffsets.add(Offset(px.toDouble(), px.toDouble()));
          }
        } else {
          this.marginVertical = conf_marginVertical;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <marginVertical> property. The marginVertical should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as marginHorizontal');
        }
      }
      if (tmpOffsets.isNotEmpty) {
        this.offsets = tmpOffsets;
      }
    }

    if (json case {'marginHorizontal': String marginHorizontal}) {
      final tmpOffsets = <Offset>[];
      this.marginHorizontal = marginHorizontal;
      if (marginHorizontal.endsWith('%')) {
        var percent = int.tryParse(marginHorizontal.substring(0, marginHorizontal.length - 1));
        if (percent != null && percent > 0) {
          percent = percent > 100 ? 100 : percent;

          for (var i = 0; i < screenSizes.length; i++) {
            final size = screenSizes[i];
            final h = size.width * (percent / 100);
            tmpOffsets.add(Offset(h, this.marginVertical == '_' ? h : this.offsets[i].dy));
          }
        } else {
          this.marginHorizontal = conf_marginHorizontal;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <marginHorizontal> property. The marginHorizontal should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as marginVertical');
        }
      } else if (marginHorizontal != '_') {
        int? px;
        if (marginHorizontal.endsWith('px')) {
          px = int.tryParse(marginHorizontal.substring(0, marginHorizontal.length - 2));
        } else {
          px = int.tryParse(marginHorizontal);
        }
        if (px != null) {
          for (var i = 0; i < screenSizes.length; i++) {
            tmpOffsets.add(Offset(px.toDouble(), this.marginVertical == '_' ? px.toDouble() : this.offsets[i].dy));
          }
        } else {
          this.marginHorizontal = conf_marginHorizontal;
          _warnings.add(
              '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <marginHorizontal> property. The marginHorizontal should be a number of pixels or a percentage. exp: "50%" or "500px" or "_" to use as same as marginVertical');
        }
      }
      if (tmpOffsets.isNotEmpty) {
        this.offsets = tmpOffsets;
      }
    }

    if (json case {'monitor': String monitor}) {
      this.monitor = monitor;
    }

    if (json case {'maxElement': int maxElement}) {
      this.maxElement = maxElement;
    } else {
      _warnings.add(
          '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has a wrong <maxElement> property. The maxElement should be a number. exp: 9');
    }

    if (json case {'items': List items}) {
      this.items = <Items>[];
      final sg = ShortcodeGenerator();
      items.forEach((v) {
        this.items.add(new Items.fromJson(v, sg));
      });
    } else {
      _warnings.add(
          '${this.name.isEmpty ? 'Menu #${index + 1}' : "'${this.name}'"} has null or empty or wrong <items> list, no items will be shown');
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['type'] = this.type;
    data['shortcut'] = this.shortcut;
    data['theme'] = this._theme;
    data['themeColorScheme'] = this.themeColorScheme;
    data['width'] = this.width;
    data['height'] = this.height;
    data['position'] = this.position;
    data['marginVertical'] = this.marginVertical;
    data['marginHorizontal'] = this.marginHorizontal;
    data['monitor'] = this.monitor;
    data['maxElement'] = this.maxElement;
    data['items'] = this.items.map((v) => v.toJson()).toList();
    return data;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

class Items {
  String name = '';
  String description = '';
  bool repeat = false;
  String shortcutInJson = '';
  late String shortcut;
  String icon = '';
  // ItemIcon icon = ItemIcon.defaultIcon();
  late String type;
  Map<String, dynamic> pluginArgs = {};

  Items.fromJson(Map<String, dynamic> json, ShortcodeGenerator sg) {
    // TODO: check the plugin is available
    if (json case {'type': String type}) {
      this.type = type;
    }

    if (json case {'name': String name}) {
      this.name = name;
    }

    if (json case {'description': String description}) {
      this.description = description;
    }

    if (json case {'repeat': bool repeat}) {
      this.repeat = repeat;
    }

    if (json case {'shortcut': String shortcut}) {
      this.shortcut = shortcut.trim().isNotEmpty ? shortcut : sg.getShortcode();
      this.shortcutInJson = shortcut;
    } else {
      this.shortcut = sg.getShortcode();
    }

    if (json case {'icon': String icon}) {
      this.icon = icon;
      // this.icon = ItemIcon(icon);
    }

    if (json case {'pluginArgs': Map<String, dynamic> pluginArgs}) {
      this.pluginArgs = pluginArgs;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['description'] = this.description;
    data['repeat'] = this.repeat;
    data['shortcut'] = this.shortcutInJson;
    data['icon'] = this.icon;
    data['type'] = this.type;
    data['pluginArgs'] = this.pluginArgs;
    return data;
  }
}

class ShortcodeGenerator {
  final _numericBase = '1'.codeUnitAt(0);
  final _numericLast = '9'.codeUnitAt(0);
  final _alphabeticBase = 'a'.codeUnitAt(0);
  final _alphabeticLast = 'z'.codeUnitAt(0);

  var _currentIndex;

  ShortcodeGenerator() {
    _currentIndex = _numericBase - 1;
  }

  String getShortcode() {
    if (_currentIndex == _numericLast) {
      _currentIndex = _alphabeticBase - 1;
      return '0';
    }
    if (_currentIndex == _alphabeticLast) {
      return '';
    }

    _currentIndex += 1;

    return String.fromCharCode(_currentIndex);
  }
}

enum IconType { img, icon, svg, def }

const supportedIconImageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.wbmp', '.ico', '.icon'];

class ItemIcon {
  late IconType type;
  late String path;

  ItemIcon(String s) {
    final ext = extension(s).toLowerCase();
    if (ext == '.svg') {
      type = IconType.svg;
      path = s;
    } else if (supportedIconImageExtensions.contains(ext)) {
      type = IconType.img;
      path = s;
    } else {
      type = IconType.icon;
      path = s;
    }
  }

  ItemIcon.defaultIcon() {
    type = IconType.def;
    path = '';
  }

  // TODO: implement toString
  @override
  String toString() {
    return path;
  }
}
