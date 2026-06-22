# Arquitetura Flutter modular para grande porte: go_router + get_it + bloc

Este guia mostra como organizar um app Flutter de forma **modular**, **desacoplada** e **testável**, com **papéis e escopos bem definidos**, uma arquitetura difícil de furar à medida que o app cresce para **vários módulos**.

## Sobre o que é este artigo

Em uma frase: **como montar a arquitetura de um app Flutter de grande porte com fronteiras claras, sem geração de código.** Ao longo do texto você vai ver, nesta ordem: as **convenções** que adotamos e os **packages** que entram (e por quê); um app de exemplo (painel de loja) construído módulo a módulo; o padrão de **injeção de dependências** com `get_it`; a **navegação modular** com `go_router`; a **gestão de estado** com `bloc`; o **tratamento de erros** em duas camadas: previstos (`fpdart`/`Either`) e não previstos (captura global no `main`); a técnica de **barrel** para encapsular cada módulo; e duas seções francas sobre **até onde isso escala** e **o que de fato economiza recursos**. Se você quer só a decisão de stack, leia a [seção de packages](#2-packages-utilizados); se quer copiar o padrão, vá direto ao [módulo de catálogo](#7-módulo-de-catálogo-completo).

## Objetivo

Construir um app cuja arquitetura tenha **fronteiras claras**: cada package responde por **uma** responsabilidade, e há **um jeito certo** de fazer cada coisa. Isso não é preciosismo, é o que impede que um dev menos experiente quebre o padrão e que, com o tempo, o código vire difícil de manter. Boa arquitetura é, antes de tudo, **limite e responsabilidade bem definidos**.

As metas concretas:

- **Escala linear**: adicionar um módulo é criar uma pasta e registrar **uma** rota; nunca tocar no que já existe.
- **Domínio limpo**: regra de negócio isolada de Flutter, de HTTP e de formato de transporte.
- **Deep links de fábrica**: qualquer tela abre direto pela URL, com suas dependências montadas do zero.
- **Erros sob controle**: falhas previstas tratadas com tipo (`Either<Failure, T>`); falhas imprevistas capturadas globalmente e registradas.
- **Economia de recursos**: instanciação **lazy** e **dispose** automático do estado de tela. Os limites disso estão na [§16](#16-economia-de-recursos-o-que-é-real-e-o-que-não-é).

> **Honestidade sobre "grande porte".** Esta arquitetura escala bem **sob uma disciplina** (a regra de ouro do `get_it`, [§12](#12-injeção-de-dependências-quem-localiza-quem-injeta)) e com a noção correta do que o dispose cobre. As [§15](#15-robustez-e-escala-o-que-é-estrutural-e-o-que-depende-de-disciplina) e [§16](#16-economia-de-recursos-o-que-é-real-e-o-que-não-é) são francas sobre os limites, porque "robusto" sem ressalva é marketing, não engenharia.

---

## 1. Convenções de código

Antes do primeiro arquivo, fixamos as regras do jogo. Elas valem para **todo** o projeto e tornam o código previsível.

**Idioma.** Comentários, identificadores de domínio, UI e mensagens em **pt-BR** (com acentuação correta). Termos técnicos e nomes de API ficam no original.

**Nomes de arquivo e classes.** Arquivos em `snake_case`; classes em `PascalCase`. **O nome do arquivo espelha a classe principal** (`ProductListPage` → `product_list_page.dart`). E vale a regra de **uma classe pública por arquivo**, com exceções legítimas, que usamos de propósito:

- **Hierarquias `sealed`** moram juntas, num arquivo só. O `sealed` *exige* que as variantes estejam no mesmo arquivo (é o que dá a exaustividade ao `switch`). Por isso `ProductListState` e suas variantes ficam todas em `product_list_state.dart`, ligadas por `part of`.
- **Helpers privados pequenos** acoplados a um widget (ex.: uma tela de fallback `_InvalidProductScreen`) podem acompanhar o arquivo do widget que os usa.

**Imutabilidade.** Entidades e estados são **imutáveis** e estendem `Equatable` (igualdade por valor). Sem `freezed` (que exige `build_runner`), o `copyWith` é escrito à mão, um trade-off consciente.

**Estado.** Sempre `Cubit`/`Bloc` com estado `sealed` + `switch` exaustivo. Um formato só, em toda tela.

**Injeção de dependências.** `get_it` **localiza**; o **construtor injeta** (a regra de ouro, [§12](#12-injeção-de-dependências-quem-localiza-quem-injeta)). Classes nunca chamam o locator por dentro.

**Erros.** Previstos → `Either<Failure, T>` (`fpdart`). Imprevistos → captura global no `main` ([§5](#5-camada-base-do-app)). Nunca um `try/catch` solto vazando `e.toString()` para a UI.

**Sem `build_runner`.** Nenhum `.g.dart`. Tudo roda com a toolchain padrão.

**Arquivos pequenos, responsabilidade única** (KISS/DRY).

### Barrel: a API pública de cada pasta/módulo

Um **barrel** é um arquivo que apenas **reexporta** outros arquivos de uma pasta:

```dart
// catalog_module/domain/entities/entities.dart
export 'product.dart';
```

Quem precisa das entidades importa **uma** linha (`import '.../entities/entities.dart';`) em vez de uma por arquivo. Mas o ganho real não é só economizar linhas de import, é **controlar o que sai de cada fronteira**.

A regra que torna o barrel uma ferramenta de arquitetura, e não só de conveniência:

> **O barrel é a API pública daquela pasta/módulo. Exporte só o que o mundo de fora tem o direito de usar; esconda o resto.**

Na prática, cada módulo terá um **barrel público** (`catalog_module.dart`) que expõe **apenas duas coisas**: a **rota** do módulo (para o router registrar) e a **função de registro de DI** (para o locator chamar). Ele **não exporta**:

- a **implementação** do repositório (`ProductRepositoryImpl`): ninguém de fora deve instanciá-la; só o `injection` interno do módulo a conhece;
- os **cubits** e as **páginas**: são detalhe de apresentação, montados internamente pelo `pageBuilder`;
- os **models/DTOs** (`ProductModel`): são detalhe do `data`.

Se um desses vaza pelo barrel, outro módulo passa a poder importar o interno do catálogo, e a encapsulação que estamos vendendo evapora. **O que você não exporta é tão importante quanto o que exporta.** Por isso, ao longo do guia, **toda pasta que eu criar termina mostrando o seu barrel**, com um comentário sobre o que ficou de fora e por quê.

---

## 2. Packages utilizados

Quatro packages no núcleo, cada um com um papel **não sobreposto**, mais dois para erros/parsing. A premissa que molda tudo: **sem `build_runner`**.

| Package | Papel (a fronteira) | Por que entrou |
|---|---|---|
| [`go_router`](https://pub.dev/packages/go_router) | **Navegação** | Rotas nomeadas, deep links, subrotas e guards (`redirect` + `refreshListenable`), config por módulo. Router recomendado pelo time Flutter. |
| [`get_it`](https://pub.dev/packages/get_it) | **DI de serviços** | Resolve dependências **sem `BuildContext`**. Lazy singletons (paga só pelo que usa), async no bootstrap, **scopes** de sessão. |
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) | **Estado** | Fluxo unidirecional **prescritivo** (`sealed` + `switch`), difícil de furar. Dispose do estado de tela automático. |
| [`equatable`](https://pub.dev/packages/equatable) | **Igualdade por valor** | Faz o dedupe de rebuild do bloc funcionar; estados/entidades comparáveis sem code-gen. **Essencial** (ver [§8](#8-domínio-e-dados)). |
| [`fpdart`](https://pub.dev/packages/fpdart) | **Erros previstos** | `Either<Failure, T>` põe o erro na **assinatura** e o compilador **obriga** a tratá-lo. Substitui o `try/catch` espalhado ([§9](#9-erros-em-duas-camadas-fpdart-para-os-previstos)). |
| [`zard`](https://pub.dev/packages/zard) | **Validação de payload** *(opcional)* | Valida o JSON no limite do `data` e devolve erro tipado em vez de `cast error` cru. Port do [Zod](https://zod.dev) (JS). Ressalva de maturidade na [§8](#8-domínio-e-dados). |
| `dart:developer` (`log`) | **Log** | Saída de log da SDK, usada aqui para não amarrar o guia a um Crashlytics específico ([§5](#5-camada-base-do-app)). |

A divisão de trabalho que você deve gravar:

> **`go_router` leva você à tela. `get_it` localiza os serviços de vida longa. O `bloc` segura o estado daquela tela. `fpdart` carrega o erro previsto. A captura global pega o imprevisto.**

> **Por que não entra Riverpod.** O Riverpod é um paradigma alternativo: ele substitui `get_it` + `bloc` de uma vez: não se *soma*, *substitui*. Eu não misturo os dois, e recomendo que você também não: ter dois sistemas de DI em paralelo é exatamente a ambiguidade que esta arquitetura existe para evitar. Se o seu time é de Riverpod, vá 100% Riverpod; aqui seguimos com `get_it` + `bloc`.

> Inspiração: a modularização do [`flutter_modular`](https://pub.dev/packages/flutter_modular), aqui obtida só com pacotes consolidados, sem micro-framework próprio.

---

## 3. O app de exemplo

Um painel de loja com **navegação em abas** (um *shell* persistente: `StatefulShellRoute.indexedStack`, [§10](#10-shell-de-navegação-com-statefulshellroute)) e três módulos de negócio:

- **Catálogo (produtos)**: lista + detalhes (o módulo completo, modelo a ser copiado).
- **Pedidos** e **Clientes**: exercício no final.

A navegação principal é uma `NavigationBar` fixa (o shell), com **uma aba por módulo**; cada aba mantém sua própria pilha, e os detalhes empilham **dentro** da aba.

```text
[shell: NavigationBar persistente, uma branch por aba]
  Catálogo   /products              → ProductListPage
             /products/details/:id  → ProductDetailsPage   (empilha dentro da aba)
  Pedidos    /orders                → OrderListPage        (exercício)
  Clientes   /customers             → CustomerListPage     (exercício)
```

---

## 4. Estrutura de pastas

Cada módulo é autocontido e segue três camadas (Clean Architecture):

- **domain**: entidades, contratos de repositório e use cases (regra de negócio pura, sem Flutter, **sem formato de transporte**).
- **data**: models de serialização (DTOs) e implementações de repositório.
- **presentation**: UI + lógica de apresentação (páginas e cubits).

```text
lib/
├── core/
│   └── error/
│       ├── failure.dart          // sealed Failure (erros de domínio)
│       └── error.dart            // barrel
├── injection.dart                // setup do get_it (chama o register de cada módulo)
├── app_router.dart               // go_router + StatefulShellRoute (o shell)
├── app_shell.dart                // MainShell: NavigationBar persistente
├── app_widget.dart               // MaterialApp.router
├── main.dart                     // entry point + captura global de erros
└── modules/
    └── catalog_module/
        ├── domain/
        │   ├── entities/
        │   │   ├── product.dart
        │   │   └── entities.dart            // barrel
        │   ├── repositories/
        │   │   ├── product_repository.dart  // contrato (abstração)
        │   │   └── repositories.dart        // barrel
        │   └── use_cases/
        │       ├── get_all_products_use_case.dart
        │       ├── get_product_by_id_use_case.dart
        │       └── use_cases.dart           // barrel
        ├── data/
        │   ├── models/
        │   │   ├── product_model.dart
        │   │   └── models.dart              // barrel (interno)
        │   └── repositories/
        │       ├── product_repository_impl.dart
        │       └── repositories.dart        // barrel (interno!)
        ├── presentation/
        │   ├── product_list/
        │   │   ├── cubit/
        │   │   │   ├── product_list_cubit.dart
        │   │   │   └── product_list_state.dart   // part of (sealed)
        │   │   └── product_list_page.dart
        │   └── product_details/
        │       ├── cubit/
        │       │   ├── product_details_cubit.dart
        │       │   └── product_details_state.dart
        │       └── product_details_page.dart
        ├── catalog_routes.dart        // rotas do módulo
        ├── catalog_injection.dart     // registro de DI do módulo
        └── catalog_module.dart        // BARREL PÚBLICO (rota + injeção; nada mais)
```

> A regra de ouro da Clean Architecture aqui: **o contrato do repositório vive no domain e retorna entidades de domínio**, nunca `Map` cru. A serialização (JSON → objeto) é detalhe de infraestrutura e mora no **data**. Assim o domínio não sabe de onde nem em que formato os dados chegam.

### `core/error`: o tipo de falha compartilhado

```dart
// core/error/failure.dart
import 'package:equatable/equatable.dart';

/// Falha de domínio: o erro "esperado", que a UI sabe tratar.
sealed class Failure extends Equatable {
  const Failure();
  @override
  List<Object?> get props => [];
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

final class ValidationFailure extends Failure {
  final String details;
  const ValidationFailure(this.details);
  @override
  List<Object?> get props => [details];
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure();
}
```

```dart
// core/error/error.dart  (barrel)
export 'failure.dart';
// Não exportamos nada além disto: `error` é a fronteira de erros do app.
```

---

## 5. Camada base do app

### `main.dart`: entry point **e captura global de erros**

É **aqui**, na entrada do app, que instalamos a rede de segurança para os erros **não previstos**, aqueles que escapam de todo `try/catch` e de todo `Either`. A ideia: nada deve morrer silenciosamente; todo erro imprevisto vai para um log (e, em produção, para um Crashlytics/Sentry).

```dart
import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:example/app_widget.dart';
import 'package:example/injection.dart';
import 'package:flutter/material.dart';

void main() {
  // runZonedGuarded cria uma "zona" que captura erros assíncronos que
  // escapariam de tudo (ex.: falhas durante o bootstrap, fora de um await tratado).
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      setupLocator(); // dependências prontas antes da UI subir

      // 1) Erros do framework Flutter (build, layout, paint).
      FlutterError.onError = (FlutterErrorDetails details) {
        log(
          'FlutterError',
          name: 'app',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // 2) Erros assíncronos que chegam ao motor (futures sem tratamento, etc.).
      //    Retornar true diz "eu tratei", evitando o crash padrão.
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        log('PlatformDispatcher', name: 'app', error: error, stackTrace: stack);
        return true;
      };

      runApp(const AppWidget());
    },
    // 3) Rede final: o que escapou das duas anteriores cai aqui.
    (Object error, StackTrace stack) {
      log('Uncaught zone error', name: 'app', error: error, stackTrace: stack);
    },
  );
}
```

Como as três camadas se encaixam:

- **`FlutterError.onError`** pega erros **dentro do framework** (um `build` que estourou, um overflow de layout que virou exceção).
- **`PlatformDispatcher.instance.onError`** pega erros **assíncronos** que não foram tratados e subiram até o motor do Flutter.
- **`runZonedGuarded`** é a **rede final**: erros que acontecem fora do ciclo do framework (ex.: durante o `setupLocator`) caem no callback de erro da zona. *Importante:* o `WidgetsFlutterBinding.ensureInitialized()` e o `runApp` precisam rodar **dentro** da mesma zona, por isso estão no corpo do `runZonedGuarded`.

> **Por que `log()` do `dart:developer` aqui.** Para não amarrar o guia a um serviço específico. O `log` aparece no DevTools/console com `error` e `stackTrace` estruturados. **Em produção, troque o corpo de cada callback** por `FirebaseCrashlytics.instance.recordError(error, stack)` (ou Sentry). O *ponto de instalação* (os três callbacks no `main`) não muda; só o destino do log muda.

> **Complemento (bloc).** Erros lançados **dentro** de um `Cubit`/`Bloc` podem ser centralizados com um `BlocObserver` global (`Bloc.observer = AppBlocObserver()`), cujo `onError` faz o mesmo `log`/`recordError`. É a quarta porta de entrada, específica do estado.

### `injection.dart`: o service locator (raiz)

A raiz **não conhece as implementações**: ela só chama a função de registro **pública** de cada módulo. Cada módulo é dono dos seus registros.

```dart
import 'package:get_it/get_it.dart';

import 'modules/catalog_module/catalog_module.dart'; // barrel público do módulo

final getIt = GetIt.instance;

void setupLocator() {
  registerCatalogModule(getIt);
  // registerOrdersModule(getIt);     // exercício
  // registerCustomersModule(getIt);  // exercício
}
```

Repare: o `injection.dart` importa o **barrel público** do catálogo e enxerga **só** `registerCatalogModule`. Ele **não** consegue importar `ProductRepositoryImpl`, porque o barrel não a exporta. A implementação fica trancada dentro do módulo.

### `app_widget.dart`: `MaterialApp.router`

```dart
import 'package:example/app_router.dart';
import 'package:flutter/material.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRoutes,
      title: 'Painel da Loja',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    );
  }
}
```

Use `MaterialApp.router` (não `MaterialApp`) para habilitar a navegação declarativa do `go_router`.

### `app_router.dart`: configuração do `go_router`

```dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'modules/catalog_module/catalog_module.dart'; // barrel público
// import 'modules/orders_module/orders_module.dart';      // exercício (§14)
// import 'modules/customers_module/customers_module.dart'; // exercício (§14)

// Navigator raiz: usado quando uma rota precisa cobrir o shell (ver §10).
final rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRoutes = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/products',
  routes: [
    // O shell é a navegação RAIZ: NavigationBar fixa + uma branch por aba.
    // Cada branch tem o seu próprio navigator e preserva pilha + estado.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [CatalogRoutes.route]),
        // StatefulShellBranch(routes: [OrdersRoutes.route]),     // exercício
        // StatefulShellBranch(routes: [CustomersRoutes.route]),  // exercício
      ],
    ),
  ],
);
```

O router importa só os **barrels públicos** e usa só as **rotas**, sem acesso a páginas, cubits ou repositórios. O `MainShell` (a `NavigationBar` persistente) e os **cuidados do shell** estão na [§10](#10-shell-de-navegação-com-statefulshellroute).

---

## 6. O padrão central: `pageBuilder`

O coração da arquitetura. Queremos que cada tela tenha seu **estado** (cubit) criado e iniciado ao montar, **sem** que o roteamento conheça esses detalhes.

A solução: um método estático na página que cria o cubit (puxando os serviços do `get_it`) e devolve o widget já no `BlocProvider`.

```dart
static Widget pageBuilder(BuildContext context, GoRouterState state) {
  return BlocProvider(
    create: (_) => ProductListCubit(getAllProducts: getIt<GetAllProductsUseCase>())..load(),
    child: const ProductListPage(),
  );
}
```

O `get_it` **enxuga** este ponto: a página declara **só o seu estado**; o repositório (singleton compartilhado) e o use case vêm de `getIt()`. O que isso traz:

- **Encapsulamento**: a tela cuida de si; o resto do app só conhece o nome da rota.
- **Deep link de fábrica**: abrir a rota direto monta o cubit do zero; serviços já estão no locator.
- **Rotas limpas** e **carga sem `initState`** (o `..load()` no `create`).
- **Dispose automático**: o `BlocProvider` fecha o cubit ao sair da árvore ([§16](#16-economia-de-recursos-o-que-é-real-e-o-que-não-é)).

---

## 7. Módulo de catálogo (completo)

Vamos construir o módulo de baixo para cima: domínio → dados → apresentação → fiação. **Cada pasta termina com seu barrel.** E é aqui que introduzimos o `fpdart` e o `zard`, mostrando primeiro o código **sem** eles, depois **com**.

### 7.1 Domínio: entidade

```dart
// domain/entities/product.dart
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
  });

  /// Regra de domínio: disponível para venda.
  bool get inStock => stock > 0;

  @override
  List<Object> get props => [id, name, description, price, stock];
}
```

Entidade **imutável**, `Equatable`, **sem `fromMap`/`toMap`** (parsing é do data). O getter `inStock` é uma regrinha de negócio que vive no domínio e é reusada por qualquer tela.

```dart
// domain/entities/entities.dart  (barrel)
export 'product.dart';
// Tudo aqui é público para o módulo: entidades são o vocabulário do domínio.
```

### 7.2 Domínio: contrato do repositório (introduzindo `fpdart`)

Aqui está a primeira decisão de erro. Vou mostrar as **duas** formas.

**Sem `fpdart` (o jeito comum, com `try/catch`).** O contrato devolve o valor direto e o erro vira **exceção**:

```dart
// ❌ versão sem fpdart: o erro NÃO está na assinatura
abstract interface class ProductRepository {
  Future<List<Product>> getAllProducts();          // pode lançar... o quê? não dá pra saber
  Future<Product> getProductById(int id);          // idem
}
```

O problema: a assinatura **mente por omissão**. Nada ali avisa que isso pode falhar, nem com qual erro. Quem consome é **obrigado a lembrar** de envolver em `try/catch`, e se esquecer, a exceção sobe e (no melhor caso) cai na captura global; no pior, quebra a tela. O compilador **não ajuda**.

**Com `fpdart` (o erro na assinatura).** O retorno é `Either<Failure, T>`: `Left` é a falha, `Right` é o sucesso.

```dart
// ✅ versão com fpdart: o erro É parte do contrato
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<Either<Failure, List<Product>>> getAllProducts();
  Future<Either<Failure, Product>> getProductById(int id);
}
```

Agora a assinatura **diz a verdade**: "isto pode te dar uma `List<Product>` **ou** uma `Failure`". O consumidor é **forçado pelo compilador** a tratar os dois lados (via `fold`/`switch`), não há como esquecer. **A partir daqui, todo contrato do guia usa `Either`.**

```dart
// domain/repositories/repositories.dart  (barrel)
export 'product_repository.dart';
// Exportamos só o CONTRATO (a abstração). A implementação vive no data e
// jamais é exportada para fora do módulo (ver 7.5).
```

### 7.3 Domínio: use cases

```dart
// domain/use_cases/get_all_products_use_case.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetAllProductsUseCase {
  final ProductRepository repository;
  const GetAllProductsUseCase({required this.repository});

  Future<Either<Failure, List<Product>>> call() async {
    final result = await repository.getAllProducts();
    // `map` opera só no Right: se for Left (Failure), passa direto.
    return result.map((products) => products.toList()
      ..sort((a, b) {
        if (a.inStock != b.inStock) return a.inStock ? -1 : 1;
        return a.name.compareTo(b.name);
      }));
  }
}
```

Repare na elegância: a ordenação (regra do catálogo) roda **só no caminho de sucesso**, via `map` do `Either`. Não há `try/catch`, não há `if (erro)`: se veio `Left`, ele atravessa intacto. É o `fpdart` pagando por si.

```dart
// domain/use_cases/get_product_by_id_use_case.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductByIdUseCase {
  final ProductRepository repository;
  const GetProductByIdUseCase({required this.repository});

  Future<Either<Failure, Product>> call(int id) => repository.getProductById(id);
}
```

> `GetAllProductsUseCase` **tem regra** (a ordenação), a camada se justifica. `GetProductByIdUseCase` só repassa: é **anêmico**. Mantemos por simetria, mas não crie use case por dogma ([§13c](#c-quando-o-use-case-vale-a-pena)).

```dart
// domain/use_cases/use_cases.dart  (barrel)
export 'get_all_products_use_case.dart';
export 'get_product_by_id_use_case.dart';
```

### 7.4 Dados: model (introduzindo `zard`)

O model espelha a entidade e adiciona **(de)serialização**. É aqui que o app conhece o formato de transporte, e onde dados malformados precisam ser barrados.

**Sem `zard` (o `fromMap` manual).** Casts diretos:

```dart
// ❌ versão sem zard: cast cru, estoura em dados inesperados
factory ProductModel.fromMap(Map<String, dynamic> map) {
  return ProductModel(
    id: map['id'] as int,                         // se vier null/String -> TypeError cru
    name: map['name'] as String,
    description: map['description'] as String,
    price: (map['price'] as num).toDouble(),
    stock: map['stock'] as int,
  );
}
```

O problema: se a API mudar um campo, mandar `null`, ou trocar `int` por `String`, o `as` lança um **`TypeError` cru**, sem dizer **qual** campo, e sem virar uma `Failure` tratável. Você descobre o bug no Crashlytics, não no código.

**Com `zard` (validação de schema no limite do data).** Definimos um **schema** e validamos; o que sai já é confiável, e o erro é **estruturado**:

```dart
// ✅ versão com zard: valida e descreve o erro
import 'package:zard/zard.dart';

import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.stock,
  });

  // O schema descreve a forma esperada do payload, uma vez, declarativamente.
  static final _schema = z.map({
    'id': z.int(),
    'name': z.string().min(1),
    'description': z.string(),
    'price': z.doubleType(),
    'stock': z.int().min(0),
  });

  /// Valida e converte. Em payload inválido, `safeParse` reporta o erro
  /// (campo + motivo) em vez de estourar um cast cru.
  static Either<Failure, ProductModel> tryParse(Map<String, dynamic> map) {
    final result = _schema.safeParse(map);
    if (!result.success) {
      return Left(ValidationFailure(result.error.toString()));
    }
    final data = result.data!;
    return Right(ProductModel(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      price: data['price'],
      stock: data['stock'],
    ));
  }
}
```

**Sobre o `zard`: a ressalva honesta.** Ele é um package **jovem e de nicho** no ecossistema Dart; o resto da nossa stack é consolidado. Em compensação, é um **port do [Zod](https://zod.dev)** (a biblioteca de validação de schema **amplamente adotada no JavaScript/TypeScript**), então o paradigma (schema declarativo, `parse`/`safeParse`, erros descritivos) é maduro e familiar, mesmo que a implementação Dart seja recente. Confira a API atual no [pub.dev](https://pub.dev/packages/zard), que ainda evolui. **Recomendação:** se você quer robustez contra payloads ruins (e já gosta do Zod), vale; se prefere zero dependências novas no `data`, o `fromMap` manual com `Either` (mapeando o `catch` para `ValidationFailure`) entrega 80% do valor. Daqui em diante o guia assume `zard` no limite de dados, mas o padrão `Either` é o que de fato importa.

```dart
// data/models/models.dart  (barrel, INTERNO)
export 'product_model.dart';
// Barrel interno: o ProductModel é detalhe do data. O barrel PÚBLICO do
// módulo (7.6) NÃO reexporta este, nada fora do módulo monta DTOs.
```

### 7.5 Dados: implementação do repositório

```dart
// data/repositories/product_repository_impl.dart
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/models.dart';

class ProductRepositoryImpl implements ProductRepository {
  // Simula o payload cru de uma API (JSON desserializado em Map).
  static const List<Map<String, dynamic>> _raw = [
    {'id': 1, 'name': 'Teclado mecânico', 'description': 'Switches marrons, ABNT2, RGB.', 'price': 349.90, 'stock': 12},
    {'id': 2, 'name': 'Mouse sem fio', 'description': '2.4 GHz, 6 botões.', 'price': 129.90, 'stock': 0},
    {'id': 3, 'name': 'Monitor 27"', 'description': 'IPS, 144 Hz, 1440p.', 'price': 1599.00, 'stock': 5},
  ];

  @override
  Future<Either<Failure, List<Product>>> getAllProducts() async {
    await Future.delayed(const Duration(seconds: 1)); // simula latência
    // Valida cada item; se UM falhar, retorna a falha (curto-circuito).
    final products = <Product>[];
    for (final map in _raw) {
      final parsed = ProductModel.tryParse(map);
      if (parsed.isLeft()) {
        return parsed.map((r) => <Product>[]); // propaga o Left
      }
      products.add(parsed.getRight().toNullable()!);
    }
    return Right(products);
  }

  @override
  Future<Either<Failure, Product>> getProductById(int id) async {
    await Future.delayed(const Duration(seconds: 1));
    final map = _raw.where((p) => p['id'] == id).firstOrNull;
    if (map == null) return const Left(NotFoundFailure());
    return ProductModel.tryParse(map).map((model) => model);
  }
}
```

Sem `try/catch`: erros viram `Left(Failure)` explicitamente. Para uma API real, troque o `_raw` por um `Dio`/`http.Client`, **mantendo a assinatura**: use cases, cubits e UI continuam intactos. Como o repositório será um **singleton** ([7.7](#77-fiação-rotas-injeção-e-o-barrel-público)), é o lugar natural para um cache compartilhado.

```dart
// data/repositories/repositories.dart  (barrel, INTERNO!)
export 'product_repository_impl.dart';
// ATENÇÃO: barrel interno. Só o catalog_injection.dart (dentro do módulo)
// importa daqui. O barrel PÚBLICO do módulo (7.7) NUNCA reexporta a impl,
// se exportasse, outro módulo poderia instanciar o repositório à revelia da DI.
```

### 7.6 Apresentação: estado e página (com `fpdart` no cubit)

```dart
// presentation/product_list/cubit/product_list_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/error/error.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/use_cases/use_cases.dart';

part 'product_list_state.dart';

class ProductListCubit extends Cubit<ProductListState> {
  final GetAllProductsUseCase getAllProducts;

  ProductListCubit({required this.getAllProducts})
      : super(const ProductListLoading());

  Future<void> load() async {
    emit(const ProductListLoading());
    final result = await getAllProducts(); // Either<Failure, List<Product>>
    if (isClosed) return; // a tela pode ter fechado durante o await
    emit(result.fold(
      (failure) => ProductListError(failure: failure),
      (products) => ProductListLoaded(products: products),
    ));
  }
}
```

Compare com o que **seria sem `fpdart`**: um `try { ... } catch (e) { emit(...e.toString()) }`, com você responsável por lembrar do `catch`, por mapear `e` para algo apresentável, e ainda assim sem garantia de ter coberto tudo. Com `Either`, o `fold` **obriga** os dois lados e o estado de erro carrega um `Failure` **tipado**: a UI decide a mensagem/ação por tipo.

> **Guarda `isClosed`.** Continua obrigatória: depois do `await`, a tela pode ter sido desmontada e o cubit fechado; um `emit` em cubit fechado lança `StateError`. O `fpdart` resolve o *tratamento de erro de domínio*, não o *ciclo de vida*: são coisas distintas.

```dart
// presentation/product_list/cubit/product_list_state.dart
part of 'product_list_cubit.dart';

sealed class ProductListState extends Equatable {
  const ProductListState();
  @override
  List<Object> get props => [];
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

final class ProductListLoaded extends ProductListState {
  final List<Product> products;
  const ProductListLoaded({required this.products});
  @override
  List<Object> get props => [products];
}

final class ProductListError extends ProductListState {
  final Failure failure;
  const ProductListError({required this.failure});
  @override
  List<Object> get props => [failure];
}
```

> **`Equatable` é essencial aqui.** `ProductListLoaded` declara `props => [products]`, e o `Equatable` compara a lista item a item pelo `==` de `Product`. Se `Product` **não** fosse `Equatable`, dois `Loaded` com dados idênticos (instâncias recriadas a cada `load()`) seriam "diferentes", e o `BlocBuilder` reconstruiria à toa. É o `equatable` que faz a promessa "não reconstrói com estado igual" ser verdadeira.

```dart
// presentation/product_list/product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/error.dart';
import '../../../../injection.dart';
import 'cubit/product_list_cubit.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  static Widget pageBuilder(BuildContext context, GoRouterState state) {
    return BlocProvider(
      create: (_) => ProductListCubit(getAllProducts: getIt<GetAllProductsUseCase>())..load(),
      child: const ProductListPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: BlocBuilder<ProductListCubit, ProductListState>(
        builder: (context, state) {
          return switch (state) {
            ProductListLoading() =>
              const Center(child: CircularProgressIndicator()),
            ProductListError(:final failure) =>
              Center(child: Text(_messageFor(failure))),
            ProductListLoaded(:final products) => ListView.builder(
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final product = products[i];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('R\$ ${product.price.toStringAsFixed(2)}'),
                    trailing: product.inStock
                        ? null
                        : const Text('Esgotado', style: TextStyle(color: Colors.red)),
                    onTap: () => context.pushNamed(
                      'product-details',
                      pathParameters: {'id': product.id.toString()},
                    ),
                  );
                },
              ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<ProductListCubit>().load(),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // A UI escolhe a mensagem por TIPO de falha, graças ao Failure tipado.
  String _messageFor(Failure failure) => switch (failure) {
        NetworkFailure() => 'Sem conexão. Tente de novo.',
        NotFoundFailure() => 'Nada encontrado.',
        ValidationFailure() => 'Recebemos dados inesperados do servidor.',
        UnexpectedFailure() => 'Algo deu errado.',
      };
}
```

Pontos a observar:

- **Imports enxutos**: só `flutter_bloc`, `go_router`, o cubit, o `error` e o `injection`. Sumiram os imports da impl do repositório e dos use cases concretos: tudo vem do locator.
- **`switch` sobre `Failure`**: o `sealed` garante que toda falha tem mensagem. Adicionar uma `Failure` nova quebra a compilação até você tratá-la na UI. É o tipo trabalhando a seu favor.
- **`context.read`** vem do `flutter_bloc` (sem precisar de `provider`).

```dart
// presentation/product_list/product_list.dart  (barrel)
export 'product_list_page.dart';
// Exporta só a PÁGINA. O cubit e o state são detalhe interno da tela,
// montados pelo pageBuilder, nunca importados de fora.
```

A página de detalhes segue o mesmo molde (estado `sealed`, `pageBuilder`, `Either` no cubit), com o cuidado extra do **deep link malformado**:

```dart
// presentation/product_details/product_details_page.dart  (trecho do pageBuilder)
static Widget pageBuilder(BuildContext context, GoRouterState state) {
  // int.tryParse evita FormatException em /products/details/abc.
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null) return const _InvalidProductScreen();

  return BlocProvider(
    create: (_) => ProductDetailsCubit(getProductById: getIt<GetProductByIdUseCase>())..load(id),
    child: const ProductDetailsPage(),
  );
}
```

> **`tryParse`, não `parse`.** `int.parse('abc')` lança `FormatException` durante a montagem da rota, falha feia justo no cenário que o padrão promete (abrir a URL direto). `tryParse` + fallback mantém o deep link robusto. (`_InvalidProductScreen` é o helper privado pequeno que mora no mesmo arquivo, exceção legítima à regra "uma classe por arquivo".)

```dart
// presentation/presentation.dart  (barrel)
export 'product_list/product_list.dart';
export 'product_details/product_details.dart';
// Só as páginas. Nenhum cubit/estado cruza esta fronteira.
```

### 7.7 Fiação: rotas, injeção e o **barrel público**

Três arquivos finais amarram o módulo e definem **exatamente** o que ele expõe.

```dart
// catalog_routes.dart: as rotas do módulo
import 'package:go_router/go_router.dart';

import 'presentation/presentation.dart';

class CatalogRoutes {
  static GoRoute get route => GoRoute(
        path: '/products',
        name: 'products',
        builder: ProductListPage.pageBuilder,
        routes: [
          GoRoute(
            path: 'details/:id',
            name: 'product-details',
            builder: ProductDetailsPage.pageBuilder,
          ),
        ],
      );
}
```

```dart
// catalog_injection.dart: o registro de DI do módulo
import 'package:get_it/get_it.dart';

import 'data/repositories/repositories.dart';      // barrel INTERNO (impl)
import 'domain/repositories/product_repository.dart';
import 'domain/use_cases/use_cases.dart';

/// Registra as dependências do catálogo. Chamado pelo injection.dart raiz.
void registerCatalogModule(GetIt getIt) {
  // Repositório: lazy singleton, único e compartilhado, com cache num lugar só.
  getIt.registerLazySingleton<ProductRepository>(ProductRepositoryImpl.new);

  // Use cases: factory, baratos e sem estado.
  getIt.registerFactory(() => GetAllProductsUseCase(repository: getIt<ProductRepository>()));
  getIt.registerFactory(() => GetProductByIdUseCase(repository: getIt<ProductRepository>()));
}
```

Note que **este** arquivo, interno ao módulo, é o **único** que importa a implementação (`data/repositories/repositories.dart`) e a casa com a abstração. É o ponto onde o concreto encontra o contrato.

```dart
// catalog_module.dart: O BARREL PÚBLICO DO MÓDULO
export 'catalog_routes.dart';      // a rota, para o app_router
export 'catalog_injection.dart';   // o register, para o injection.dart raiz

// O QUE NÃO EXPORTAMOS, e por quê:
// - domain/, data/, presentation/  -> são internos; o mundo de fora não os toca.
// - ProductRepositoryImpl          -> ninguém de fora instancia o repositório (só a DI interna).
// - ProductModel                   -> DTO é detalhe do data.
// - ProductListCubit / *Page       -> montados pelo pageBuilder, nunca de fora.
//
// Resultado: de fora, o catálogo é uma caixa-preta com DUAS portas:
// "registre minhas dependências" e "aqui está minha rota". Nada mais vaza.
```

Esse é o pagamento do barrel: a fronteira do módulo não é só convenção de pasta, é **imposta pelo que o arquivo público escolhe (não) exportar**.

---

## 8. Domínio e dados: a regra que não pode vazar

Recapitulando a regra de ouro da Clean Architecture aqui, agora que vimos o código: **o domain nunca enxerga `Map`.** A entidade `Product` não tem `fromMap`; o contrato `ProductRepository` retorna `Either<Failure, Product>` (entidade), nunca JSON; o `ProductModel` (data) é quem conhece o formato de transporte e o valida (com `zard`). Troca-se mock por REST, GraphQL ou banco local mexendo **só no data**, porque nenhuma camada acima jamais viu o `Map`.

---

## 9. Erros em duas camadas: `fpdart` para os previstos

Já usamos os dois mecanismos; vale nomeá-los como **estratégia**:

| Camada | Cobre | Mecanismo | Quem "vê" |
|---|---|---|---|
| **Erros previstos** | Falhas de negócio/infra esperadas (rede caiu, não encontrado, payload inválido) | `Either<Failure, T>` + `Failure` `sealed` | O **usuário** (UI tratada por tipo) |
| **Erros imprevistos** | Bugs, estados impossíveis, exceções que escaparam | Captura global no `main` ([§5](#5-camada-base-do-app)) | O **dev** (log/Crashlytics) |

São **complementares**, não concorrentes. O `Either` torna o erro previsto **parte do contrato**: o compilador obriga a tratá-lo, e ele nunca chega à captura global. O que sobra para a captura global é o **genuinamente inesperado**, exatamente o que você quer ver num crash report. Um app maduro tem as duas; faltando qualquer uma, ou você vaza erro cru na UI, ou perde bug em silêncio.

---

## 10. Shell de navegação com `StatefulShellRoute`

A navegação principal do app é um **shell**: uma `NavigationBar` que fica **fixa** enquanto o conteúdo troca por aba. Em vez de uma `HomePage` com botões (um hub que seria só "mais um jeito de navegar"), a própria barra é o hub. Usamos `StatefulShellRoute.indexedStack`, que dá a cada aba o seu **próprio navigator**, com **pilha e estado preservados** ao alternar.

### O `MainShell`: o casco persistente

```dart
// app_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Casco visual fixo. A NavigationBar não se reconstrói ao trocar de aba;
/// o conteúdo da aba ativa é o próprio `navigationShell`.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // a branch ativa (um IndexedStack por baixo)
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Catálogo'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clientes'),
        ],
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Tocar de novo na aba JÁ ativa volta a aba à sua raiz (UX padrão).
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
```

O `navigationShell` faz o trabalho pesado: `currentIndex` diz a aba ativa, `goBranch(i)` troca de aba. O `builder` do `StatefulShellRoute.indexedStack` (no `app_router.dart`, [§5](#5-camada-base-do-app)) entrega esse objeto já pronto.

### O benefício: estado e pilha por aba

Este é o ganho que justifica o `indexedStack`: **cada aba lembra onde você estava.** Navegue até o detalhe de um produto no Catálogo, troque para Pedidos, volte para o Catálogo: você cai **de volta no detalhe**, com a rolagem e o estado intactos. É o comportamento que o usuário espera de um app com abas, e vem de graça: cada branch mantém o seu navigator vivo.

### Os cuidados (onde dá ruim se você não souber)

Shell tem armadilhas que valem mais que o exemplo feliz:

1. **`destinations` e `branches` precisam ter o mesmo número, e na mesma ordem.** A `NavigationBar` acima tem 3 destinos; logo o `StatefulShellRoute` precisa de 3 branches. Se você ainda não implementou Pedidos/Clientes (o exercício da [§14](#14-exercício-módulos-de-pedidos-e-clientes)), use uma rota *placeholder* por branch, senão `goBranch(2)` aponta para um índice que não existe e estoura em runtime. Índice e ordem são a fonte nº 1 de bug aqui.

2. **Detalhe dentro da aba × cobrindo o shell: você escolhe.** Como `/products/details/:id` é **subrota** de `/products` (dentro da branch do Catálogo, [§7.7](#77-fiação-rotas-injeção-e-o-barrel-público)), o detalhe empilha **dentro da aba** e a `NavigationBar` **continua visível**. É o padrão de apps com abas. Se você quiser que uma tela **cubra o shell** (checkout, câmera, um fluxo modal), declare-a no **navigator raiz**, passando a `parentNavigatorKey`:

   ```dart
   GoRoute(
     path: 'details/:id',
     parentNavigatorKey: rootNavigatorKey, // sobe ao navigator raiz: cobre a NavigationBar
     builder: ProductDetailsPage.pageBuilder,
   )
   ```

   Sem `parentNavigatorKey`, fica na branch (barra visível). É uma decisão de UX por rota: saber **onde** a rota é declarada é o que dá controle.

3. **Deep link tem que cair na branch certa.** Abrir `/orders/details/5` direto precisa **ativar a branch de Pedidos** e empilhar o detalhe nela. O `go_router` faz isso **se** a rota estiver declarada sob a branch correta. Tradução prática: cada módulo declara as suas rotas, e o shell as pendura na branch certa; declarou no lugar errado, o deep link abre na aba errada.

4. **Custo de memória: o preço do estado preservado.** O `IndexedStack` **constrói a branch no primeiro acesso e a mantém viva** depois. É exatamente isso que preserva o estado da aba, e é também memória **retida**: abas já visitadas não sofrem dispose enquanto você está no shell. Trade-off consciente (UX × memória), e uma exceção honesta ao "dispose automático" da [§16](#16-economia-de-recursos-o-que-é-real-e-o-que-não-é): o estado de tela **dentro** de uma branch ativa não é descartado ao trocar de aba, só ao sair do shell.

> **A forma simples: `ShellRoute` (sem estado por aba).** Se as abas **não** precisam preservar pilha/estado (ao voltar para uma aba, tudo bem ela reiniciar na raiz), o `ShellRoute` "puro" é mais simples: um único navigator, sem branches. Troca o casco e reconstrói o conteúdo. Use-o para um drawer/app bar fixos sobre telas que não têm o que lembrar. Para abas de verdade (o caso comum), `StatefulShellRoute.indexedStack` é o que entrega a experiência esperada, por isso é o **padrão deste guia**.

---

## 11. Navegação com go_router: qual método usar

| Método | Comportamento | Quando usar |
|---|---|---|
| `context.go(path)` / `goNamed(name)` | Substitui a pilha | Redirecionamentos, splash → login, troca de aba raiz |
| `context.push(path)` / `pushNamed(name)` | Empilha (permite voltar) | Telas de detalhe, fluxos com "voltar" |

**Prefira as variantes `*Named`**, que desacoplam módulos: você navega de qualquer lugar passando `pathParameters`/`queryParameters` sem conhecer a estrutura interna do destino.

> **Strings mágicas, não.** Em escala, centralize os nomes em constantes (`AppRoutes.productDetails`) e exponha helpers (`AppRoutes.goToProductDetails(context, id)`). Sem `go_router_builder` (code-gen), essa é a forma "sem build_runner" de tirar as strings cruas do meio do código.

### Armadilha: subrota também monta a rota-pai

`context.go('/products/details/1')` monta **o pai antes da filha** (a `ProductListPage` e depois a `ProductDetailsPage`), disparando um `load()` redundante na lista. Dois cenários, respostas diferentes:

1. **Navegação interna** → use `push`/`pushNamed`: empilha **só o destino**.
2. **Deep link real** (abrir a URL/recarregar no Web) → você não controla: o `go_router` precisa montar o pai para a pilha do "voltar" fazer sentido. Saídas: **(a)** declarar os detalhes como rota **irmã** top-level (sem pai, nada redundante; "voltar" não cai na lista), ou **(b)** tornar o pai **barato e idempotente**, e aqui o **repositório singleton** com cache faz o `load()` redundante servir do cache. Um guard no cubit ("já tenho dados? não recarrego") fecha de vez.

> O casco persistente (`NavigationBar` fixa, estado por aba) e seus cuidados estão na [§10](#10-shell-de-navegação-com-statefulshellroute), é o padrão de navegação deste guia.

---

## 12. Injeção de dependências: quem localiza, quem injeta

Dois mecanismos, cada um no seu lugar:

- **`get_it` localiza serviços de vida longa** (repositórios, datasources, use cases, `Session`), sem `BuildContext`.
- **`BlocProvider` provê o estado de tela** (o cubit), atrelado à árvore, criado ao montar, descartado ao desmontar.

> **Regra de ouro do `get_it`.** Use o locator **só no ponto de montagem** (o `pageBuilder` / a factory do cubit). As classes **nunca** chamam `getIt<T>()` por dentro: recebem tudo por **construtor**. O locator *localiza*; o construtor *injeta*. Assim os testes instanciam com mocks sem tocar no locator, e o "service locator vira saco de tudo" não acontece.

```dart
// ✅ CERTO: locator só no ponto de montagem.
create: (_) => ProductListCubit(getAllProducts: getIt<GetAllProductsUseCase>())..load(),

// ❌ ERRADO: cubit chamando o locator por dentro (acopla, esconde dependência,
// quebra teste). Revisável em PR com: grep "getIt<" fora dos *_page.dart.
class ProductListCubit extends Cubit<ProductListState> {
  Future<void> load() async {
    final r = await getIt<GetAllProductsUseCase>()(); // não faça isto
  }
}
```

Essa é a única regra que o time precisa internalizar para o `get_it` escalar sem virar bagunça.

> **Convenção: tipe a resolução.** Escreva sempre `getIt<GetAllProductsUseCase>()`, nunca o `getIt()` "pelado". O Dart **consegue** inferir o tipo pelo contexto (o parâmetro do construtor já é tipado), mas o explícito é melhor por três razões: ele **se autodocumenta** (você lê o que está sendo resolvido sem caçar a assinatura), é **seguro a refactor** (se o tipo do parâmetro mudar, o `getIt()` inferido segue em silêncio para o novo tipo e pode resolver o registro errado; o explícito reclama) e **nunca quebra fora de contexto** (`var x = getIt();` resolve `Object` e estoura em runtime). O custo é um par de `<>`; o ganho é uma resolução sem mágica.

---

## 13. Variações e armadilhas em produção

### a) Scope de sessão: registrar no login, descartar no logout

Serviços do usuário autenticado nascem no login e **morrem no logout**. O `get_it` faz com **scopes**:

```dart
getIt.pushNewScope(
  scopeName: 'session',
  init: (gi) => gi.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(token: ...)),
  dispose: () { /* fechar conexões, limpar cache do usuário */ },
);
// No logout: descarta tudo do escopo numa linha.
getIt.dropScope('session');
```

É **aqui** (e só aqui) que existe "dispose modularizado" de serviços ([§16](#16-economia-de-recursos-o-que-é-real-e-o-que-não-é)).

### b) `Either` x exceção: onde fica a fronteira

Adotamos `Either` nos **contratos de domínio**. Exceções não somem do mundo, elas existem na borda (um `Dio` lança `DioException`). A regra: **a camada `data` é o tradutor** que captura a exceção da infra e a converte em `Left(Failure)`. Acima do `data`, ninguém mais vê exceção; todo mundo vê `Either`. É o que mantém o `try/catch` confinado a um único lugar.

### c) Quando o use case vale a pena

Use case que só repassa o repositório é boilerplate. A camada se justifica com **regra de negócio** (orquestrar, validar, transformar), como a ordenação de `GetAllProductsUseCase` ou um `PlaceOrderUseCase`. Sem regra, é legítimo o cubit chamar o repositório direto (resolvido pelo `getIt`). Não adicione a camada por dogma.

---

## 14. Exercício: módulos de Pedidos e Clientes

Replique o módulo de catálogo. **Módulo de Pedidos** (`/orders`, subrota `details/:id`): entidade `Order` + `OrderItem`; contrato `OrderRepository` retornando `Either<Failure, T>`; `OrderRepositoryImpl` mockado com `OrderModel` validado por `zard`; use case **com regra de verdade** (`PlaceOrderUseCase` validando estoque, calculando total/desconto); páginas com `pageBuilder`; cubits com estado `sealed`, `Either` e guarda `isClosed`. Não esqueça os **barrels** de cada pasta e o **barrel público** expondo só `OrdersRoutes` + `registerOrdersModule`. **Módulo de Clientes** (`/customers`): mesma receita, mais simples. Por fim, registre as rotas no `app_router.dart` (uma branch do shell por módulo) e os módulos no `injection.dart`.

---

## 15. Robustez e escala: o que é estrutural e o que depende de disciplina

Vou ser direto: esta arquitetura escala, mas parte disso vem de graça e parte depende de você manter a disciplina. Separo as duas, porque vender só a primeira metade seria desonesto.

**Escala sozinho (estrutural):** crescimento **linear** por módulo (nova pasta + uma rota + um register; nunca tocar no existente); camadas com dependência só pra dentro (troca de fonte de dados não sobe); desacoplamento por nome de rota; **barrels** impondo a fronteira de cada módulo; estado previsível pela prescritividade do bloc.

**Depende de disciplina (seja honesto com o time):**

- **O `get_it` é o ponto de falha de escala.** Sem a regra de ouro ([§12](#12-injeção-de-dependências-quem-localiza-quem-injeta)), degenera num registro global gigante. Com ela, escala bem. Exige cultura, não só código.
- **"Módulo" aqui é convenção de pasta, reforçada por barrel, não package isolado.** O barrel **desencoraja** importar o interno de outro módulo, mas não **impede** fisicamente (dá para furar importando o caminho completo do arquivo). Em times grandes onde isso vira problema, o próximo passo é promover cada módulo a um **package** do workspace (fronteira que o compilador faz cumprir), fora do escopo aqui.
- **Sem code-gen tem custo recorrente**: `copyWith` manual, registro de DI manual, schemas `zard` à mão. Previsível e barato, mas existe.

Veredito: base **robusta e honesta para grande porte**, contanto que o time abrace a regra de ouro do `get_it` e respeite os barrels. Não é "robusto mágico", é "robusto se você mantém a fronteira".

---

## 16. Economia de recursos: o que é real e o que não é

A economia existe, mas vem de **dois mecanismos**, e um terceiro que muita gente **assume e não acontece**.

**Real (e automático):**

- **Lazy: paga só pelo que abre.** Tela não visitada não instancia cubit; `registerLazySingleton` só cria o serviço no primeiro `getIt()`. Um app de 30 módulos não carrega 30 módulos.
- **Dispose automático do estado de tela.** O `BlocProvider` chama `close()` no cubit ao sair da árvore: streams cancelam, listeners liberam. Você **não acumula** cubits de telas fechadas.

**NÃO acontece (a correção):**

- **Serviços singleton no `get_it` NÃO sofrem dispose ao sair do módulo.** Vivem o app inteiro **de propósito**, é cache compartilhado, não vazamento. O **estado de tela** é descartado (bloc); os **serviços** persistem.
- **Dispose de serviços por módulo/sessão é opt-in, via scopes** ([§13a](#a-scope-de-sessão-registrar-no-login-descartar-no-logout)).
- **Um shell (`StatefulShellRoute.indexedStack`) mantém as abas visitadas vivas.** Trocar de aba não descarta a branch (é o que preserva o estado dela, [§10](#10-shell-de-navegação-com-statefulshellroute)); o dispose do estado de tela vale ao **sair** do shell, não ao alternar abas.

| Recurso | Quem cria | Quando é descartado |
|---|---|---|
| Cubit/estado da tela | `BlocProvider` no `pageBuilder` | Automático, ao sair da tela (`close()`) |
| Estado de uma aba do shell | branch do `StatefulShellRoute` | Ao sair do shell, não ao trocar de aba |
| Use case (factory) | `getIt()` no ponto de montagem | Nada a descartar (sem estado) |
| Repositório/serviço (singleton de app) | `registerLazySingleton` | Vive o app todo (intencional) |
| Serviço de sessão (singleton de scope) | `pushNewScope` no login | `dropScope` no logout (opt-in) |

A frase honesta: **a economia vem do lazy + do dispose automático do estado de tela.** Os serviços são persistência intencional. Prometa isso, e o app entrega; prometa "dispose de tudo ao trocar de módulo", e você está mentindo para o leitor.

---

## Resumo

| Conceito | O que resolve |
|---|---|
| **Stack `go_router` + `get_it` + `bloc`** | Uma responsabilidade por package, fronteira sem sobreposição |
| **Convenções declaradas no topo** | Um jeito certo de fazer cada coisa |
| **Barrel como API pública do módulo** | Fronteira imposta pelo que (não) se exporta |
| **Módulos domain/data/presentation** | Escala linear e separação de responsabilidades |
| **Contrato retorna `Either<Failure, entidade>`; DTO no data** | Domínio puro; erro no contrato; nunca vê `Map` |
| **`get_it` localiza, construtor injeta (regra de ouro)** | DI sem `BuildContext`, sem virar "saco de tudo" |
| **`pageBuilder` cria só o cubit** | Tela injeta seu estado; rota fica limpa |
| **Shell `StatefulShellRoute.indexedStack`** | Abas com pilha e estado próprios; cuidados na §10 |
| **`fpdart Either` (erros previstos)** | Compilador obriga a tratar; nada vaza cru na UI |
| **Captura global no `main` (erros imprevistos)** | Nada morre em silêncio; pronto para Crashlytics |
| **`zard` no limite do data** *(opcional)* | Valida payload; erro descritivo em vez de cast cru |
| **`equatable`** | Dedupe de rebuild do estado funciona de verdade |
| **`registerLazySingleton` + scopes** | Lazy; scope dá dispose de sessão (opt-in) |
| **Guarda `isClosed` antes de `emit`** | Evita `StateError` quando a tela fecha no `await` |
| **`Cubit` + estados `sealed`** | Estado simples, previsível, exaustivo |

Um app modular, baixo acoplamento, domínio limpo, erros em duas camadas, pronto para deep links e fácil de testar, escalável para grande porte **enquanto o time mantém a regra de ouro do `get_it` e os barrels**, só com pacotes consolidados (o `zard` é a única aposta mais nova, e opcional), sem um único `.g.dart`.

---

## 17. Versões de referência (junho de 2026)

| Package | Versão | Observação |
|---|---|---|
| `go_router` | **17.3.0** | `onException`, `redirect`+`refreshListenable`, `StatefulShellRoute.indexedStack`. SDK mín. Flutter 3.38 / Dart 3.10. |
| `get_it` | **9.2.1** | Scopes, async singletons, lazy singletons. |
| `flutter_bloc` / `bloc` | **9.1.1 / 9.2.1** | `Bloc.observer` + `MultiBlocObserver` para observabilidade. |
| `equatable` | **2.0.8** | Estados/eventos `sealed` e value objects. |
| `fpdart` | **1.2.0** | `Either<Failure, T>` sem code-gen. |
| `zard` | *ver pub.dev* | Port do [Zod](https://zod.dev); jovem, confira a API atual. |
| `provider` | **6.1.5+1** | Só como dependência transitiva do `flutter_bloc`. |
| `injectable` / `freezed` / `go_router_builder` | n/a | Exigem `build_runner`, **fora da premissa**. |

## 18. Próximos capítulos (sem `build_runner`)

- **Testes**: `bloc_test` + `mocktail` (mocks injetados por construtor, graças à regra de ouro);
- **Observabilidade**: `Bloc.observer` global ligado à captura do `main` (logging + crash reporting);
- **Navegação avançada**: auth guards via `redirect` + `refreshListenable`, `StatefulShellRoute.indexedStack`, `onException`, rotas por constantes + helpers;
- **Imutabilidade**: `sealed` nativa + `equatable`; entidades com `copyWith` **manual** (o preço de dispensar `freezed`).
