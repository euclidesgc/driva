import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('isBinding', () {
    test('reconhece a expressão entre chaves duplas', () {
      expect(SduiBinding.isBinding('{{usuario.nome}}'), isTrue);
      expect(SduiBinding.isBinding('{{ usuario.nome }}'), isTrue);
    });

    test('recusa o que não é binding', () {
      expect(SduiBinding.isBinding('usuario.nome'), isFalse);
      expect(SduiBinding.isBinding('{{}}'), isFalse);
      expect(SduiBinding.isBinding('{{   }}'), isFalse);
      expect(SduiBinding.isBinding('{usuario}'), isFalse);
      expect(SduiBinding.isBinding(42), isFalse);
      expect(SduiBinding.isBinding(null), isFalse);
    });

    test('texto com binding no meio não conta: liga o valor inteiro', () {
      expect(SduiBinding.isBinding('Olá, {{nome}}!'), isFalse);
    });
  });

  group('expressionOf', () {
    test('devolve a expressão sem as chaves nem espaços', () {
      expect(SduiBinding.expressionOf('{{ usuario.nome }}'), 'usuario.nome');
    });

    test('devolve null fora de um binding', () {
      expect(SduiBinding.expressionOf('texto'), isNull);
      expect(SduiBinding.expressionOf(7), isNull);
      expect(SduiBinding.expressionOf(null), isNull);
    });
  });

  group('wrap', () {
    test('embrulha a expressão', () {
      expect(SduiBinding.wrap('usuario.nome'), '{{usuario.nome}}');
      expect(SduiBinding.wrap('  usuario.nome  '), '{{usuario.nome}}');
    });

    test('expressão vazia vira null, para o chamador remover a chave', () {
      expect(SduiBinding.wrap(''), isNull);
      expect(SduiBinding.wrap('   '), isNull);
    });

    test('roundtrip: wrap e expressionOf se cancelam', () {
      final wrapped = SduiBinding.wrap('produto.preco')!;
      expect(SduiBinding.isBinding(wrapped), isTrue);
      expect(SduiBinding.expressionOf(wrapped), 'produto.preco');
    });
  });
}
