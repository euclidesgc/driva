import 'dart:convert';
import 'dart:developer';

import 'package:driva_client/src/cache/driva_cache_store.dart';
import 'package:driva_client/src/cached_content.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsCacheStore implements DrivaCacheStore {
  @override
  Future<CachedContent?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return CachedContent.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object catch (error) {
      log(
        'Entrada de cache corrompida para "$key": $error',
        name: 'driva_client',
      );
      await prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedContent value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value.toJson()));
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
