import 'dart:convert';
import 'dart:io';

import 'package:puppet/config/path_manager.dart';
import 'package:http/http.dart' as http;

class Plugin {
  final String name;
  final String description;
  final String author;
  final String source;
  final List<String> platforms;
  final List<PluginArg> args;
  final List<String> allowedPaths;
  final List<String> allowedHosts;
  final bool wasi;
  final String wasmPath;
  final bool cli;

  Future<String?> getLatestVersion() async {
    if (source.startsWith('built-in')) return null;

    final uri = Uri.parse(source);
    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      print('Invalid GitHub URL: $source');
      return null;
    }

    final repoPath = '${pathSegments[0]}/${pathSegments[1]}';
    final apiUrl = 'https://api.github.com/repos/$repoPath/releases/latest';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode != 200) return null;

      final release = jsonDecode(response.body);
      return release['tag_name'] as String;
    } catch (e) {
      print('Error fetching latest version: $e');
      return null;
    }
  }

  Future<bool> hasUpdate() async {
    if (source.startsWith('built-in')) return false;

    final versionFile = File('${PathManager().plugins}$name/.version');
    if (!versionFile.existsSync()) return false;

    final currentVersion = versionFile.readAsStringSync().trim();
    final latestVersion = await getLatestVersion();
    if (latestVersion == null) return false;

    return currentVersion != latestVersion;
  }

  Plugin(
    this.name,
    this.description,
    this.author,
    this.source,
    this.platforms,
    this.args,
    this.wasmPath, {
    this.allowedPaths = const [],
    this.allowedHosts = const [],
    this.wasi = false,
    this.cli = false,
  });

  static String? _findWasmPath(String pluginFolder) {
    String platform;
    if (Platform.isWindows) {
      platform = 'windows';
    } else if (Platform.isMacOS) {
      platform = 'macos';
    } else if (Platform.isLinux) {
      platform = 'linux';
    } else {
      print('Error: Unsupported platform');
      return null;
    }

    final platformSpecificPath = '$pluginFolder/$platform/plugin.wasm';
    final genericPath = '$pluginFolder/plugin.wasm';

    if (File(platformSpecificPath).existsSync()) {
      return platformSpecificPath;
    } else if (File(genericPath).existsSync()) {
      return genericPath;
    } else {
      print('Error: WASM file not found at $platformSpecificPath or $genericPath');
      return null;
    }
  }
}

class PluginArg {
  final String name;
  final String description;
  final String defaultValue;

  const PluginArg(this.name, this.description, this.defaultValue);
}

class PluginItem {
  final String name;
  final String description;
  final String icon;
  final String? shortcut;
  final bool repeat;
  final String plugin;
  final Map<String, dynamic> args;

  const PluginItem(
    this.name,
    this.description,
    this.icon,
    this.plugin,
    this.shortcut,
    this.repeat, [
    this.args = const {},
  ]);
}

Plugin? _parseManifest(String manifestJson, String pluginPath) {
  final manifest = jsonDecode(manifestJson);
  if (manifest
      case {
        'name': String name,
        'description': String description,
        'author': String author,
        'source': String source,
        'platforms': List platforms,
        'allowedPaths': List allowedPaths,
        'allowedHosts': List allowedHosts,
        'wasi': bool wasi,
        'cli': bool cli,
      }) {
    // Check that all list entries are strings.
    if (!platforms.every((e) => e is String) ||
        !allowedPaths.every((e) => e is String) ||
        !allowedHosts.every((e) => e is String)) {
      print('One of the list fields does not contain only strings.');
      return null;
    }

    if (platforms.isEmpty || !platforms.every((e) => e == 'windows' || e == 'macos' || e == 'linux')) {
      return null;
    }

    final args = <PluginArg>[];
    if (manifest case {'pluginArgs': List pluginArgs}) {
      for (final arg in pluginArgs) {
        if (arg is! Map<String, dynamic> ||
            arg['name'] is! String ||
            arg['description'] is! String ||
            arg['defaultValue'] is! String) {
          print('Skipping invalid plugin arg in plugin "$name": $arg');
          continue;
        }

        args.add(PluginArg(
          arg['name'] as String,
          arg['description'] as String,
          arg['defaultValue'] as String,
        ));
      }
    }

    final wasmPath = Plugin._findWasmPath(pluginPath);
    if (wasmPath == null) {
      return null;
    }

    return Plugin(
      name,
      description,
      author,
      source,
      platforms.cast<String>(),
      args,
      wasmPath,
      allowedPaths: allowedPaths.cast<String>(),
      allowedHosts: allowedHosts.cast<String>(),
      wasi: wasi,
      cli: cli,
    );
  }
  return null;
}

List<Plugin> getAvailablePlugins(String pluginDirPath) {
  final plugins = List<Plugin>.from(_builtInPlugins);
  final directory = Directory(pluginDirPath);
  if (!directory.existsSync()) {
    return plugins;
  }
  final files = directory.listSync().toList();
  for (var file in files) {
    if (file is Directory) {
      final manifestFile = File('${file.path}/manifest.json');
      if (manifestFile.existsSync()) {
        final manifestContent = manifestFile.readAsStringSync();
        final plugin = _parseManifest(manifestContent, file.path);
        if (plugin != null && isCurrentPlatformSupported(plugin.platforms)) {
          plugins.add(plugin);
        }
      }
    }
  }
  return plugins;
}

bool isCurrentPlatformSupported(List<String> platforms) {
  if (Platform.isWindows) return platforms.contains('windows');
  if (Platform.isMacOS) return platforms.contains('macos');
  if (Platform.isLinux) return platforms.contains('linux');
  return false;
}

String getPluginDataDir(String pluginName) {
  final path = '${PathManager().plugins}$pluginName/data';
  final pluginDir = Directory(path);
  // create the data directory if it doesn't exist
  if (!pluginDir.existsSync()) {
    pluginDir.createSync(recursive: true);
  }
  return pluginDir.path;
}

final _builtInPlugins = [
  Plugin(
      'menu',
      'open different menu',
      'Puppet',
      'built-in',
      ['windows', 'macos', 'linux'],
      [
        PluginArg('menu name', 'name of the menu to open', ''),
      ],
      ''),
  Plugin(
      'run',
      'run a command',
      'Puppet',
      'built-in',
      ['windows', 'macos', 'linux'],
      [
        PluginArg('command', 'command to run', ''),
        PluginArg(
            'arguments',
            'arguments to pass to the command, separated by spaces, if there are any spaces in the argument, enclose it in quotes, e.g. arg1 arg2 "arg with spaces"',
            ''),
        PluginArg(
            'environment variables',
            'environment variables to pass to the command, written as a JSON object, e.g. {"var1": "value1", "var2": "value2"}',
            ''),
        PluginArg(
            'run in shell',
            'run the command in the shell. If "true", the process will be spawned through a system shell. On Linux and OS X, /bin/sh is used, while %WINDIR%\system32\cmd.exe is used on Windows.',
            ''),
      ],
      ''),
];
