import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart';

part 'loaded_content_version.dart';
part 'loaded_content_checkpoint.dart';

/// Raiz comum de tudo que já chegou do servidor **com o spec dentro** — o
/// que permite ver e comparar uma entrada do histórico, publicada ou não.
///
/// `sealed` força todo `switch` sobre a família a tratar as duas espécies:
/// nenhum consumidor de "candidata de comparação" ou "alvo de revisão" pode
/// esquecer o checkpoint só porque só a versão existia antes.
sealed class LoadedHistoryEntry extends Equatable {
  const LoadedHistoryEntry();

  ContentSpec get spec;
  DateTime get createdAt;
  String? get note;
}
