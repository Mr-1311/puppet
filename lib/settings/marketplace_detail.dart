import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:puppet/plugin/marketplace.dart';

final selectedMarketplacePluginProvider = StateProvider<String?>((ref) => null);

final marketplacePluginDetailsProvider = FutureProvider<(String?, String?)>((ref) {
  final pluginName = ref.watch(selectedMarketplacePluginProvider);
  if (pluginName == null) return (null, null);

  final plugins = ref.watch(marketplacePluginsProvider).valueOrNull;
  if (plugins == null) return (null, null);

  final plugin = plugins.firstWhere((p) => p.name == pluginName);
  return ref.read(marketplacePluginsProvider.notifier).getPluginDetails(plugin);
});

class MarketplacePluginDetailPane extends ConsumerWidget {
  const MarketplacePluginDetailPane({super.key});

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
    final pluginName = ref.watch(selectedMarketplacePluginProvider);
    if (pluginName == null) return const SizedBox();

    final plugins = ref.watch(marketplacePluginsProvider).valueOrNull;
    if (plugins == null) return const SizedBox();

    final plugin = plugins.firstWhere((p) => p.name == pluginName);
    final details = ref.watch(marketplacePluginDetailsProvider);

    return details.when(
      data: (details) {
        final manifestJson = details.$1 != null ? jsonDecode(details.$1!) : null;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plugin.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        plugin.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
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
                          if (_isValidUrl(plugin.repo))
                            InkWell(
                              onTap: () => _launchUrl(plugin.repo),
                              child: Text(
                                plugin.repo,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            )
                          else
                            Text(
                              plugin.repo,
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
                                  if (manifestJson?['wasi'] == true)
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
                                  if (manifestJson?['cli'] == true)
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
                              if (manifestJson?['allowedPaths']?.isNotEmpty ?? false) ...[
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
                                  children: (manifestJson!['allowedPaths'] as List)
                                      .map(
                                        (path) => Chip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FaIcon(FontAwesomeIcons.folder, size: 12),
                                              SizedBox(width: 6),
                                              Text(path.toString()),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              if (manifestJson?['allowedHosts']?.isNotEmpty ?? false) ...[
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
                                  children: (manifestJson!['allowedHosts'] as List)
                                      .map(
                                        (host) => Chip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FaIcon(FontAwesomeIcons.globe, size: 12),
                                              SizedBox(width: 6),
                                              Text(host.toString()),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              if (manifestJson?['pluginArgs']?.isNotEmpty ?? false) ...[
                                SizedBox(height: 16),
                                Text(
                                  'Arguments',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                SizedBox(height: 8),
                                ...(manifestJson!['pluginArgs'] as List).map(
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
                                                label: Text(arg['name']),
                                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                              ),
                                              if (arg['defaultValue']?.isNotEmpty ?? false) ...[
                                                SizedBox(width: 8),
                                                Text(
                                                  'default:',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  arg['defaultValue'],
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          if (arg['description']?.isNotEmpty ?? false)
                                            Text(
                                              arg['description'],
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (details.$2 != null) ...[
                                SizedBox(height: 24),
                                Divider(),
                                SizedBox(height: 16),
                                Markdown(
                                  data: details.$2!,
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
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error loading plugin details: $error'),
      ),
    );
  }
}
