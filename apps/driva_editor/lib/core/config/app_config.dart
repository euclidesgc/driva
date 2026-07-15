import 'package:equatable/equatable.dart';

/// Values come from `--dart-define-from-file=config/<env>.json`
/// (never secrets — dart-defines are embedded in the binary).
final class AppConfig extends Equatable {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.defaultProjectId,
    required this.useFakeData,
  });

  const AppConfig.fromEnvironment({required String environment})
    : this(
        environment: environment,
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        defaultProjectId: const String.fromEnvironment(
          'DEFAULT_PROJECT_ID',
          defaultValue: 'default',
        ),
        // Default dev-amigável: sem o arquivo de config, roda com fakes.
        // O build de produção SEMPRE usa --dart-define-from-file
        // (config/prod.json define USE_FAKE_DATA=false).
        useFakeData: const bool.fromEnvironment(
          'USE_FAKE_DATA',
          defaultValue: true,
        ),
      );

  final String environment;

  final String apiBaseUrl;

  /// Tenant scope sent as `x-project-id` (multi-tenant real chega no I4).
  final String defaultProjectId;

  /// Roda com repositórios fake em memória (enquanto o backend não sobe,
  /// e para o QA instrumentar o E2E sem servidor).
  final bool useFakeData;

  @override
  List<Object?> get props => [
    environment,
    apiBaseUrl,
    defaultProjectId,
    useFakeData,
  ];
}
