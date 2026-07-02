import 'package:sdui_core/sdui_core.dart';

/// In-memory page store for the fake repositories (dev only).
///
/// Vive no core porque é compartilhado entre `pages_module` e
/// `editor_module` — os dois fakes precisam ver as mesmas páginas para o
/// fluxo "criar na lista → abrir no editor" funcionar sem backend.
/// Registrado no locator apenas quando `AppConfig.useFakeData` é true.
class FakePagesStore {
  FakePagesStore() {
    final sample = _samplePage();
    _pages[sample.id] = sample;
    _updatedAt[sample.id] = DateTime.now();
  }

  final Map<String, PageSpec> _pages = {};
  final Map<String, DateTime> _updatedAt = {};
  int _sequence = 1;

  List<PageSpec> get pages => _pages.values.toList(growable: false);

  DateTime updatedAtOf(String id) => _updatedAt[id] ?? DateTime.now();

  PageSpec? find(String id) => _pages[id];

  PageSpec create({required String name, required String screenTarget}) {
    final id = 'pg_${_sequence++}';
    final page = PageSpec(
      specVersion: kSpecVersion,
      id: id,
      name: name,
      screenTarget: screenTarget,
      root: SduiNode(id: 'nd_root_$id', type: 'column'),
    );
    _pages[id] = page;
    _updatedAt[id] = DateTime.now();
    return page;
  }

  void save(PageSpec page) {
    _pages[page.id] = page;
    _updatedAt[page.id] = DateTime.now();
  }

  bool delete(String id) {
    _updatedAt.remove(id);
    return _pages.remove(id) != null;
  }

  /// Uma página de exemplo para o editor nunca abrir vazio em dev.
  PageSpec _samplePage() {
    return PageSpec(
      specVersion: kSpecVersion,
      id: 'pg_exemplo',
      name: 'Home — vitrine',
      screenTarget: 'home',
      root: const SduiNode(
        id: 'nd_root',
        type: 'column',
        properties: {'crossAxisAlignment': 'stretch', 'spacing': 8.0},
        children: [
          SduiNode(
            id: 'nd_banner',
            type: 'container',
            properties: {
              'height': 140.0,
              'color': '#E8602C',
              'borderRadius': 12.0,
              'padding': {'all': 16.0},
              'alignment': 'centerLeft',
            },
            child: SduiNode(
              id: 'nd_banner_text',
              type: 'text',
              properties: {
                'data': 'Semana do cliente',
                'fontSize': 22.0,
                'fontWeight': 'w700',
                'color': '#FFFFFF',
              },
            ),
          ),
          SduiNode(
            id: 'nd_caption',
            type: 'text',
            properties: {'data': 'Ofertas selecionadas', 'fontSize': 14.0},
          ),
          SduiNode(id: 'nd_divider', type: 'divider'),
          SduiNode(
            id: 'nd_cta',
            type: 'button',
            properties: {'label': 'Ver todas as ofertas', 'variant': 'filled'},
          ),
        ],
      ),
    );
  }
}
