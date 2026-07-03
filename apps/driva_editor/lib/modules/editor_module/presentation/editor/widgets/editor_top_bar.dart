import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../cubit/editor_cubit.dart';

/// Top bar do editor: voltar, identificação do conteúdo, status de salvamento
/// e a ação de salvar. Preview/Publish reais chegam nos próximos incrementos.
class EditorTopBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorTopBar({super.key, required this.state, required this.onSave});

  final EditorReady state;
  final VoidCallback onSave;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      leadingWidth: 48,
      leading: IconButton(
        tooltip: 'Voltar para os conteúdos',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.goNamed('contents'),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Text(state.document.name, style: theme.textTheme.titleMedium),
          const SizedBox(width: 12),
          Chip(
            avatar: const Icon(Icons.tag, size: 16),
            label: Text('Slug: ${state.document.slug}'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      actions: [
        _SaveIndicator(status: state.saveStatus),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: state.saveStatus == SaveStatus.saving ? null : onSave,
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Salvar'),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Publicação chega no incremento I4',
          child: OutlinedButton(onPressed: null, child: const Text('Publish')),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.status});

  final SaveStatus status;

  @override
  Widget build(BuildContext context) {
    // Cor + ícone + texto: a cor nunca é o único sinal (acessibilidade).
    final (icon, label, color) = switch (status) {
      SaveStatus.saved => (Icons.check_circle, 'Salvo', AppTheme.success),
      SaveStatus.dirty => (
        Icons.edit_outlined,
        'Não salvo',
        AppTheme.inkSecondary,
      ),
      SaveStatus.saving => (Icons.sync, 'Salvando…', AppTheme.inkSecondary),
      SaveStatus.saveFailed => (
        Icons.error_outline,
        'Falha ao salvar',
        Colors.red,
      ),
    };
    return Semantics(
      liveRegion: true,
      label: 'Status do salvamento: $label',
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
