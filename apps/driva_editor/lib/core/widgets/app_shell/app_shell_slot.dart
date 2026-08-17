import 'package:driva_editor/core/widgets/app_shell/app_bar_action.dart';
import 'package:driva_editor/core/widgets/app_shell/app_shell_scope.dart';
import 'package:driva_editor/core/widgets/app_shell/crumb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Envolve o corpo de uma página e publica seus crumbs/actions/status no
/// [AppShellController] do shell. A publicação nunca acontece durante o build
/// (sempre pós-frame), para não disparar `notifyListeners` na fase de build.
class AppShellSlot extends StatefulWidget {
  const AppShellSlot({
    required this.child,
    super.key,
    this.crumbs = const [],
    this.actions = const [],
    this.status,
    this.immersive = false,
  });

  final List<Crumb> crumbs;
  final List<AppBarAction> actions;
  final AppBarStatus? status;

  /// Repassado a [AppShellController.setImmersive] com o mesmo `_token` do
  /// `publish` (F7/D15) — é o único jeito de uma página pedir o modo tela
  /// cheia do shell sem inventar um segundo dono.
  final bool immersive;

  final Widget child;

  @override
  State<AppShellSlot> createState() => _AppShellSlotState();
}

class _AppShellSlotState extends State<AppShellSlot> {
  final Object _token = Object();
  AppShellController? _controller;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = AppShellScope.of(context);
    _schedulePublish();
  }

  @override
  void didUpdateWidget(AppShellSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePublish();
  }

  void _schedulePublish() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      _publishIfChanged();
    });
  }

  void _publishIfChanged() {
    final controller = _controller;
    if (controller == null) return;
    final unchanged =
        controller.isOwner(_token) &&
        listEquals(controller.crumbs, widget.crumbs) &&
        listEquals(controller.actions, widget.actions) &&
        controller.status == widget.status;
    if (!unchanged) {
      controller.publish(
        _token,
        crumbs: widget.crumbs,
        actions: widget.actions,
        status: widget.status,
      );
    }
    controller.setImmersive(_token, value: widget.immersive);
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.clear(_token);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
