import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/config_providers.dart';
import 'package:puppet/settings/menu_detail_pane.dart';
import 'package:puppet/settings/settings_element.dart';
import 'package:collection/collection.dart';

final menuDetailProvider = StateProvider<String?>((ref) => null);

class MenusPane extends ConsumerWidget {
  const MenusPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(configProvider);
    final menuDetail = ref.watch(menuDetailProvider);
    if (menuDetail == null) {
      return switch (conf) {
        AsyncData(value: final conf) => ListView(children: [
            SettingsElement(conf: conf, field: Fields.mainMenu),
            SettingsElement(conf: conf, field: Fields.mainHotkey),
            Divider(),
            for (final menu in conf.menus)
              InkWell(
                onTap: () => (ref.read(menuDetailProvider.notifier).state = menu.name),
                child: Card(
                  child: Container(
                    height: elementHeight,
                    padding: elementPadding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menu.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Row(
                              children: [
                                Chip(
                                  label: Row(
                                    children: [
                                      ImageIcon(
                                        AssetImage('assets/icon_${menu.type}.png'),
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        menu.type,
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  _deleteConfirmationDialogBuilder(context, menu.name).then((value) {
                                    if (value == true) {
                                      conf.menus.removeWhere((element) => element.name == menu.name);
                                      if (menu.name == conf.mainMenu) {
                                        conf.mainMenu = conf.menus[0].name;
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Main menu changed to \'${conf.menus[0].name}\''),
                                        ));
                                      }
                                      ref.read(configProvider.notifier).updateConfig(conf);
                                    }
                                  });
                                },
                                icon: Icon(Icons.delete)),
                            SizedBox(width: 18),
                            FaIcon(
                              FontAwesomeIcons.chevronRight,
                              size: 18,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: FloatingActionButton.extended(
                onPressed: () {
                  var counter = 1;
                  var menuName = 'New Menu $counter';
                  while (conf.menus.firstWhereOrNull((menu) => menu.name == menuName) != null) {
                    counter++;
                    menuName = 'New Menu $counter';
                  }
                  Menus newMenu = Menus(name: menuName);
                  conf.menus = [...conf.menus, newMenu];
                  ref.read(configProvider.notifier).updateConfig(conf);
                },
                label: Text('Create New Menu'),
                icon: Icon(Icons.add),
              ),
            ),
          ]),
        _ => CircularProgressIndicator(),
      };
    } else {
      return MenuDetailPane();
    }
  }

  Future<bool?> _deleteConfirmationDialogBuilder(BuildContext context, String menuName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm delete'),
          content: Text('Are you sure you want to delete \'$menuName\'?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}
