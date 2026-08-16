import 'dart:async';

import 'package:driva_editor/core/theme/app_durations.dart';
import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/core/util/date_format.dart';
import 'package:flutter/material.dart';

/// A pílula da D4: o conteúdo mostrado é sempre o último salvo (não há
/// autosave), mas o `HH:MM` que ela exibe é o instante da **busca**, não do
/// save — o `ContentSpec` não carrega `updatedAt`. Salvar de novo no desktop
/// sem puxar aqui não muda nada, e puxar aqui sem ter salvo de novo também
/// não muda nada — só o relógio andaria se o texto prometesse "salvo".
///
/// Desde a D30, o gesto de atualizar é o `RefreshIndicator` da tela — esta
/// pílula é só rótulo, sem `InkWell` nem afordância de toque.
///
/// Desde a D34, ela se apaga sozinha e volta a cada busca bem-sucedida. Quem
/// puxa está olhando para a tela, e é aí que o carimbo precisa ser lido; o
/// resto do tempo ele só ocupa o preview. A falha **não** a traz de volta —
/// `fetchedAt` não muda quando o refresh falha, então o timer não reinicia e
/// o único sinal que aparece é o banner de erro. É isso que mantém "puxei e
/// nada mudou" e "puxei e falhou" com prints diferentes.
class LastSavedPill extends StatefulWidget {
  const LastSavedPill({required this.fetchedAt, super.key});

  final DateTime fetchedAt;

  @override
  State<LastSavedPill> createState() => _LastSavedPillState();
}

class _LastSavedPillState extends State<LastSavedPill> {
  Timer? _hideTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _restartHideTimer();
  }

  @override
  void didUpdateWidget(LastSavedPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fetchedAt != oldWidget.fetchedAt) _restartHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    setState(() => _visible = true);
    _hideTimer = Timer(AppDurations.transientNotice, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final label =
        'Último salvo às ${DateFormatUtil.hourMinute(widget.fetchedAt)}';
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppDurations.normal,
      child: Material(
        color: colors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          side: BorderSide(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: AppIconSizes.s18,
                color: colors.inkSecondary,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.base,
                  color: colors.inkPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
