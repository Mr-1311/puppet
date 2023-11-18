import 'dart:convert';
import 'dart:io';

import 'package:app_dirs/app_dirs.dart';
import 'package:flutter/services.dart';
import 'package:puppet/config/config.dart';
import 'package:screen_retriever/screen_retriever.dart';

class ConfigRepository {
  static ConfigRepository? _instance;

  final List<Items> _elements;

  static Future<ConfigRepository> getInstance() async {
    if (_instance == null) {
      final configString = await _getConfigString();
      final config = Config.fromJson(jsonDecode(configString), Size(640, 640));
      _instance = ConfigRepository._(config.menus.first.items);
    }
    return _instance!;
  }

  ConfigRepository._(List<Items> elements) : _elements = elements;

  static Future<String> _getConfigString() async {
    final configPath = getAppDirs(application: 'puppet').config;
    final File confFile = File('$configPath/puppet/config.json');

    if (!confFile.existsSync()) {
      confFile.createSync(recursive: true);
      final defaultConfig = await rootBundle.loadString('assets/config.json');
      confFile.writeAsStringSync(defaultConfig);
    }

    return confFile.readAsString();
  }

  List<Items> get elements => _elements;
}

class MonitorInfo {
  static MonitorInfo? _instance;

  Display? primaryDisplay;
  List<Display> displayList = [];

  static Future<MonitorInfo> getInstance() async {
    if (_instance == null) {
      var primaryDisplay = await screenRetriever.getPrimaryDisplay();
      var displayList = await screenRetriever.getAllDisplays();
      _instance = MonitorInfo._(primaryDisplay, displayList);
    }
    return _instance!;
  }

  MonitorInfo._(Display primaryDisplay, List<Display> displayList)
      : this.primaryDisplay = primaryDisplay,
        this.displayList = displayList;

  static Future<Offset> getMousePosition() async {
    return await screenRetriever.getCursorScreenPoint();
  }
}
