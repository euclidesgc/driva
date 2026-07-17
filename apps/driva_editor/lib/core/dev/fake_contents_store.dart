import 'package:sdui_core/sdui_core.dart';

/// Vive no core porque é compartilhado entre `contents_module` e
/// `editor_module` — os dois fakes precisam ver os mesmos conteúdos para o
/// fluxo "criar na lista → abrir no editor" funcionar sem backend.
/// Registrado no locator apenas quando `AppConfig.useFakeData` é true.
class FakeContentsStore {
  FakeContentsStore() {
    final sample = _sampleContent();
    _contents[sample.id] = sample;
    _updatedAt[sample.id] = DateTime.now();
    _categoryOf[sample.id] = defaultCategoryId;
  }

  /// Id da categoria "Geral" — espelha a seed do backend e a raiz de
  /// `CategoriesRepositoryFake`. Destino default quando a escrita omite
  /// `categoryId`, como no contrato real.
  static const defaultCategoryId = 'cat_geral';

  final Map<String, ContentSpec> _contents = {};
  final Map<String, DateTime> _updatedAt = {};
  final Map<String, String> _categoryOf = {};
  int _sequence = 1;

  List<ContentSpec> get contents => _contents.values.toList(growable: false);

  /// Slugs já em uso — a base da sugestão local de slug livre em colisão.
  Set<String> get slugs =>
      _contents.values.map((content) => content.slug).toSet();

  bool slugExists(String slug) => slugs.contains(slug);

  DateTime updatedAtOf(String id) => _updatedAt[id] ?? DateTime.now();

  /// Categoria do conteúdo — sempre presente (todo conteúdo tem categoria,
  /// "Geral" é o default), espelhando `categoryId` obrigatório do contrato.
  String categoryIdOf(String id) => _categoryOf[id] ?? defaultCategoryId;

  ContentSpec? find(String id) => _contents[id];

  ContentSpec create({
    required String name,
    required String slug,
    String? description,
    String? categoryId,
  }) {
    final id = 'ct_${_sequence++}';
    // Conteúdo novo nasce VAZIO (sem root): o primeiro widget adicionado no
    // editor vira a raiz, de qualquer tipo.
    final content = ContentSpec(
      specVersion: kSpecVersion,
      id: id,
      name: name,
      slug: slug,
      description: description,
    );
    _contents[id] = content;
    _updatedAt[id] = DateTime.now();
    _categoryOf[id] = categoryId ?? defaultCategoryId;
    return content;
  }

  void save(ContentSpec content) {
    _contents[content.id] = content;
    _updatedAt[content.id] = DateTime.now();
  }

  bool delete(String id) {
    _updatedAt.remove(id);
    _categoryOf.remove(id);
    return _contents.remove(id) != null;
  }

  /// Move o conteúdo para outra categoria (espelha `PUT` com `categoryId`).
  /// `false` quando o conteúdo não existe.
  bool moveToCategory(String id, String categoryId) {
    if (!_contents.containsKey(id)) return false;
    _categoryOf[id] = categoryId;
    _updatedAt[id] = DateTime.now();
    return true;
  }

  /// Um conteúdo de exemplo para o editor nunca abrir vazio em dev.
  ContentSpec _sampleContent() {
    return const ContentSpec(
      specVersion: kSpecVersion,
      id: 'ct_exemplo',
      name: 'Home — vitrine',
      slug: 'home',
      description: 'Banner de destaque da home com chamada para ofertas.',
      root: SduiNode(
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
