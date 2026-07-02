import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Dev entrypoint. Run with:
/// `flutter run -d chrome --target apps/driva_editor/lib/main_dev.dart \
///   --dart-define-from-file=apps/driva_editor/config/dev.json`
void main() => bootstrap(const AppConfig.fromEnvironment(environment: 'dev'));
