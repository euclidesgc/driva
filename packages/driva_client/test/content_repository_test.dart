import 'dart:convert';

import 'package:driva_client/driva_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
      expect(emissions.single.slug, 'home');
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
      expect(emissions.single.id, 'home-id');
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
        expect(emissions.single.id, 'home-id');
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
