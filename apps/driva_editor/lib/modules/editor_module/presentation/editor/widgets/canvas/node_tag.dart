import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_theme.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/device_mock_colors.dart';
import 'package:flutter/material.dart';

class NodeTag extends StatelessWidget {
  const NodeTag({required this.label, required this.isSelected, super.key});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final mock = Theme.of(context).extension<DeviceMockColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s2,
      ),
      color: isSelected ? AppTheme.primary : mock.nodeTag,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: AppTypography.xs,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
