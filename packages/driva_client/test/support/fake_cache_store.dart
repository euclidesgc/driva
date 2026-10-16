import 'package:driva_client/driva_client.dart';

class FakeCacheStore implements DrivaCacheStore {
  FakeCacheStore({CachedContent? seed}) : _current = seed;

  CachedContent? _current;
  final List<CachedContent> written = [];

  @override
  Future<CachedContent?> read(String key) async => _current;

  @override
  Future<void> write(String key, CachedContent value) async {
    written.add(value);
    _current = value;
  }

  @override
  Future<void> delete(String key) async => _current = null;
}
