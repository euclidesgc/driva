import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Prod entrypoint. Build with:
/// `flutter build web --target apps/driva_editor/lib/main_prod.dart \
///   --dart-define-from-file=apps/driva_editor/config/prod.json`
void main() => bootstrap(const AppConfig.fromEnvironment(environment: 'prod'));
