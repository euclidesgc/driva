import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Sees the lifecycle of EVERY Cubit/Bloc in the app, without any of them
/// knowing. Installed once, in [bootstrap] (`Bloc.observer`).
///
/// This is the fourth safety net: `onChange` gives the audit trail of every
/// state transition; `onError` catches what escaped the `Either` boundary.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    log('onCreate', name: '${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log(
      '${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      name: '${bloc.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log(
      'onError',
      name: '${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    log('onClose', name: '${bloc.runtimeType}');
  }
}
