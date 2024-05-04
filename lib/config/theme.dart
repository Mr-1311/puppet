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
  AutoOrNum itemNameFontSize = thm_itemNameFontSize;
  AutoOrNum menuNameFontSize = thm_menuNameFontSize;
  AutoOrNum iconSize = thm_iconSize;
  AutoOrNum descriptionFontSize = thm_descriptionFontSize;
  bool showItemNameOnCenter = thm_showItemNameOnCenter;
  bool showDescOnCenter = thm_showDescOnCenter;
  bool showIconOnCenter = thm_showIconOnCenter;
  ThemeColorSolid pageIndicatorActiveColor = thm_pageIndicatorActiveColor;
  ThemeColorSolid pageIndicatorPassiveColor = thm_pageIndicatorPassiveColor;
  ThemeColor backgroundColor = thm_backgroundColor;
  ThemeColor separatorColor = thm_separatorColor;
  ThemeColor outlineColor = thm_outlineColor;
  ThemeColor hoveredBackgroundColor = thm_hoveredBackgroundColor;
  ThemeColor hoveredSeparatorColor = thm_hoveredSeparatorColor;
  ThemeColor hoveredOutlineColor = thm_hoveredOutlineColor;

  Theme();
  Theme.fromJson(Map<String, dynamic> json) {
    for (final prop in ThemeProps.values) {
      if (json.containsKey(prop.propName)) {
        _setPropValue(prop, json[prop.propName]);
      }
    }
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
          String strVal when strVal == 'random' => ThemeColorRandom(),
          String strVal when strVal.startsWith('{"type":') => ThemeColorGradient(strVal),
          String strVal => ThemeColorSolid(strVal),
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
      case ThemeProps.showItemNameOnCenter:
        this.showItemNameOnCenter = switch (propVal) {
          bool val => val,
          _ => this.showItemNameOnCenter,
        };
      case ThemeProps.showDescOnCenter:
        this.showDescOnCenter = switch (propVal) {
          bool val => val,
          _ => this.showDescOnCenter,
        };
      case ThemeProps.showIconOnCenter:
        this.showIconOnCenter = switch (propVal) {
          bool val => val,
          _ => this.showIconOnCenter,
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
      case ThemeProps.hoveredSeparatorColor:
        this.hoveredSeparatorColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.hoveredSeparatorColor,
        };
      case ThemeProps.hoveredOutlineColor:
        this.hoveredOutlineColor = switch (propVal) {
          ThemeColor val => val,
          _ => this.hoveredOutlineColor,
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
  itemNameFontSize('itemNameFontSize', AutoOrNum, 'Item Name Font Size', 'Item Name Font Size', ['wheel']),
  menuNameFontSize('menuNameFontSize', AutoOrNum, 'Menu Name Font Size', 'Menu Name Font Size', ['wheel']),
  iconSize('iconSize', AutoOrNum, 'Icon Size', 'Icon Size', ['wheel']),
  descFontSize('descriptionFontSize', AutoOrNum, 'Description Font Size', 'Description Font Size', ['wheel']),
  showItemNameOnCenter('showItemNameOnCenter', bool, 'Show Item Name On Center', 'Show Item Name On Center', ['wheel']),
  showDescOnCenter('showDescOnCenter', bool, 'Show Description On Center', 'Show Description On Center', ['wheel']),
  showIconOnCenter('showIconOnCenter', bool, 'Show Icon On Center', 'Show Icon On Center', ['wheel']),
  pageIndicatorActiveColor('pageIndicatorActiveColor', ThemeColorSolid, 'Page Indicator Active Dot Color',
      'Page Indicator Active Dot Color on Wheel Menu', ['wheel']),
  pageIndicatorPassiveColor('pageIndicatorPassiveColor', ThemeColorSolid, 'Page Indicator Passive Dot Color',
      'Page Indicator Passive Dot Color on Wheel Menu', ['wheel']),
  backgroundColor('backgroundColor', ThemeColor, 'Background Color', 'Background Color of menu', ['wheel']),
  separatorColor('separatorColor', ThemeColor, 'Separator Color', 'Separator Color of menu items', ['wheel']),
  outlineColor('outlineColor', ThemeColor, 'Outline Color', 'Outline Color of menu', ['wheel']),
  hoveredBackgroundColor('hoveredBackgroundColor', ThemeColor, 'Background Color on Hover',
      'Background Color of hovered menu items', ['wheel']),
  hoveredSeparatorColor('hoveredSeparatorColor', ThemeColor, 'Separator Color on Hover',
      'Separator Color of hovered menu items', ['wheel']),
  hoveredOutlineColor(
      'hoveredOutlineColor', ThemeColor, 'Outline Color on Hover', 'Outline Color of hovered menus', ['wheel']),
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
      ThemeProps.showItemNameOnCenter => theme.showItemNameOnCenter,
      ThemeProps.showDescOnCenter => theme.showDescOnCenter,
      ThemeProps.showIconOnCenter => theme.showIconOnCenter,
      ThemeProps.pageIndicatorActiveColor => theme.pageIndicatorActiveColor,
      ThemeProps.pageIndicatorPassiveColor => theme.pageIndicatorPassiveColor,
      ThemeProps.backgroundColor => theme.backgroundColor,
      ThemeProps.separatorColor => theme.separatorColor,
      ThemeProps.outlineColor => theme.outlineColor,
      ThemeProps.hoveredBackgroundColor => theme.hoveredBackgroundColor,
      ThemeProps.hoveredSeparatorColor => theme.hoveredSeparatorColor,
      ThemeProps.hoveredOutlineColor => theme.hoveredOutlineColor,
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
      case ThemeProps.showItemNameOnCenter:
        theme.showItemNameOnCenter = value;
      case ThemeProps.showDescOnCenter:
        theme.showDescOnCenter = value;
      case ThemeProps.showIconOnCenter:
        theme.showIconOnCenter = value;
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
      case ThemeProps.hoveredSeparatorColor:
        theme.hoveredSeparatorColor = value;
      case ThemeProps.hoveredOutlineColor:
        theme.hoveredOutlineColor = value;
    }
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

class ThemeColorRandom extends ThemeColor {
  @override
  String toString() {
    return 'random';
  }
}
