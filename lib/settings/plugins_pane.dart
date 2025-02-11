import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config/path_manager.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';

final selectedPluginProvider = StateProvider<String?>((ref) => null);

final availablePluginsProvider = Provider<List<Plugin>>((ref) {
  return getAvailablePlugins(PathManager().plugins);
});

class PluginsPane extends ConsumerWidget {
  const PluginsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlugin = ref.watch(selectedPluginProvider);

    if (selectedPlugin != null) {
      return PluginDetailPane();
    }

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TabBar(
          dividerHeight: 0,
          tabs: [
            Tab(
              icon: FaIcon(FontAwesomeIcons.boxOpen),
              text: 'Installed',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.magnifyingGlass),
              text: 'Explore',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: TabBarView(
            children: [
              // Installed plugins tab
              InstalledPluginsView(),
              // Explore tab (to be implemented)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.wandMagicSparkles,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Plugin marketplace coming soon...',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InstalledPluginsView extends ConsumerWidget {
  const InstalledPluginsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(availablePluginsProvider);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 85.0),
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        return Card(
          child: InkWell(
            onTap: () =>
                ref.read(selectedPluginProvider.notifier).state = plugin.name,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plugin.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          plugin.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(FontAwesomeIcons.computer, size: 12),
                                  SizedBox(width: 6),
                                  Text(
                                    plugin.platforms.join(', '),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FaIcon(
                    FontAwesomeIcons.chevronRight,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PluginDetailPane extends ConsumerWidget {
  const PluginDetailPane({super.key});

  String? _findReadmeContent(String pluginName) {
    final pluginDir = Directory('${PathManager().plugins}$pluginName');
    if (!pluginDir.existsSync()) return null;

    final files = pluginDir.listSync();
    final readmeFile = files.firstWhere(
      (file) => file.path.toLowerCase().endsWith('readme.md'),
      orElse: () => File(''),
    );

    if (readmeFile is File && readmeFile.existsSync()) {
      return readmeFile.readAsStringSync();
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginName = ref.watch(selectedPluginProvider);
    final plugins = ref.watch(availablePluginsProvider);
    final plugin = plugins.firstWhere((p) => p.name == pluginName);
    final readmeContent = _findReadmeContent(plugin.name);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // asdf
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (plugin.description.isNotEmpty) ...[
                      Text(
                        plugin.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plugin info chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FaIcon(FontAwesomeIcons.computer,
                                          size: 12),
                                      SizedBox(width: 6),
                                      Text(plugin.platforms.join(', ')),
                                    ],
                                  ),
                                ),
                                if (plugin.wasi)
                                  Chip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FaIcon(FontAwesomeIcons.microchip,
                                            size: 12),
                                        SizedBox(width: 6),
                                        Text('WASI'),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (plugin.allowedPaths.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Allowed Paths',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: plugin.allowedPaths
                                    .map(
                                      (path) => Chip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(FontAwesomeIcons.folder,
                                                size: 12),
                                            SizedBox(width: 6),
                                            Text(path),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if (plugin.allowedHosts.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Allowed Hosts',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: plugin.allowedHosts
                                    .map(
                                      (host) => Chip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FaIcon(FontAwesomeIcons.globe,
                                                size: 12),
                                            SizedBox(width: 6),
                                            Text(host),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if (plugin.args.isNotEmpty) ...[
                              SizedBox(height: 16),
                              Text(
                                'Arguments',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              SizedBox(height: 8),
                              ...plugin.args.map(
                                (arg) => Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(arg.name),
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                            ),
                                            if (arg
                                                .defaultValue.isNotEmpty) ...[
                                              SizedBox(width: 8),
                                              Text(
                                                'default:',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                arg.defaultValue,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        if (arg.description.isNotEmpty)
                                          Text(
                                            arg.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (readmeContent != null) ...[
                              SizedBox(height: 24),
                              Divider(),
                              SizedBox(height: 16),
                              Markdown(
                                data: readmeContent,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
