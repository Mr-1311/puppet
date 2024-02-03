import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/config/config_repository.dart';
import 'package:puppet/error_page.dart';
import 'package:puppet/wheel.dart';
import 'package:window_manager/window_manager.dart';

final configRepositoryProvider = FutureProvider<ConfigRepository>((ref) {
  return ConfigRepository.getInstance();
});

final menuProvider =
    AsyncNotifierProvider<MenuNotifier, Menus>(MenuNotifier.new);

class MenuNotifier extends AsyncNotifier<Menus> {
  @override
  Future<Menus> build() async {
    final configRepo = await ref.watch(configRepositoryProvider.future);

    return configRepo.config.menus
        .firstWhere((element) => element.name == configRepo.config.mainMenu);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(640, 640),
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

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(configRepositoryProvider);
    conf.whenData((value) {
      print(value.config.toString());
      print(value.config.errors);
    });
    final menu = ref.watch(menuProvider);
    menu.whenData((value) {
      print(value.toString());
    });

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: switch (conf) {
          AsyncData(:final value) when value.config.errors.isNotEmpty =>
            ErrorPage(value.config.errors),
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
