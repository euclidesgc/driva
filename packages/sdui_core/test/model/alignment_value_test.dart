import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('parse', () {
    test('nome do preset vira o par canônico', () {
      expect(AlignmentValue.parse('topLeft'), (x: -1.0, y: -1.0));
      expect(AlignmentValue.parse('center'), (x: 0.0, y: 0.0));
      expect(AlignmentValue.parse('bottomRight'), (x: 1.0, y: 1.0));
    });

    test('par livre é lido como está', () {
      expect(AlignmentValue.parse({'x': 0.3, 'y': -1}), (x: 0.3, y: -1.0));
      expect(AlignmentValue.parse({'x': 10, 'y': 0}), (x: 10.0, y: 0.0));
    });

    test('eixo ausente conta como zero', () {
      expect(AlignmentValue.parse({'x': 0.5}), (x: 0.5, y: 0.0));
      expect(AlignmentValue.parse({'y': 0.5}), (x: 0.0, y: 0.5));
    });

    test('devolve null para o que não é alinhamento', () {
      expect(AlignmentValue.parse(null), isNull);
      expect(AlignmentValue.parse('meio'), isNull);
      expect(AlignmentValue.parse(<String, dynamic>{}), isNull);
      expect(AlignmentValue.parse({'x': 'a'}), isNull);
      expect(AlignmentValue.parse('{{layout.alinhamento}}'), isNull);
    });
  });

  group('encode', () {
    test('par canônico vira o nome, mantendo o JSON legível', () {
      expect(AlignmentValue.encode(x: -1, y: -1), 'topLeft');
      expect(AlignmentValue.encode(x: 0, y: 0), 'center');
      expect(AlignmentValue.encode(x: 1, y: 0), 'centerRight');
    });

    test('par livre vira mapa', () {
      expect(AlignmentValue.encode(x: 0.3, y: -1), {'x': 0.3, 'y': -1.0});
    });

    test('ler e escrever não altera um spec existente', () {
      for (final name in AlignmentValue.presets.keys) {
        final pair = AlignmentValue.parse(name)!;
        expect(
          AlignmentValue.encode(x: pair.x, y: pair.y),
          name,
          reason: 'roundtrip de $name',
        );
      }
    });

    test('roundtrip do par livre também se fecha', () {
      const raw = {'x': 0.3, 'y': -0.75};
      final pair = AlignmentValue.parse(raw)!;

      expect(AlignmentValue.encode(x: pair.x, y: pair.y), raw);
    });
  });

  group('presetNameOf', () {
    test('devolve o nome quando o valor cai num preset', () {
      expect(AlignmentValue.presetNameOf({'x': 0, 'y': -1}), 'topCenter');
      expect(AlignmentValue.presetNameOf('topCenter'), 'topCenter');
    });

    test('devolve null para posição livre', () {
      expect(AlignmentValue.presetNameOf({'x': 0.3, 'y': 0}), isNull);
      expect(AlignmentValue.presetNameOf(null), isNull);
    });
  });
}
