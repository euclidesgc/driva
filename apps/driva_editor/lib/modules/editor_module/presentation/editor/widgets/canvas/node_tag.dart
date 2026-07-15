import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/theme/device_mock_colors.dart';

class NodeTag extends StatelessWidget {
  const NodeTag({super.key, required this.label, required this.isSelected});

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
