import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_widget.dart';
import 'core/config/app_config.dart';
import 'core/observability/app_bloc_observer.dart';
import 'injection.dart';

/// Shared startup, called by every flavor entrypoint (`main_dev`/`main_prod`).
///
/// Installs the four safety nets for *unexpected* errors — nothing dies in
/// silence:
/// 1. `FlutterError.onError` — framework errors (build/layout/paint);
/// 2. `PlatformDispatcher.onError` — unhandled async errors reaching the engine;
/// 3. `runZonedGuarded` — the final net, outside the framework's cycle;
/// 4. `Bloc.observer` — state lifecycle + errors escaping the Either boundary.
Future<void> bootstrap(AppConfig config) async {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // URLs limpas no Flutter Web (`/contents` em vez de `/#/contents`). Exige que o
      // servidor faça SPA fallback para index.html — o nosso nginx já faz
      // (`try_files … /index.html`, veja deploy/nginx.conf).
      usePathUrlStrategy();

      Bloc.observer = const AppBlocObserver();

      FlutterError.onError = (FlutterErrorDetails details) {
        log(
          'FlutterError',
          name: 'app',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        log('PlatformDispatcher', name: 'app', error: error, stackTrace: stack);
        return true;
      };

      // Armazenamento local resolvido antes do primeiro frame — o tema
      // persistido já sobe aplicado, sem flash do padrão. Roda dentro da zona
      // guardada, então falhas aqui caem nas redes de segurança acima.
      unawaited(
        SharedPreferences.getInstance().then((prefs) {
          setupInjection(config, prefs);
          runApp(const AppWidget());
        }),
      );
    },
    (Object error, StackTrace stack) {
      log('Uncaught zone error', name: 'app', error: error, stackTrace: stack);
    },
  );
}
