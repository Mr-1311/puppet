import 'package:puppet/src/rust/api/plugin_manager.dart';

/// PluginManagerSingleton ensures there is only one instance of PluginManager.
/// It wraps the PluginManager instance exposed by flutter_rust_bridge.
class PluginManagerSingleton {
  static final PluginManagerSingleton _instance =
      PluginManagerSingleton._internal();

  final PluginManager _pluginManager;

  factory PluginManagerSingleton() {
    return _instance;
  }

  PluginManagerSingleton._internal()
      : _pluginManager = PluginManager.newInstance();

  /// Exposes the singleton PluginManager instance.
  PluginManager get manager => _pluginManager;
}
