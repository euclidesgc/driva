import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';

import '../cubit/editor_cubit.dart';
import 'json_preview/json_preview.dart';

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JsonToolbar(copied: _copied, onCopy: _copy),
        Expanded(child: JsonView(json: _json)),
      ],
    );
  }
}
