import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('diagnoseTree', () {
    test('árvore sem raiz não tem o que diagnosticar', () {
      expect(diagnoseTree(null), isEmpty);
    });

    test('expanded e spacer dentro de column passam limpo', () {
      const tree = SduiNode(
        id: 'col',
        type: 'column',
        children: [
          SduiNode(
            id: 'exp',
            type: 'expanded',
            child: SduiNode(id: 'txt', type: 'text'),
          ),
          SduiNode(id: 'sp', type: 'spacer'),
        ],
      );
      expect(diagnoseTree(tree), isEmpty);
    });

    test('spacer fora de row/column vira erro', () {
      const tree = SduiNode(
        id: 'ct',
        type: 'container',
        child: SduiNode(id: 'sp', type: 'spacer'),
      );
      final found = diagnoseTree(tree);

      expect(found, hasLength(1));
      expect(found.single.nodeId, 'sp');
      expect(found.single.code, DiagnosticCode.flexOnlyOutsideFlex);
      expect(found.single.severity, DiagnosticSeverity.error);
      expect(found.single.message, contains('Row ou Column'));
    });

    test('expanded na raiz também é erro (não tem pai flexível)', () {
      const tree = SduiNode(
        id: 'exp',
        type: 'expanded',
        child: SduiNode(id: 'txt', type: 'text'),
      );
      expect(
        diagnoseTree(tree).map((d) => d.code),
        [DiagnosticCode.flexOnlyOutsideFlex],
      );
    });

    test('embrulho de slot único sem filho vira aviso', () {
      const tree = SduiNode(
        id: 'col',
        type: 'column',
        children: [
          SduiNode(id: 'pad', type: 'padding'),
          SduiNode(id: 'cen', type: 'center'),
        ],
      );
      final found = diagnoseTree(tree);

      expect(found.map((d) => d.nodeId), ['pad', 'cen']);
      expect(
        found.every((d) => d.severity == DiagnosticSeverity.warning),
        isTrue,
      );
      expect(found.first.code, DiagnosticCode.emptySingleSlot);
    });

    test('container vazio não é problema (tem tamanho e cor próprios)', () {
      const tree = SduiNode(
        id: 'col',
        type: 'column',
        children: [SduiNode(id: 'ct', type: 'container')],
      );
      expect(diagnoseTree(tree), isEmpty);
    });

    test('desce por child e por children', () {
      const tree = SduiNode(
        id: 'col',
        type: 'column',
        children: [
          SduiNode(
            id: 'ct',
            type: 'container',
            child: SduiNode(
              id: 'inner',
              type: 'stack',
              children: [SduiNode(id: 'sp', type: 'spacer')],
            ),
          ),
        ],
      );
      expect(diagnoseTree(tree).map((d) => d.nodeId), ['sp']);
    });
  });
}
