import 'dart:io';

class PathManager {
  static final PathManager _instance = PathManager._internal();

  factory PathManager() => _instance;

  PathManager._internal() {
    if (Platform.isLinux) {
      _base =
          '${Platform.environment['XDG_CONFIG_HOME'] ?? ('${Platform.environment['HOME']}/.config')}/puppet/';
    } else if (Platform.isWindows) {
      _base = '${Platform.environment['APPDATA']}/puppet/';
    } else if (Platform.isMacOS) {
      _base = '${Platform.environment['HOME']}/.config/puppet/';
    } else {
      _base = '';
    }
    _config = _base + 'config/' + Platform.operatingSystem + '/';
    _themes = _base + 'themes/';
    _plugins = _base + 'plugins/';
    _icons = _base + 'icons/';
  }

  late String _base;
  late String _config;
  late String _themes;
  late String _plugins;
  late String _icons;

  String get base => _base;
  String get config => _config;
  String get themes => _themes;
  String get plugins => _plugins;
  String get icons => _icons;
}
