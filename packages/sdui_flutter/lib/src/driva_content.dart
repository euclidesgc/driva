import 'package:flutter/widgets.dart';

class DrivaContent extends StatelessWidget {
  const DrivaContent({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError(
      'DrivaContent(slug: "$slug"): a resolução por slug em runtime chega no '
      'próximo incremento. Para renderizar um ContentSpec já resolvido, use '
      'SduiView.content(spec).',
    );
  }
}
