import 'package:driva_demo_app/modules/published_module/presentation/catalog/page/catalog_page.dart';
import 'package:driva_demo_app/modules/published_module/presentation/content/page/content_page.dart';
import 'package:go_router/go_router.dart';

class PublishedRoutes {
  static const String catalog = '/';
  static const String catalogName = 'catalog';

  static const String content = '/c/:slug';
  static const String contentName = 'content';

  static GoRoute get catalogRoute => GoRoute(
    path: catalog,
    name: catalogName,
    builder: CatalogPage.pageBuilder,
  );

  static GoRoute get contentRoute => GoRoute(
    path: content,
    name: contentName,
    builder: ContentPage.pageBuilder,
  );
}
