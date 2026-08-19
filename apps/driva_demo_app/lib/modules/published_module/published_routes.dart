import 'package:driva_demo_app/modules/published_module/presentation/content/page/content_page.dart';
import 'package:go_router/go_router.dart';

class PublishedRoutes {
  static const String content = '/';
  static const String contentName = 'content';

  static GoRoute get contentRoute => GoRoute(
    path: content,
    name: contentName,
    builder: ContentPage.pageBuilder,
  );
}
