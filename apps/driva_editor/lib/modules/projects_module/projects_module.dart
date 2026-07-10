export 'projects_routes.dart'; // a rota, para o app_router
export 'projects_injection.dart'; // o register, para o injection.dart raiz

// Terceira porta, deliberada e restrita: leitura de UM projeto por id.
// `contents_module` (a tela do projeto) precisa mostrar `title` no header
// e não pode alcançar `domain`/`data` de `projects_module` por fora do
// barrel (regra "só o barrel público"). Expor o USE CASE de leitura + a
// entidade `Project` (tipo de retorno dele — sem ela o barrel não compila
// para quem chama) é o menor contrato cross-módulo que resolve isso: não
// expõe o repositório, nem os use cases de escrita, nem `data`/`presentation`.
// Decisão de arquitetura registrada no
// `docs/08-api-conteudos-filtro-busca/plan.md` (P3) como leve desvio da
// regra "barrel só rota+DI".
export 'domain/entities/project.dart';
export 'domain/use_cases/get_project_use_case.dart';

// De fora, o módulo é uma caixa-preta com DUAS portas (rota + DI) mais essa
// leitura pontual. domain/, data/ e presentation/ seguem internos — nada
// mais cruza esta fronteira.
