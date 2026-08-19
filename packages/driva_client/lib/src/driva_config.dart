import 'package:driva_client/src/cache/driva_cache_store.dart';
import 'package:equatable/equatable.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

class DrivaConfig extends Equatable {
  const DrivaConfig({
    required this.baseUrl,
    required this.publishableKey,
    this.fallbacks = const {},
    this.registry,
    this.cache,
  });

  final String baseUrl;
  final String publishableKey;
  final Map<String, Map<String, dynamic>> fallbacks;
  final SduiRegistry? registry;
  final DrivaCacheStore? cache;

  @override
  List<Object?> get props => [
    baseUrl,
    publishableKey,
    fallbacks,
    registry,
    cache,
  ];
}
