import 'package:driva_editor/core/theme/app_radii.dart';
import 'package:driva_editor/core/theme/app_spacing.dart';
import 'package:driva_editor/core/theme/editor_colors.dart';
import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/widgets/project_form/cover_placeholder.dart';
import 'package:driva_editor/modules/projects_module/presentation/project_list/widgets/project_form/cover_preview.dart';
import 'package:flutter/material.dart';

class CoverPicker extends StatelessWidget {
  const CoverPicker({
    required this.image,
    required this.currentImageUrl,
    required this.hovering,
    required this.onPick,
    required this.onClear,
    super.key,
  });

  final ProjectImageInput? image;
  final String? currentImageUrl;
  final bool hovering;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<EditorColors>()!;
    final hasPreview = image != null || currentImageUrl != null;

    return Semantics(
      button: true,
      label: hasPreview
          ? 'Trocar imagem de capa do projeto'
          : 'Arraste uma imagem de capa ou clique para escolher um arquivo',
      child: Tooltip(
        message: 'Formatos aceitos: PNG, JPG, WEBP',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.r14),
          onTap: onPick,
          child: Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.r14),
                  border: Border.all(
                    color: hovering ? theme.colorScheme.primary : colors.border,
                    width: hovering ? 2 : 1,
                  ),
                  color: colors.panelAlt,
                ),
                child: hasPreview
                    ? CoverPreview(
                        image: image,
                        currentImageUrl: currentImageUrl,
                      )
                    : CoverPlaceholder(hovering: hovering),
              ),
              if (onClear != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: 'Remover imagem',
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onClear,
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.s6),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
