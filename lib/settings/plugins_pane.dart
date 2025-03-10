import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config/path_manager.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:puppet/plugin/marketplace.dart';
import 'package:puppet/settings/marketplace_detail.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

final selectedPluginProvider = StateProvider<(String?, bool)>((ref) => (null, false));

final updatingPluginProvider = StateProvider<String?>((ref) => null);

class PluginsPane extends ConsumerWidget {
  const PluginsPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlugin = ref.watch(selectedPluginProvider);

    if (selectedPlugin.$1 != null && !selectedPlugin.$2) {
      return PluginDetailPane();
    } else if (selectedPlugin.$2) {
      return MarketplacePluginDetailPane();
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
              InstalledPluginsView(),
              _ExplorePluginsView(),
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
    final plugins = ref.watch(pluginProvider);
    final updatingPlugin = ref.watch(updatingPluginProvider);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 85.0),
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        return Card(
          child: InkWell(
            onTap: () => ref.read(selectedPluginProvider.notifier).state = (plugin.name, false),
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
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (!plugin.source.startsWith('built-in')) ...[
                        FutureBuilder<bool>(
                          future: plugin.hasUpdate(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data == true) {
                              return updatingPlugin == plugin.name
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: () async {
                                        ref.read(updatingPluginProvider.notifier).state = plugin.name;
                                        final success = await updatePlugin(plugin);
                                        if (success) {
                                          ref.invalidate(pluginProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Plugin updated successfully')),
                                            );
                                          }
                                        } else if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to update plugin')),
                                          );
                                        }
                                        ref.read(updatingPluginProvider.notifier).state = null;
                                      },
                                      icon: Icon(
                                        Icons.upgrade,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      tooltip: 'Update available',
                                    );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Plugin'),
                                content: Text('Are you sure you want to delete ${plugin.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      try {
                                        final dir = Directory('${PathManager().plugins}${plugin.name}');
                                        if (dir.existsSync()) {
                                          dir.deleteSync(recursive: true);
                                          ref.invalidate(pluginProvider);
                                          ref.invalidate(marketplacePluginsProvider);
                                          ref.read(selectedPluginProvider.notifier).state = (null, false);
                                          stdout.write('config_updated');
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to delete plugin')),
                                        );
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.delete),
                        )
                      ],
                      FaIcon(
                        FontAwesomeIcons.chevronRight,
                        size: 18,
                      ),
                    ],
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

class _ExplorePluginsView extends ConsumerStatefulWidget {
  const _ExplorePluginsView();

  @override
  ConsumerState<_ExplorePluginsView> createState() => _ExplorePluginsViewState();
}

class _ExplorePluginsViewState extends ConsumerState<_ExplorePluginsView> {
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(MarketplacePlugin plugin) {
    if (searchQuery.isEmpty) return true;

    final query = searchQuery.toLowerCase();
    return plugin.name.toLowerCase().contains(query) ||
        plugin.description.toLowerCase().contains(query) ||
        plugin.author.toLowerCase().contains(query);
  }

  Widget _buildPluginItem(BuildContext context, MarketplacePlugin plugin) {
    return Card(
      child: InkWell(
        onTap: () {
          ref.read(selectedMarketplacePluginProvider.notifier).state = plugin.name;
          ref.read(selectedPluginProvider.notifier).state = (plugin.name, true);
        },
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
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Chip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.user, size: 12),
                              SizedBox(width: 6),
                              Text(
                                plugin.author,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  if (!isCurrentPlatformSupported(plugin.platforms)) {
                    return Chip(
                      label: Text('Not Supported'),
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    );
                  } else if (plugin.isInstalled) {
                    return Chip(
                      label: Text('Installed'),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    );
                  } else if (plugin.isInstalling) {
                    return SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    );
                  } else {
                    return FilledButton.icon(
                      onPressed: () async {
                        final notifier = ref.read(marketplacePluginsProvider.notifier);
                        notifier.setPluginInstalling(plugin.name, true);
                        final success = await notifier.installPlugin(plugin);
                        if (success) {
                          ref.invalidate(pluginProvider);
                        } else {
                          notifier.setPluginInstalling(plugin.name, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to install plugin')),
                          );
                        }
                      },
                      icon: FaIcon(FontAwesomeIcons.download, size: 14),
                      label: Text('Install'),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plugins = ref.watch(marketplacePluginsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search plugins...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
        Expanded(
          child: plugins.when(
            data: (plugins) {
              final filteredPlugins = plugins.where(_matchesSearch).toList();
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 85.0),
                itemCount: filteredPlugins.length,
                itemBuilder: (context, index) => _buildPluginItem(context, filteredPlugins[index]),
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load plugins',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  bool _isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.scheme.startsWith('http');
    } catch (e) {
      return false;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPluginProvider);
    final pluginName = selected.$1;
    final plugins = ref.watch(pluginProvider);
    final plugin = plugins.firstWhere((p) => p.name == pluginName);
    final readmeContent = _findReadmeContent(plugin.name);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                    SizedBox(height: 8),
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.user, size: 14),
                        SizedBox(width: 8),
                        Text(
                          plugin.author,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        FaIcon(FontAwesomeIcons.code, size: 14),
                        SizedBox(width: 8),
                        if (_isValidUrl(plugin.source))
                          InkWell(
                            onTap: () => _launchUrl(plugin.source),
                            child: Text(
                              plugin.source,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          )
                        else
                          Text(
                            plugin.source,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
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
                                      FaIcon(FontAwesomeIcons.computer, size: 12),
                                      SizedBox(width: 6),
                                      Text(plugin.platforms.join(', ')),
                                    ],
                                  ),
                                ),
                                if (plugin.wasi)
                                  Tooltip(
                                    message:
                                        'WebAssembly System Interface - Allows the plugin to access system resources',
                                    child: Chip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.microchip, size: 12),
                                          SizedBox(width: 6),
                                          Text('WASI'),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (plugin.cli)
                                  Tooltip(
                                    message:
                                        'Command Line Interface - Plugin can execute any command or program, including shell scripts\n Be careful with this plugin!, all commands this plugin executes will be logged to the console',
                                    child: Chip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FaIcon(FontAwesomeIcons.terminal, size: 12),
                                          SizedBox(width: 6),
                                          Text('CLI'),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (plugin.allowedPaths.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Tooltip(
                                message: 'File system paths this plugin has permission to access',
                                child: Text(
                                  'Allowed Paths',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
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
                                            FaIcon(FontAwesomeIcons.folder, size: 12),
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
                              Tooltip(
                                message: 'Network hosts this plugin has permission to connect to',
                                child: Text(
                                  'Allowed Hosts',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
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
                                            FaIcon(FontAwesomeIcons.globe, size: 12),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(arg.name),
                                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                            ),
                                            if (arg.defaultValue.isNotEmpty) ...[
                                              SizedBox(width: 8),
                                              Text(
                                                'default:',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                arg.defaultValue,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        if (arg.description.isNotEmpty)
                                          Text(
                                            arg.description,
                                            style: Theme.of(context).textTheme.bodyMedium,
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
