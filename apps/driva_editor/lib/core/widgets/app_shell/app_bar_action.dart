import 'package:flutter/material.dart';

enum AppBarActionKind { filled, outlined, text, icon }

/// É dado, não widget: o shell (acima dos `BlocProvider` das páginas) constrói
/// o botão. [onPressed] é um closure que já capturou o context da página, então
/// o clique fala com o cubit certo; `null` desabilita.
@immutable
class AppBarAction {
  const AppBarAction({
    required this.kind,
    this.label,
    this.icon,
    this.onPressed,
    this.tooltip,
  });

  const AppBarAction.filled({
    required String this.label,
    this.icon,
    required this.onPressed,
    this.tooltip,
  }) : kind = AppBarActionKind.filled;

  const AppBarAction.outlined({
    required String this.label,
    this.icon,
    this.onPressed,
    this.tooltip,
  }) : kind = AppBarActionKind.outlined;

  const AppBarAction.text({
    required String this.label,
    this.icon,
    required this.onPressed,
    this.tooltip,
  }) : kind = AppBarActionKind.text;

  const AppBarAction.icon({
    required IconData this.icon,
    required this.onPressed,
    this.tooltip,
  }) : kind = AppBarActionKind.icon,
       label = null;

  final AppBarActionKind kind;
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Igualdade estrutural que ignora a identidade do closure — só muda quando
  /// o visual muda (label/icon/tooltip/enabled). Alimenta o dedupe do slot.
  @override
  bool operator ==(Object other) =>
      other is AppBarAction &&
      other.kind == kind &&
      other.label == label &&
      other.icon == icon &&
      other.tooltip == tooltip &&
      (other.onPressed == null) == (onPressed == null);

  @override
  int get hashCode =>
      Object.hash(kind, label, icon, tooltip, onPressed == null);
}

enum AppBarStatusTone { success, neutral, danger }

/// Indicador de estado (ex.: status de salvamento do editor) como dado.
@immutable
class AppBarStatus {
  const AppBarStatus({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final AppBarStatusTone tone;

  @override
  bool operator ==(Object other) =>
      other is AppBarStatus &&
      other.icon == icon &&
      other.label == label &&
      other.tone == tone;

  @override
  int get hashCode => Object.hash(icon, label, tone);
}
