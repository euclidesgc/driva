import 'package:driva_editor/bootstrap.dart';
import 'package:driva_editor/core/config/app_config.dart';

void main() => bootstrap(const AppConfig.fromEnvironment(environment: 'prod'));
