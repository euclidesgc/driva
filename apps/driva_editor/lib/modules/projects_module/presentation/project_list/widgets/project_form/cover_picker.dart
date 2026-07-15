import 'package:flutter/material.dart';

import '../../../../../../core/theme/editor_colors.dart';
import '../../../../domain/entities/entities.dart';
import 'cover_placeholder.dart';
import 'cover_preview.dart';

class CoverPicker extends StatelessWidget {
  const CoverPicker({
    super.key,
    required this.image,
    required this.currentImageUrl,
    required this.hovering,
    required this.onPick,
    required this.onClear,
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
          borderRadius: BorderRadius.circular(14),
          onTap: onPick,
          child: Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
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
                          padding: EdgeInsets.all(6),
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
