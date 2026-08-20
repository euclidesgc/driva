import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_comparison_base.dart';

/// Como a base é nomeada nas telas de comparação (T5, item 50 — decisão do
/// dono do produto, 2026-08-20): com o rascunho como base, ela é "o
/// rascunho"; trocada para "no ar", a base vira a versão publicada de
/// verdade (`vN`), nunca "rascunho" — inclusive nos marcadores ("Somente no
/// rascunho" → "Somente em vN (no ar)"), na mensagem de "nada difere" e no
/// rótulo do preview à esquerda. `publishedVersion` só é lido quando [base]
/// é [VersionComparisonBase.published] — sempre não nulo nesse caso, porque
/// é o mesmo número que abriu o toggle "No ar".
String baseLocationPhrase(VersionComparisonBase base, int? publishedVersion) =>
    switch (base) {
      VersionComparisonBase.draft => 'no rascunho',
      VersionComparisonBase.published => 'em v$publishedVersion (no ar)',
    };

/// Mesma base de [baseLocationPhrase], como sujeito de frase ("entre ___ e
/// esta versão"), não como complemento de preposição.
String baseNounPhrase(VersionComparisonBase base, int? publishedVersion) =>
    switch (base) {
      VersionComparisonBase.draft => 'o rascunho',
      VersionComparisonBase.published => 'v$publishedVersion (no ar)',
    };

/// Mesma base, como título curto (rótulo do preview à esquerda).
String baseHeadingLabel(VersionComparisonBase base, int? publishedVersion) =>
    switch (base) {
      VersionComparisonBase.draft => 'Rascunho',
      VersionComparisonBase.published => 'v$publishedVersion (no ar)',
    };
