import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:puppet/config/path_manager.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:puppet/providers.dart';
import 'package:path/path.dart' as path;

class MarketplacePlugin {
  final String name;
  final String author;
  final String description;
  final List<String> platforms;
  final String repo;
  bool isInstalled;
  bool isInstalling;

  MarketplacePlugin({
    required this.name,
    required this.author,
    required this.description,
    required this.platforms,
    required this.repo,
    this.isInstalled = false,
    this.isInstalling = false,
  });

  factory MarketplacePlugin.fromJson(Map<String, dynamic> json) {
    return MarketplacePlugin(
      name: json['name'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
      platforms: (json['platforms'] as List).cast<String>(),
      repo: json['repo'] as String,
    );
  }
}

final marketplacePluginsProvider =
    AsyncNotifierProvider<MarketplacePluginsNotifier, List<MarketplacePlugin>>(MarketplacePluginsNotifier.new);

Future<Map<String, dynamic>?> _fetchLatestRelease(String repo) async {
  final uri = Uri.parse(repo);
  final pathSegments = uri.pathSegments;
  if (pathSegments.length < 2) {
    print('Invalid GitHub URL: $repo');
    return null;
  }

  final repoPath = '${pathSegments[0]}/${pathSegments[1]}';
  final apiUrl = 'https://api.github.com/repos/$repoPath/releases/latest';
  final response = await http.get(Uri.parse(apiUrl));
  if (response.statusCode != 200) return null;

  final release = jsonDecode(response.body);
  final assets = release['assets'] as List;
  final version = release['tag_name'] as String;

  return {
    'version': version,
    'assets': Map.fromEntries(assets.map((asset) => MapEntry(
          asset['name'].toString().toLowerCase(),
          asset['browser_download_url'] as String,
        ))),
  };
}

class MarketplacePluginsNotifier extends AsyncNotifier<List<MarketplacePlugin>> {
  static const _pluginsUrl = 'https://raw.githubusercontent.com/Mr-1311/puppet-plugins/main/plugins.json';

  @override
  Future<List<MarketplacePlugin>> build() async {
    final response = await http.get(Uri.parse(_pluginsUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch plugins');
    }

    final List<dynamic> jsonList = jsonDecode(response.body);
    final plugins = jsonList.map((json) => MarketplacePlugin.fromJson(json)).toList();

    // Check which plugins are installed
    final installedPlugins = ref.read(pluginProvider);
    for (var plugin in plugins) {
      plugin.isInstalled = installedPlugins.any((p) => p.name == plugin.name);
    }

    return plugins;
  }

  Future<(String?, String?)> getPluginDetails(MarketplacePlugin plugin) async {
    try {
      final release = await _fetchLatestRelease(plugin.repo);
      if (release == null) return (null, null);

      final assets = release['assets'] as Map<String, String>;

      String? manifestContent;
      if (assets.containsKey('manifest.json')) {
        manifestContent = await _downloadAsset(assets['manifest.json']!, false);
      }

      String? readmeContent;
      if (assets.containsKey('readme.md')) {
        readmeContent = await _downloadAsset(assets['readme.md']!, false);
      } else if (assets.containsKey('README.md')) {
        readmeContent = await _downloadAsset(assets['README.md']!, false);
      }

      return (manifestContent, readmeContent);
    } catch (e) {
      print('Error fetching plugin details: $e');
      return (null, null);
    }
  }

  void setPluginInstalling(String pluginName, bool installing) {
    if (state case AsyncData(:final value)) {
      state = AsyncData([
        for (var p in value)
          if (p.name == pluginName)
            MarketplacePlugin(
              name: p.name,
              author: p.author,
              description: p.description,
              platforms: p.platforms,
              repo: p.repo,
              isInstalled: p.isInstalled,
              isInstalling: installing,
            )
          else
            p
      ]);
    }
  }

  Future<bool> installPlugin(MarketplacePlugin plugin) async {
    try {
      final pluginsPath = PathManager().plugins;
      final pluginPath = path.join(pluginsPath, plugin.name);
      final pluginDir = Directory(pluginPath);
      if (pluginDir.existsSync()) {
        return false; // Plugin directory already exists
      }

      // Create plugin directory
      pluginDir.createSync(recursive: true);

      // Fetch release info
      final release = await _fetchLatestRelease(plugin.repo);
      if (release == null) {
        await pluginDir.delete(recursive: true);
        return false;
      }

      final assets = release['assets'] as Map<String, String>;
      final version = release['version'] as String;

      // Get and verify manifest
      if (!assets.containsKey('manifest.json')) {
        await pluginDir.delete(recursive: true);
        return false;
      }

      final manifestContent = await _downloadAsset(assets['manifest.json']!, false);
      if (manifestContent == null) {
        await pluginDir.delete(recursive: true);
        return false;
      }

      // Save manifest and verify name
      final manifestPath = path.join(pluginPath, 'manifest.json');
      await File(manifestPath).writeAsString(manifestContent);

      final manifestJson = jsonDecode(manifestContent);
      if (manifestJson['name'] != plugin.name) {
        await pluginDir.delete(recursive: true);
        return false;
      }

      // Save version file
      await File(path.join(pluginPath, '.version')).writeAsString(version);

      // Get and save plugin.wasm
      if (!assets.containsKey('plugin.wasm')) {
        await pluginDir.delete(recursive: true);
        return false;
      }

      final wasmContent = await _downloadAsset(assets['plugin.wasm']!, true);
      if (wasmContent == null) {
        await pluginDir.delete(recursive: true);
        return false;
      }
      await File(path.join(pluginPath, 'plugin.wasm')).writeAsBytes(base64.decode(wasmContent));

      // Try to save readme
      if (assets.containsKey('readme.md') || assets.containsKey('README.md')) {
        final readmeUrl = assets['readme.md'] ?? assets['README.md'];
        final readmeContent = await _downloadAsset(readmeUrl!, false);
        if (readmeContent != null) {
          await File(path.join(pluginPath, 'readme.md')).writeAsString(readmeContent);
        }
      }

      // Save other assets to data directory
      final dataDir = Directory(path.join(pluginPath, 'data'));
      dataDir.createSync();

      for (final entry in assets.entries) {
        final name = entry.key;
        if (!['plugin.wasm', 'manifest.json', 'readme.md', 'README.md'].contains(name)) {
          final content = await _downloadAsset(entry.value, true);
          if (content != null) {
            await File(path.join(dataDir.path, name)).writeAsBytes(base64.decode(content));
            if (Platform.isLinux || Platform.isMacOS) {
              await Process.run('chmod', ['+x', path.join(dataDir.path, name)]);
            }
          }
        }
      }

      // Refresh providers
      ref.invalidate(pluginProvider);
      state = AsyncData([
        for (var p in state.value ?? [])
          if (p.name == plugin.name)
            MarketplacePlugin(
              name: p.name,
              author: p.author,
              description: p.description,
              platforms: p.platforms,
              repo: p.repo,
              isInstalled: true,
              isInstalling: false,
            )
          else
            p
      ]);

      stdout.write('config_updated');
      return true;
    } catch (e) {
      print('Error installing plugin: $e');
      return false;
    }
  }
}

Future<bool> updatePlugin(Plugin plugin) async {
  final pluginsPath = PathManager().plugins;
  final pluginPath = path.join(pluginsPath, plugin.name);
  final pluginDir = Directory(pluginPath);
  final backupDir = '${pluginDir.path}.b';

  try {
    if (Directory(backupDir).existsSync()) {
      Directory(backupDir).deleteSync(recursive: true);
    }
    pluginDir.renameSync(backupDir);

    // Create empty plugin directory
    pluginDir.createSync();

    // Fetch release info
    final release = await _fetchLatestRelease(plugin.source);
    if (release == null) {
      await pluginDir.delete(recursive: true);
      await Directory(backupDir).rename(pluginPath);
      return false;
    }

    final assets = release['assets'] as Map<String, String>;
    final version = release['version'] as String;

    // Get and verify manifest
    if (!assets.containsKey('manifest.json')) {
      await pluginDir.delete(recursive: true);
      await Directory(backupDir).rename(pluginPath);
      return false;
    }

    final manifestContent = await _downloadAsset(assets['manifest.json']!, false);
    if (manifestContent == null) {
      await pluginDir.delete(recursive: true);
      await Directory(backupDir).rename(pluginPath);
      return false;
    }

    // Save manifest and verify name
    final manifestPath = path.join(pluginPath, 'manifest.json');
    await File(manifestPath).writeAsString(manifestContent);

    final manifestJson = jsonDecode(manifestContent);
    if (manifestJson['name'] != plugin.name) {
      await pluginDir.delete(recursive: true);
      await Directory(backupDir).rename(pluginPath);
      return false;
    }

    // Save version file
    await File(path.join(pluginPath, '.version')).writeAsString(version);

    // Get and save plugin.wasm
    if (!assets.containsKey('plugin.wasm')) {
      await pluginDir.delete(recursive: true);
      await Directory(backupDir).rename(pluginPath);
      return false;
    }

    final wasmContent = await _downloadAsset(assets['plugin.wasm']!, true);
    if (wasmContent == null) {
      await pluginDir.delete(recursive: true);
      await Directory(backupDir).rename(pluginPath);
      return false;
    }
    await File(path.join(pluginPath, 'plugin.wasm')).writeAsBytes(base64.decode(wasmContent));

    // Try to save readme
    if (assets.containsKey('readme.md') || assets.containsKey('README.md')) {
      final readmeUrl = assets['readme.md'] ?? assets['README.md'];
      final readmeContent = await _downloadAsset(readmeUrl!, false);
      if (readmeContent != null) {
        await File(path.join(pluginPath, 'readme.md')).writeAsString(readmeContent);
      }
    }

    // Save other assets to data directory
    final dataDir = Directory(path.join(pluginPath, 'data'));
    dataDir.createSync();

    for (final entry in assets.entries) {
      final name = entry.key;
      if (!['plugin.wasm', 'manifest.json', 'readme.md', 'README.md'].contains(name)) {
        final content = await _downloadAsset(entry.value, true);
        if (content != null) {
          await File(path.join(dataDir.path, name)).writeAsBytes(base64.decode(content));
          if (Platform.isLinux || Platform.isMacOS) {
            await Process.run('chmod', ['+x', path.join(dataDir.path, name)]);
          }
        }
      }
    }

    await Directory(backupDir).delete(recursive: true);
    stdout.write('config_updated');
    return true;
  } catch (e) {
    print('Error installing plugin: $e');
    await pluginDir.delete(recursive: true);
    await Directory(backupDir).rename(pluginPath);
    return false;
  }
}

Future<String?> _downloadAsset(String url, bool isBinary) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) return null;

  return isBinary ? base64.encode(response.bodyBytes) : utf8.decode(response.bodyBytes);
}
