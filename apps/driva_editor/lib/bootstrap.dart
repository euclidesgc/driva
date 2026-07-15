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

Future<void> bootstrap(AppConfig config) async {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

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

      // Prefs antes do primeiro frame: sem isso o tema persistido dá flash.
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
