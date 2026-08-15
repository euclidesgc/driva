import 'package:equatable/equatable.dart';

/// Vem de `--dart-define-from-file=config/<env>.json`. A chave publicável é
/// feita para viajar no binário: ela só lê conteúdo publicado, nunca escreve.
final class AppConfig extends Equatable {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.publishableKey,
  });

  const AppConfig.fromEnvironment({required String environment})
    : this(
        environment: environment,
        apiBaseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000',
        ),
        publishableKey: const String.fromEnvironment('PUBLISHABLE_KEY'),
      );

  final String environment;

  final String apiBaseUrl;

  /// Identifica o projeto do driva que este app consome.
  final String publishableKey;

  @override
  List<Object?> get props => [environment, apiBaseUrl, publishableKey];
}
