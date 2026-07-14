import 'package:flutter/material.dart';

/// Paleta fixa de gradientes das capas de projeto (o protótipo alterna
/// laranja/violeta/teal/rosa). A capa escolhe um par por hash do id do projeto,
/// mantendo a mesma cor entre reloads.
///
/// Decoração de marca, invariante ao tema (uma capa é igual em claro/escuro),
/// por isso `static const` — centraliza os pares antes soltos no
/// `project_cover.dart`.
abstract final class AppCoverGradients {
  static const List<List<Color>> palettes = [
    [Color(0xFFE07B39), Color(0xFFD96E2B)],
    [Color(0xFF7A5CF0), Color(0xFF5B3FD1)],
    [Color(0xFF2FA88E), Color(0xFF1F8A73)],
    [Color(0xFFD1476B), Color(0xFFB13457)],
  ];

  /// Par de gradiente estável para um [seed] (id do projeto).
  static List<Color> forSeed(String seed) {
    final index =
        seed.codeUnits.fold<int>(0, (sum, c) => sum + c) % palettes.length;
    return palettes[index];
  }
}
