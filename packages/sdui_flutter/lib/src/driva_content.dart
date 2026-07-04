import 'package:flutter/widgets.dart';

/// Fachada pública reservada para os apps clientes renderizarem um conteúdo
/// SDUI pelo seu [slug].
///
/// Nesta fase apenas o nome e o contrato de dados estão reservados: a resolução
/// do [slug] em runtime (rede/serving) e o `Driva.init(projectId:)` são o
/// próximo incremento e ainda não existem. Por isso [build] lança
/// [UnimplementedError] em vez de fingir um comportamento inexistente — quem já
/// renderiza um `ContentSpec` resolvido usa `SduiView.content`.
class DrivaContent extends StatelessWidget {
  const DrivaContent({super.key, required this.slug});

  /// Identifica o conteúdo dentro do projeto.
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
