import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:puppet/providers.dart';
import 'package:puppet/settings/settings_element.dart';
import 'package:collection/collection.dart';

class MenuItemElement extends ConsumerWidget {
  MenuItemElement({required this.conf, required this.menuId, required this.itemId, super.key});

  final Config conf;
  final int menuId;
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginProvider);

    return InkWell(
      onTap: () => {_itemDetails(context, conf.menus[menuId].items[itemId].name, plugins)},
      child: Card(
        child: Container(
          height: elementHeight,
          padding: elementPadding,
          margin: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(conf.menus[menuId].items[itemId].name),
              IconButton(
                onPressed: () {
                  _deleteConfirmationDialogBuilder(context, conf.menus[menuId].items[itemId].name).then((value) {
                    if (value == true) {
                      conf.menus[menuId].items.removeAt(itemId);
                      ref.read(configProvider.notifier).updateConfig(conf);
                    }
                  });
                },
                icon: Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _deleteConfirmationDialogBuilder(BuildContext context, String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm delete'),
          content: Text('Are you sure you want to delete \'$itemName\'?'),
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

  Future _itemDetails(BuildContext context, String itemName, List<Plugin> plugins) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(itemName),
          content: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final pluginName = conf.menus[menuId].items[itemId].plugin;
              final plugin = plugins.firstWhereOrNull((element) => element.name == pluginName);
              final pluginArgs = plugin?.args ?? [];
              return Container(
                width: 630,
                child: ListView(
                  children: [
                    SettingsElement(conf: conf, field: Fields.itemName, menuId: menuId, itemId: itemId),
                    SettingsElement(conf: conf, field: Fields.itemDescription, menuId: menuId, itemId: itemId),
                    SettingsElement(conf: conf, field: Fields.itemRepeat, menuId: menuId, itemId: itemId),
                    SettingsElement(conf: conf, field: Fields.itemShortcut, menuId: menuId, itemId: itemId),
                    SettingsElement(conf: conf, field: Fields.itemIcon, menuId: menuId, itemId: itemId),
                    SettingsElement(conf: conf, field: Fields.itemPlugin, menuId: menuId, itemId: itemId),
                    if (pluginArgs.isNotEmpty) ...[
                      Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                        child: Text('Plugin Arguments:'),
                      ),
                      ...pluginArgs.map((arg) => SettingsElement(
                          conf: conf, field: Fields.itemPluginArg, menuId: menuId, itemId: itemId, pluginArg: arg)),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
