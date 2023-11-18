import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/config.dart';
import 'package:puppet/config_repository.dart';
import 'package:puppet/wheel.dart';
import 'dart:ui';

final configRepositoryProvider = FutureProvider<ConfigRepository>((ref) {
  return ConfigRepository.getInstance();
});

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(configRepositoryProvider);
    conf.whenData((value) {
      print(value.elements);
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Wheel(
        sectionSize: 3,
      ),
    );
  }
}
