import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config_providers.dart';
import 'package:puppet/settings/menus_pane.dart';
import 'package:puppet/settings/settings_element.dart';

class MenuDetailPane extends ConsumerWidget {
  MenuDetailPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(configProvider);
    final menuName = ref.watch(menuDetailProvider);
    final id = conf.when(
      data: (value) => value.menus.indexWhere((element) => element.name == menuName),
      error: (o, e) => 0,
      loading: () => 0,
    );
    return ListView(
      children: [
        SettingsElement(conf: conf.value!, field: Fields.name, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.type, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.menuHotkey, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.theme, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.colorScheme, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.width, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.height, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.position, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.marginVertical, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.marginHorizontal, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.monitor, menuId: id),
        SettingsElement(conf: conf.value!, field: Fields.maxElement, menuId: id),
      ],
    );
  }
}
