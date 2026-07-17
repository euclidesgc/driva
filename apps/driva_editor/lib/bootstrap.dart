import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:driva_editor/app_widget.dart';
import 'package:driva_editor/core/config/app_config.dart';
import 'package:driva_editor/core/observability/app_bloc_observer.dart';
import 'package:driva_editor/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap(AppConfig config) async {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      usePathUrlStrategy();

      Bloc.observer = const AppBlocObserver();

      FlutterError.onError = (details) {
        log(
          'FlutterError',
          name: 'app',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
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
    (error, stack) {
      log('Uncaught zone error', name: 'app', error: error, stackTrace: stack);
    },
  );
}
