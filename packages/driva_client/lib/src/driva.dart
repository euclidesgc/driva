import 'package:driva_client/src/content_repository.dart';
import 'package:driva_client/src/driva_config.dart';
import 'package:http/http.dart' as http;

class Driva {
  Driva._(this.config, this.repository);

  static Driva? _instance;

  final DrivaConfig config;
  final DrivaContentRepository repository;

  static Future<void> init(
    DrivaConfig config, {
    http.Client? httpClient,
  }) async {
    if (_instance != null) return;
    _instance = Driva._(
      config,
      DrivaContentRepository(config: config, httpClient: httpClient),
    );
  }

  static Driva get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'Driva.init(DrivaConfig(...)) ainda não foi chamado. Chame-o antes '
        'de usar DrivaContent — normalmente no main(), antes de runApp().',
      );
    }
    return current;
  }

  static bool get isInitialized => _instance != null;

  static void resetForTesting() => _instance = null;
}
