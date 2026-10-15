import 'dart:convert';

import 'package:driva_client/driva_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sdui_core/sdui_core.dart';

import 'support/fake_cache_store.dart';

const Map<String, dynamic> _validSpecJson = {
  'specVersion': 1,
  'kind': 'content',
  'id': 'home-id',
  'name': 'Home',
  'slug': 'home',
};

Map<String, dynamic> _envelope(Map<String, dynamic> spec) => {
  'id': 'home-id',
  'name': 'Home',
  'slug': 'home',
  'updatedAt': DateTime.now().toIso8601String(),
  'spec': spec,
};

Map<String, dynamic> _themedEnvelope(Object? theme) => {
  ..._envelope(_validSpecJson),
  'theme': theme,
};

const Map<String, dynamic> _redThemeJson = {
  'colors': {'primary': '#FF0000'},
};

const Map<String, dynamic> _blueThemeJson = {
  'colors': {'primary': '#0000FF'},
};

DrivaContentRepository _repositoryWith({
  required http.Client client,
  required DrivaCacheStore cache,
  Map<String, Map<String, dynamic>> fallbacks = const {},
}) => DrivaContentRepository(
  config: DrivaConfig(
    baseUrl: 'https://api.example.com',
    publishableKey: 'pk_test',
    fallbacks: fallbacks,
    cache: cache,
  ),
  httpClient: client,
);

String? _primaryOf(DrivaLoadedContent loaded) =>
    loaded.theme.colors[ThemeColorRole.primary];

void main() {
  group('DrivaContentRepository', () {
    test('sem cache: busca da rede e emite uma vez', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode(_envelope(_validSpecJson)),
          200,
          headers: {'etag': '"home-1"'},
        ),
      );
      final repository = DrivaContentRepository(
        config: DrivaConfig(
          baseUrl: 'https://api.example.com',
          publishableKey: 'pk_test',
          cache: MemoryCacheStore(),
        ),
        httpClient: client,
      );

      final emissions = await repository.load('home').toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.spec.slug, 'home');
    });

    test('304 não produz emissão além da já servida em memória', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            jsonEncode(_envelope(_validSpecJson)),
            200,
            headers: {'etag': '"home-1"'},
          );
        }
        expect(request.headers['if-none-match'], '"home-1"');
        return http.Response('', 304);
      });
      final repository = DrivaContentRepository(
        config: DrivaConfig(
          baseUrl: 'https://api.example.com',
          publishableKey: 'pk_test',
          cache: MemoryCacheStore(),
        ),
        httpClient: client,
      );

      final first = await repository.load('home').toList();
      final second = await repository.load('home').toList();

      expect(first, hasLength(1));
      expect(second, hasLength(1));
      expect(requestCount, 2);
    });

    test('specVersion incompatível cai no fallback embarcado', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode(
            _envelope({..._validSpecJson, 'specVersion': 999}),
          ),
          200,
        ),
      );
      final repository = DrivaContentRepository(
        config: DrivaConfig(
          baseUrl: 'https://api.example.com',
          publishableKey: 'pk_test',
          fallbacks: const {'home': _validSpecJson},
          cache: MemoryCacheStore(),
        ),
        httpClient: client,
      );

      final emissions = await repository.load('home').toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.spec.id, 'home-id');
    });

    test(r'spec v2 com $bind numa prop carrega sem falha', () async {
      const boundText = {
        r'$bind': {
          'source': 'pageParam',
          'path': 'nomeCliente',
          'fallback': 'Visitante',
          'literal': 'Olá',
        },
      };
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode(
            _envelope({
              ..._validSpecJson,
              'specVersion': 2,
              'root': {
                'id': 'title',
                'type': 'text',
                'props': {'text': boundText},
              },
            }),
          ),
          200,
        ),
      );
      final repository = DrivaContentRepository(
        config: DrivaConfig(
          baseUrl: 'https://api.example.com',
          publishableKey: 'pk_test',
          cache: MemoryCacheStore(),
        ),
        httpClient: client,
      );

      final emissions = await repository.load('home').toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.spec.specVersion, 2);
      expect(emissions.single.spec.root?.properties['text'], boundText);
    });

    test(
      'falha total sem fallback emite DrivaLoadFailure(serverError) e não '
      'lança exceção não capturada',
      () async {
        final client = MockClient((request) async => http.Response('', 500));
        final repository = DrivaContentRepository(
          config: DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        DrivaLoadFailure? caught;
        try {
          await repository.load('home').toList();
        } on DrivaLoadFailure catch (error) {
          caught = error;
        }

        expect(caught, isNotNull);
        expect(caught!.slug, 'home');
        expect(caught.cause, DrivaLoadCause.serverError);
      },
    );

    test(
      'falha total por exceção de rede emite DrivaLoadFailure(network)',
      () async {
        final client = MockClient((request) async => throw Exception('boom'));
        final repository = DrivaContentRepository(
          config: DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        DrivaLoadFailure? caught;
        try {
          await repository.load('home').toList();
        } on DrivaLoadFailure catch (error) {
          caught = error;
        }

        expect(caught, isNotNull);
        expect(caught!.slug, 'home');
        expect(caught.cause, DrivaLoadCause.network);
      },
    );

    test(
      'falha total por 404 emite DrivaLoadFailure(notFound)',
      () async {
        final client = MockClient((request) async => http.Response('', 404));
        final repository = DrivaContentRepository(
          config: DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        DrivaLoadFailure? caught;
        try {
          await repository.load('home').toList();
        } on DrivaLoadFailure catch (error) {
          caught = error;
        }

        expect(caught, isNotNull);
        expect(caught!.slug, 'home');
        expect(caught.cause, DrivaLoadCause.notFound);
      },
    );

    test(
      'falha total por spec que não passa no parse emite '
      'DrivaLoadFailure(invalidSpec)',
      () async {
        final client = MockClient(
          (request) async => http.Response(
            jsonEncode(_envelope(const {'kind': 'content'})),
            200,
          ),
        );
        final repository = DrivaContentRepository(
          config: DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        DrivaLoadFailure? caught;
        try {
          await repository.load('home').toList();
        } on DrivaLoadFailure catch (error) {
          caught = error;
        }

        expect(caught, isNotNull);
        expect(caught!.slug, 'home');
        expect(caught.cause, DrivaLoadCause.invalidSpec);
      },
    );

    test(
      'falha de rede com fallback embarcado servível não produz erro no '
      'stream',
      () async {
        final client = MockClient((request) async => throw Exception('boom'));
        final repository = DrivaContentRepository(
          config: DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            fallbacks: const {'home': _validSpecJson},
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        final emissions = await repository.load('home').toList();

        expect(emissions, hasLength(1));
        expect(emissions.single.spec.id, 'home-id');
      },
    );

    test(
      '304 sem cache local para revalidar emite '
      'DrivaLoadFailure(serverError)',
      () async {
        final client = MockClient((request) async => http.Response('', 304));
        final repository = DrivaContentRepository(
          config: DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: MemoryCacheStore(),
          ),
          httpClient: client,
        );

        DrivaLoadFailure? caught;
        try {
          await repository.load('home').toList();
        } on DrivaLoadFailure catch (error) {
          caught = error;
        }

        expect(caught, isNotNull);
        expect(caught!.slug, 'home');
        expect(caught.cause, DrivaLoadCause.serverError);
      },
    );

    test(
      'spec inválido em disco é descartado, não renderizado, e a falha '
      'total que segue emite DrivaLoadFailure',
      () async {
        final cache = _CorruptCacheStore();
        final client = MockClient((request) async => http.Response('', 500));
        final repository = DrivaContentRepository(
          config: DrivaConfig(
            baseUrl: 'https://api.example.com',
            publishableKey: 'pk_test',
            cache: cache,
          ),
          httpClient: client,
        );

        DrivaLoadFailure? caught;
        try {
          await repository.load('home').toList();
        } on DrivaLoadFailure catch (error) {
          caught = error;
        }

        expect(caught, isNotNull);
        expect(caught!.cause, DrivaLoadCause.serverError);
        expect(cache.deleted, isTrue);
      },
    );
  });

  group('DrivaContentRepository: tema do projeto', () {
    test(
      '200 com theme emite o tema lido e grava o themeJson no cache',
      () async {
        final cache = FakeCacheStore();
        final client = MockClient(
          (request) async => http.Response(
            jsonEncode(_themedEnvelope(_redThemeJson)),
            200,
            headers: {'etag': '"home-1"'},
          ),
        );

        final emissions = await _repositoryWith(
          client: client,
          cache: cache,
        ).load('home').toList();

        expect(emissions, hasLength(1));
        expect(_primaryOf(emissions.single), '#FF0000');
        expect(cache.written.single.themeJson, _redThemeJson);
      },
    );

    test(
      'cache em disco com tema e rede falhando emite o tema guardado',
      () async {
        final cache = FakeCacheStore(
          seed: CachedContent(
            specJson: _validSpecJson,
            etag: '"home-1"',
            fetchedAt: DateTime.now(),
            themeJson: _redThemeJson,
          ),
        );
        final client = MockClient((request) async => throw Exception('boom'));

        final emissions = await _repositoryWith(
          client: client,
          cache: cache,
        ).load('home').toList();

        expect(emissions, hasLength(1));
        expect(emissions.single.spec.id, 'home-id');
        expect(_primaryOf(emissions.single), '#FF0000');
      },
    );

    test('304 mantém o tema já emitido', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            jsonEncode(_themedEnvelope(_redThemeJson)),
            200,
            headers: {'etag': '"home-1"'},
          );
        }
        return http.Response('', 304);
      });
      final repository = _repositoryWith(
        client: client,
        cache: FakeCacheStore(),
      );

      final first = await repository.load('home').toList();
      final second = await repository.load('home').toList();

      expect(requestCount, 2);
      expect(second, hasLength(1));
      expect(second.single, first.single);
      expect(_primaryOf(second.single), '#FF0000');
    });

    test('200 com tema novo emite de novo com o tema novo', () async {
      final cache = FakeCacheStore(
        seed: CachedContent(
          specJson: _validSpecJson,
          etag: '"home-1"',
          fetchedAt: DateTime.now(),
          themeJson: _redThemeJson,
        ),
      );
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode(_themedEnvelope(_blueThemeJson)),
          200,
          headers: {'etag': '"home-2"'},
        ),
      );

      final emissions = await _repositoryWith(
        client: client,
        cache: cache,
      ).load('home').toList();

      expect(emissions.map(_primaryOf), ['#FF0000', '#0000FF']);
      expect(cache.written.single.themeJson, _blueThemeJson);
    });

    test(
      'CachedContent.fromJson sem a chave themeJson lê sem erro e o '
      'conteúdo sai com o tema padrão',
      () async {
        final legacy = CachedContent.fromJson({
          'specJson': _validSpecJson,
          'etag': '"home-1"',
          'fetchedAt': DateTime.now().toIso8601String(),
        });
        final client = MockClient((request) async => throw Exception('boom'));

        final emissions = await _repositoryWith(
          client: client,
          cache: FakeCacheStore(seed: legacy),
        ).load('home').toList();

        expect(legacy.themeJson, isNull);
        expect(emissions, hasLength(1));
        expect(emissions.single.theme, kDefaultProjectTheme);
      },
    );

    test('CachedContent preserva o themeJson ida e volta pelo JSON', () {
      final original = CachedContent(
        specJson: _validSpecJson,
        etag: '"home-1"',
        fetchedAt: DateTime.utc(2026, 10, 15),
        themeJson: _redThemeJson,
      );

      expect(CachedContent.fromJson(original.toJson()), original);
    });

    test(
      'envelope com theme que não é objeto emite o conteúdo com o tema '
      'padrão',
      () async {
        final cache = FakeCacheStore();
        final client = MockClient(
          (request) async =>
              http.Response(jsonEncode(_themedEnvelope('abc')), 200),
        );

        final emissions = await _repositoryWith(
          client: client,
          cache: cache,
        ).load('home').toList();

        expect(emissions, hasLength(1));
        expect(emissions.single.spec.id, 'home-id');
        expect(emissions.single.theme, kDefaultProjectTheme);
        expect(cache.written.single.themeJson, isNull);
      },
    );

    test(
      'envelope com primary ilegível emite o conteúdo com o primary padrão',
      () async {
        final client = MockClient(
          (request) async => http.Response(
            jsonEncode(
              _themedEnvelope({
                'colors': {'primary': 1},
              }),
            ),
            200,
          ),
        );

        final emissions = await _repositoryWith(
          client: client,
          cache: FakeCacheStore(),
        ).load('home').toList();

        expect(emissions, hasLength(1));
        expect(emissions.single.spec.id, 'home-id');
        expect(
          _primaryOf(emissions.single),
          kDefaultProjectTheme.colors[ThemeColorRole.primary],
        );
      },
    );

    test('fallback embarcado é emitido com o tema padrão', () async {
      final client = MockClient((request) async => throw Exception('boom'));

      final emissions = await _repositoryWith(
        client: client,
        cache: FakeCacheStore(),
        fallbacks: const {'home': _validSpecJson},
      ).load('home').toList();

      expect(emissions, hasLength(1));
      expect(emissions.single.spec.id, 'home-id');
      expect(emissions.single.theme, kDefaultProjectTheme);
    });
  });

  group('Driva', () {
    tearDown(Driva.resetForTesting);

    test('instance lança StateError antes de init', () {
      expect(() => Driva.instance, throwsStateError);
    });

    test('init é idempotente', () async {
      await Driva.init(
        const DrivaConfig(
          baseUrl: 'https://a.example.com',
          publishableKey: 'pk_a',
        ),
      );
      final first = Driva.instance;

      await Driva.init(
        const DrivaConfig(
          baseUrl: 'https://b.example.com',
          publishableKey: 'pk_b',
        ),
      );

      expect(Driva.instance, same(first));
      expect(Driva.instance.config.publishableKey, 'pk_a');
    });

    test('init encaminha o httpClient injetado ao repositório', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response(jsonEncode(_envelope(_validSpecJson)), 200);
      });

      await Driva.init(
        DrivaConfig(
          baseUrl: 'https://api.example.com',
          publishableKey: 'pk_test',
          cache: MemoryCacheStore(),
        ),
        httpClient: client,
      );

      await Driva.instance.repository.load('home').toList();

      expect(requestCount, greaterThan(0));
    });
  });
}

class _CorruptCacheStore implements DrivaCacheStore {
  bool deleted = false;

  @override
  Future<CachedContent?> read(String key) async => CachedContent(
    specJson: const {'kind': 'content'},
    etag: null,
    fetchedAt: DateTime.now(),
  );

  @override
  Future<void> write(String key, CachedContent value) async {}

  @override
  Future<void> delete(String key) async => deleted = true;
}
