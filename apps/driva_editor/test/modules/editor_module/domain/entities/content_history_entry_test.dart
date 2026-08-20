import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

ContentVersion _version(int number, DateTime at) =>
    ContentVersion(version: number, createdAt: at);

ContentCheckpoint _checkpoint(String id, DateTime at) =>
    ContentCheckpoint(id: id, createdAt: at);

void main() {
  test('mescla as duas espécies em ordem cronológica decrescente', () {
    final entries = mergeHistoryEntries(
      versions: [
        _version(2, DateTime.utc(2026, 8, 20, 15)),
        _version(1, DateTime.utc(2026, 8, 18, 10)),
      ],
      checkpoints: [
        _checkpoint('ckpt_b', DateTime.utc(2026, 8, 19, 9)),
        _checkpoint('ckpt_a', DateTime.utc(2026, 8, 17, 8)),
      ],
    );

    expect(entries.map((each) => each.createdAt), [
      DateTime.utc(2026, 8, 20, 15),
      DateTime.utc(2026, 8, 19, 9),
      DateTime.utc(2026, 8, 18, 10),
      DateTime.utc(2026, 8, 17, 8),
    ]);
    expect(entries[0], isA<PublishedVersionEntry>());
    expect(entries[1], isA<CheckpointEntry>());
  });

  test('no mesmo instante, a publicação vem primeiro', () {
    final momento = DateTime.utc(2026, 8, 20, 12);
    final entries = mergeHistoryEntries(
      versions: [_version(3, momento)],
      checkpoints: [_checkpoint('ckpt_1', momento)],
    );

    expect(
      entries.first,
      isA<PublishedVersionEntry>(),
      reason:
          'o publish salva antes de publicar, então os dois podem cair no '
          'mesmo instante — e quem mudou o que o usuário final vê é a '
          'publicação',
    );
  });

  test('sem checkpoints, a lista é só de publicações', () {
    final entries = mergeHistoryEntries(
      versions: [_version(1, DateTime.utc(2026, 8, 18))],
      checkpoints: const [],
    );

    expect(entries, hasLength(1));
    expect(entries.single, isA<PublishedVersionEntry>());
  });

  test('sem publicações, a lista é só de pontos marcados', () {
    final entries = mergeHistoryEntries(
      versions: const [],
      checkpoints: [_checkpoint('ckpt_1', DateTime.utc(2026, 8, 18))],
    );

    expect(entries.single, isA<CheckpointEntry>());
  });

  test('a nota e a data são legíveis pela espécie, sem desembrulhar', () {
    final entries = mergeHistoryEntries(
      versions: [
        ContentVersion(
          version: 1,
          createdAt: DateTime.utc(2026, 8, 18),
          note: 'da publicação',
        ),
      ],
      checkpoints: [
        ContentCheckpoint(
          id: 'ckpt_1',
          createdAt: DateTime.utc(2026, 8, 19),
          note: 'do ponto',
        ),
      ],
    );

    expect(entries.map((each) => each.note), ['do ponto', 'da publicação']);
  });
}
