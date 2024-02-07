import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/config/config_repository.dart';
import 'package:puppet/error_page.dart';
import 'package:puppet/wheel.dart';
import 'package:window_manager/window_manager.dart';
import 'package:puppet/config/calculate_window_position.dart';

final configRepositoryProvider = FutureProvider.family<ConfigRepository, String?>((ref, mainMenu) {
  return ConfigRepository.getInstance(mainMenu);
});

final menuProvider = AsyncNotifierProvider.family<MenuNotifier, Menus, String?>(MenuNotifier.new);

class MenuNotifier extends FamilyAsyncNotifier<Menus, String?> {
  @override
  Future<Menus> build(String? menu) async {
    final configRepo = await ref.watch(configRepositoryProvider(menu).future);

    final mainMenu = configRepo.config.menus.firstWhere((element) => element.name == configRepo.config.mainMenu);
    windowManager.setSize(mainMenu.size);

    final positionCoordinate = await calculateWindowPosition(
        windowSize: mainMenu.size, alignment: mainMenu.alignment, offset: mainMenu.offset, display: mainMenu.monitor);
    windowManager.setPosition(positionCoordinate);

    return mainMenu;
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    // size: Size(640, 640),
    // center: true,
    backgroundColor: Colors.transparent,
    // skipTaskbar: true,
    // alwaysOnTop: true,
  );

  windowManager.setResizable(false);
  if (Platform.isMacOS) {
    windowManager.setMovable(false);
    windowManager.setMinimizable(false);
    windowManager.setMaximizable(false);
    windowManager.setVisibleOnAllWorkspaces(true);
    windowManager.setHasShadow(false);
  }
  if (Platform.isWindows) {
    windowManager.setMinimizable(false);
    windowManager.setMaximizable(false);
    windowManager.setHasShadow(false);
  }

  windowManager.setAsFrameless();

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final argParser = ArgParser();
  argParser.addOption('menu', abbr: 'm', help: 'set the menu to show on start');
  final results = argParser.parse(args);

  runApp(ProviderScope(child: MainApp(results)));
}

class MainApp extends ConsumerWidget {
  const MainApp(this.args, {super.key});

  final ArgResults args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(configRepositoryProvider(args['menu']));
    conf.whenData((value) {
      print(value.config.toString());
      print('errors: ${value.config.errors}');
      print('warnings: ${value.config.warnings}');
    });
    final menu = ref.watch(menuProvider(args['menu']));
    menu.whenData((value) {
      print(value.toString());
    });

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: switch (conf) {
          AsyncData(:final value) when value.config.errors.isNotEmpty => ErrorPage(value.config.errors),
          _ => switch (menu) {
              AsyncData(:final value) => Menu(menu: value),
              _ => CircularProgressIndicator(),
            }
        });
  }
}

class Menu extends StatelessWidget {
  const Menu({required this.menu, super.key});

  final Menus menu;

  // TODO: generate menu items from plugin and send generated items to menu types
  @override
  Widget build(BuildContext context) {
    return switch (menu) {
      Menus(menuType: MenuType.wheel) => Wheel(menu: menu),
      Menus(menuType: MenuType.list) => CircularProgressIndicator(),
      Menus(menuType: MenuType.canvas) => CircularProgressIndicator(),
    };
  }
}
