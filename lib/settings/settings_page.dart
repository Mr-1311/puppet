import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/providers.dart';
import 'package:puppet/settings/menus_pane.dart';
import 'package:puppet/settings/plugins_pane.dart';
import 'package:puppet/settings/themes_pane.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    final themeData = ThemeData(colorSchemeSeed: Colors.blue);
    final darkThemeData =
        ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.dark);
    return MaterialApp(
      theme: themeData,
      darkTheme: darkThemeData,
      themeMode: config.whenOrNull(data: (conf) {
            switch (conf.menus
                .firstWhere((element) => element.name == conf.mainMenu)
                .themeColorScheme) {
              case 'light':
                return ThemeMode.light;
              case 'dark':
                return ThemeMode.dark;
              default:
                return ThemeMode.system;
            }
          }) ??
          ThemeMode.system,
      home: SettingsScaffold(),
    );
  }
}

class SettingsScaffold extends ConsumerStatefulWidget {
  const SettingsScaffold({super.key});

  @override
  ConsumerState<SettingsScaffold> createState() => _SettingsScaffoldState();
}

class _SettingsScaffoldState extends ConsumerState<SettingsScaffold> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    // ref.read(systemBrightnessProvider.notifier).state =
    //     MediaQuery.of(context).platformBrightness == Brightness.dark ? 'dark' : 'light';
    ref
        .watch(systemBrightnessNotifierProvider.notifier)
        .setSystemTheme(context);

    final surfaceColor = Color.alphaBlend(
        Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
        Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white);

    final conf = ref.watch(configProvider).whenOrNull(data: (value) => value);
    return Scaffold(
      backgroundColor: surfaceColor,
      body: Row(
        children: [
          NavigationDrawer(
            backgroundColor: surfaceColor,
            surfaceTintColor: surfaceColor,
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 16, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 95,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'uppet',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
              ),
              NavigationDrawerDestination(
                label: Text('Menus'),
                icon: FaIcon(FontAwesomeIcons.list),
              ),
              NavigationDrawerDestination(
                label: Text('Themes'),
                icon: FaIcon(FontAwesomeIcons.palette),
              ),
              NavigationDrawerDestination(
                label: Text('Plugins'),
                icon: FaIcon(FontAwesomeIcons.puzzlePiece),
              ),
              ...(conf != null && conf.warnings.isNotEmpty)
                  ? [
                      NavigationDrawerDestination(
                        label: Text('Warnings'),
                        icon: FaIcon(FontAwesomeIcons.triangleExclamation),
                      ),
                    ]
                  : [],
            ],
          ),
          // Right panel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                child: Scaffold(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  body: Column(
                    children: [
                      generatePanelHeader(ref, context, index),
                      Expanded(
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: switch (index) {
                              0 => MenusPane(),
                              1 => ThemesPane(),
                              2 => PluginsPane(),
                              _ => SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      for (var warning in conf!.warnings)
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: (Text(warning)),
                                        ),
                                    ],
                                  ),
                                ),
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Padding generatePanelHeader(WidgetRef ref, BuildContext context, int index) {
  final menuDetail = ref.watch(menuDetailProvider);
  final themeDetail = ref.watch(themeDetailProvider);
  final pluginDetail = ref.watch(selectedPluginProvider);
  final title = switch (index) {
    0 when menuDetail == null => 'Menus',
    0 when menuDetail != null => menuDetail,
    1 when themeDetail == null => 'Themes',
    1 when themeDetail != null => themeDetail,
    2 when pluginDetail == null => 'Plugins',
    2 when pluginDetail != null => pluginDetail,
    _ => 'Settings',
  };
  final style = Theme.of(context).textTheme.headlineMedium!;

  return Padding(
    padding: const EdgeInsets.all(18.0),
    child: Row(
      children: [
        IconButton(
            onPressed: switch (index) {
              0 when menuDetail != null => () =>
                  ref.read(menuDetailProvider.notifier).state = null,
              1 when themeDetail != null => () =>
                  ref.read(themeDetailProvider.notifier).state = null,
              2 when pluginDetail != null => () =>
                  ref.read(selectedPluginProvider.notifier).state = null,
              _ => null,
            },
            icon: FaIcon(
              FontAwesomeIcons.chevronLeft,
            )),
        Text(
          title,
          style: style,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
