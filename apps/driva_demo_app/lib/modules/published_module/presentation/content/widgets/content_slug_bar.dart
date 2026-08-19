import 'package:driva_demo_app/core/theme/theme.dart';
import 'package:flutter/material.dart';

class ContentSlugBar extends StatefulWidget {
  const ContentSlugBar({
    required this.currentSlug,
    required this.onSubmit,
    super.key,
  });

  final String currentSlug;
  final ValueChanged<String> onSubmit;

  @override
  State<ContentSlugBar> createState() => _ContentSlugBarState();
}

class _ContentSlugBarState extends State<ContentSlugBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentSlug,
  );

  @override
  void didUpdateWidget(covariant ContentSlugBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSlug != widget.currentSlug) {
      _controller.text = widget.currentSlug;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final slug = _controller.text.trim();
    if (slug.isEmpty || slug == widget.currentSlug) return;
    widget.onSubmit(slug);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  textField: true,
                  label: 'Slug do conteúdo a abrir',
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'slug do conteúdo',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Abrir slug',
                onPressed: _submit,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
