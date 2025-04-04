import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/config/path_manager.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:puppet/providers.dart';
import 'package:puppet/settings/menus_pane.dart';
import 'package:puppet/widgets/item_icon.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:collection/collection.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:path/path.dart';

const elementHeight = 82.0;
const elementPadding = EdgeInsets.symmetric(horizontal: 32);

enum Fields {
  mainMenu('Main Menu', description: 'Select which menu to show when the application starts'),
  mainHotkey('Shortcut', description: 'Global shortcut key combination to open the main menu. Note: On linux global shortcuts may not work, try to set shortcut via your WM/Compositor to run `Puppet`'),
  name('Name', description: 'Name of the menu - must be unique across all menus'),
  type('Type', description: 'Menu display style - either wheel (circular) or list (vertical) layout'),
  menuHotkey('Shortcut', description: 'Shortcut key combination to open this specific menu. Note: On linux global shortcuts may not work, try to set shortcut via your WM/Compositor, to open a specific menu pass menu argument to `Puppet` like `--menu "menu name"`'),
  theme('Theme', description: 'Visual theme for the menu - use default or select a custom theme'),
  colorScheme('Color Scheme', description: 'Choose between light, dark, or system color scheme for the menu'),
  width('Width', description: 'Width of the menu in pixels (px) or percentage (%) of screen width'),
  height('Height', description: 'Height of the menu in pixels (px) or percentage (%) of screen height'),
  position('Position',
      description:
          'Menu position on screen - can be relative to mouse cursor or fixed position with vertical/horizontal alignment. Note: On Linux Wayland compositors, mouse-relative positioning is currently unsupported'),
  marginVertical('Margin Vertical',
      description: 'Vertical margin from the top/bottom of the screen in pixels (px) or percentage (%)'),
  marginHorizontal('Margin Horizontal',
      description: 'Horizontal margin from the left/right of the screen in pixels (px) or percentage (%)'),
  monitor('Monitor', description: 'Select which monitor to display the menu on - auto or specific display'),
  maxElement('Max Element',
      description:
          'Wheel: Maximum number of elements to display on one page\nList: If height not set, set height based on this number of items'),
  itemName('Name',
      description: 'Name of the menu item - displayed as the primary text, this can be overridden in the plugin'),
  itemDescription('Description',
      description: 'Optional description text shown below the item name, this can be overridden in the plugin'),
  itemRepeat('Repetition', description: 'Item(s) can be repeated without closing the menu after being used'),
  itemShortcut('Hotkey',
      description:
          'Add a hotkey for the item(s) generated by the plugin. If there are multiple item with the same hotkey, the first item will be selected'),
  itemIcon('Icon',
      description:
          'Override the icon of the element - set empty to let plugin set the icon. Can be a Font Awesome icon or local image'),
  itemPlugin('Plugin',
      description: 'Select the plugin to generate the element(s) - determines the action when item is selected'),
  itemPluginArg('', description: 'Arguments passed to the selected plugin - varies based on plugin type');

  const Fields(this.label, {this.description});
  final String label;
  final String? description;
}

class SettingsElement extends ConsumerStatefulWidget {
  SettingsElement(
      {required this.conf, required this.field, this.menuId = 0, this.itemId = -1, this.pluginArg, super.key});

  final Config conf;
  final Fields field;
  final int menuId;
  final int itemId;
  final PluginArg? pluginArg;

  @override
  ConsumerState<SettingsElement> createState() => _SettingsElementState();
}

class _SettingsElementState extends ConsumerState<SettingsElement> {
  var sizeType = {'px'};
  var verticalPosVal = '';
  var horizontalPosVal = '';
  List<Display>? displays;

  late String fieldName;
  late String fieldDesc;

  @override
  void initState() {
    super.initState();
    screenRetriever.getAllDisplays().then((value) => setState(() {
          displays = value;
        }));

    fieldName = widget.field.label;
    fieldDesc = widget.field.description ?? '';
    if (widget.pluginArg != null && widget.field == Fields.itemPluginArg) {
      fieldName = widget.pluginArg!.name;
      fieldDesc = widget.pluginArg!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: elementHeight,
        padding: elementPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (fieldDesc.isNotEmpty)
                    Tooltip(
                      message: fieldDesc,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          fieldDesc,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            getFieldWidget(ref, context),
          ],
        ),
      ),
    );
  }

  Widget getFieldWidget(WidgetRef ref, BuildContext context) {
    switch (widget.field) {
      case Fields.mainMenu:
        return Container(
          width: 170,
          child: DropdownMenu(
            initialSelection: widget.conf.mainMenu,
            dropdownMenuEntries: getDropdownMenuEntries(),
            trailingIcon: FaIcon(FontAwesomeIcons.caretDown),
            selectedTrailingIcon: FaIcon(FontAwesomeIcons.caretUp),
            onSelected: (value) {
              widget.conf.mainMenu = value ?? '';
              ref.read(configProvider.notifier).updateConfig(widget.conf);
            },
          ),
        );
      case Fields.name:
        var nameValue = widget.conf.menus[widget.menuId].name;
        final isMainMenu = widget.conf.mainMenu == nameValue;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 160),
          child: Focus(
            child: TextField(
              controller: TextEditingController(text: nameValue),
              onChanged: (value) => nameValue = value,
            ),
            onFocusChange: (value) {
              if (!value) {
                if (nameValue != widget.conf.menus[widget.menuId].name &&
                    widget.conf.menus.firstWhereOrNull((element) => element.name == nameValue) != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Name must be unique'),
                  ));
                } else {
                  widget.conf.menus[widget.menuId].name = nameValue;
                  if (isMainMenu) {
                    widget.conf.mainMenu = nameValue;
                  }
                  ref.read(menuDetailProvider.notifier).state = nameValue;
                  ref.read(configProvider.notifier).updateConfig(widget.conf);
                }
              }
            },
          ),
        );
      case Fields.itemName || Fields.itemDescription || Fields.itemShortcut || Fields.itemPluginArg:
        var nameValue = switch (widget.field) {
          Fields.itemName => widget.conf.menus[widget.menuId].items[widget.itemId].name,
          Fields.itemDescription => widget.conf.menus[widget.menuId].items[widget.itemId].description,
          Fields.itemShortcut => widget.conf.menus[widget.menuId].items[widget.itemId].shortcut,
          Fields.itemPluginArg =>
            widget.conf.menus[widget.menuId].items[widget.itemId].pluginArgs.keys.contains(widget.pluginArg!.name)
                ? widget.conf.menus[widget.menuId].items[widget.itemId].pluginArgs[widget.pluginArg!.name] as String
                : widget.pluginArg!.defaultValue,
          _ => '',
        };

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.field == Fields.itemShortcut ? 60 : 160),
          child: Focus(
            child: TextField(
              controller: TextEditingController(text: nameValue),
              onChanged: (value) => nameValue = value,
              maxLength: widget.field == Fields.itemShortcut ? 1 : null,
              decoration: InputDecoration(
                counterText: '',
              ),
            ),
            onFocusChange: (value) {
              if (!value) {
                switch (widget.field) {
                  case Fields.itemName:
                    widget.conf.menus[widget.menuId].items[widget.itemId].name = nameValue;
                    break;
                  case Fields.itemDescription:
                    widget.conf.menus[widget.menuId].items[widget.itemId].description = nameValue;
                    break;
                  case Fields.itemShortcut:
                    widget.conf.menus[widget.menuId].items[widget.itemId].shortcut = nameValue;
                    break;
                  case Fields.itemPluginArg:
                    widget.conf.menus[widget.menuId].items[widget.itemId].pluginArgs[widget.pluginArg!.name] =
                        nameValue;
                    break;
                  default:
                }
                ref.read(configProvider.notifier).updateConfig(widget.conf);
              }
            },
          ),
        );
      case Fields.itemRepeat:
        return Switch(
          value: widget.conf.menus[widget.menuId].items[widget.itemId].repeat,
          onChanged: (value) {
            widget.conf.menus[widget.menuId].items[widget.itemId].repeat = value;
            ref.read(configProvider.notifier).updateConfig(widget.conf);
          },
        );
      case Fields.mainHotkey || Fields.menuHotkey:
        return Tooltip(
          message: 'Change HotKey',
          child: TextButton(
              onPressed: () => _setHotkeyDialogBuilder(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: widget.field == Fields.mainHotkey
                    ? HotKeyVirtualView(hotKey: widget.conf.hotkey)
                    : (widget.conf.menus[widget.menuId].hotkey == null
                        ? Text('Not Set')
                        : HotKeyVirtualView(hotKey: widget.conf.menus[widget.menuId].hotkey!)),
              )),
        );
      case Fields.type:
        return ChipMenu(
          menuItemList: [
            (
              'wheel',
              ImageIcon(
                AssetImage('assets/icon_wheel.png'),
                size: 16,
              )
            ),
            (
              'list',
              ImageIcon(
                AssetImage('assets/icon_list.png'),
                size: 16,
              )
            ),
          ],
          initialSelectionIndex: ['wheel', 'list'].indexOf(widget.conf.menus[widget.menuId].type),
          onSelected: (p0) {
            widget.conf.menus[widget.menuId].type = p0;
            ref.read(configProvider.notifier).updateConfig(widget.conf);
          },
        );
      case Fields.theme:
        final themes = ref.watch(themeProvider);
        final initial = widget.conf.menus[widget.menuId].getThemeName().isEmpty
            ? '/default'
            : widget.conf.menus[widget.menuId].getThemeName();
        return switch (themes) {
          AsyncData(:final value) => Container(
              width: 200,
              child: DropdownMenu(
                initialSelection: initial,
                dropdownMenuEntries: <DropdownMenuEntry<String>>[
                  DropdownMenuEntry(
                    value: '/default',
                    label: 'Default',
                  ),
                  ...[
                    for (var name in value.keys)
                      DropdownMenuEntry(
                        label: name,
                        value: name,
                      )
                  ],
                ],
                trailingIcon: FaIcon(FontAwesomeIcons.caretDown),
                selectedTrailingIcon: FaIcon(FontAwesomeIcons.caretUp),
                onSelected: (value) {
                  widget.conf.menus[widget.menuId].setTheme(value);
                  ref.read(configProvider.notifier).updateConfig(widget.conf);
                },
              ),
            ),
          _ => CircularProgressIndicator(),
        };
      case Fields.itemPlugin:
        final plugins = ref.watch(pluginProvider);
        final initial = widget.conf.menus[widget.menuId].items[widget.itemId].plugin;
        return Container(
          width: 200,
          child: DropdownMenu(
            initialSelection: initial,
            dropdownMenuEntries: <DropdownMenuEntry<String>>[
              ...[
                for (var plugin in plugins)
                  DropdownMenuEntry(
                    label: plugin.name,
                    value: plugin.name,
                    labelWidget: Column(
                      children: [
                        Text(plugin.name),
                        Text(
                          plugin.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
              ],
            ],
            trailingIcon: FaIcon(FontAwesomeIcons.caretDown),
            selectedTrailingIcon: FaIcon(FontAwesomeIcons.caretUp),
            onSelected: (value) {
              widget.conf.menus[widget.menuId].items[widget.itemId].plugin = value ?? '';
              ref.read(configProvider.notifier).updateConfig(widget.conf);
            },
          ),
        );
      case Fields.colorScheme:
        var colorScheme = widget.conf.menus[widget.menuId].themeColorScheme;
        return SegmentedButton(
          segments: [
            ButtonSegment(
              value: 'light',
              label: Icon(Icons.light_mode),
              tooltip: 'Light Mode',
            ),
            ButtonSegment(
              value: 'system',
              label: Icon(Icons.computer),
              tooltip: 'System Default',
            ),
            ButtonSegment(
              value: 'dark',
              label: Icon(Icons.dark_mode),
              tooltip: 'Dark Mode',
            ),
          ],
          selected: {colorScheme},
          onSelectionChanged: (p0) {
            widget.conf.menus[widget.menuId].themeColorScheme = p0.first;
            ref.read(configProvider.notifier).updateConfig(widget.conf);
          },
          showSelectedIcon: false,
        );
      case Fields.width || Fields.height || Fields.marginVertical || Fields.marginHorizontal:
        var value = switch (widget.field) {
          Fields.width => widget.conf.menus[widget.menuId].width,
          Fields.height => widget.conf.menus[widget.menuId].height,
          Fields.marginVertical => widget.conf.menus[widget.menuId].marginVertical,
          Fields.marginHorizontal => widget.conf.menus[widget.menuId].marginHorizontal,
          _ => ''
        };
        if (value.endsWith('%')) {
          setState(() {
            sizeType = {'%'};
          });
        }
        return Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 50),
              child: Focus(
                child: TextField(
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  controller: TextEditingController(text: value.replaceAll(RegExp('%|px|_'), '')),
                  onChanged: (text) => value = text + sizeType.first,
                ),
                onFocusChange: (focus) {
                  if (!focus) {
                    final newVal = !value.startsWith(RegExp(r'[0-9]')) ? '_' : value;
                    switch (widget.field) {
                      case Fields.width:
                        widget.conf.menus[widget.menuId].width = newVal;
                      case Fields.height:
                        widget.conf.menus[widget.menuId].height = newVal;
                      case Fields.marginVertical:
                        widget.conf.menus[widget.menuId].marginVertical = newVal;
                      case Fields.marginHorizontal:
                        widget.conf.menus[widget.menuId].marginHorizontal = newVal;
                      case _:
                    }
                    ref.read(configProvider.notifier).updateConfig(widget.conf);
                  }
                },
              ),
            ),
            SizedBox(
              width: 16,
            ),
            SegmentedButton(
              segments: [
                ButtonSegment(
                  value: 'px',
                  label: Text('px'),
                ),
                ButtonSegment(
                  value: '%',
                  label: Text('%'),
                ),
              ],
              selected: sizeType,
              onSelectionChanged: (p0) {
                value = p0.first == 'px' ? value.replaceAll('%', 'px') : value.replaceAll('px', '%');
                switch (widget.field) {
                  case Fields.width:
                    widget.conf.menus[widget.menuId].width = value;
                  case Fields.height:
                    widget.conf.menus[widget.menuId].height = value;
                  case Fields.marginVertical:
                    widget.conf.menus[widget.menuId].marginVertical = value;
                  case Fields.marginHorizontal:
                    widget.conf.menus[widget.menuId].marginHorizontal = value;
                  case _:
                }
                ref.read(configProvider.notifier).updateConfig(widget.conf);
                setState(() {
                  sizeType = p0;
                });
              },
              showSelectedIcon: false,
            ),
          ],
        );
      case Fields.position:
        var isMouse = widget.conf.menus[widget.menuId].position == 'mouse';
        var split = widget.conf.menus[widget.menuId].position.split('-');
        var verticalIndex = ['center', 'top', 'bottom'].indexOf(split.first).clamp(0, 2);
        var horizontalIndex = ['center', 'left', 'right'].indexOf(split.last).clamp(0, 2);
        return Row(
          children: [
            Icon(Icons.mouse),
            Tooltip(
              message: 'Open menu where mouse cursor is located',
              child: Switch(
                  value: isMouse,
                  onChanged: (val) {
                    widget.conf.menus[widget.menuId].position = val
                        ? 'mouse'
                        : '${verticalPosVal.isEmpty ? 'center' : verticalPosVal}-${horizontalPosVal.isEmpty ? 'center' : horizontalPosVal}';
                    setState(() {
                      isMouse = val;
                    });
                    ref.read(configProvider.notifier).updateConfig(widget.conf);
                  }),
            ),
            VerticalDivider(),
            Tooltip(
              message: 'Vertical Alignment',
              child: ChipMenu(
                menuItemList: [
                  ('center', Icon(Icons.align_vertical_center)),
                  ('top', Icon(Icons.align_vertical_top)),
                  ('bottom', Icon(Icons.align_vertical_bottom)),
                ],
                initialSelectionIndex: verticalIndex,
                disabled: isMouse,
                onSelected: (p0) {
                  verticalPosVal = p0;
                  widget.conf.menus[widget.menuId].position =
                      '$p0-${horizontalPosVal.isEmpty ? 'center' : horizontalPosVal}';
                  ref.read(configProvider.notifier).updateConfig(widget.conf);
                },
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Tooltip(
              message: 'Horizontal Alignment',
              child: ChipMenu(
                menuItemList: [
                  ('center', Icon(Icons.align_horizontal_center)),
                  ('left', Icon(Icons.align_horizontal_left)),
                  ('right', Icon(Icons.align_horizontal_right)),
                ],
                initialSelectionIndex: horizontalIndex,
                disabled: isMouse,
                onSelected: (p0) {
                  horizontalPosVal = p0;
                  widget.conf.menus[widget.menuId].position =
                      '${verticalPosVal.isEmpty ? 'center' : verticalPosVal}-$p0';
                  ref.read(configProvider.notifier).updateConfig(widget.conf);
                },
              ),
            ),
          ],
        );
      case Fields.monitor:
        return ChipMenu(
          menuItemList: [
            ('auto', FaIcon(FontAwesomeIcons.arrowPointer)),
            for (int i = 0; i < ((displays != null) ? displays!.length : 0); i++)
              ('Display ${i + 1}', FaIcon(FontAwesomeIcons.display)),
          ],
          initialSelectionIndex: int.tryParse(widget.conf.menus[widget.menuId].monitor) ?? 0,
          onSelected: (p0) {
            widget.conf.menus[widget.menuId].monitor =
                p0 == 'auto' ? 'auto' : int.tryParse(p0.characters.last).toString();
            ref.read(configProvider.notifier).updateConfig(widget.conf);
          },
        );
      case Fields.maxElement:
        var val = widget.conf.menus[widget.menuId].maxElement.toString();
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 50),
          child: Focus(
            child: TextField(
              controller: TextEditingController(text: val),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => val = value,
            ),
            onFocusChange: (value) {
              if (!value) {
                widget.conf.menus[widget.menuId].maxElement = int.parse(val);
                ref.read(configProvider.notifier).updateConfig(widget.conf);
              }
            },
          ),
        );
      case Fields.itemIcon:
        final iconData = widget.conf.menus[widget.menuId].items[widget.itemId].icon;
        return Row(
          children: [
            Tooltip(
                message: 'Pick icon from icon picker',
                child: IconButton(onPressed: () => _pickIcon(this.context), icon: FaIcon(FontAwesomeIcons.icons))),
            Tooltip(
                message: 'Pick image from local storage',
                child:
                    IconButton(onPressed: () => _pickImage(this.context), icon: FaIcon(FontAwesomeIcons.folderOpen))),
            Tooltip(
                message: 'Clear icon',
                child: IconButton(
                    onPressed: () {
                      widget.conf.menus[widget.menuId].items[widget.itemId].icon = '';
                      ref.read(configProvider.notifier).updateConfig(widget.conf);
                    },
                    icon: FaIcon(FontAwesomeIcons.rotateRight))),
            VerticalDivider(),
            (iconData == null)
                ? Text('No Icon')
                : ItemIcon(
                    icon: iconData,
                    size: 26,
                  ),
          ],
        );
    }
  }

  List<DropdownMenuEntry> getDropdownMenuEntries() {
    switch (widget.field) {
      case Fields.mainMenu:
        return [
          for (var menu in widget.conf.menus)
            DropdownMenuEntry(
              label: menu.name,
              value: menu.name,
            )
        ];
      case Fields.type:
        return [
          DropdownMenuEntry(label: 'wheel', value: 'wheel'),
          DropdownMenuEntry(label: 'list', value: 'list'),
        ];
      default:
    }
    return [];
  }

  Future<void> _setHotkeyDialogBuilder(BuildContext context, WidgetRef ref) async {
    HotKey? hotkey = null;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set shortcut'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Press the hotkey to set it as the shortcut'),
              SizedBox(height: 20),
              HotKeyRecorder(
                  initalHotKey: widget.field == Fields.mainHotkey ? widget.conf.hotkey : null,
                  onHotKeyRecorded: (value) {
                    hotkey = value;
                  }),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Dismiss'),
              onPressed: () {
                hotkey = null;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Set'),
              onPressed: () async {
                if (widget.field == Fields.menuHotkey && hotkey == null) {
                  widget.conf.menus[widget.menuId].hotkey = null;
                  widget.conf.menus[widget.menuId].shortcut = {};
                  ref.read(configProvider.notifier).updateConfig(widget.conf);
                  Navigator.of(context).pop();
                }
                if (hotkey != null) {
                  final shortcutMap = {
                    'key': hotkey!.toJson()['key'],
                    'modifiers': hotkey!.toJson()['modifiers'],
                  };
                  bool? shouldSet = false;
                  final (isUnique, isMainMenu, menuName) = _isHotkeyUnique(shortcutMap);
                  if (!isUnique) {
                    shouldSet = await _hotkeyConfirmationDialogBuilder(context, ref, isMainMenu ? null : menuName);
                    if (shouldSet == true) {
                      widget.conf.menus.firstWhere((menu) => menu.name == menuName).shortcut = {};
                      widget.conf.menus.firstWhere((menu) => menu.name == menuName).hotkey = null;
                      widget.conf.menus[widget.menuId].hotkey = hotkey;
                      widget.conf.menus[widget.menuId].shortcut = shortcutMap;
                      ref.read(configProvider.notifier).updateConfig(widget.conf);
                      Navigator.of(context).pop();
                    }
                  } else {
                    if (widget.field == Fields.mainHotkey) {
                      widget.conf.hotkey = hotkey!;
                      widget.conf.shortcut = shortcutMap;
                    } else {
                      widget.conf.menus[widget.menuId].hotkey = hotkey;
                      widget.conf.menus[widget.menuId].shortcut = shortcutMap;
                    }
                    ref.read(configProvider.notifier).updateConfig(widget.conf);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // returns (is unique, is main menu, menu name)
  (bool, bool, String) _isHotkeyUnique(Map<String, dynamic> shortcut) {
    // check main menu shortcut
    if (DeepCollectionEquality().equals(shortcut, widget.conf.shortcut)) {
      return (false, true, '');
    }
    // check other menu shortcuts
    final menu = widget.conf.menus.firstWhereOrNull((m) => DeepCollectionEquality().equals(m.shortcut, shortcut));
    if (menu != null && menu.name != widget.conf.menus[widget.menuId].name) {
      return (false, false, menu.name);
    }
    return (true, false, '');
  }

  // Hotkey confirmation dialog
  Future<bool?> _hotkeyConfirmationDialogBuilder(BuildContext context, WidgetRef ref, String? menuName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Shortcut already set'),
          content: Text(menuName == null
              ? 'The shortcut has been set for the main menu.\nPlease change main menu shortcut first or set another shortcut.'
              : 'The shortcut has been set for "$menuName" menu, do you want to set it anyway?\nThis will delete "$menuName" menu shortcut.'),
          actions: menuName == null
              ? <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                ]
              : <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: const Text('Dismiss'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge,
                    ),
                    child: const Text('Set'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
        );
      },
    );
  }

  _pickIcon(BuildContext context) async {
    IconPickerIcon? icon = await showIconPicker(context,
        configuration: SinglePickerConfiguration(
          iconPackModes: [IconPack.fontAwesomeIcons],
          showTooltips: true,
        ));

    if (icon != null) {
      final iconString = '${icon.data.codePoint.toRadixString(16)}:${icon.data.fontFamily}:${icon.data.fontPackage}';
      widget.conf.menus[widget.menuId].items[widget.itemId].icon = iconString;
      iconDatas[iconString] = icon.data;
      ref.read(configProvider.notifier).updateConfig(widget.conf);
    }
  }

  Future<bool> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedIconImageExtensions.map((e) => e.substring(1)).toList(),
    );

    if (result != null && result.files.isNotEmpty) {
      File? file = null;
      try {
        file = await File('${PathManager().icons + result.files.first.name}').create(recursive: true, exclusive: true);
      } on PathExistsException {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('File already exists'),
              content: Text('Image file named "${result.files.first.name}" already exists'),
              actions: [
                TextButton(
                  child: Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      if (file != null && result.files.first.path != null) {
        File(result.files.first.path!).copySync(file.path);
        widget.conf.menus[widget.menuId].items[widget.itemId].icon = result.files.first.name;
        iconDatas[result.files.first.name] = MemoryImage(file.readAsBytesSync());
        ref.read(configProvider.notifier).updateConfig(widget.conf);
        return true;
      }
    }
    return false;
  }

  _pickImage(BuildContext context) {
    Directory directory = Directory(PathManager().icons);
    List<FileSystemEntity> files = directory.listSync().toList();
    final images = files.where((file) => supportedIconImageExtensions.contains(extension(file.path))).toList();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Recently added images'),
            content: Container(
              width: 500,
              height: 400,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                        child: Image.file(File(images[index].path)),
                        onTap: () {
                          widget.conf.menus[widget.menuId].items[widget.itemId].icon = basename(images[index].path);
                          iconDatas[basename(images[index].path)] =
                              MemoryImage(File(images[index].path).readAsBytesSync());
                          ref.read(configProvider.notifier).updateConfig(widget.conf);
                          Navigator.of(context).pop();
                        }),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text('Select image from local storage'),
                onPressed: () async {
                  if (await _pickFile(context)) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}

class ChipMenu extends StatefulWidget {
  ChipMenu(
      {required this.menuItemList,
      required this.initialSelectionIndex,
      this.onSelected,
      this.disabled = false,
      super.key});

  final List<(String, Widget)> menuItemList;
  final int initialSelectionIndex;
  final Function(String)? onSelected;
  final bool disabled;

  @override
  State<ChipMenu> createState() => _ChipMenuState();
}

class _ChipMenuState extends State<ChipMenu> {
  late String _selectedText;
  late Widget _selectedIcon;

  @override
  void initState() {
    super.initState();
    final index = widget.initialSelectionIndex > widget.menuItemList.length ? 0 : widget.initialSelectionIndex;
    _selectedText = widget.menuItemList[index].$1;
    _selectedIcon = widget.menuItemList[index].$2;
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return FilterChip(
          label: Row(
            children: [
              _selectedIcon,
              SizedBox(width: 5),
              Text(_selectedText),
            ],
          ),
          // selected: true,
          onSelected: (widget.disabled)
              ? null
              : (_) {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
        );
      },
      menuChildren: [
        for (final rec in widget.menuItemList)
          MenuItemButton(
            leadingIcon: rec.$2,
            child: Text(rec.$1),
            onPressed: () {
              setState(() {
                _selectedText = rec.$1;
                _selectedIcon = rec.$2;
              });
              widget.onSelected?.call(rec.$1);
            },
          ),
      ],
    );
  }
}
