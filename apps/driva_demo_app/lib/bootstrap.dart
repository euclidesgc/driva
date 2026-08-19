import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:driva_client/driva_client.dart';
import 'package:driva_demo_app/app_widget.dart';
import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:driva_demo_app/core/observability/app_bloc_observer.dart';
import 'package:driva_demo_app/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> bootstrap(AppConfig config) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      setupInjection(config);
      await Driva.init(
        DrivaConfig(
          baseUrl: config.apiBaseUrl,
          publishableKey: config.publishableKey,
        ),
      );
      runApp(const AppWidget());
    },
    (error, stack) {
      log('Uncaught zone error', name: 'app', error: error, stackTrace: stack);
    },
  );
}
