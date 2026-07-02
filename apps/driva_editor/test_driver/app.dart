import 'package:driva_editor/bootstrap.dart';
import 'package:driva_editor/core/config/app_config.dart';
import 'package:flutter_driver/driver_extension.dart';

/// Entrypoint instrumentado para verificação dirigida (flutter driver / MCP).
/// Só para dev e E2E — nunca é alvo de build de produção.
void main() {
  enableFlutterDriverExtension();
  bootstrap(const AppConfig.fromEnvironment(environment: 'dev'));
}
