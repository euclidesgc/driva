import 'package:driva_demo_app/core/config/app_config.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

void setupInjection(AppConfig config) {
  getIt.registerSingleton<AppConfig>(config);
}
