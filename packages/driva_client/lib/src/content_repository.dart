import 'dart:convert';
import 'dart:developer';

import 'package:driva_client/src/cache/driva_cache_store.dart';
import 'package:driva_client/src/cache/prefs_cache_store.dart';
import 'package:driva_client/src/cached_content.dart';
import 'package:driva_client/src/driva_config.dart';
import 'package:driva_client/src/driva_load_failure.dart';
import 'package:driva_client/src/fetch_outcome.dart';
import 'package:http/http.dart' as http;
import 'package:sdui_core/sdui_core.dart';

typedef _Entry = ({ContentSpec spec, CachedContent cached});

class DrivaContentRepository {
  DrivaContentRepository({required DrivaConfig config, http.Client? httpClient})
    : _config = config,
      _httpClient = httpClient ?? http.Client(),
      _cache = config.cache ?? PrefsCacheStore();

  final DrivaConfig _config;
  final http.Client _httpClient;
  final DrivaCacheStore _cache;
  final Map<String, _Entry> _memory = {};

  Stream<ContentSpec> load(String slug) async* {
    final cacheKey = _cacheKeyFor(slug);
    var entry = _memory[cacheKey];

    entry ??= await _readDiskEntry(cacheKey);
    if (entry != null) {
      _memory[cacheKey] = entry;
      yield entry.spec;
    }

    final outcome = await _fetchAndValidate(
      slug,
      ifNoneMatch: entry?.cached.etag,
    );

    DrivaLoadCause? failureCause;
    switch (outcome) {
      case FetchOk(entry: final fetched):
        _memory[cacheKey] = fetched;
        await _cache.write(cacheKey, fetched.cached);
        yield fetched.spec;
        return;
      case FetchNotModified():
        if (entry != null) return;
      case FetchFailed(cause: final cause):
        failureCause = cause;
    }

    if (entry != null) return;

    final fallback = _fallbackFor(slug);
    if (fallback != null) {
      yield fallback;
      return;
    }

    final cause = failureCause ?? DrivaLoadCause.serverError;
    log(
      'Nenhum conteúdo disponível para "$slug": sem cache, sem rede, sem '
      'fallback (causa: $cause).',
      name: 'driva_client',
    );
    throw DrivaLoadFailure(slug: slug, cause: cause);
  }

  void dispose() => _httpClient.close();

  Future<_Entry?> _readDiskEntry(String cacheKey) async {
    final onDisk = await _cache.read(cacheKey);
    if (onDisk == null) return null;

    final parsed = parseContentSpec(onDisk.specJson);
    if (parsed.isLeft()) {
      await _cache.delete(cacheKey);
      return null;
    }
    return (spec: parsed.getRight().toNullable()!, cached: onDisk);
  }

  Future<FetchOutcome> _fetchAndValidate(
    String slug, {
    String? ifNoneMatch,
  }) async {
    final http.Response response;
    try {
      response = await _httpClient.get(
        _uriFor(slug),
        headers: {
          'x-driva-key': _config.publishableKey,
          'if-none-match': ?ifNoneMatch,
        },
      );
    } on Object catch (error) {
      log('Falha de rede ao buscar "$slug": $error', name: 'driva_client');
      return const FetchFailed(DrivaLoadCause.network);
    }

    if (response.statusCode == 304) return const FetchNotModified();

    if (response.statusCode == 404) {
      log('Conteúdo "$slug" não encontrado (404)', name: 'driva_client');
      return const FetchFailed(DrivaLoadCause.notFound);
    }

    if (response.statusCode != 200) {
      log(
        'Resposta ${response.statusCode} ao buscar "$slug"',
        name: 'driva_client',
      );
      return const FetchFailed(DrivaLoadCause.serverError);
    }

    final dynamic envelope;
    try {
      envelope = jsonDecode(response.body);
    } on Object catch (error) {
      log('Corpo inválido ao buscar "$slug": $error', name: 'driva_client');
      return const FetchFailed(DrivaLoadCause.invalidSpec);
    }
    if (envelope is! Map || envelope['spec'] is! Map) {
      log('Envelope inesperado ao buscar "$slug"', name: 'driva_client');
      return const FetchFailed(DrivaLoadCause.invalidSpec);
    }

    final specJson = Map<String, dynamic>.from(envelope['spec'] as Map);
    final parsed = parseContentSpec(specJson);
    if (parsed.isLeft()) {
      final reason = parsed.getLeft().toNullable()?.message;
      log('Spec inválido ao buscar "$slug": $reason', name: 'driva_client');
      return const FetchFailed(DrivaLoadCause.invalidSpec);
    }

    return FetchOk((
      spec: parsed.getRight().toNullable()!,
      cached: CachedContent(
        specJson: specJson,
        etag: response.headers['etag'],
        fetchedAt: DateTime.now(),
      ),
    ));
  }

  ContentSpec? _fallbackFor(String slug) {
    final raw = _config.fallbacks[slug];
    if (raw == null) return null;

    final parsed = parseContentSpec(raw);
    if (parsed.isLeft()) {
      final reason = parsed.getLeft().toNullable()?.message;
      log(
        'Fallback embarcado inválido para "$slug": $reason',
        name: 'driva_client',
      );
      return null;
    }
    return parsed.getRight().toNullable();
  }

  Uri _uriFor(String slug) {
    final base = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    return Uri.parse('$base/v1/public/contents/${Uri.encodeComponent(slug)}');
  }

  String _cacheKeyFor(String slug) =>
      'driva:${_shortHash(_config.publishableKey)}:$slug';

  String _shortHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) * 0x01000193 & 0xffffffff;
    }
    return hash.toRadixString(36);
  }
}
