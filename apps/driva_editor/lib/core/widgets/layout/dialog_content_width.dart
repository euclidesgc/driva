import 'package:driva_editor/core/theme/app_sizes.dart';
import 'package:flutter/material.dart';

/// O `AlertDialog` do Material envolve o `content` num `IntrinsicWidth`
/// interno, que ignora o clamp normal de `BoxConstraints` — uma largura fixa
/// aqui dentro vaza para fora da tela em vez de encolher. O teto por isso vem
/// de fora, contra a largura real do viewport (não das constraints locais).
class DialogContentWidth extends StatelessWidget {
  const DialogContentWidth({
    required this.maxWidth,
    required this.child,
    super.key,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final available =
        MediaQuery.sizeOf(context).width - AppSizes.dialogInsetBudget;
    final width = maxWidth < available ? maxWidth : available;
    return SizedBox(width: width, child: child);
  }
}
