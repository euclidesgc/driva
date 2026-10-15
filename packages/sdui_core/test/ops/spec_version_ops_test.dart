import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

const _bound = {
  r'$bind': {'source': 'pageParam', 'path': 'nomeCliente'},
};

ContentSpec _spec({
  int specVersion = 1,
  SduiNode? root,
  Map<String, dynamic> safeArea = const {},
}) => ContentSpec(
  specVersion: specVersion,
  id: 'ct_1',
  name: 'Início',
  slug: 'inicio',
  root: root,
  safeArea: safeArea,
);

SduiNode _deepTree(Map<String, dynamic> leafProps) => SduiNode(
  id: 'root',
  type: 'column',
  children: [
    SduiNode(
      id: 'box',
      type: 'container',
      child: SduiNode(id: 'leaf', type: 'text', properties: leafProps),
    ),
  ],
);

void main() {
  group('requiredSpecVersion', () {
    test(r'documento sem $bind/$theme dá 1', () {
      expect(requiredSpecVersion(_spec()), 1);
      expect(requiredSpecVersion(_spec(root: _deepTree({'text': 'Olá'}))), 1);
    });

    test(r'$bind num nó profundo dá 2', () {
      expect(requiredSpecVersion(_spec(root: _deepTree({'text': _bound}))), 2);
    });

    test(r'$theme dá 2', () {
      final root = _deepTree({
        'color': {r'$theme': 'primary'},
      });

      expect(requiredSpecVersion(_spec(root: root)), 2);
    });

    test(r'$bind só na safeArea dá 2', () {
      expect(requiredSpecVersion(_spec(safeArea: {'top': _bound})), 2);
    });

    test('{{x}} dá 1', () {
      expect(
        requiredSpecVersion(_spec(root: _deepTree({'text': '{{user.name}}'}))),
        1,
      );
    });
  });

  group('withRequiredSpecVersion', () {
    test('sobe para 2 quando aparece uma forma nova', () {
      final spec = _spec(root: _deepTree({'text': _bound}));

      expect(withRequiredSpecVersion(spec).specVersion, 2);
    });

    test('um documento v2 sem forma nova rebaixa para 1', () {
      final spec = _spec(specVersion: 2, root: _deepTree({'text': 'Olá'}));

      expect(withRequiredSpecVersion(spec).specVersion, 1);
    });

    test('devolve a mesma instância quando a versão já está certa', () {
      final v1 = _spec(root: _deepTree({'text': 'Olá'}));
      final v2 = _spec(specVersion: 2, root: _deepTree({'text': _bound}));

      expect(identical(withRequiredSpecVersion(v1), v1), isTrue);
      expect(identical(withRequiredSpecVersion(v2), v2), isTrue);
    });

    test('o JSON do resultado passa em parseContentSpec', () {
      final root = bindNodeProp(
        _deepTree({'text': 'Olá'}),
        'leaf',
        'text',
        const BoundPropValue(
          source: BindingSourceIds.pageParam,
          path: 'nomeCliente',
          fallback: 'Visitante',
        ),
      );

      final normalized = withRequiredSpecVersion(_spec(root: root));
      final parsed = parseContentSpec(normalized.toJson());

      expect(parsed.isRight(), isTrue, reason: parsed.toString());
      expect(parseContentSpec(_spec(root: root).toJson()).isLeft(), isTrue);
    });
  });
}
