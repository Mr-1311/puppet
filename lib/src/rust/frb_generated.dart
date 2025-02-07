// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.7.0.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api/plugin_manager.dart';
import 'api/simple.dart';
import 'dart:async';
import 'dart:convert';
import 'frb_generated.dart';
import 'frb_generated.io.dart'
    if (dart.library.js_interop) 'frb_generated.web.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

/// Main entrypoint of the Rust API
class RustLib extends BaseEntrypoint<RustLibApi, RustLibApiImpl, RustLibWire> {
  @internal
  static final instance = RustLib._();

  RustLib._();

  /// Initialize flutter_rust_bridge
  static Future<void> init({
    RustLibApi? api,
    BaseHandler? handler,
    ExternalLibrary? externalLibrary,
  }) async {
    await instance.initImpl(
      api: api,
      handler: handler,
      externalLibrary: externalLibrary,
    );
  }

  /// Initialize flutter_rust_bridge in mock mode.
  /// No libraries for FFI are loaded.
  static void initMock({
    required RustLibApi api,
  }) {
    instance.initMockImpl(
      api: api,
    );
  }

  /// Dispose flutter_rust_bridge
  ///
  /// The call to this function is optional, since flutter_rust_bridge (and everything else)
  /// is automatically disposed when the app stops.
  static void dispose() => instance.disposeImpl();

  @override
  ApiImplConstructor<RustLibApiImpl, RustLibWire> get apiImplConstructor =>
      RustLibApiImpl.new;

  @override
  WireConstructor<RustLibWire> get wireConstructor =>
      RustLibWire.fromExternalLibrary;

  @override
  Future<void> executeRustInitializers() async {
    await api.crateApiSimpleInitApp();
  }

  @override
  ExternalLibraryLoaderConfig get defaultExternalLibraryLoaderConfig =>
      kDefaultExternalLibraryLoaderConfig;

  @override
  String get codegenVersion => '2.7.0';

  @override
  int get rustContentHash => 158356657;

  static const kDefaultExternalLibraryLoaderConfig =
      ExternalLibraryLoaderConfig(
    stem: 'rust_lib_puppet',
    ioDirectory: 'rust/target/release/',
    webPrefix: 'pkg/',
  );
}

abstract class RustLibApi extends BaseApi {
  Future<List<PluginItem>> crateApiPluginManagerPluginManagerFilterPlugin(
      {required PluginManager that,
      required String name,
      required List<(String, String)> config,
      required String query});

  Future<List<PluginItem>> crateApiPluginManagerPluginManagerInitPlugin(
      {required PluginManager that,
      required String name,
      required PluginConfig pluginConfig});

  Future<PluginManager> crateApiPluginManagerPluginManagerNew();

  Future<void> crateApiPluginManagerPluginManagerSelect(
      {required PluginManager that,
      required String name,
      required List<(String, String)> config,
      required String elementName});

  Future<(String, PathBuf)> crateApiPluginManagerExpandEnvVars(
      {required String path});

  String crateApiSimpleGreet({required String name});

  Future<void> crateApiSimpleInitApp();

  RustArcIncrementStrongCountFnType get rust_arc_increment_strong_count_PathBuf;

  RustArcDecrementStrongCountFnType get rust_arc_decrement_strong_count_PathBuf;

  CrossPlatformFinalizerArg get rust_arc_decrement_strong_count_PathBufPtr;

  RustArcIncrementStrongCountFnType
      get rust_arc_increment_strong_count_PluginManager;

  RustArcDecrementStrongCountFnType
      get rust_arc_decrement_strong_count_PluginManager;

  CrossPlatformFinalizerArg
      get rust_arc_decrement_strong_count_PluginManagerPtr;
}

class RustLibApiImpl extends RustLibApiImplPlatform implements RustLibApi {
  RustLibApiImpl({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @override
  Future<List<PluginItem>> crateApiPluginManagerPluginManagerFilterPlugin(
      {required PluginManager that,
      required String name,
      required List<(String, String)> config,
      required String query}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
            that, serializer);
        sse_encode_String(name, serializer);
        sse_encode_list_record_string_string(config, serializer);
        sse_encode_String(query, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 1, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_list_plugin_item,
        decodeErrorData: sse_decode_AnyhowException,
      ),
      constMeta: kCrateApiPluginManagerPluginManagerFilterPluginConstMeta,
      argValues: [that, name, config, query],
      apiImpl: this,
    ));
  }

  TaskConstMeta get kCrateApiPluginManagerPluginManagerFilterPluginConstMeta =>
      const TaskConstMeta(
        debugName: "PluginManager_filter_plugin",
        argNames: ["that", "name", "config", "query"],
      );

  @override
  Future<List<PluginItem>> crateApiPluginManagerPluginManagerInitPlugin(
      {required PluginManager that,
      required String name,
      required PluginConfig pluginConfig}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
            that, serializer);
        sse_encode_String(name, serializer);
        sse_encode_box_autoadd_plugin_config(pluginConfig, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 2, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_list_plugin_item,
        decodeErrorData: sse_decode_AnyhowException,
      ),
      constMeta: kCrateApiPluginManagerPluginManagerInitPluginConstMeta,
      argValues: [that, name, pluginConfig],
      apiImpl: this,
    ));
  }

  TaskConstMeta get kCrateApiPluginManagerPluginManagerInitPluginConstMeta =>
      const TaskConstMeta(
        debugName: "PluginManager_init_plugin",
        argNames: ["that", "name", "pluginConfig"],
      );

  @override
  Future<PluginManager> crateApiPluginManagerPluginManagerNew() {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 3, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData:
            sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager,
        decodeErrorData: null,
      ),
      constMeta: kCrateApiPluginManagerPluginManagerNewConstMeta,
      argValues: [],
      apiImpl: this,
    ));
  }

  TaskConstMeta get kCrateApiPluginManagerPluginManagerNewConstMeta =>
      const TaskConstMeta(
        debugName: "PluginManager_new",
        argNames: [],
      );

  @override
  Future<void> crateApiPluginManagerPluginManagerSelect(
      {required PluginManager that,
      required String name,
      required List<(String, String)> config,
      required String elementName}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
            that, serializer);
        sse_encode_String(name, serializer);
        sse_encode_list_record_string_string(config, serializer);
        sse_encode_String(elementName, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 4, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: sse_decode_AnyhowException,
      ),
      constMeta: kCrateApiPluginManagerPluginManagerSelectConstMeta,
      argValues: [that, name, config, elementName],
      apiImpl: this,
    ));
  }

  TaskConstMeta get kCrateApiPluginManagerPluginManagerSelectConstMeta =>
      const TaskConstMeta(
        debugName: "PluginManager_select",
        argNames: ["that", "name", "config", "elementName"],
      );

  @override
  Future<(String, PathBuf)> crateApiPluginManagerExpandEnvVars(
      {required String path}) {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_String(path, serializer);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 5, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData:
            sse_decode_record_string_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_path_buf,
        decodeErrorData: null,
      ),
      constMeta: kCrateApiPluginManagerExpandEnvVarsConstMeta,
      argValues: [path],
      apiImpl: this,
    ));
  }

  TaskConstMeta get kCrateApiPluginManagerExpandEnvVarsConstMeta =>
      const TaskConstMeta(
        debugName: "expand_env_vars",
        argNames: ["path"],
      );

  @override
  String crateApiSimpleGreet({required String name}) {
    return handler.executeSync(SyncTask(
      callFfi: () {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        sse_encode_String(name, serializer);
        return pdeCallFfi(generalizedFrbRustBinding, serializer, funcId: 6)!;
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_String,
        decodeErrorData: null,
      ),
      constMeta: kCrateApiSimpleGreetConstMeta,
      argValues: [name],
      apiImpl: this,
    ));
  }

  TaskConstMeta get kCrateApiSimpleGreetConstMeta => const TaskConstMeta(
        debugName: "greet",
        argNames: ["name"],
      );

  @override
  Future<void> crateApiSimpleInitApp() {
    return handler.executeNormal(NormalTask(
      callFfi: (port_) {
        final serializer = SseSerializer(generalizedFrbRustBinding);
        pdeCallFfi(generalizedFrbRustBinding, serializer,
            funcId: 7, port: port_);
      },
      codec: SseCodec(
        decodeSuccessData: sse_decode_unit,
        decodeErrorData: null,
      ),
      constMeta: kCrateApiSimpleInitAppConstMeta,
      argValues: [],
      apiImpl: this,
    ));
  }

  TaskConstMeta get kCrateApiSimpleInitAppConstMeta => const TaskConstMeta(
        debugName: "init_app",
        argNames: [],
      );

  RustArcIncrementStrongCountFnType
      get rust_arc_increment_strong_count_PathBuf => wire
          .rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf;

  RustArcDecrementStrongCountFnType
      get rust_arc_decrement_strong_count_PathBuf => wire
          .rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf;

  RustArcIncrementStrongCountFnType
      get rust_arc_increment_strong_count_PluginManager => wire
          .rust_arc_increment_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager;

  RustArcDecrementStrongCountFnType
      get rust_arc_decrement_strong_count_PluginManager => wire
          .rust_arc_decrement_strong_count_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager;

  @protected
  AnyhowException dco_decode_AnyhowException(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return AnyhowException(raw as String);
  }

  @protected
  PathBuf
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
          dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return PathBufImpl.frbInternalDcoDecode(raw as List<dynamic>);
  }

  @protected
  PluginManager
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return PluginManagerImpl.frbInternalDcoDecode(raw as List<dynamic>);
  }

  @protected
  PluginManager
      dco_decode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return PluginManagerImpl.frbInternalDcoDecode(raw as List<dynamic>);
  }

  @protected
  PathBuf
      dco_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
          dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return PathBufImpl.frbInternalDcoDecode(raw as List<dynamic>);
  }

  @protected
  PluginManager
      dco_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return PluginManagerImpl.frbInternalDcoDecode(raw as List<dynamic>);
  }

  @protected
  String dco_decode_String(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as String;
  }

  @protected
  bool dco_decode_bool(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as bool;
  }

  @protected
  PluginConfig dco_decode_box_autoadd_plugin_config(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return dco_decode_plugin_config(raw);
  }

  @protected
  List<String> dco_decode_list_String(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_String).toList();
  }

  @protected
  List<PluginItem> dco_decode_list_plugin_item(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_plugin_item).toList();
  }

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as Uint8List;
  }

  @protected
  List<(String, String)> dco_decode_list_record_string_string(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return (raw as List<dynamic>).map(dco_decode_record_string_string).toList();
  }

  @protected
  PluginConfig dco_decode_plugin_config(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 5)
      throw Exception('unexpected arr length: expect 5 but see ${arr.length}');
    return PluginConfig(
      wasmPath: dco_decode_String(arr[0]),
      allowedPaths: dco_decode_list_String(arr[1]),
      allowedHosts: dco_decode_list_String(arr[2]),
      enableWasi: dco_decode_bool(arr[3]),
      config: dco_decode_list_record_string_string(arr[4]),
    );
  }

  @protected
  PluginItem dco_decode_plugin_item(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 3)
      throw Exception('unexpected arr length: expect 3 but see ${arr.length}');
    return PluginItem(
      name: dco_decode_String(arr[0]),
      description: dco_decode_String(arr[1]),
      icon: dco_decode_String(arr[2]),
    );
  }

  @protected
  (
    String,
    PathBuf
  ) dco_decode_record_string_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_path_buf(
      dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 2) {
      throw Exception('Expected 2 elements, got ${arr.length}');
    }
    return (
      dco_decode_String(arr[0]),
      dco_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
          arr[1]),
    );
  }

  @protected
  (String, String) dco_decode_record_string_string(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    final arr = raw as List<dynamic>;
    if (arr.length != 2) {
      throw Exception('Expected 2 elements, got ${arr.length}');
    }
    return (
      dco_decode_String(arr[0]),
      dco_decode_String(arr[1]),
    );
  }

  @protected
  int dco_decode_u_8(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return raw as int;
  }

  @protected
  void dco_decode_unit(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return;
  }

  @protected
  BigInt dco_decode_usize(dynamic raw) {
    // Codec=Dco (DartCObject based), see doc to use other codecs
    return dcoDecodeU64(raw);
  }

  @protected
  AnyhowException sse_decode_AnyhowException(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var inner = sse_decode_String(deserializer);
    return AnyhowException(inner);
  }

  @protected
  PathBuf
      sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
          SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return PathBufImpl.frbInternalSseDecode(
        sse_decode_usize(deserializer), sse_decode_i_32(deserializer));
  }

  @protected
  PluginManager
      sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return PluginManagerImpl.frbInternalSseDecode(
        sse_decode_usize(deserializer), sse_decode_i_32(deserializer));
  }

  @protected
  PluginManager
      sse_decode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return PluginManagerImpl.frbInternalSseDecode(
        sse_decode_usize(deserializer), sse_decode_i_32(deserializer));
  }

  @protected
  PathBuf
      sse_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
          SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return PathBufImpl.frbInternalSseDecode(
        sse_decode_usize(deserializer), sse_decode_i_32(deserializer));
  }

  @protected
  PluginManager
      sse_decode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return PluginManagerImpl.frbInternalSseDecode(
        sse_decode_usize(deserializer), sse_decode_i_32(deserializer));
  }

  @protected
  String sse_decode_String(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var inner = sse_decode_list_prim_u_8_strict(deserializer);
    return utf8.decoder.convert(inner);
  }

  @protected
  bool sse_decode_bool(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint8() != 0;
  }

  @protected
  PluginConfig sse_decode_box_autoadd_plugin_config(
      SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return (sse_decode_plugin_config(deserializer));
  }

  @protected
  List<String> sse_decode_list_String(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <String>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_String(deserializer));
    }
    return ans_;
  }

  @protected
  List<PluginItem> sse_decode_list_plugin_item(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <PluginItem>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_plugin_item(deserializer));
    }
    return ans_;
  }

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var len_ = sse_decode_i_32(deserializer);
    return deserializer.buffer.getUint8List(len_);
  }

  @protected
  List<(String, String)> sse_decode_list_record_string_string(
      SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs

    var len_ = sse_decode_i_32(deserializer);
    var ans_ = <(String, String)>[];
    for (var idx_ = 0; idx_ < len_; ++idx_) {
      ans_.add(sse_decode_record_string_string(deserializer));
    }
    return ans_;
  }

  @protected
  PluginConfig sse_decode_plugin_config(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_wasmPath = sse_decode_String(deserializer);
    var var_allowedPaths = sse_decode_list_String(deserializer);
    var var_allowedHosts = sse_decode_list_String(deserializer);
    var var_enableWasi = sse_decode_bool(deserializer);
    var var_config = sse_decode_list_record_string_string(deserializer);
    return PluginConfig(
        wasmPath: var_wasmPath,
        allowedPaths: var_allowedPaths,
        allowedHosts: var_allowedHosts,
        enableWasi: var_enableWasi,
        config: var_config);
  }

  @protected
  PluginItem sse_decode_plugin_item(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_name = sse_decode_String(deserializer);
    var var_description = sse_decode_String(deserializer);
    var var_icon = sse_decode_String(deserializer);
    return PluginItem(
        name: var_name, description: var_description, icon: var_icon);
  }

  @protected
  (
    String,
    PathBuf
  ) sse_decode_record_string_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_path_buf(
      SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_field0 = sse_decode_String(deserializer);
    var var_field1 =
        sse_decode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
            deserializer);
    return (var_field0, var_field1);
  }

  @protected
  (String, String) sse_decode_record_string_string(
      SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    var var_field0 = sse_decode_String(deserializer);
    var var_field1 = sse_decode_String(deserializer);
    return (var_field0, var_field1);
  }

  @protected
  int sse_decode_u_8(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getUint8();
  }

  @protected
  void sse_decode_unit(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
  }

  @protected
  BigInt sse_decode_usize(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getBigUint64();
  }

  @protected
  int sse_decode_i_32(SseDeserializer deserializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    return deserializer.buffer.getInt32();
  }

  @protected
  void sse_encode_AnyhowException(
      AnyhowException self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.message, serializer);
  }

  @protected
  void
      sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
          PathBuf self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(
        (self as PathBufImpl).frbInternalSseEncode(move: true), serializer);
  }

  @protected
  void
      sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          PluginManager self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(
        (self as PluginManagerImpl).frbInternalSseEncode(move: true),
        serializer);
  }

  @protected
  void
      sse_encode_Auto_RefMut_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          PluginManager self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(
        (self as PluginManagerImpl).frbInternalSseEncode(move: false),
        serializer);
  }

  @protected
  void
      sse_encode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
          PathBuf self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(
        (self as PathBufImpl).frbInternalSseEncode(move: null), serializer);
  }

  @protected
  void
      sse_encode_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPluginManager(
          PluginManager self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_usize(
        (self as PluginManagerImpl).frbInternalSseEncode(move: null),
        serializer);
  }

  @protected
  void sse_encode_String(String self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_list_prim_u_8_strict(utf8.encoder.convert(self), serializer);
  }

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint8(self ? 1 : 0);
  }

  @protected
  void sse_encode_box_autoadd_plugin_config(
      PluginConfig self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_plugin_config(self, serializer);
  }

  @protected
  void sse_encode_list_String(List<String> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_String(item, serializer);
    }
  }

  @protected
  void sse_encode_list_plugin_item(
      List<PluginItem> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_plugin_item(item, serializer);
    }
  }

  @protected
  void sse_encode_list_prim_u_8_strict(
      Uint8List self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    serializer.buffer.putUint8List(self);
  }

  @protected
  void sse_encode_list_record_string_string(
      List<(String, String)> self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_i_32(self.length, serializer);
    for (final item in self) {
      sse_encode_record_string_string(item, serializer);
    }
  }

  @protected
  void sse_encode_plugin_config(PluginConfig self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.wasmPath, serializer);
    sse_encode_list_String(self.allowedPaths, serializer);
    sse_encode_list_String(self.allowedHosts, serializer);
    sse_encode_bool(self.enableWasi, serializer);
    sse_encode_list_record_string_string(self.config, serializer);
  }

  @protected
  void sse_encode_plugin_item(PluginItem self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.name, serializer);
    sse_encode_String(self.description, serializer);
    sse_encode_String(self.icon, serializer);
  }

  @protected
  void
      sse_encode_record_string_auto_owned_rust_opaque_flutter_rust_bridgefor_generated_rust_auto_opaque_inner_path_buf(
          (String, PathBuf) self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.$1, serializer);
    sse_encode_Auto_Owned_RustOpaque_flutter_rust_bridgefor_generatedRustAutoOpaqueInnerPathBuf(
        self.$2, serializer);
  }

  @protected
  void sse_encode_record_string_string(
      (String, String) self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    sse_encode_String(self.$1, serializer);
    sse_encode_String(self.$2, serializer);
  }

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putUint8(self);
  }

  @protected
  void sse_encode_unit(void self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
  }

  @protected
  void sse_encode_usize(BigInt self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putBigUint64(self);
  }

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer) {
    // Codec=Sse (Serialization based), see doc to use other codecs
    serializer.buffer.putInt32(self);
  }
}

@sealed
class PathBufImpl extends RustOpaque implements PathBuf {
  // Not to be used by end users
  PathBufImpl.frbInternalDcoDecode(List<dynamic> wire)
      : super.frbInternalDcoDecode(wire, _kStaticData);

  // Not to be used by end users
  PathBufImpl.frbInternalSseDecode(BigInt ptr, int externalSizeOnNative)
      : super.frbInternalSseDecode(ptr, externalSizeOnNative, _kStaticData);

  static final _kStaticData = RustArcStaticData(
    rustArcIncrementStrongCount:
        RustLib.instance.api.rust_arc_increment_strong_count_PathBuf,
    rustArcDecrementStrongCount:
        RustLib.instance.api.rust_arc_decrement_strong_count_PathBuf,
    rustArcDecrementStrongCountPtr:
        RustLib.instance.api.rust_arc_decrement_strong_count_PathBufPtr,
  );
}

@sealed
class PluginManagerImpl extends RustOpaque implements PluginManager {
  // Not to be used by end users
  PluginManagerImpl.frbInternalDcoDecode(List<dynamic> wire)
      : super.frbInternalDcoDecode(wire, _kStaticData);

  // Not to be used by end users
  PluginManagerImpl.frbInternalSseDecode(BigInt ptr, int externalSizeOnNative)
      : super.frbInternalSseDecode(ptr, externalSizeOnNative, _kStaticData);

  static final _kStaticData = RustArcStaticData(
    rustArcIncrementStrongCount:
        RustLib.instance.api.rust_arc_increment_strong_count_PluginManager,
    rustArcDecrementStrongCount:
        RustLib.instance.api.rust_arc_decrement_strong_count_PluginManager,
    rustArcDecrementStrongCountPtr:
        RustLib.instance.api.rust_arc_decrement_strong_count_PluginManagerPtr,
  );

  Future<List<PluginItem>> filterPlugin(
          {required String name,
          required List<(String, String)> config,
          required String query}) =>
      RustLib.instance.api.crateApiPluginManagerPluginManagerFilterPlugin(
          that: this, name: name, config: config, query: query);

  Future<List<PluginItem>> initPlugin(
          {required String name, required PluginConfig pluginConfig}) =>
      RustLib.instance.api.crateApiPluginManagerPluginManagerInitPlugin(
          that: this, name: name, pluginConfig: pluginConfig);

  Future<void> select(
          {required String name,
          required List<(String, String)> config,
          required String elementName}) =>
      RustLib.instance.api.crateApiPluginManagerPluginManagerSelect(
          that: this, name: name, config: config, elementName: elementName);
}
