import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/core/theme/app_icon_sizes.dart';
import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/app_typography.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:flutter/material.dart';

/// O terceiro estado da tabela da D30: puxar e falhar. O conteúdo em tela
/// (`PreviewReady` reemitido) não muda — só este banner aparece, cor não é o
/// único sinal (ícone + texto), e some sozinho quando o próximo `refresh()`
/// tiver sucesso.
class PreviewRefreshFailureBanner extends StatelessWidget {
  const PreviewRefreshFailureBanner({required this.failure, super.key});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<EditorColors>()!;
    final message = _messageFor(failure);
    return Semantics(
      liveRegion: true,
      label: message,
      child: Material(
        color: colors.danger,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off,
                size: AppIconSizes.s18,
                color: colors.onDanger,
              ),
              const SizedBox(width: AppSpacing.s8),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTypography.base,
                    color: colors.onDanger,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _messageFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'Sem conexão. Mostrando o último salvo.',
    NotFoundFailure() => 'Conteúdo não encontrado ao atualizar.',
    ConflictFailure() => 'Não foi possível atualizar agora.',
    ValidationFailure() => 'Spec inválido ao atualizar.',
    UnexpectedFailure() => 'Algo deu errado ao atualizar.',
  };
}
