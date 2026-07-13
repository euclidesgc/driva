import 'package:flutter/material.dart';

import 'app_bar_action.dart';
import 'crumb.dart';

/// Barramento entre as páginas (que publicam crumbs/actions/status) e as faixas
/// do [AppShell] (que os renderizam). Vive enquanto o shell vive, ou seja
/// através das 4 rotas — é o ponto do `ShellRoute`.
class AppShellController extends ChangeNotifier {
  List<Crumb> _crumbs = const [];
  List<AppBarAction> _actions = const [];
  AppBarStatus? _status;
  Object? _ownerToken;
  bool _disposed = false;

  List<Crumb> get crumbs => _crumbs;
  List<AppBarAction> get actions => _actions;
  AppBarStatus? get status => _status;

  bool isOwner(Object token) => identical(_ownerToken, token);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void publish(
    Object token, {
    required List<Crumb> crumbs,
    required List<AppBarAction> actions,
    AppBarStatus? status,
  }) {
    if (_disposed) return;
    _ownerToken = token;
    _crumbs = crumbs;
    _actions = actions;
    _status = status;
    notifyListeners();
  }

  /// Só o dono atual limpa. Na transição A→B, B publica (vira dono) antes de A
  /// fazer `dispose`; o `clear` de A cai aqui e é ignorado, então o topo de B
  /// não pisca vazio.
  void clear(Object token) {
    if (_disposed || !identical(_ownerToken, token)) return;
    _ownerToken = null;
    _crumbs = const [];
    _actions = const [];
    _status = null;
    notifyListeners();
  }
}

class AppShellScope extends InheritedNotifier<AppShellController> {
  const AppShellScope({
    super.key,
    required AppShellController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Acesso sem assinar — para o slot escrever sem se inscrever em rebuilds.
  /// Nulo fora de um [AppShell] (ex.: página montada isolada em teste): o slot
  /// vira no-op em vez de quebrar.
  static AppShellController? of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AppShellScope>()?.notifier;
  }

  /// Assina — para as faixas do shell reconstruírem em `notifyListeners`.
  static AppShellController watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppShellScope>();
    assert(scope != null, 'AppShellScope não encontrado acima deste contexto.');
    return scope!.notifier!;
  }
}
