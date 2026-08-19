import 'package:sdui_core/sdui_core.dart';

/// Metadados de uma versão publicada em memória — sem depender de nenhum
/// tipo de módulo (`core` fica agnóstico; quem converte para `ContentVersion`
/// é o `EditorRepositoryFake`).
typedef FakeVersionMeta = ({
  int version,
  DateTime createdAt,
  String? note,
  String? createdBy,
});

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
  final Map<String, List<ContentSpec>> _versionSpecs = {};
  final Map<String, List<FakeVersionMeta>> _versionMeta = {};
  final Map<String, int?> _publishedVersion = {};
  final Map<String, DateTime?> _publishedAt = {};
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

  int? publishedVersionOf(String id) => _publishedVersion[id];

  int? latestVersionOf(String id) {
    final metas = _versionMeta[id];
    if (metas == null || metas.isEmpty) return null;
    return metas.last.version;
  }

  DateTime? publishedAtOf(String id) => _publishedAt[id];

  bool hasUnpublishedChanges(String id) {
    final publishedAt = _publishedAt[id];
    if (publishedAt == null) return true;
    return updatedAtOf(id).isAfter(publishedAt);
  }

  /// Publica o rascunho atual. Idempotente (D3 do plano do item 24): sem
  /// mudança desde a última publicação, devolve a versão já publicada em vez
  /// de criar um registro novo.
  FakeVersionMeta? publish(String id, {String? note}) {
    final content = _contents[id];
    if (content == null) return null;
    if (!hasUnpublishedChanges(id)) {
      final version = _publishedVersion[id]!;
      return _versionMeta[id]!.firstWhere((meta) => meta.version == version);
    }
    final specs = _versionSpecs.putIfAbsent(id, () => []);
    final metas = _versionMeta.putIfAbsent(id, () => []);
    final now = DateTime.now();
    final meta = (
      version: specs.length + 1,
      createdAt: now,
      note: note,
      createdBy: null,
    );
    specs.add(content);
    metas.add(meta);
    _publishedVersion[id] = meta.version;
    _publishedAt[id] = now;
    return meta;
  }

  /// Tira do ar sem apagar o histórico de versões.
  void unpublish(String id) {
    _publishedVersion[id] = null;
    _publishedAt[id] = null;
  }

  List<FakeVersionMeta> versionsOf(String id) =>
      (_versionMeta[id] ?? const []).reversed.toList(growable: false);

  ContentSpec? specAtVersion(String id, int version) {
    final specs = _versionSpecs[id];
    if (specs == null || version < 1 || version > specs.length) return null;
    return specs[version - 1];
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
