import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/data/models/publication_state_model.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryParse', () {
    test('publishedVersion presente devolve o estado publicado', () {
      final map = {
        'publishedVersion': {
          'version': 3,
          'publishedAt': DateTime(2026, 8, 16, 9),
        },
        'hasUnpublishedChanges': false,
      };

      final result = PublicationStateModel.tryParse(map);

      final state = result.getRight().toNullable();
      expect(state, isNotNull);
      expect(
        state!.props,
        PublicationState(
          publishedVersion: 3,
          publishedAt: DateTime(2026, 8, 16, 9),
          hasUnpublishedChanges: false,
        ).props,
      );
    });

    test('publishedVersion nulo devolve "nunca publicado"', () {
      final map = {
        'publishedVersion': null,
        'hasUnpublishedChanges': true,
      };

      final result = PublicationStateModel.tryParse(map);

      final state = result.getRight().toNullable();
      expect(state, isNotNull);
      expect(state!.isPublished, isFalse);
      expect(state.hasUnpublishedChanges, isTrue);
    });

    test(
      'publishedVersion ausente do mapa (mesma coisa que nulo) também parseia',
      () {
        final map = {'hasUnpublishedChanges': true};

        final result = PublicationStateModel.tryParse(map);

        final state = result.getRight().toNullable();
        expect(state, isNotNull);
        expect(state!.isPublished, isFalse);
      },
    );

    test('hasUnpublishedChanges ausente vira ValidationFailure', () {
      final map = {
        'publishedVersion': {
          'version': 1,
          'publishedAt': DateTime(2026, 8, 16, 9),
        },
      };

      final result = PublicationStateModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('publishedVersion com campo corrompido vira ValidationFailure', () {
      final map = {
        'publishedVersion': {'version': 'um', 'publishedAt': DateTime.now()},
        'hasUnpublishedChanges': false,
      };

      final result = PublicationStateModel.tryParse(map);

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });
}
