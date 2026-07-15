import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';

/// Tag pequena com o nome do componente. Destacada quando selecionado; discreta
/// (só um sinal a mais de "há algo aqui") caso contrário.
class NodeTag extends StatelessWidget {
  const NodeTag({super.key, required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: isSelected ? AppTheme.primary : const Color(0xCC3A3D44),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
