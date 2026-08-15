import 'package:driva_demo_app/bootstrap.dart';
import 'package:driva_demo_app/core/config/app_config.dart';

void main() => bootstrap(const AppConfig.fromEnvironment(environment: 'dev'));
