import 'dart:convert';
import 'dart:io';

class Plugin {
  final String name;
  final String description;
  final List<String> platforms;
  final List<PluginArg> args;

  const Plugin(this.name, this.description, this.platforms, this.args);
}

class PluginArg {
  final String name;
  final String description;
  final String defaultValue;

  const PluginArg(this.name, this.description, this.defaultValue);
}

Plugin? _parseManifest(String manifestJson) {
  final manifest = jsonDecode(manifestJson);

  if (manifest case {'name': String name, 'description': String description, 'platforms': List<String> platforms}) {
    if (platforms.length == 0 || !platforms.every((e) => e == 'windows' || e == 'macos' || e == 'linux')) {
      return null;
    }
    final args = <PluginArg>[];
    if (manifest case {'args': List<Map<String, String>> pluginArgs}) {
      for (final arg in pluginArgs) {
        if (arg case {'name': String name, 'description': String description, 'defaultValue': String defaultValue}) {
          args.add(PluginArg(name, description, defaultValue));
        }
      }
    }
    return Plugin(name, description, platforms, args);
  }
  return null;
}

List<Plugin> getAvailablePlugins(String pluginDirPath) {
  final plugins = <Plugin>[
    Plugin('menu', 'open different menu', [
      'windows',
      'macos',
      'linux'
    ], [
      PluginArg('menu name', 'name of the menu to open', ''),
    ])
  ];
  final directory = Directory(pluginDirPath);
  if (!directory.existsSync()) {
    return plugins;
  }
  final files = directory.listSync().toList();
  for (var file in files) {
    if (file is File) {
      final manifestFile = File('${file.path}/manifest.json');
      if (manifestFile.existsSync()) {
        final manifestContent = manifestFile.readAsStringSync();
        final plugin = _parseManifest(manifestContent);
        if (plugin != null) {
          plugins.add(plugin);
        }
      }
    }
  }
  return plugins;
}
