import 'package:driva_editor/core/util/date_format.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';

/// Título de uma entrada carregada do histórico — nunca "Versão" para quem
/// nunca foi ao ar (vocabulário do produto: publicação × ponto salvo).
String historyEntryTitle(LoadedHistoryEntry entry) => switch (entry) {
  LoadedContentVersion(:final version) => 'Versão $version',
  LoadedContentCheckpoint(:final note) =>
    note == null || note.isEmpty ? 'Ponto salvo' : note,
};

/// Rótulo de uma linha só (barra da candidata, item 53): o número já
/// identifica uma publicação sozinho, mas notas de ponto salvo podem se
/// repetir — a data junto garante que a barra aponta para um registro só.
String historyEntryCandidateLabel(LoadedHistoryEntry entry) => switch (entry) {
  LoadedContentVersion() => historyEntryTitle(entry),
  LoadedContentCheckpoint(:final createdAt) =>
    '${historyEntryTitle(entry)} — '
        '${DateFormatUtil.dayMonthYearHourMinute(createdAt)}',
};

/// A referência embutida numa frase ("Carregar ___ no rascunho?"): o artigo
/// concorda em gênero com a espécie — "a versão N" vs. "o ponto salvo […]".
String historyEntryPhraseReference(LoadedHistoryEntry entry) => switch (entry) {
  LoadedContentVersion(:final version) => 'a versão $version',
  LoadedContentCheckpoint() =>
    'o ponto salvo "${historyEntryCandidateLabel(entry)}"',
};
