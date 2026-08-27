import 'dart:async';
import 'dart:developer';

import 'package:driva_client/src/driva.dart';
import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart';
import 'package:sdui_flutter/sdui_flutter.dart';

typedef DrivaErrorBuilder = Widget Function(BuildContext context, Object error);

class DrivaContent extends StatefulWidget {
  const DrivaContent({
    required this.slug,
    super.key,
    this.onAction,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String slug;
  final SduiActionHandler? onAction;
  final WidgetBuilder? loadingBuilder;
  final DrivaErrorBuilder? errorBuilder;

  @override
  State<DrivaContent> createState() => _DrivaContentState();
}

class _DrivaContentState extends State<DrivaContent> {
  StreamSubscription<ContentSpec>? _subscription;
  ContentSpec? _spec;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant DrivaContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      unawaited(_subscription?.cancel());
      _spec = null;
      _error = null;
      _subscribe();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _subscribe() {
    _subscription = Driva.instance.repository
        .load(widget.slug)
        .listen(
          (spec) {
            if (!mounted) return;
            setState(() {
              _spec = spec;
              _error = null;
            });
          },
          onError: (Object error, StackTrace stackTrace) {
            log(
              'Erro inesperado ao carregar "${widget.slug}": $error',
              name: 'driva_client',
              stackTrace: stackTrace,
            );
            if (!mounted) return;
            setState(() => _error = error);
          },
          onDone: () {
            // Stream que fecha com erro também dispara onDone — sem este
            // retorno cedo, o StateError genérico abaixo sobrescreveria o
            // DrivaLoadFailure que o onError acima acabou de guardar.
            if (!mounted || _spec != null || _error != null) return;
            setState(
              () => _error = StateError(
                'Driva: nenhum conteúdo disponível para "${widget.slug}" '
                '(sem cache, sem rede, sem fallback).',
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    if (spec != null) {
      return SduiView.content(
        spec,
        registry: Driva.instance.config.registry,
        onAction: widget.onAction,
      );
    }

    final error = _error;
    if (error != null) {
      final errorBuilder = widget.errorBuilder;
      if (errorBuilder != null) return errorBuilder(context, error);
      return const SizedBox.shrink();
    }

    final loadingBuilder = widget.loadingBuilder;
    if (loadingBuilder != null) return loadingBuilder(context);
    return const SizedBox.shrink();
  }
}
