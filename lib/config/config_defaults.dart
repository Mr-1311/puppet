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
final conf_hotkey = HotKey(KeyCode.space, modifiers: [KeyModifier.alt]);

// THEME
final thm_backgroundColor = ThemeColorSolid('#cc278d');
final thm_separatorColor = ThemeColorSolid('#3498db');
final thm_outlineColor = ThemeColorSolid('#3498db');
final thm_centerColor = ThemeColorSolid('#3498db');
final thm_hoveredBackgroundColor = ThemeColorSolid('#3498db');
final thm_hoveredSeparatorColor = ThemeColorSolid('#3498db');
final thm_hoveredOutlineColor = ThemeColorSolid('#3498db');
final thm_separatorThickness = AONInt(3);
final thm_outlineThickness = AONInt(3);
final thm_itemNameFont = Font(null);
final thm_menuNameFont = Font(null);
final thm_descriptionFont = Font(null);
final thm_itemNameFontSize = AONAuto();
final thm_menuNameFontSize = AONAuto();
final thm_iconSize = AONAuto();
final thm_descriptionFontSize = AONAuto();
final thm_showItemNameOnCenter = false;
final thm_showDescOnCenter = false;
final thm_showIconOnCenter = false;
final thm_pageIndicatorActiveColor = ThemeColorSolid('#ffffff');
final thm_pageIndicatorPassiveColor = ThemeColorSolid('#474747');
