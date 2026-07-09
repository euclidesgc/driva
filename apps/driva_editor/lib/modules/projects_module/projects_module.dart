export 'projects_routes.dart'; // a rota, para o app_router
export 'projects_injection.dart'; // o register, para o injection.dart raiz

// De fora, o módulo é uma caixa-preta com DUAS portas: "registre minhas
// dependências" e "aqui está minha rota". domain/, data/ e presentation/
// são internos e não cruzam esta fronteira.
