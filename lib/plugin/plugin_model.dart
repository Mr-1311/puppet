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

Plugin? _parseManifest(String manifestJson) {
  final manifest = jsonDecode(manifestJson);

  if (manifest
      case {
        'name': String name,
        'description': String description,
        'platforms': List<String> platforms
      }) {
    if (platforms.length == 0 ||
        !platforms
            .every((e) => e == 'windows' || e == 'macos' || e == 'linux')) {
      return null;
    }
    final args = <PluginArg>[];
    if (manifest case {'args': List<Map<String, String>> pluginArgs}) {
      for (final arg in pluginArgs) {
        if (arg
            case {
              'name': String name,
              'description': String description,
              'defaultValue': String defaultValue
            }) {
          args.add(PluginArg(name, description, defaultValue));
        }
      }
    }
    return Plugin(name, description, platforms, args);
  }
  return null;
}

List<Plugin> getAvailablePlugins(String pluginDirPath) {
  final plugins = _builtInPlugins;
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

const _builtInPlugins = [
  Plugin('menu', 'open different menu', [
    'windows',
    'macos',
    'linux'
  ], [
    PluginArg('menu name', 'name of the menu to open', ''),
  ]),
  Plugin('run', 'run a command', [
    'windows',
    'macos',
    'linux'
  ], [
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
  ]),
];
