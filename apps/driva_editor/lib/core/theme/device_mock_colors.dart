import 'package:flutter/material.dart';

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
    required this.statusBarIcon,
    required this.homeIndicator,
    required this.statusBarClockLabel,
    required this.statusBarClockWeight,
  });

  final Color body;

  /// Topo do gradiente do corpo (o corpo vai de [bodyGradientTop] a [body]).
  final Color bodyGradientTop;

  final Color rim;

  final Color button;

  final Color screen;

  final Color notch;

  final Color shadow;

  final Color glow;

  final Color nodeTag;

  final Color dropHint;

  /// Cor do relógio e dos ícones (sinal, wifi, bateria) da status bar do mock
  /// (D29). Chrome desenhado, não derivado do conteúdo — a cor de verdade,
  /// condicionada ao fundo da página, é o item 43.
  final Color statusBarIcon;

  /// Cor da cápsula do indicador de home do mock (D29).
  final Color homeIndicator;

  /// Rótulo fixo do relógio da status bar do mock (D29) — não
  /// `DateTime.now()`, para o golden do `canvas_panel` não ficar
  /// não-determinístico.
  final String statusBarClockLabel;

  /// Peso do rótulo do relógio da status bar do mock (D29).
  final FontWeight statusBarClockWeight;

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
    statusBarIcon: Color(0xFF1B1D21),
    homeIndicator: Color(0x991B1D21),
    statusBarClockLabel: '9:41',
    statusBarClockWeight: FontWeight.w600,
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
    Color? statusBarIcon,
    Color? homeIndicator,
    String? statusBarClockLabel,
    FontWeight? statusBarClockWeight,
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
      statusBarIcon: statusBarIcon ?? this.statusBarIcon,
      homeIndicator: homeIndicator ?? this.homeIndicator,
      statusBarClockLabel: statusBarClockLabel ?? this.statusBarClockLabel,
      statusBarClockWeight: statusBarClockWeight ?? this.statusBarClockWeight,
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
      statusBarIcon: Color.lerp(statusBarIcon, other.statusBarIcon, t)!,
      homeIndicator: Color.lerp(homeIndicator, other.homeIndicator, t)!,
      statusBarClockLabel: t < 0.5
          ? statusBarClockLabel
          : other.statusBarClockLabel,
      statusBarClockWeight: t < 0.5
          ? statusBarClockWeight
          : other.statusBarClockWeight,
    );
  }
}
