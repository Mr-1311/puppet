import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/providers.dart';
import 'package:puppet/settings/menu_item_element.dart';
import 'package:puppet/settings/menus_pane.dart';
import 'package:puppet/settings/settings_element.dart';

class MenuDetailPane extends ConsumerWidget {
  MenuDetailPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(configProvider);
    final menuName = ref.watch(menuDetailProvider);
    final menuId = conf.when(
      data: (value) => value.menus.indexWhere((element) => element.name == menuName),
      error: (o, e) => 0,
      loading: () => 0,
    );
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TabBar(
          dividerHeight: 0,
          tabs: [
            Tab(
              icon: FaIcon(FontAwesomeIcons.puzzlePiece),
              text: 'Items',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.gear),
              text: 'Settings',
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TabBarView(
            children: [
              Stack(
                children: [
                  ReorderableListView.builder(
                    onReorder: (oldIndex, newIndex) =>
                        ref.read(configProvider.notifier).reorderMenuItem(oldIndex, newIndex, menuId),
                    itemCount: conf.value!.menus[menuId].items.length,
                    padding: const EdgeInsets.only(bottom: 85.0),
                    itemBuilder: (BuildContext context, int i) {
                      return MenuItemElement(conf: conf.value!, menuId: menuId, itemId: i, key: ValueKey(i));
                    },
                  ),
                  Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(12.0),
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          conf.value!.menus[menuId].items.add(Items());
                          ref.read(configProvider.notifier).updateConfig(conf.value!);
                        },
                        icon: Icon(Icons.add),
                        label: Text('Add new plugin'),
                      )),
                ],
              ),
              ListView(
                children: [
                  SettingsElement(conf: conf.value!, field: Fields.name, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.type, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.menuHotkey, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.theme, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.colorScheme, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.width, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.height, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.position, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.marginVertical, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.marginHorizontal, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.monitor, menuId: menuId),
                  SettingsElement(conf: conf.value!, field: Fields.maxElement, menuId: menuId),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
