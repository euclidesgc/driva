import 'package:flutter/material.dart';

/// Cores do chrome do mock de dispositivo no canvas (corpo, aro, botões, notch,
/// sombras, glow de seleção). É a "cara de telefone" desenhada em volta do
/// preview.
///
/// Registrada como [ThemeExtension] com slots claro/escuro para deixar o
/// caminho aberto a um mock com aparência distinta no tema escuro. Hoje os dois
/// slots são **idênticos** — um telefone parece um telefone em claro ou escuro
/// —, então tokenizar aqui não muda nada visualmente; só centraliza os valores
/// em `core/theme/` (antes eram constantes soltas no `canvas_panel.dart`).
class DeviceMockColors extends ThemeExtension<DeviceMockColors> {
  const DeviceMockColors({
    required this.body,
    required this.bodyGradientTop,
    required this.rim,
    required this.button,
    required this.screen,
    required this.notch,
    required this.shadow,
    required this.glow,
    required this.nodeTag,
    required this.dropHint,
  });

  /// Corpo (carcaça) do dispositivo.
  final Color body;

  /// Topo do gradiente do corpo (o corpo vai de [bodyGradientTop] a [body]).
  final Color bodyGradientTop;

  /// Aro/rim ao redor da tela.
  final Color rim;

  /// Botões laterais (volume/power).
  final Color button;

  /// Fundo da tela (onde o preview é desenhado).
  final Color screen;

  /// Recorte da câmera / notch.
  final Color notch;

  /// Sombra projetada sob o dispositivo.
  final Color shadow;

  /// Glow (halo) laranja quando um nó está selecionado.
  final Color glow;

  /// Fundo da tag com o nome do nó (não selecionado).
  final Color nodeTag;

  /// Cor do hint tracejado de "solte aqui" sobre o canvas.
  final Color dropHint;

  static const DeviceMockColors light = DeviceMockColors(
    body: Color(0xFF1B1D21),
    bodyGradientTop: Color(0xFF25282E),
    rim: Color(0xFF3A3D44),
    button: Color(0xFF2A2D33),
    screen: Color(0xFFFFFFFF),
    notch: Color(0xFF0B0C0E),
    shadow: Color(0x40000000),
    glow: Color(0x66E8602C),
    nodeTag: Color(0xCC3A3D44),
    dropHint: Color(0x66A0A4AD),
  );

  /// Idêntico ao claro por ora (o mock não varia entre temas hoje).
  static const DeviceMockColors dark = light;

  @override
  DeviceMockColors copyWith({
    Color? body,
    Color? bodyGradientTop,
    Color? rim,
    Color? button,
    Color? screen,
    Color? notch,
    Color? shadow,
    Color? glow,
    Color? nodeTag,
    Color? dropHint,
  }) {
    return DeviceMockColors(
      body: body ?? this.body,
      bodyGradientTop: bodyGradientTop ?? this.bodyGradientTop,
      rim: rim ?? this.rim,
      button: button ?? this.button,
      screen: screen ?? this.screen,
      notch: notch ?? this.notch,
      shadow: shadow ?? this.shadow,
      glow: glow ?? this.glow,
      nodeTag: nodeTag ?? this.nodeTag,
      dropHint: dropHint ?? this.dropHint,
    );
  }

  @override
  DeviceMockColors lerp(covariant DeviceMockColors? other, double t) {
    if (other == null) return this;
    return DeviceMockColors(
      body: Color.lerp(body, other.body, t)!,
      bodyGradientTop: Color.lerp(bodyGradientTop, other.bodyGradientTop, t)!,
      rim: Color.lerp(rim, other.rim, t)!,
      button: Color.lerp(button, other.button, t)!,
      screen: Color.lerp(screen, other.screen, t)!,
      notch: Color.lerp(notch, other.notch, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      nodeTag: Color.lerp(nodeTag, other.nodeTag, t)!,
      dropHint: Color.lerp(dropHint, other.dropHint, t)!,
    );
  }
}
