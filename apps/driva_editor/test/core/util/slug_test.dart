import 'package:driva_editor/core/util/slug.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlugUtil.isValid', () {
    test('aceita o formato canônico ^[a-z][a-z0-9-]*\$', () {
      expect(SlugUtil.isValid('home'), isTrue);
      expect(SlugUtil.isValid('home-2'), isTrue);
      expect(SlugUtil.isValid('a'), isTrue);
      expect(SlugUtil.isValid('landing-page-2026'), isTrue);
    });

    test('rejeita maiúsculas, início por não-letra e caracteres inválidos', () {
      expect(SlugUtil.isValid('Home'), isFalse);
      expect(SlugUtil.isValid('2home'), isFalse);
      expect(SlugUtil.isValid('-home'), isFalse);
      expect(SlugUtil.isValid('home_page'), isFalse);
      expect(SlugUtil.isValid('home page'), isFalse);
      expect(SlugUtil.isValid(''), isFalse);
    });

    test('o hífen à direita passa no regex (não é sanitizado por isValid)', () {
      // Comportamento real: a validação é só do padrão; a limpeza de bordas
      // é responsabilidade do slugify, não do isValid.
      expect(SlugUtil.isValid('home-'), isTrue);
    });
  });

  group('SlugUtil.slugify', () {
    test('minúsculas e caso feliz', () {
      expect(SlugUtil.slugify('Home'), 'home');
      expect(SlugUtil.slugify('HELLO'), 'hello');
    });

    test('espaços viram hífen único', () {
      expect(SlugUtil.slugify('Home Page'), 'home-page');
      expect(SlugUtil.slugify('Ola   Mundo'), 'ola-mundo');
    });

    test('remove acentos/diacríticos', () {
      expect(SlugUtil.slugify('Página Início'), 'pagina-inicio');
      expect(SlugUtil.slugify('Ação'), 'acao');
      expect(SlugUtil.slugify('Café com Leite'), 'cafe-com-leite');
      expect(SlugUtil.slugify('Português Ñandu'), 'portugues-nandu');
    });

    test('remove caracteres inválidos (pontuação/símbolos)', () {
      expect(SlugUtil.slugify('Olá, Mundo!'), 'ola-mundo');
      expect(SlugUtil.slugify('preço: R\$ 9,90'), 'preco-r-9-90');
    });

    test('colapsa hífens repetidos e apara as pontas', () {
      expect(SlugUtil.slugify('a--b'), 'a-b');
      expect(SlugUtil.slugify('-home-'), 'home');
      expect(SlugUtil.slugify('  espaços nas bordas  '), 'espacos-nas-bordas');
    });

    test('remove prefixo que não começa por letra (dígitos/símbolos)', () {
      expect(SlugUtil.slugify('123abc'), 'abc');
      expect(SlugUtil.slugify('2026-home'), 'home');
    });

    test('devolve string vazia quando não sobra nada canônico', () {
      expect(SlugUtil.slugify(''), '');
      expect(SlugUtil.slugify('   '), '');
      expect(SlugUtil.slugify('---'), '');
      expect(SlugUtil.slugify(r'@#$%'), '');
      expect(SlugUtil.slugify('123'), '');
    });
  });

  group('SlugUtil.suggestFree', () {
    test('base canônica e livre é devolvida como está', () {
      expect(SlugUtil.suggestFree('home', <String>{}), 'home');
    });

    test('normaliza a base quando não é canônica', () {
      expect(SlugUtil.suggestFree('Home Page', <String>{}), 'home-page');
    });

    test('sufixa incremental a partir de 2 em colisão', () {
      expect(SlugUtil.suggestFree('home', {'home'}), 'home-2');
      expect(SlugUtil.suggestFree('home', {'home', 'home-2'}), 'home-3');
      expect(
        SlugUtil.suggestFree('home', {'home', 'home-2', 'home-3'}),
        'home-4',
      );
    });

    test('normaliza e depois resolve a colisão', () {
      expect(SlugUtil.suggestFree('Home', {'home'}), 'home-2');
    });

    test('base vazia após normalizar volta vazia (chamador trata)', () {
      expect(SlugUtil.suggestFree(r'@#$', <String>{}), '');
      expect(SlugUtil.suggestFree('', <String>{}), '');
    });
  });
}
