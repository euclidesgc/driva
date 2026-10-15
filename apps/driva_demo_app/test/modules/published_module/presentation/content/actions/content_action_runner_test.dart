import 'package:driva_demo_app/modules/published_module/presentation/content/actions/content_action_runner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

class _Message {
  const _Message(this.text, this.duration, this.backgroundColor);

  final String text;
  final Duration? duration;
  final Color? backgroundColor;
}

class _Harness {
  final navigated = <String>[];
  int backCount = 0;
  final messages = <_Message>[];
  final openedUrls = <Uri>[];
  bool openerResult = true;

  ContentActionRunner get runner => ContentActionRunner(
    onNavigate: navigated.add,
    onNavigateBack: () => backCount++,
    showMessage: (text, {duration, backgroundColor}) =>
        messages.add(_Message(text, duration, backgroundColor)),
    urlOpener: (url) async {
      openedUrls.add(url);
      return openerResult;
    },
  );

  Future<void> run(String type, [Map<String, dynamic> params = const {}]) =>
      runner.run(SduiAction(type: type, params: params));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Harness h;
  setUp(() => h = _Harness());

  group('navigate', () {
    test('slug literal chama onNavigate com o slug sem espaços', () async {
      await h.run('navigate', {'slug': ' promocoes '});

      expect(h.navigated, ['promocoes']);
      expect(h.messages, isEmpty);
    });

    test('slug em binding mostra o aviso e não navega', () async {
      await h.run('navigate', {
        'slug': {r'$bind': 'item.slug'},
      });

      expect(h.navigated, isEmpty);
      expect(h.messages.single.text, startsWith('Ação recebida: "navigate"'));
    });
  });

  test('navigateBack chama onNavigateBack uma vez', () async {
    await h.run('navigateBack');

    expect(h.backCount, 1);
    expect(h.messages, isEmpty);
  });

  group('showSnackBar', () {
    test('mensagem com duração e cor', () async {
      await h.run('showSnackBar', {
        'message': 'Cupom aplicado',
        'durationMs': 1500,
        'backgroundColor': '#FF0000',
      });

      final message = h.messages.single;
      expect(message.text, 'Cupom aplicado');
      expect(message.duration, const Duration(milliseconds: 1500));
      expect(message.backgroundColor, const Color(0xFFFF0000));
    });

    test('sem durationMs usa 4000 ms', () async {
      await h.run('showSnackBar', {'message': 'Oi'});

      expect(
        h.messages.single.duration,
        const Duration(milliseconds: 4000),
      );
    });

    test('cor inválida vira cor nula', () async {
      await h.run('showSnackBar', {'message': 'Oi', 'backgroundColor': 'azul'});

      expect(h.messages.single.backgroundColor, isNull);
    });

    test('sem message mostra o aviso', () async {
      await h.run('showSnackBar');

      expect(h.messages.single.text, 'Ação recebida: "showSnackBar"');
    });
  });

  group('copyToClipboard', () {
    final copied = <Object?>[];

    setUp(() {
      copied.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied.add((call.arguments as Map)['text']);
            }
            return null;
          });
    });

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    test('grava o texto no clipboard sem mostrar mensagem', () async {
      await h.run('copyToClipboard', {'text': 'CUPOM10'});

      expect(copied, ['CUPOM10']);
      expect(h.messages, isEmpty);
    });

    test('sem text mostra o aviso e não copia', () async {
      await h.run('copyToClipboard');

      expect(copied, isEmpty);
      expect(h.messages.single.text, 'Ação recebida: "copyToClipboard"');
    });
  });

  group('launchUrl', () {
    test('url literal chama o opener uma vez com o Uri', () async {
      await h.run('launchUrl', {'url': 'https://driva.dev'});

      expect(h.openedUrls, [Uri.parse('https://driva.dev')]);
      expect(h.messages, isEmpty);
    });

    test('opener devolvendo false mostra a falha', () async {
      h.openerResult = false;

      await h.run('launchUrl', {'url': 'https://driva.dev'});

      expect(h.messages.single.text, ContentActionRunner.linkFailureMessage);
      expect(h.messages.single.text, 'Não foi possível abrir o link.');
    });

    test('texto sem esquema mostra a falha sem chamar o opener', () async {
      await h.run('launchUrl', {'url': 'não é url'});

      expect(h.openedUrls, isEmpty);
      expect(h.messages.single.text, 'Não foi possível abrir o link.');
    });
  });

  for (final type in ['wait', 'apiCall']) {
    test('$type mostra o aviso e não chama outro callback', () async {
      await h.run(type, {'ms': 300});

      expect(h.messages.single.text, 'Ação recebida: "$type" {ms: 300}');
      expect(h.navigated, isEmpty);
      expect(h.backCount, 0);
      expect(h.openedUrls, isEmpty);
    });
  }
}
