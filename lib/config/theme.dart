import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:puppet/config/config_defaults.dart';

class ThemeVariants {
  final Theme light;
  final Theme dark;

  ThemeVariants({required this.light, required this.dark});

  ThemeVariants copyWith({Theme? light, Theme? dark}) {
    return ThemeVariants(light: light ?? this.light, dark: dark ?? this.dark);
  }

  Map<String, Map<String, dynamic>> toJson() {
    return {
      'light': light.toJson(),
      'dark': dark.toJson(),
    };
  }
}

class Theme {
  ThemeColor backgroundColor = thm_light_backgroundColor;
  ThemeColor separatorColor = thm_light_separatorColor;
  ThemeColor outlineColor = thm_light_outlineColor;
  ThemeColor centerColor = thm_light_centerColor;
  ThemeColor hoveredBackgroundColor = thm_light_hoveredBackgroundColor;
  ThemeColor hoveredSeparatorColor = thm_light_hoveredSeparatorColor;
  ThemeColor hoveredOutlineColor = thm_light_hoveredOutlineColor;
  AutoOrNum separatorThickness = thm_separatorThickness;
  AutoOrNum outlineThickness = thm_outlineThickness;
  Font itemNameFont = thm_itemNameFont;
  Font menuNameFont = thm_menuNameFont;
  Font descriptionFont = thm_descriptionFont;
  AutoOrNum itemNameFontSize = thm_itemNameFontSize;
  AutoOrNum descriptionFontSize = thm_descriptionFontSize;
  AutoOrNum menuNameFontSize = thm_menuNameFontSize;
  AutoOrNum iconSize = thm_iconSize;
  ThemeColor itemFontColor = thm_light_itemFontColor;
  ThemeColor menuFontColor = thm_light_menuFontColor;
  ThemeColor descriptionFontColor = thm_light_descriptionFontColor;
  ThemeColorSolid pageIndicatorActiveColor = thm_light_pageIndicatorActiveColor;
  ThemeColorSolid pageIndicatorPassiveColor = thm_light_pageIndicatorPassiveColor;

  Theme()
      : backgroundColor = thm_light_backgroundColor,
        separatorColor = thm_light_separatorColor,
        outlineColor = thm_light_outlineColor,
        centerColor = thm_light_centerColor,
        hoveredBackgroundColor = thm_light_hoveredBackgroundColor,
        hoveredSeparatorColor = thm_light_hoveredSeparatorColor,
        hoveredOutlineColor = thm_light_hoveredOutlineColor,
        separatorThickness = thm_separatorThickness,
        outlineThickness = thm_outlineThickness,
        itemNameFont = thm_itemNameFont,
        menuNameFont = thm_menuNameFont,
        descriptionFont = thm_descriptionFont,
        itemNameFontSize = thm_itemNameFontSize,
        menuNameFontSize = thm_menuNameFontSize,
        iconSize = thm_iconSize,
        itemFontColor = thm_light_itemFontColor,
        menuFontColor = thm_light_menuFontColor,
        descriptionFontColor = thm_light_descriptionFontColor,
        descriptionFontSize = thm_descriptionFontSize,
        pageIndicatorActiveColor = thm_light_pageIndicatorActiveColor,
        pageIndicatorPassiveColor = thm_light_pageIndicatorPassiveColor;

  Theme.dark()
      : backgroundColor = thm_dark_backgroundColor,
        separatorColor = thm_dark_separatorColor,
        outlineColor = thm_dark_outlineColor,
        centerColor = thm_dark_centerColor,
        hoveredBackgroundColor = thm_dark_hoveredBackgroundColor,
        hoveredSeparatorColor = thm_dark_hoveredSeparatorColor,
        hoveredOutlineColor = thm_dark_hoveredOutlineColor,
        separatorThickness = thm_separatorThickness,
        outlineThickness = thm_outlineThickness,
        itemNameFont = thm_itemNameFont,
        menuNameFont = thm_menuNameFont,
        descriptionFont = thm_descriptionFont,
        itemNameFontSize = thm_itemNameFontSize,
        menuNameFontSize = thm_menuNameFontSize,
        iconSize = thm_iconSize,
        itemFontColor = thm_dark_itemFontColor,
        menuFontColor = thm_dark_menuFontColor,
        descriptionFontColor = thm_dark_descriptionFontColor,
        descriptionFontSize = thm_descriptionFontSize,
        pageIndicatorActiveColor = thm_dark_pageIndicatorActiveColor,
        pageIndicatorPassiveColor = thm_dark_pageIndicatorPassiveColor;

  Theme.fromJson(Map<String, dynamic> json) {
    for (final prop in ThemeProps.values) {
      if (json.containsKey(prop.propName)) {
        _setPropValue(prop, json[prop.propName]);
      }
    }
  }

  Theme.withValues(
    this.backgroundColor,
    this.separatorColor,
    this.outlineColor,
    this.hoveredBackgroundColor,
    this.hoveredSeparatorColor,
    this.hoveredOutlineColor,
    this.separatorThickness,
    this.outlineThickness,
    this.itemNameFont,
    this.menuNameFont,
    this.descriptionFont,
    this.itemNameFontSize,
    this.menuNameFontSize,
    this.iconSize,
    this.descriptionFontSize,
    this.pageIndicatorActiveColor,
    this.pageIndicatorPassiveColor,
  );

  Theme.clone(Theme t)
      : this.withValues(
          t.backgroundColor,
          t.separatorColor,
          t.outlineColor,
          t.hoveredBackgroundColor,
          t.hoveredSeparatorColor,
          t.hoveredOutlineColor,
          t.separatorThickness,
          t.outlineThickness,
          t.itemNameFont,
          t.menuNameFont,
          t.descriptionFont,
          t.itemNameFontSize,
          t.menuNameFontSize,
          t.iconSize,
          t.descriptionFontSize,
          t.pageIndicatorActiveColor,
          t.pageIndicatorPassiveColor,
        );

  Theme copyWith({
    ThemeColor? backgroundColor,
    ThemeColor? separatorColor,
    ThemeColor? outlineColor,
    ThemeColor? hoveredBackgroundColor,
    ThemeColor? hoveredSeparatorColor,
    ThemeColor? hoveredOutlineColor,
    AutoOrNum? separatorThickness,
    AutoOrNum? outlineThickness,
    Font? itemNameFont,
    Font? menuNameFont,
    Font? descriptionFont,
    AutoOrNum? itemNameFontSize,
    AutoOrNum? menuNameFontSize,
    AutoOrNum? iconSize,
    AutoOrNum? descriptionFontSize,
    ThemeColorSolid? pageIndicatorActiveColor,
    ThemeColorSolid? pageIndicatorPassiveColor,
  }) {
    return Theme.withValues(
      backgroundColor ?? this.backgroundColor,
      separatorColor ?? this.separatorColor,
      outlineColor ?? this.outlineColor,
      hoveredBackgroundColor ?? this.hoveredBackgroundColor,
      hoveredSeparatorColor ?? this.hoveredSeparatorColor,
      hoveredOutlineColor ?? this.hoveredOutlineColor,
      separatorThickness ?? this.separatorThickness,
      outlineThickness ?? this.outlineThickness,
      itemNameFont ?? this.itemNameFont,
      menuNameFont ?? this.menuNameFont,
      descriptionFont ?? this.descriptionFont,
      itemNameFontSize ?? this.itemNameFontSize,
      menuNameFontSize ?? this.menuNameFontSize,
      iconSize ?? this.iconSize,
      descriptionFontSize ?? this.descriptionFontSize,
      pageIndicatorActiveColor ?? this.pageIndicatorActiveColor,
      pageIndicatorPassiveColor ?? this.pageIndicatorPassiveColor,
    );
  }

  void _setPropValue(ThemeProps prop, dynamic value) {
    final propVal = switch (prop.propType) {
      AutoOrNum => switch (value) {
          String intVal when (int.tryParse(value) != null) => AONInt(int.parse(intVal)),
          (String strVal) => switch (strVal) {
              'auto' => AONAuto(),
              _ => null,
            },
          _ => null,
        },
      bool => switch (value) {
          bool boolVal => boolVal,
          _ => null,
        },
      ThemeColorSolid => switch (value) {
          String strVal => ThemeColorSolid(strVal),
          _ => null,
        },
      ThemeColor => switch (value) {
          String strVal when strVal.startsWith('{"type":') => ThemeColorGradient(strVal),
          String strVal => ThemeColorSolid(strVal),
          _ => null,
        },
      Font => switch (value) {
          String strVal => Font(strVal),
          _ => null,
        },
      _ => null,
    };

    switch (prop) {
      case ThemeProps.descFontSize:
        this.descriptionFontSize = switch (propVal) {
          AutoOrNum val => val,
          _ => this.descriptionFontSize,
        };
      case ThemeProps.itemNameFontSize:
        this.itemNameFontSize = switch (propVal) {
          AutoOrNum val => val,
          _ => this.itemNameFontSize,
        };
      case ThemeProps.menuNameFontSize:
        this.menuNameFontSize = switch (propVal) {
          AutoOrNum val => val,
          _ => this.menuNameFontSize,
        };
      case ThemeProps.iconSize:
        this.iconSize = switch (propVal) {
          AutoOrNum val => val,
          _ => this.iconSize,
        };
      case ThemeProps.pageIndicatorActiveColor:
        this.pageIndicatorActiveColor = switch (propVal) {
          ThemeColorSolid val => val,
          _ => this.pageIndicatorActiveColor,
        };
      case ThemeProps.pageIndicatorPassiveColor:
        this.pageIndicatorPassiveColor = switch (propVal) {
          ThemeColorSolid val => val,
          _ => this.pageIndicatorPassiveColor,
        };
      case ThemeProps.backgroundColor:
        this.backgroundColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.backgroundColor,
        };
      case ThemeProps.separatorColor:
        this.separatorColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.separatorColor,
        };
      case ThemeProps.outlineColor:
        this.outlineColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.outlineColor,
        };
      case ThemeProps.hoveredBackgroundColor:
        this.hoveredBackgroundColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.hoveredBackgroundColor,
        };
      // case ThemeProps.hoveredSeparatorColor:
      //   this.hoveredSeparatorColor = switch (propVal) {
      //     ThemeColor val => val,
      //     _ => this.hoveredSeparatorColor,
      //   };
      // case ThemeProps.hoveredOutlineColor:
      //   this.hoveredOutlineColor = switch (propVal) {
      //     ThemeColor val => val,
      //     _ => this.hoveredOutlineColor,
      //   };
      case ThemeProps.separatorThickness:
        this.separatorThickness = switch (propVal) {
          AutoOrNum val => val,
          _ => this.separatorThickness,
        };
      case ThemeProps.outlineThickness:
        this.outlineThickness = switch (propVal) {
          AutoOrNum val => val,
          _ => this.outlineThickness,
        };
      case ThemeProps.itemNameFont:
        this.itemNameFont = switch (propVal) {
          Font val => val,
          _ => this.itemNameFont,
        };
      case ThemeProps.menuNameFont:
        this.menuNameFont = switch (propVal) {
          Font val => val,
          _ => this.menuNameFont,
        };
      case ThemeProps.descriptionFont:
        this.descriptionFont = switch (propVal) {
          Font val => val,
          _ => this.descriptionFont,
        };
      case ThemeProps.centerColor:
        this.centerColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.centerColor,
        };
      case ThemeProps.itemFontColor:
        this.itemFontColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.itemFontColor,
        };
      case ThemeProps.menuFontColor:
        this.menuFontColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.menuFontColor,
        };
      case ThemeProps.descFontColor:
        this.descriptionFontColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.descriptionFontColor,
        };
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    for (final prop in ThemeProps.values) {
      data[prop.propName] = prop.getPropVariable(this).toString();
    }
    return data;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

//------ types

enum ThemeProps {
  backgroundColor('backgroundColor', ThemeColor, 'Background Color', 'Background color of the menu', ['wheel', 'list']),
  separatorColor(
      'separatorColor', ThemeColor, 'Separator Color', 'Color of dividing lines between menu items', ['wheel', 'list']),
  outlineColor('outlineColor', ThemeColor, 'Outline Color', 'Border color around the entire menu', ['wheel', 'list']),
  centerColor('centerColor', ThemeColor, 'Center Color', 'Color of the central circle (wheel menu only)', ['wheel']),
  hoveredBackgroundColor('hoveredBackgroundColor', ThemeColor, 'Background Color on Hover',
      'Background color when hovering over menu items', ['wheel', 'list']),
  // hoveredSeparatorColor('hoveredSeparatorColor', ThemeColor, 'Separator Color on Hover',
  //     'Separator Color of hovered menu items', ['wheel']),
  // hoveredOutlineColor(
  //     'hoveredOutlineColor', ThemeColor, 'Outline Color on Hover', 'Outline Color of hovered menus', ['wheel']),
  separatorThickness('separatorThickness', AutoOrNum, 'Separator Thickness',
      'Width of dividing lines between menu items (auto or pixels)', ['wheel', 'list']),
  outlineThickness('outlineThickness', AutoOrNum, 'Outline Thickness',
      'Width of the border around the menu (auto or pixels)', ['wheel', 'list']),
  itemNameFont('itemNameFont', Font, 'Item Name Font', 'Font family used for menu item names', ['wheel', 'list']),
  menuNameFont('menuNameFont', Font, 'Menu Name Font',
      'Font family used for the menu title in the center (wheel menu only)', ['wheel']),
  descriptionFont(
      'descriptionFont', Font, 'Description Font', 'Font family used for item descriptions', ['wheel', 'list']),
  itemNameFontSize('itemNameFontSize', AutoOrNum, 'Item Name Font Size', 'Size of menu item names (auto or pixels)',
      ['wheel', 'list']),
  menuNameFontSize('menuNameFontSize', AutoOrNum, 'Menu Name Font Size',
      'Size of the menu title (wheel menu only, auto or pixels)', ['wheel']),
  iconSize('iconSize', AutoOrNum, 'Icon Size', 'Size of menu item icons (auto or pixels)', ['wheel', 'list']),
  descFontSize('descriptionFontSize', AutoOrNum, 'Description Font Size', 'Size of item descriptions (auto or pixels)',
      ['wheel', 'list']),
  itemFontColor(
      'itemFontColor', ThemeColor, 'Item Name Font Color', 'Text color for menu item names', ['wheel', 'list']),
  menuFontColor('menuFontColor', ThemeColor, 'Menu Name Font Color', 'Text color for the menu title (wheel menu only)',
      ['wheel']),
  descFontColor(
      'descFontColor', ThemeColor, 'Description Font Color', 'Text color for item descriptions', ['wheel', 'list']),
  pageIndicatorActiveColor('pageIndicatorActiveColor', ThemeColorSolid, 'Page Indicator Active Color',
      'Color of the dot indicating the current active page (wheel menu only)', ['wheel']),
  pageIndicatorPassiveColor('pageIndicatorPassiveColor', ThemeColorSolid, 'Page Indicator Inactive Color',
      'Color of the dots representing inactive pages (wheel menu only)', ['wheel']),
  ;

  const ThemeProps(this.propName, this.propType, this.label, this.description, this.availableMenuTypes);
  final String propName;
  final dynamic propType;
  final String label;
  final String description;
  final List<String> availableMenuTypes;

  dynamic getPropVariable(Theme theme) {
    return switch (this) {
      ThemeProps.descFontSize => theme.descriptionFontSize,
      ThemeProps.itemNameFontSize => theme.itemNameFontSize,
      ThemeProps.menuNameFontSize => theme.menuNameFontSize,
      ThemeProps.iconSize => theme.iconSize,
      ThemeProps.pageIndicatorActiveColor => theme.pageIndicatorActiveColor,
      ThemeProps.pageIndicatorPassiveColor => theme.pageIndicatorPassiveColor,
      ThemeProps.backgroundColor => theme.backgroundColor,
      ThemeProps.separatorColor => theme.separatorColor,
      ThemeProps.outlineColor => theme.outlineColor,
      ThemeProps.hoveredBackgroundColor => theme.hoveredBackgroundColor,
      // ThemeProps.hoveredSeparatorColor => theme.hoveredSeparatorColor,
      // ThemeProps.hoveredOutlineColor => theme.hoveredOutlineColor,
      ThemeProps.separatorThickness => theme.separatorThickness,
      ThemeProps.outlineThickness => theme.outlineThickness,
      ThemeProps.itemNameFont => theme.itemNameFont,
      ThemeProps.menuNameFont => theme.menuNameFont,
      ThemeProps.descriptionFont => theme.descriptionFont,
      ThemeProps.centerColor => theme.centerColor,
      ThemeProps.itemFontColor => theme.itemFontColor,
      ThemeProps.menuFontColor => theme.menuFontColor,
      ThemeProps.descFontColor => theme.descriptionFontColor,
    };
  }

  void setPropVariable(Theme theme, dynamic value) {
    switch (this) {
      case ThemeProps.descFontSize:
        theme.descriptionFontSize = value;
      case ThemeProps.itemNameFontSize:
        theme.itemNameFontSize = value;
      case ThemeProps.menuNameFontSize:
        theme.menuNameFontSize = value;
      case ThemeProps.iconSize:
        theme.iconSize = value;
      case ThemeProps.pageIndicatorActiveColor:
        theme.pageIndicatorActiveColor = value;
      case ThemeProps.pageIndicatorPassiveColor:
        theme.pageIndicatorPassiveColor = value;
      case ThemeProps.backgroundColor:
        theme.backgroundColor = value;
      case ThemeProps.separatorColor:
        theme.separatorColor = value;
      case ThemeProps.outlineColor:
        theme.outlineColor = value;
      case ThemeProps.hoveredBackgroundColor:
        theme.hoveredBackgroundColor = value;
      // case ThemeProps.hoveredSeparatorColor:
      //   theme.hoveredSeparatorColor = value;
      // case ThemeProps.hoveredOutlineColor:
      //   theme.hoveredOutlineColor = value;
      case ThemeProps.separatorThickness:
        theme.separatorThickness = value;
      case ThemeProps.outlineThickness:
        theme.outlineThickness = value;
      case ThemeProps.itemNameFont:
        theme.itemNameFont = value;
      case ThemeProps.menuNameFont:
        theme.menuNameFont = value;
      case ThemeProps.descriptionFont:
        theme.descriptionFont = value;
      case ThemeProps.centerColor:
        theme.centerColor = value;
      case ThemeProps.itemFontColor:
        theme.itemFontColor = value;
      case ThemeProps.menuFontColor:
        theme.menuFontColor = value;
      case ThemeProps.descFontColor:
        theme.descriptionFontColor = value;
    }
  }
}

class Font {
  String? value;
  Font(this.value);
  @override
  String toString() {
    return value ?? '';
  }
}

sealed class AutoOrNum {}

class AONInt extends AutoOrNum {
  int value;
  AONInt(this.value);
  AONInt.def() : this(12);
  AONInt.fromStr(String value) : this(int.tryParse(value) ?? 12);

  @override
  String toString() {
    return value.toString();
  }
}

class AONAuto extends AutoOrNum {
  AONAuto();

  @override
  String toString() {
    return 'auto';
  }
}

sealed class ThemeColor {}

class ThemeColorSolid extends ThemeColor {
  late Color value;

  // expected format: #RRGGBBAA
  ThemeColorSolid(String hexColor) {
    final rgba = hexColor.startsWith('#') ? hexColor.substring(1) : hexColor;
    final argb = switch (rgba) {
      _ when rgba.length == 8 => rgba.substring(6) + rgba.substring(0, 6),
      _ when rgba.length == 6 => 'FF' + rgba,
      _ => null,
    };

    if (argb == null) {
      this.value = Colors.transparent;
      return;
    }
    final intColor = int.tryParse(argb, radix: 16);
    this.value = intColor == null ? Colors.transparent : Color(intColor);
  }

  @override
  String toString() {
    return '#' +
        value.red.toRadixString(16).padLeft(2, '0') +
        value.green.toRadixString(16).padLeft(2, '0') +
        value.blue.toRadixString(16).padLeft(2, '0') +
        value.alpha.toRadixString(16).padLeft(2, '0');
  }
}

class ThemeColorGradient extends ThemeColor {
  late Gradient value;
  late Alignment linearStart;
  late Alignment linearEnd;
  late Alignment radialCenter;

  ThemeColorGradient.fromGradient(Gradient value) {
    this.value = value;

    this.linearStart = value is LinearGradient ? value.begin.resolve(null) : Alignment.centerLeft;
    this.linearEnd = value is LinearGradient ? value.end.resolve(null) : Alignment.centerRight;
    this.radialCenter = value is RadialGradient ? value.center.resolve(null) : Alignment.center;
  }

  ThemeColorGradient(String jsonString) {
    Map<String, dynamic> map = json.decode(jsonString);

    if (map case {'type': 'linear'}) {
      this.value = LinearGradient(
        colors: (map['colors'].map((e) => Color(int.parse(e, radix: 16))).toList() as List).cast<Color>(),
        stops: (map['stops'] as List).cast<double>(),
        begin: Alignment(double.parse(map['begin'].split(',')[0]), double.parse(map['begin'].split(',')[1])),
        end: Alignment(double.parse(map['end'].split(',')[0]), double.parse(map['end'].split(',')[1])),
      );

      this.linearStart = (this.value as LinearGradient).begin.resolve(null);
      this.linearEnd = (this.value as LinearGradient).end.resolve(null);
      this.radialCenter = Alignment.center;
    } else if (map case {'type': 'radial'}) {
      this.value = RadialGradient(
        colors: (map['colors'].map((e) => Color(int.parse(e, radix: 16))).toList() as List).cast<Color>(),
        stops: (map['stops'] as List).cast<double>(),
        center: Alignment(double.parse(map['center'].split(',')[0]), double.parse(map['center'].split(',')[1])),
      );

      this.linearStart = Alignment.centerLeft;
      this.linearEnd = Alignment.centerRight;
      this.radialCenter = (this.value as RadialGradient).center.resolve(null);
    }
  }

  @override
  String toString() {
    String type = value is LinearGradient ? 'linear' : 'radial';
    return json.encode({
      'type': type,
      'colors': value.colors.isEmpty
          ? [Colors.black.value.toRadixString(16).padLeft(8, '0')]
          : value.colors.map((e) => e.value.toRadixString(16).padLeft(8, '0')).toList(),
      'stops': (value.stops?.isEmpty ?? true) ? [0.0] : value.stops,
      if (type == 'linear') 'begin': '${linearStart.resolve(null).x},${linearStart.resolve(null).y}',
      if (type == 'linear') 'end': '${linearEnd.resolve(null).x},${linearEnd.resolve(null).y}',
      if (type == 'radial') 'center': '${radialCenter.resolve(null).x},${radialCenter.resolve(null).y}',
    });
  }
}
