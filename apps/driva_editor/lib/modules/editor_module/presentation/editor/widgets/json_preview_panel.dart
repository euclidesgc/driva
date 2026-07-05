import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../../core/theme/app_theme.dart';
import '../cubit/editor_cubit.dart';
import 'json_highlighter.dart';

/// Painel de preview do JSON do spec em tempo real (itens 7 e 8 do roadmap).
///
/// Somente-leitura, com botão de copiar e syntax highlight próprio. Assina o
/// `document` do cubit e **throttla** a re-serialização (o custo é `toJson` +
/// encode + realce), no mesmo espírito do preview do canvas: digitação rápida
/// é coalescida, com render final garantido.
class JsonPreviewPanel extends StatefulWidget {
  const JsonPreviewPanel({super.key});

  @override
  State<JsonPreviewPanel> createState() => _JsonPreviewPanelState();
}

class _JsonPreviewPanelState extends State<JsonPreviewPanel> {
  static const _throttle = Duration(milliseconds: 200);
  static const _encoder = JsonEncoder.withIndent('  ');

  late final EditorCubit _cubit = context.read<EditorCubit>();
  late StreamSubscription<EditorState> _subscription;

  late ContentSpec _rendered;
  late String _json;
  Timer? _cooldown;
  bool _pendingRender = false;
  bool _copied = false;
  Timer? _copiedReset;

  @override
  void initState() {
    super.initState();
    final state = _cubit.state as EditorReady;
    _rendered = state.document;
    _json = _encoder.convert(_rendered.toJson());
    _subscription = _cubit.stream.listen(_onState);
  }

  void _onState(EditorState state) {
    if (state is! EditorReady || !mounted) return;
    if (state.document == _rendered) return;

    if (_cooldown?.isActive ?? false) {
      _pendingRender = true;
    } else {
      _applyDocument();
    }
  }

  void _applyDocument() {
    final state = _cubit.state;
    if (state is! EditorReady || !mounted) return;
    setState(() {
      _rendered = state.document;
      _json = _encoder.convert(_rendered.toJson());
    });
    _pendingRender = false;
    _cooldown = Timer(_throttle, () {
      if (_pendingRender && mounted) _applyDocument();
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _json));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedReset?.cancel();
    _copiedReset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _cooldown?.cancel();
    _copiedReset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _JsonToolbar(copied: _copied, onCopy: _copy),
        Expanded(child: _JsonView(json: _json)),
      ],
    );
  }
}

class _JsonToolbar extends StatelessWidget {
  const _JsonToolbar({required this.copied, required this.onCopy});

  final bool copied;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.data_object, size: 16, color: AppTheme.inkMuted),
          const SizedBox(width: 8),
          const Text(
            'JSON do spec (somente-leitura)',
            style: TextStyle(fontSize: 12, color: AppTheme.inkSecondary),
          ),
          const Spacer(),
          // Estado do copiar não fica só na cor: ícone + rótulo mudam juntos.
          TextButton.icon(
            onPressed: () => onCopy(),
            icon: Icon(
              copied ? Icons.check : Icons.copy_all_outlined,
              size: 16,
              color: copied ? AppTheme.success : AppTheme.ink,
            ),
            label: Text(
              copied ? 'Copiado' : 'Copiar',
              style: TextStyle(
                fontSize: 12,
                color: copied ? AppTheme.success : AppTheme.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView({required this.json});

  final String json;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5);
    return ColoredBox(
      color: AppTheme.surface,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          primary: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText.rich(
                TextSpan(children: JsonHighlighter.highlight(json, base: base)),
                style: base,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
