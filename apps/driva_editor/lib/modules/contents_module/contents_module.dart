export 'contents_routes.dart'; // a rota, para o app_router
export 'contents_injection.dart'; // o register, para o injection.dart raiz

// De fora, o módulo é uma caixa-preta com DUAS portas: "registre minhas
// dependências" e "aqui está minha rota". domain/, data/ e presentation/
// são internos e não cruzam esta fronteira.
//
// Categorias moram AQUI (não num módulo próprio): a tela do projeto compõe
// árvore de categorias + painel de conteúdos numa única tela, e a regra
// "presentation nunca importa data de outro módulo" impediria essa
// composição se categorias vivessem num `categories_module` separado.
// Categoria é parte da feature "organização de conteúdos" — decisão
// registrada em docs/08-api-conteudos-filtro-busca/plan.md (P2, Passo 0).
