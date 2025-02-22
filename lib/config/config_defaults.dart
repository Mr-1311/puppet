import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:puppet/config/theme.dart';

// CONFIG
const conf_version = 1;
const conf_type = 'wheel';
const conf_theme = '';
const conf_themeColorScheme = 'system';
const conf_width = '_';
const conf_height = '30%';
const conf_position = 'center-center';
const conf_marginVertical = '0px';
const conf_marginHorizontal = '_';
const conf_monitor = 'auto';
const conf_maxElement = 9;
const conf_shortcut = {
  "keyCode": "space",
  "modifiers": ["alt"]
};
final conf_hotkey = HotKey(key: LogicalKeyboardKey.space, modifiers: [HotKeyModifier.alt]);

final conf_iconData = FontAwesomeIcons.terminal;

// Default grey color for icons when theme uses gradient
const conf_defaultIconColor = Color.fromARGB(255, 148, 163, 184);

// Light Theme (Default)
final thm_light_backgroundColor = ThemeColorSolid('#ffffff'); // background
final thm_light_separatorColor = ThemeColorSolid('#e2e8f0'); // slate-200
final thm_light_outlineColor = ThemeColorSolid('#e2e8f0'); // slate-200
final thm_light_centerColor = ThemeColorSolid('#f8fafc'); // slate-50
final thm_light_hoveredBackgroundColor = ThemeColorSolid('#f1f5f9'); // slate-100
final thm_light_hoveredSeparatorColor = ThemeColorSolid('#3b82f6'); // blue-500
final thm_light_hoveredOutlineColor = ThemeColorSolid('#3b82f6'); // blue-500
final thm_light_itemFontColor = ThemeColorSolid('#020617'); // slate-950
final thm_light_menuFontColor = ThemeColorSolid('#020617'); // slate-950
final thm_light_descriptionFontColor = ThemeColorSolid('#64748b'); // slate-500
final thm_light_pageIndicatorActiveColor = ThemeColorSolid('#3b82f6'); // blue-500
final thm_light_pageIndicatorPassiveColor = ThemeColorSolid('#94a3b8'); // slate-400

// Dark Theme
final thm_dark_backgroundColor = ThemeColorSolid('#020617'); // slate-950
final thm_dark_separatorColor = ThemeColorSolid('#475569'); // slate-600
final thm_dark_outlineColor = ThemeColorSolid('#475569'); // slate-600
final thm_dark_centerColor = ThemeColorSolid('#1e293b'); // slate-800
final thm_dark_hoveredBackgroundColor = ThemeColorSolid('#1e293b'); // slate-800
final thm_dark_hoveredSeparatorColor = ThemeColorSolid('#3b82f6'); // blue-500
final thm_dark_hoveredOutlineColor = ThemeColorSolid('#3b82f6'); // blue-500
final thm_dark_itemFontColor = ThemeColorSolid('#ffffff'); // white
final thm_dark_menuFontColor = ThemeColorSolid('#ffffff'); // white
final thm_dark_descriptionFontColor = ThemeColorSolid('#94a3b8'); // slate-400
final thm_dark_pageIndicatorActiveColor = ThemeColorSolid('#3b82f6'); // blue-500
final thm_dark_pageIndicatorPassiveColor = ThemeColorSolid('#475569'); // slate-600

// Shared Theme Values
final thm_separatorThickness = AONInt(3);
final thm_outlineThickness = AONInt(3);
final thm_itemNameFont = Font(null);
final thm_menuNameFont = Font(null);
final thm_descriptionFont = Font(null);
final thm_itemNameFontSize = AONAuto();
final thm_menuNameFontSize = AONAuto();
final thm_iconSize = AONAuto();
final thm_descriptionFontSize = AONAuto();
