import 'package:equatable/equatable.dart';

/// Immutable app configuration, assembled once per flavor entrypoint and
/// registered as a singleton in the service locator.
///
/// Values come from `--dart-define-from-file=config/<env>.json`
/// (never secrets — dart-defines are embedded in the binary).
final class AppConfig extends Equatable {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.defaultProjectId,
    required this.useFakeData,
  });

  /// Reads the dart-defines injected at build time.
  /// The flavor entrypoint only names the environment.
  const AppConfig.fromEnvironment({required String environment})
      : this(
          environment: environment,
          apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
          defaultProjectId: const String.fromEnvironment(
            'DEFAULT_PROJECT_ID',
            defaultValue: 'default',
          ),
          useFakeData: const bool.fromEnvironment('USE_FAKE_DATA'),
        );

  /// Flavor name: `dev` or `prod`.
  final String environment;

  /// Backend base URL (e.g. `http://localhost:3000` in dev).
  final String apiBaseUrl;

  /// Tenant scope sent as `x-project-id` (multi-tenant real chega no I4).
  final String defaultProjectId;

  /// Roda com repositórios fake em memória (enquanto o backend não sobe,
  /// e para o QA instrumentar o E2E sem servidor).
  final bool useFakeData;

  @override
  List<Object?> get props =>
      [environment, apiBaseUrl, defaultProjectId, useFakeData];
}
