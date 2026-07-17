import 'dart:async';

import 'package:driva_editor/bootstrap.dart';
import 'package:driva_editor/core/config/app_config.dart';

/// Entrypoint de verificação da integração com o backend REAL
/// (docker compose + nest em localhost:3000). Só para dev — ferramentas de
/// launch que não passam dart-defines usam este alvo.
void main() {
  unawaited(
    bootstrap(
      const AppConfig(
        environment: 'dev',
        apiBaseUrl: 'http://localhost:3000',
        defaultProjectId: 'default',
        useFakeData: false,
      ),
    ),
  );
}
