import 'package:driva_client/src/cache/driva_cache_store.dart';
import 'package:driva_client/src/cached_content.dart';

class MemoryCacheStore implements DrivaCacheStore {
  final Map<String, CachedContent> _entries = {};

  @override
  Future<CachedContent?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, CachedContent value) async {
    _entries[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _entries.remove(key);
  }
}
