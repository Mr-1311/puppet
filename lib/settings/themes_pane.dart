import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/config_providers.dart';
import 'package:puppet/settings/settings_element.dart';
import 'package:puppet/settings/theme_detail_pane.dart';

final themeDetailProvider = StateProvider<String?>((ref) => null);

class ThemesPane extends ConsumerWidget {
  const ThemesPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final themeDetail = ref.watch(themeDetailProvider);
    if (themeDetail == null) {
      return switch (theme) {
        AsyncData(value: final theme) => ListView(children: [
            Divider(),
            for (final themeName in theme.keys)
              InkWell(
                onTap: () => (ref.read(themeDetailProvider.notifier).state = themeName),
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
                              themeName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  _deleteConfirmationDialogBuilder(context, themeName).then((value) {
                                    if (value == true) {
                                      ref.read(themeProvider.notifier).deleteTheme(themeName);
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
                  ref.read(themeProvider.notifier).createNewTheme();
                },
                label: Text('Create New Theme'),
                icon: Icon(Icons.add),
              ),
            ),
          ]),
        _ => CircularProgressIndicator(),
      };
    } else {
      return ThemeDetailPane();
    }
  }

  Future<bool?> _deleteConfirmationDialogBuilder(BuildContext context, String themeName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm delete'),
          content: Text('Are you sure you want to delete \'$themeName\'?'),
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
