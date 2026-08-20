import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/content_checkpoint_model.dart';
import 'package:driva_editor/modules/editor_module/data/models/content_checkpoints_page_model.dart';
import 'package:driva_editor/modules/editor_module/data/models/loaded_content_checkpoint_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentCheckpointModel', () {
    test('lê id, data e nota', () {
      final parsed = ContentCheckpointModel.tryParse({
        'id': 'ckpt_1',
        'createdAt': '2026-08-20T12:00:00.000Z',
        'note': 'antes do banner',
      });

      final model = parsed.getOrElse((_) => throw StateError('esperava Right'));
      expect(model.id, 'ckpt_1');
      expect(model.note, 'antes do banner');
      expect(model.createdAt, DateTime.parse('2026-08-20T12:00:00.000Z'));
    });

    test('nota ausente é válida — o servidor a trata como opcional', () {
      final parsed = ContentCheckpointModel.tryParse({
        'id': 'ckpt_1',
        'createdAt': '2026-08-20T12:00:00.000Z',
      });

      expect(parsed.isRight(), isTrue);
    });

    test('sem id, recusa: um ponto sem id não pode ser aberto depois', () {
      final parsed = ContentCheckpointModel.tryParse({
        'createdAt': '2026-08-20T12:00:00.000Z',
      });

      expect(parsed.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });

  group('ContentCheckpointsPageModel', () {
    test('lê a lista e o cursor', () {
      final parsed = ContentCheckpointsPageModel.tryParse({
        'data': [
          {'id': 'ckpt_2', 'createdAt': '2026-08-20T12:00:00.000Z'},
          {'id': 'ckpt_1', 'createdAt': '2026-08-19T12:00:00.000Z'},
        ],
        'nextCursor': 'abc',
      });

      final page = parsed.getOrElse((_) => throw StateError('esperava Right'));
      expect(page.items.map((each) => each.id), ['ckpt_2', 'ckpt_1']);
      expect(page.nextCursor, 'abc');
    });

    test('um item inválido reprova a página inteira', () {
      final parsed = ContentCheckpointsPageModel.tryParse({
        'data': [
          {'id': 'ckpt_2', 'createdAt': '2026-08-20T12:00:00.000Z'},
          {'createdAt': '2026-08-19T12:00:00.000Z'},
        ],
      });

      expect(parsed.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });

  group('LoadedContentCheckpointModel', () {
    test('valida o spec pelo kernel, não só a forma do envelope', () {
      final parsed = LoadedContentCheckpointModel.tryParse({
        'id': 'ckpt_1',
        'createdAt': '2026-08-20T12:00:00.000Z',
        'spec': {'specVersion': 1, 'kind': 'content', 'id': 'ct_1'},
      });

      expect(
        parsed.getLeft().toNullable(),
        isA<ValidationFailure>(),
        reason:
            'spec sem name/slug não passa no parse do kernel — envelope '
            'válido não basta',
      );
    });

    test('spec bom vira ContentSpec', () {
      final parsed = LoadedContentCheckpointModel.tryParse({
        'id': 'ckpt_1',
        'createdAt': '2026-08-20T12:00:00.000Z',
        'note': 'ponto',
        'spec': {
          'specVersion': 1,
          'kind': 'content',
          'id': 'ct_1',
          'name': 'Home',
          'slug': 'home',
        },
      });

      final model = parsed.getOrElse((_) => throw StateError('esperava Right'));
      expect(model.spec.slug, 'home');
      expect(model.note, 'ponto');
    });
  });
}
