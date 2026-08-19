import 'package:driva_client/src/cached_content.dart';

abstract interface class DrivaCacheStore {
  Future<CachedContent?> read(String key);
  Future<void> write(String key, CachedContent value);
  Future<void> delete(String key);
}
