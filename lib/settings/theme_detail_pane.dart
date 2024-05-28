import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/config/theme.dart';
import 'package:puppet/config_providers.dart';
import 'package:puppet/settings/gradient_picker.dart';
import 'package:puppet/settings/settings_element.dart';
import 'package:puppet/settings/themes_pane.dart';
import 'package:puppet/config/theme.dart' as t;
import 'package:system_fonts/system_fonts.dart';

class ThemeDetailPane extends ConsumerWidget {
  ThemeDetailPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final themeName = ref.watch(themeDetailProvider);
    final ThemeVariants? themeVariants = theme.when(
      data: (value) => value.entries.firstWhere((element) => element.key == themeName).value,
      error: (o, e) => null,
      loading: () => null,
    );
    var nameValue = themeName.toString();
    return themeVariants != null
        ? (ListView(
            children: [
              Card(
                child: Container(
                  height: elementHeight,
                  padding: elementPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Theme Name',
                        style: m.Theme.of(context).textTheme.titleMedium,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 160),
                        child: Focus(
                          child: TextField(
                            controller: TextEditingController(text: nameValue),
                            onChanged: (value) => nameValue = value,
                          ),
                          onFocusChange: (value) {
                            if (!value) {
                              if (nameValue != themeName && !ref.read(themeProvider.notifier).isNameUnique(nameValue)) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Name must be unique'),
                                ));
                              } else if (nameValue != themeName && nameValue.isNotEmpty) {
                                ref.read(themeProvider.notifier).changeName(themeName!, nameValue);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Light Theme',
                  style: m.Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ..._getThemeProps(context, themeVariants.light, themeName, true, ref),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Dark Theme',
                  style: m.Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ..._getThemeProps(context, themeVariants.dark, themeName, false, ref),
            ],
          ))
        : Text('No theme found');
  }

  List<Widget> _getThemeProps(BuildContext context, t.Theme theme, String? themeName, bool isLight, WidgetRef ref) {
    return [
      for (final prop in ThemeProps.values)
        Card(
          child: Container(
            height: elementHeight,
            padding: elementPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  prop.label,
                  style: m.Theme.of(context).textTheme.titleMedium,
                ),
                switch (prop.propType) {
                  AutoOrNum => _getAutoOrNumWidget(prop, theme, themeName, isLight, ref),
                  bool => _getBoolWidget(prop, theme, themeName, isLight, ref),
                  ThemeColor || ThemeColorSolid => _getColorWidget(prop, theme, themeName, isLight, ref),
                  Font => _getFontWidget(prop, theme, themeName, isLight, ref),
                  _ => throw UnimplementedError(),
                },
              ],
            ),
          ),
        ),
    ];
  }

  Widget _getAutoOrNumWidget(ThemeProps prop, t.Theme theme, String? themeName, bool isLight, WidgetRef ref) {
    final isAuto = prop.getPropVariable(theme) is AONAuto;
    var intVal = prop.getPropVariable(theme).toString();
    return Row(
      children: [
        FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 20),
        SizedBox(width: 8),
        Switch(
            value: isAuto,
            onChanged: (val) {
              _updateTheme(val ? AONAuto() : AONInt.def(), prop, theme, themeName, isLight, ref);
            }),
        VerticalDivider(),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 50),
          child: Focus(
            child: TextField(
              controller: TextEditingController(text: intVal),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !isAuto,
              onChanged: (value) => intVal = value,
            ),
            onFocusChange: (value) {
              if (!value) {
                _updateTheme(AONInt.fromStr(intVal), prop, theme, themeName, isLight, ref);
              }
            },
          ),
        ),
      ],
    );
  }

  _getBoolWidget(ThemeProps prop, t.Theme theme, String? themeName, bool isLight, WidgetRef ref) {
    return Row(
      children: [
        Text(
          prop.getPropVariable(theme) ? 'On' : 'Off',
          style: m.Theme.of(ref.context).textTheme.titleMedium,
        ),
        SizedBox(width: 10),
        Switch(
          value: prop.getPropVariable(theme),
          onChanged: (val) {
            _updateTheme(val, prop, theme, themeName, isLight, ref);
          },
        ),
      ],
    );
  }

  _getFontWidget(ThemeProps prop, t.Theme theme, String? themeName, bool isLight, WidgetRef ref) {
    final fontVal = prop.getPropVariable(theme).value as String;
    return SystemFontSelector(
      initial: fontVal.isEmpty ? null : fontVal,
      onFontSelected: (val) {
        _updateTheme(Font(val), prop, theme, themeName, isLight, ref);
      },
    );
  }

  _getColorWidget(ThemeProps prop, t.Theme theme, String? themeName, bool isLight, WidgetRef ref) {
    return InkWell(
      onTap: () => _showColorPickerDialog(ref, prop, theme).then((value) {
        if (value == null) return;
        _updateTheme(value, prop, theme, themeName, isLight, ref);
      }),
      child: Stack(
        children: [
          ThemeColorIndicator.fromThemeColor(
            themeColor: prop.getPropVariable(theme) as ThemeColor,
            width: 60,
            height: 60,
            radius: BorderRadius.circular(30),
          ),
        ],
      ),
    );
  }

  Future<ThemeColor?> _showColorPickerDialog(WidgetRef ref, ThemeProps prop, t.Theme theme) {
    t.ThemeColor res = prop.getPropVariable(theme);
    return showDialog<ThemeColor?>(
      context: ref.context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ThemeColorPicker(
                initial: prop.getPropVariable(theme),
                onChange: (p0) => res = p0,
                availableTypes: prop.propType == ThemeColorSolid
                    ? [PickerType.solid]
                    : [PickerType.solid, PickerType.linearGradient, PickerType.radialGradient, PickerType.random],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: m.Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: m.Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(res);
              },
            ),
          ],
        );
      },
    );
  }

  void _updateTheme(dynamic val, ThemeProps prop, t.Theme theme, String? themeName, bool isLight, WidgetRef ref) {
    prop.setPropVariable(theme, val);
    ref.read(themeProvider.notifier).updateTheme(theme, themeName, isLight);
  }
}
