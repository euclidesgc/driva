import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> textNode(Object? data) => {
    'id': 'n1',
    'type': 'text',
    'props': {'data': data},
  };

  const themed = {r'$theme': 'primary'};

  group('parseNode e specVersion', () {
    test(r'sem specVersion, recusa $theme como a versão mais antiga', () {
      final result = parseNode(textNode(themed));

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable()!.message,
        startsWith('root.props.data: '),
      );
      expect(
        result.getLeft().toNullable()!.message,
        contains('specVersion $kTypedPropValuesSpecVersion'),
      );
    });

    test(r'com specVersion 2, aceita $theme e guarda o mapa cru', () {
      final result = parseNode(
        textNode(themed),
        specVersion: kTypedPropValuesSpecVersion,
      );

      final node = result.getRight().toNullable();
      expect(node, isNotNull, reason: result.toString());
      expect(node!.properties['data'], themed);
    });

    test('repassa specVersion aos filhos', () {
      final json = <String, dynamic>{
        'id': 'c1',
        'type': 'column',
        'children': [textNode(themed)],
      };

      expect(parseNode(json).isLeft(), isTrue);
      expect(
        parseNode(json, specVersion: kTypedPropValuesSpecVersion).isRight(),
        isTrue,
      );
    });
  });
}
