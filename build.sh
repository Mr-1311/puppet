dart pub get
dart run flutter_iconpicker:generate_packs --packs fontAwesomeIcons

#rust must be installed
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen generate

flutter run
