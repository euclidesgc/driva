# Arquitetura Flutter modular para grande porte

go_router, get_it e bloc, sem `build_runner`

*Um guia prático, do primeiro arquivo ao deploy, para construir apps Flutter robustos, modulares e escaláveis com fronteiras claras.*

por Euclides Catunda

---

## Créditos

**Arquitetura Flutter modular para grande porte.** Primeira edição, 2026.

© 2026 Euclides Catunda. Todos os direitos reservados.

Os nomes de bibliotecas, ferramentas e produtos citados pertencem aos seus respectivos donos. As versões usadas como referência estão na [seção 28](#28-versões-de-referência-junho-de-2026).

Encontrou um erro, tem uma dúvida ou uma sugestão? Fale comigo em [linkedin.com/in/euclidesgc](https://www.linkedin.com/in/euclidesgc/).

---

## Epígrafe

> "Qualquer tolo escreve código que um computador entende. Bons programadores escrevem código que outras pessoas entendem."
>
> Martin Fowler

---

## Prefácio

A maior parte do material de Flutter te deixa ali, num app de contador: um botão, um número que sobe, e a sensação de que você já domina arquitetura. Aí chega o app de verdade, com dezenas de telas, um time mexendo no mesmo código e um prazo, e a conta não fecha. O que faltava nunca foi saber widget; era saber onde cada coisa mora, e por quê.

Este livro preenche esse vão. Ele mostra, do primeiro arquivo ao deploy, como montar a arquitetura de um app Flutter de grande porte com fronteiras claras, sem geração de código, sobre pacotes consolidados: `go_router` para navegar, `get_it` para injetar, `bloc` para o estado e `fpdart` para o erro previsto. Em uma frase: uma arquitetura difícil de furar, que cresce somando módulos sem você tocar no que já existe.

Eu o escrevi a partir de prática, não de teoria. Cada decisão aqui apanhou em algum app real antes de virar regra, e cada regra vem com a ressalva honesta de onde ela deixa de valer. Porque "robusto" sem ressalva é marketing, não engenharia, e eu prefiro te entregar o mapa com os buracos já marcados.

---

## Para quem é este livro

Para quem já desenvolve aplicativos usando Flutter e quer dar o próximo passo: sair do app que funciona para o app que sustenta crescimento e time. Em especial:

- O **dev intermediário** que sente o código embolar conforme o app cresce e quer um padrão que segure a barra.
- O **dev a caminho de tech lead**, que precisa fixar um jeito certo de fazer e defendê-lo no time.
- O **time** que quer um vocabulário comum e fronteiras que um dev menos experiente não quebre sem querer.

O que eu presumo que você já tem:

- Dart no dia a dia (classes, `async`/`await`, null safety).
- O básico de Flutter (widgets, `setState`, rodar um app no emulador).
- Já ouviu falar de `Cubit`/`Bloc`, mesmo sem dominar.

Não presumo Clean Architecture, injeção de dependências nem programação funcional: tudo isso é construído aqui, de baixo para cima. Se Dart e Flutter ainda são novidade, a documentação oficial do Flutter é o melhor lugar para começar antes de voltar para cá.

---

## Como este livro está organizado

São seis partes, e a ordem importa: cada uma se apoia na anterior.

- **Parte I: Fundamentos** (seções 1 a 6): as convenções, os packages e a base do app, o esqueleto sobre o qual tudo se monta.
- **Parte II: Um módulo de ponta a ponta** (seções 7 a 11): o módulo de catálogo completo, o modelo que você vai copiar, mais as disciplinas que o sustentam, como erros, observabilidade e imutabilidade.
- **Parte III: Navegação** (seções 12 a 14): o shell de abas, os métodos de navegação e os guards de produção.
- **Parte IV: Injeção, variações e testes** (seções 15 a 18): a regra de ouro da injeção, as armadilhas reais, os testes e um exercício para fixar.
- **Parte V: Levando para produção** (seções 19 a 25): ambientes e flavors, internacionalização, segurança, monitoramento, feature flags, testes A/B e performance.
- **Parte VI: Veredito honesto e referências** (seções 26 a 29): até onde isso escala, o que de fato economiza, as versões usadas e os próximos passos.

A Parte II é o coração: o módulo de catálogo é o gabarito que se replica para qualquer outro. Leia do começo ao fim na primeira vez, e depois volte ao catálogo sempre que for criar um módulo novo.

---

## Convenções deste livro

Para a leitura fluir, alguns combinados:

- **Blocos de código** vêm comentados em pt-BR e mostram só o trecho que importa naquele ponto.
- **"Sem X, depois com X"** aparece bastante: primeiro o jeito comum (e por que ele machuca), depois o jeito que adotamos. Os marcadores ❌ e ✅ nos comentários dizem qual é qual.
- **Caixas com barra lateral** (como a logo abaixo) carregam as ressalvas honestas: o cuidado, o limite, a pegadinha que economiza a sua tarde.
- **Idioma**: identificadores de domínio e texto em pt-BR; nomes de API e termos técnicos no original (é a primeira convenção do livro, detalhada na [seção 1](#1-convenções-de-código)).
- **Referências cruzadas** aparecem como "seção N" e são clicáveis, para você pular ao assunto ligado sem perder o fio.

> Esta é uma caixa de ressalva. Sempre que vir uma, é um aviso de quem já se cortou ali.

---

## Sumário

**Parte I: Fundamentos**

1. [Convenções de código](#1-convenções-de-código)
2. [Packages utilizados](#2-packages-utilizados)
3. [O app de exemplo](#3-o-app-de-exemplo)
4. [Estrutura de pastas](#4-estrutura-de-pastas)
5. [Camada base do app](#5-camada-base-do-app)
6. [O padrão central: pageBuilder](#6-o-padrão-central-pagebuilder)

**Parte II: Um módulo de ponta a ponta**

7. [Módulo de catálogo (completo)](#7-módulo-de-catálogo-completo)
8. [Domínio e dados: a regra que não pode vazar](#8-domínio-e-dados-a-regra-que-não-pode-vazar)
9. [Erros em duas camadas](#9-erros-em-duas-camadas-fpdart-para-os-previstos)
10. [Observabilidade: o BlocObserver global](#10-observabilidade-o-blocobserver-global)
11. [Imutabilidade: copyWith manual e seus limites](#11-imutabilidade-copywith-manual-e-seus-limites)

**Parte III: Navegação**

12. [Shell de navegação com StatefulShellRoute](#12-shell-de-navegação-com-statefulshellroute)
13. [Navegação com go_router: qual método usar](#13-navegação-com-go_router-qual-método-usar)
14. [Navegação avançada: guards, onException e rotas por constante](#14-navegação-avançada-guards-onexception-e-rotas-por-constante)

**Parte IV: Injeção, variações e testes**

15. [Injeção de dependências: quem localiza, quem injeta](#15-injeção-de-dependências-quem-localiza-quem-injeta)
16. [Variações e armadilhas em produção](#16-variações-e-armadilhas-em-produção)
17. [Testes: bloc_test, mocktail e a regra de ouro](#17-testes-bloc_test-mocktail-e-a-regra-de-ouro)
18. [Exercício: módulos de Pedidos e Clientes](#18-exercício-módulos-de-pedidos-e-clientes)

**Parte V: Levando para produção**

19. [Ambientes e flavors](#19-ambientes-e-flavors)
20. [Internacionalização](#20-internacionalização)
21. [Segurança: blindando o app](#21-segurança-blindando-o-app)
22. [Monitoramento e alertas em produção](#22-monitoramento-e-alertas-em-produção)
23. [Feature flags: mudar o app sem novo lançamento](#23-feature-flags-mudar-o-app-sem-novo-lançamento)
24. [Testes A/B: decidir com dados](#24-testes-ab-decidir-com-dados)
25. [Performance: medindo com o Flutter DevTools](#25-performance-medindo-com-o-flutter-devtools)

**Parte VI: Veredito honesto e referências**

26. [Robustez e escala](#26-robustez-e-escala-o-que-é-estrutural-e-o-que-depende-de-disciplina)
27. [Economia de recursos](#27-economia-de-recursos-o-que-é-real-e-o-que-não-é)
28. [Versões de referência](#28-versões-de-referência-junho-de-2026)
29. [Próximos capítulos](#29-próximos-capítulos)

Ao final: [Resumo](#resumo), [Sobre o autor](#sobre-o-autor) e [Agradecimentos](#agradecimentos).

## Objetivo

Construir um app cuja arquitetura tenha **fronteiras claras**: cada package responde por uma responsabilidade, e há **um jeito certo** de fazer cada coisa. Isso não é preciosismo, é o que impede que um dev menos experiente quebre o padrão e que, com o tempo, o código vire difícil de manter. Boa arquitetura é, antes de tudo, limite e responsabilidade bem definidos.

As metas concretas:

- **Escala linear**: adicionar um módulo é criar uma pasta e registrar uma rota; nunca tocar no que já existe.
- **Domínio limpo**: regra de negócio isolada de Flutter, de HTTP e de formato de transporte.
- **Deep links de fábrica**: qualquer tela abre direto pela URL, com suas dependências montadas do zero.
- **Erros sob controle**: falhas previstas tratadas com tipo (`Either<Failure, T>`); falhas imprevistas capturadas globalmente e registradas.
- **Economia de recursos**: instanciação **lazy** e **dispose** automático do estado de tela. Os limites disso estão na [seção 27](#27-economia-de-recursos-o-que-é-real-e-o-que-não-é).

> **Honestidade sobre "grande porte".** Esta arquitetura escala bem **sob uma disciplina** (a regra de ouro do `get_it`, [seção 15](#15-injeção-de-dependências-quem-localiza-quem-injeta)) e com a noção correta do que o dispose cobre. As [seções 16](#26-robustez-e-escala-o-que-é-estrutural-e-o-que-depende-de-disciplina) e [17](#27-economia-de-recursos-o-que-é-real-e-o-que-não-é) são francas sobre os limites, porque "robusto" sem ressalva é marketing, não engenharia.

---

## Parte I: Fundamentos

As decisões e o esqueleto sobre o qual tudo se monta: as convenções, os packages que entram e a camada base do app.

---

## 1. Convenções de código

Antes do primeiro arquivo, fixamos as regras do jogo. Elas valem para todo o projeto e tornam o código previsível.

**Idioma.** Comentários, identificadores de domínio, UI e mensagens em **pt-BR** (com acentuação correta). Termos técnicos e nomes de API ficam no original.

**Nomes de arquivo e classes.** Arquivos em `snake_case`; classes em `PascalCase`. O nome do arquivo espelha a classe principal (`ProductListPage` → `product_list_page.dart`). E vale a regra de uma classe pública por arquivo, com exceções legítimas, que usamos de propósito:

- **Hierarquias `sealed`** moram juntas, num arquivo só. O `sealed` *exige* que as variantes estejam no mesmo arquivo (é o que dá a exaustividade ao `switch`). Por isso `ProductListState` e suas variantes ficam todas em `product_list_state.dart`, ligadas por `part of`.
- **Helpers privados pequenos** acoplados a um widget (ex.: uma tela de fallback `_InvalidProductScreen`) podem acompanhar o arquivo do widget que os usa.

**Imutabilidade.** Entidades e estados são **imutáveis** e estendem `Equatable` (igualdade por valor). O `copyWith` é escrito à mão, um trade-off consciente cujos detalhes e armadilhas estão na [seção 11](#11-imutabilidade-copywith-manual-e-seus-limites).

**Estado.** Sempre `Cubit`/`Bloc` com estado `sealed` + `switch` exaustivo. Um formato só, em toda tela.

**Injeção de dependências.** `get_it` **localiza**; o **construtor injeta** (a regra de ouro, [seção 15](#15-injeção-de-dependências-quem-localiza-quem-injeta)). Classes nunca chamam o locator por dentro.

**Erros.** Previstos → `Either<Failure, T>` (`fpdart`). Imprevistos → captura global no `main` ([seção 5](#5-camada-base-do-app)). Nunca um `try/catch` solto vazando `e.toString()` para a UI.

**Arquivos pequenos, responsabilidade única** (os princípios KISS, "mantenha simples", e DRY, "não se repita").

### Barrel: a API pública de cada pasta/módulo

Um **barrel** é um arquivo que apenas **reexporta** outros arquivos de uma pasta:

```dart
// catalog_module/domain/entities/entities.dart
export 'product.dart';
```

Quem precisa das entidades importa uma linha (`import '.../entities/entities.dart';`) em vez de uma por arquivo. Mas o ganho real não é só economizar linhas de import, é controlar o que sai de cada fronteira.

A regra que torna o barrel uma ferramenta de arquitetura, e não só de conveniência:

> **O barrel é a API pública daquela pasta/módulo. Exporte só o que o mundo de fora tem o direito de usar; esconda o resto.**

Na prática, cada módulo terá um **barrel público** (`catalog_module.dart`) que expõe apenas duas coisas: a **rota** do módulo (para o router registrar) e a função de registro de DI (injeção de dependências; para o locator chamar). Ele **não exporta**:

- a **implementação** do repositório (`ProductRepositoryImpl`): ninguém de fora deve instanciá-la; só o `injection` interno do módulo a conhece;
- os **cubits** e as **páginas**: são detalhe de apresentação, montados internamente pelo `pageBuilder`;
- os **models/DTOs** (DTO é *Data Transfer Object*, o objeto que só carrega dados entre as camadas, como o `ProductModel`): são detalhe do `data`.

Se um desses vaza pelo barrel, outro módulo passa a poder importar o interno do catálogo, e a encapsulação que estamos vendendo evapora. O que você não exporta é tão importante quanto o que exporta. Por isso, ao longo do guia, toda pasta que eu criar termina mostrando o seu barrel, com um comentário sobre o que ficou de fora e por quê.

---

## 2. Packages utilizados

Quatro packages no núcleo, cada um com um papel **não sobreposto**, mais dois para erros/parsing. A premissa que molda tudo: **sem `build_runner`**.

Antes dos nomes, os quatro motivadores que guiaram cada escolha:

- **Uma responsabilidade por package**: nada de duas ferramentas disputando o mesmo trabalho.
- **Packages consolidados**: não apostar a arquitetura numa biblioteca obscura ou abandonada.
- **Prescritividade**: um caminho certo, difícil de um dev menos experiente furar.
- **Zero `build_runner`**: nenhuma etapa de geração de código entre você e rodar o app.

A coluna "Por que entrou" abaixo diz como cada package atende a esses critérios.

| Package | Papel (a fronteira) | Por que entrou |
|---|---|---|
| [`go_router`](https://pub.dev/packages/go_router) | **Navegação** | Rotas nomeadas, deep links, subrotas e guards, ou seja, travas de acesso a rotas (`redirect` + `refreshListenable`), config por módulo. Router recomendado pelo time Flutter. |
| [`get_it`](https://pub.dev/packages/get_it) | **DI de serviços** | Resolve dependências **sem `BuildContext`**. Lazy singletons (paga só pelo que usa), inicialização assíncrona no bootstrap (a subida do app), **scopes** de sessão. |
| [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) | **Estado** | Fluxo unidirecional **prescritivo** (`sealed` + `switch`), difícil de furar. Dispose do estado de tela automático. |
| [`equatable`](https://pub.dev/packages/equatable) | **Igualdade por valor** | Faz o dedupe de rebuild do bloc funcionar (ou seja, não reconstruir a tela quando o estado é igual); estados e entidades comparáveis por valor. **Essencial** (ver [seção 8](#8-domínio-e-dados-a-regra-que-não-pode-vazar)). |
| [`fpdart`](https://pub.dev/packages/fpdart) | **Erros previstos** | `Either<Failure, T>` põe o erro na **assinatura** e o compilador **obriga** a tratá-lo. Substitui o `try/catch` espalhado ([seção 9](#9-erros-em-duas-camadas-fpdart-para-os-previstos)). |
| [`zard`](https://pub.dev/packages/zard) | **Validação de payload** *(opcional)* | Valida o JSON que chega (o *payload*, o corpo de dados) no limite do `data` e devolve erro tipado em vez de `cast error` cru. Port do [Zod](https://zod.dev) (JS). Ressalva de maturidade na [seção 8](#8-domínio-e-dados-a-regra-que-não-pode-vazar). |
| `dart:developer` (`log`) | **Log** | Função de log que já vem no próprio Dart e Flutter, usada aqui para não amarrar o guia a um Crashlytics específico ([seção 5](#5-camada-base-do-app)). |

A divisão de trabalho que você deve gravar:

> **`go_router` leva você à tela. `get_it` localiza os serviços de vida longa. O `bloc` segura o estado daquela tela. `fpdart` carrega o erro previsto. A captura global pega o imprevisto.**

> **Por que não entra Riverpod.** O Riverpod é um paradigma alternativo: ele substitui `get_it` + `bloc` de uma vez: não se *soma*, *substitui*. Eu não misturo os dois, e recomendo que você também não: ter dois sistemas de DI em paralelo é exatamente a ambiguidade que esta arquitetura existe para evitar. Se o seu time é de Riverpod, vá 100% Riverpod; aqui seguimos com `get_it` + `bloc`.

> Inspiração: a modularização do [`flutter_modular`](https://pub.dev/packages/flutter_modular), aqui obtida só com pacotes consolidados, sem micro-framework próprio.

### `build_runner`: uma escolha, não um mandamento

Você vai ver a expressão "sem `build_runner`" voltar de vez em quando ao longo do guia, então deixa eu ser claro de uma vez: isto é uma escolha minha, não uma lei da engenharia. O `build_runner` é a ferramenta de geração de código do ecossistema Dart, a que faz o `freezed` escrever o `copyWith` por você, o `json_serializable` montar o `fromJson`, o `injectable` registrar a injeção e o `go_router_builder` tipar as rotas. Eu preferi ficar fora dela neste livro, e é justo dizer o porquê e o preço.

O que se ganha:

- **Nada entre escrever e rodar.** Sem etapa de geração, sem um `build_runner watch` rodando ao lado, sem arquivo gerado desatualizado para te morder. Quem clona o projeto roda o app de primeira.
- **Tudo é o que parece.** O `copyWith`, o registro de dependência e o parser estão ali, legíveis e fáceis de buscar, em vez de escondidos num arquivo gerado. Menos mágica, menos peças móveis, CI mais simples.

O que se paga:

- **Trabalho manual recorrente.** `copyWith` à mão, registro de injeção à mão, schema de validação à mão. É previsível e barato por item, mas existe, e um campo esquecido no `copyWith` pode escapar em silêncio.
- **Menos garantias do compilador.** O que a geração daria de graça (as uniões do `freezed`, os parâmetros de rota tipados do `go_router_builder`, o `fromJson` sem erro de digitação) aqui passa a depender de disciplina e de teste.

Não é dogma. Num app pesado de DTOs, o `json_serializable` poupa dor real, e um time fluente em `freezed` rende mais com ele. Tanto que este livro abre uma exceção consciente na internacionalização ([seção 20](#20-internacionalização)), onde gerar código é o caminho certo. A regra de bolso: a geração compensa quando o que ela automatiza é volumoso e repetitivo a ponto de o erro manual ficar provável. Para a espinha desta arquitetura, preferi a transparência. E o que mais importa: a arquitetura não depende dessa escolha. Se o seu time ama o `freezed`, troque, que o resto continua de pé.

---

## 3. O app de exemplo

Um painel de loja com **navegação em abas** (um *shell* persistente: `StatefulShellRoute.indexedStack`, [seção 12](#12-shell-de-navegação-com-statefulshellroute)) e três módulos de negócio:

- **Catálogo (produtos)**: lista + detalhes (o módulo completo, modelo a ser copiado).
- **Pedidos** e **Clientes**: exercício no final.

A navegação principal é uma `NavigationBar` fixa (o shell), com uma aba por módulo; cada aba mantém sua própria pilha, e os detalhes empilham dentro da aba.

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

- **domain**: entidades, contratos de repositório e use cases (regra de negócio pura, sem o framework Flutter, sem formato de transporte).
- **data**: models de serialização (DTOs) e implementações de repositório.
- **presentation**: UI + lógica de apresentação (páginas e cubits).

Um aviso sobre **"sem Flutter"**: aqui é **sem o framework** (`package:flutter`), ou seja, **Dart puro**. Não é "sem dependências": packages Dart puros entram numa boa, e o domínio já usa dois (`equatable` e `fpdart`). A régua é só "o package puxa `package:flutter`?", e a [seção 11](#11-imutabilidade-copywith-manual-e-seus-limites) mostra por que esse limite vale a pena sem virar dogma.

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

> A regra de ouro da Clean Architecture aqui: o contrato do repositório vive no domain e retorna entidades de domínio, nunca `Map` cru. A serialização (JSON → objeto) é detalhe de infraestrutura e mora no **data**. Assim o domínio não sabe de onde nem em que formato os dados chegam.

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

### `main.dart`: entry point e captura global de erros

É aqui, na entrada do app, que instalamos a rede de segurança para os erros **não previstos**, aqueles que escapam de todo `try/catch` e de todo `Either`. A ideia: nada deve morrer silenciosamente; todo erro imprevisto vai para um log (e, em produção, para um Crashlytics/Sentry).

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

Como as três redes se encaixam:

- **`FlutterError.onError`** pega erros **dentro do framework** (um `build` que estourou, um overflow de layout que virou exceção).
- **`PlatformDispatcher.instance.onError`** pega erros **assíncronos** que não foram tratados e subiram até o motor do Flutter.
- **`runZonedGuarded`** é a **rede final**: erros que acontecem fora do ciclo do framework (ex.: durante o `setupLocator`) caem no callback de erro da zona. *Importante:* o `WidgetsFlutterBinding.ensureInitialized()` e o `runApp` precisam rodar dentro da mesma zona, por isso estão no corpo do `runZonedGuarded`.

> **Por que `log()` do `dart:developer` aqui.** Para não amarrar o guia a um serviço específico. O `log` aparece no DevTools/console com `error` e `stackTrace` estruturados. Em produção, troque o corpo de cada callback por `FirebaseCrashlytics.instance.recordError(error, stack)` (ou Sentry). O *ponto de instalação* (os três callbacks no `main`) não muda; só o destino do log muda.

> **Complemento (bloc).** Há ainda uma **quarta rede**, específica do estado: um `BlocObserver` global (`Bloc.observer = AppBlocObserver()`) cujo `onError` faz o mesmo `log`/`recordError`, e cujo `onChange` dá de graça o rastro de todas as transições de estado. Tratamos dela em detalhe na [seção 10](#10-observabilidade-o-blocobserver-global), inclusive a ressalva de que, num `Cubit` com `Either`, esse `onError` é quieto por construção (o erro previsto não lança).

### `injection.dart`: o service locator (raiz)

A raiz não conhece as implementações: ela só chama a função de registro **pública** de cada módulo. Cada módulo é dono dos seus registros.

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

Repare: o `injection.dart` importa o **barrel público** do catálogo e enxerga só `registerCatalogModule`. Ele **não** consegue importar `ProductRepositoryImpl`, porque o barrel não a exporta. A implementação fica trancada dentro do módulo.

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
// import 'modules/orders_module/orders_module.dart';      // exercício (seção 18)
// import 'modules/customers_module/customers_module.dart'; // exercício (seção 18)

// Navigator raiz: usado quando uma rota precisa cobrir o shell (ver seção 12).
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

O router importa só os **barrels públicos** e usa só as **rotas**, sem acesso a páginas, cubits ou repositórios. O `MainShell` (a `NavigationBar` persistente) e os **cuidados do shell** estão na [seção 12](#12-shell-de-navegação-com-statefulshellroute).

---

## 6. O padrão central: `pageBuilder`

O coração da arquitetura. Queremos que cada tela tenha seu **estado** (cubit) criado e iniciado ao montar, sem que o roteamento conheça esses detalhes.

A solução: um método estático na página que cria o cubit (puxando os serviços do `get_it`) e devolve o widget já no `BlocProvider`.

```dart
static Widget pageBuilder(BuildContext context, GoRouterState state) {
  return BlocProvider(
    create: (_) => ProductListCubit(getAllProducts: getIt<GetAllProductsUseCase>())..load(),
    child: const ProductListPage(),
  );
}
```

O `get_it` **enxuga** este ponto: a página declara só o seu estado; o repositório (singleton compartilhado) e o use case vêm de `getIt()`. O que isso traz:

- **Encapsulamento**: a tela cuida de si; o resto do app só conhece o nome da rota.
- **Deep link de fábrica**: abrir a rota direto monta o cubit do zero; serviços já estão no locator.
- **Rotas limpas** e **carga sem `initState`** (o `..load()` no `create`).
- **Dispose automático**: o `BlocProvider` fecha o cubit ao sair da árvore ([seção 27](#27-economia-de-recursos-o-que-é-real-e-o-que-não-é)).

---

## Parte II: Um módulo de ponta a ponta

O módulo de catálogo completo, o gabarito que se copia para qualquer outro, e as disciplinas que mantêm o estado honesto: erros, observabilidade e imutabilidade.

---

## 7. Módulo de catálogo (completo)

Vamos construir o módulo de baixo para cima: domínio → dados → apresentação → fiação. Cada pasta termina com seu barrel. E é aqui que introduzimos o `fpdart` e o `zard`, mostrando primeiro o código sem eles, depois com.

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

  /// Cópia imutável com alterações pontuais (o que o `freezed` geraria).
  /// Aqui todos os campos são não-nulos, então `?? this.campo` basta;
  /// o caso de campo nullable (e o `ValueGetter`) está na seção 11.
  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }

  @override
  List<Object> get props => [id, name, description, price, stock];
}
```

Entidade **imutável**, `Equatable`, **sem `fromMap`/`toMap`** (parsing é do data). O getter `inStock` é uma regrinha de negócio que vive no domínio e é reusada por qualquer tela. O `copyWith` cumpre a imutabilidade prometida na [seção 1](#1-convenções-de-código); as armadilhas dele (campos nulos, `final List`) moram na [seção 11](#11-imutabilidade-copywith-manual-e-seus-limites).

```dart
// domain/entities/entities.dart  (barrel)
export 'product.dart';
// Tudo aqui é público para o módulo: entidades são o vocabulário do domínio.
```

### 7.2 Domínio: contrato do repositório (introduzindo `fpdart`)

Aqui está a primeira decisão de erro. Vou mostrar as duas formas.

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

Agora a assinatura **diz a verdade**: "isto pode te dar uma `List<Product>` ou uma `Failure`". O consumidor é **forçado pelo compilador** a tratar os dois lados (via `fold`/`switch`), não há como esquecer. A partir daqui, todo contrato do guia usa `Either`.

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

Repare na elegância: a ordenação (regra do catálogo) roda só no caminho de sucesso, via `map` do `Either`. Não há `try/catch`, não há `if (erro)`: se veio `Left`, ele atravessa intacto. É o `fpdart` pagando por si.

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

> `GetAllProductsUseCase` **tem regra** (a ordenação), a camada se justifica. `GetProductByIdUseCase` só repassa: é **anêmico** (sem regra própria). Mantemos por simetria, mas não crie use case por dogma ([seção 16c](#c-quando-o-use-case-vale-a-pena)).

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

O problema: se a API mudar um campo, mandar `null`, ou trocar `int` por `String`, o `as` lança um **`TypeError` cru**, sem dizer qual campo, e sem virar uma `Failure` tratável. Você descobre o bug no Crashlytics, não no código.

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

**Sobre o `zard`: a ressalva honesta.** Ele é um package jovem e de nicho no ecossistema Dart; o resto da nossa stack é consolidado. Em compensação, é um **port do [Zod](https://zod.dev)** (a biblioteca de validação de schema amplamente adotada no JavaScript/TypeScript), então o paradigma (schema declarativo, `parse`/`safeParse`, erros descritivos) é maduro e familiar, mesmo que a implementação Dart seja recente. Confira a API atual no [pub.dev](https://pub.dev/packages/zard), que ainda evolui. **Recomendação:** se você quer robustez contra payloads ruins (e já gosta do Zod), vale; se prefere zero dependências novas no `data`, o `fromMap` manual com `Either` (mapeando o `catch` para `ValidationFailure`) entrega 80% do valor. Daqui em diante o guia assume `zard` no limite de dados, mas o padrão `Either` é o que de fato importa.

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

Três arquivos finais amarram o módulo e definem exatamente o que ele expõe.

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

Note que este arquivo, interno ao módulo, é o **único** que importa a implementação (`data/repositories/repositories.dart`) e a casa com a abstração. É o ponto onde o concreto encontra o contrato.

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

Esse é o pagamento do barrel: a fronteira do módulo não é só convenção de pasta, é imposta pelo que o arquivo público escolhe (não) exportar.

---

## 8. Domínio e dados: a regra que não pode vazar

Recapitulando a regra de ouro da Clean Architecture aqui, agora que vimos o código: o domain nunca enxerga `Map`. A entidade `Product` não tem `fromMap`; o contrato `ProductRepository` retorna `Either<Failure, Product>` (entidade), nunca JSON; o `ProductModel` (data) é quem conhece o formato de transporte e o valida (com `zard`). Troca-se mock por REST, GraphQL ou banco local mexendo **só no data**, porque nenhuma camada acima jamais viu o `Map`.

---

## 9. Erros em duas camadas: `fpdart` para os previstos

Já usamos os dois mecanismos; vale nomeá-los como **estratégia**:

| Camada | Cobre | Mecanismo | Quem "vê" |
|---|---|---|---|
| **Erros previstos** | Falhas de negócio/infra esperadas (rede caiu, não encontrado, payload inválido) | `Either<Failure, T>` + `Failure` `sealed` | O **usuário** (UI tratada por tipo) |
| **Erros imprevistos** | Bugs, estados impossíveis, exceções que escaparam | Captura global no `main` ([seção 5](#5-camada-base-do-app)) | O **dev** (log/Crashlytics) |

São **complementares**, não concorrentes. O `Either` torna o erro previsto **parte do contrato**: o compilador obriga a tratá-lo, e ele nunca chega à captura global. O que sobra para a captura global é o **genuinamente inesperado**, exatamente o que você quer ver num crash report. Um app maduro tem as duas; faltando qualquer uma, ou você vaza erro cru na UI, ou perde bug em silêncio.

---

## 10. Observabilidade: o `BlocObserver` global

O app já está de pé: o catálogo inteiro ([seção 7](#7-módulo-de-catálogo-completo)), os erros em duas camadas ([seção 9](#9-erros-em-duas-camadas-fpdart-para-os-previstos)), o `main` com suas três redes de captura ([seção 5](#5-camada-base-do-app)). Agora queremos **enxergar** o que esse app faz em runtime: cada estado que muda, cada cubit que nasce e morre, cada erro que escapa. E queremos isso sem reabrir um único arquivo de módulo.

É exatamente o que o `BlocObserver` entrega. Ele é um gancho global no ciclo de vida de todo `Cubit`/`Bloc`: você registra uma instância em `Bloc.observer` e ela passa a ser notificada de tudo, sem que nenhum cubit saiba que está sendo observado. Observabilidade entra aqui como **camada transversal**, uma responsabilidade que atravessa o app inteiro, em vez de espalhada dentro das telas.

```dart
// core/observability/app_bloc_observer.dart
import 'dart:developer';

import 'package:bloc/bloc.dart';

/// Vê o ciclo de vida de TODO Cubit/Bloc do app, sem que nenhum deles saiba.
/// Instalado uma única vez, no main.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    log('onCreate', name: '${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // O ganho de verdade: rastro de TODA transição de estado do app.
    log('${change.currentState} → ${change.nextState}', name: '${bloc.runtimeType}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    // A quarta rede da seção 5, agora específica do estado.
    log('onError', name: '${bloc.runtimeType}', error: error, stackTrace: stackTrace);
    // Em produção: FirebaseCrashlytics.instance.recordError(error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    log('onClose', name: '${bloc.runtimeType}');
  }
}
```

A instalação é uma linha, no mesmo `main` da [seção 5](#5-camada-base-do-app), ao lado das outras redes. O ponto de instalação é o mesmo; o destino do log troca em produção (igual aos outros callbacks):

```dart
void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      Bloc.observer = const AppBlocObserver(); // a quarta rede, antes da UI subir
      setupLocator();

      // FlutterError.onError / PlatformDispatcher.instance.onError (seção 5, inalterados)
      // ...

      runApp(const AppWidget());
    },
    (Object error, StackTrace stack) =>
        log('Uncaught zone error', name: 'app', error: error, stackTrace: stack),
  );
}
```

> **A mudança no código é minúscula, e isso é a manchete.** Ligar observabilidade no app inteiro custou **uma classe nova** (`AppBlocObserver`) e uma linha no `main`. Zero mudança em `domain/`, `data/`, `presentation/`, nos cubits, nas páginas ou nos barrels. Nenhum módulo sabe que está sendo observado, nenhuma fronteira foi furada. Para uma responsabilidade que corta o app inteiro (o chamado *cross-cutting concern*), isso é a tese de "limite e responsabilidade bem definidos" ([seção 1](#1-convenções-de-código)) se pagando: a observabilidade é uma camada por cima, não um cabo solto atravessando cada tela.

### Os callbacks (e o que muda entre `Cubit` e `Bloc`)

| Callback | Dispara quando | Vale para |
|---|---|---|
| `onCreate(bloc)` | um cubit é instanciado | `Cubit` e `Bloc` |
| `onChange(bloc, change)` | toda mudança de estado (`currentState → nextState`) | `Cubit` e `Bloc` |
| `onError(bloc, error, st)` | um erro é **reportado** ao bloc | `Cubit` e `Bloc` |
| `onClose(bloc)` | o cubit é fechado (`close()`) | `Cubit` e `Bloc` |
| `onEvent(bloc, event)` | um **evento** é adicionado | **só `Bloc`** |
| `onTransition(bloc, transition)` | a mudança **com o evento que a causou** | **só `Bloc`** |

O **ganho diário** está no `onChange`: de graça, você ganha um rastro de auditoria de toda transição de estado do app (`ProductListLoading → ProductListLoaded`, `ProductDetailsLoading → ProductDetailsLoaded`), sem tocar em nenhum cubit. Para debugar "o que aconteceu antes da tela quebrar?", esse log linear de estados vale mais que qualquer `print` espalhado.

### A ressalva honesta: `onError` em `Cubit` não é o que parece

Aqui vai a parte que todo tutorial pula. O `onError` é vendido como "centralize os erros do bloc", mas o comportamento **difere** entre `Cubit` e `Bloc`, e este guia é Cubit-first:

- Num **`Bloc`** (orientado a evento), uma exceção lançada dentro de um event handler é capturada pela máquina do bloc e roteada para o `onError` **automaticamente**.
- Num **`Cubit`**, não há captura automática: um método que lança propaga a exceção para quem chamou. Para o observer ver, você precisa de `addError(...)` explícito.
- **Mas** repare como isso fecha com a [seção 9](#9-erros-em-duas-camadas-fpdart-para-os-previstos): o ponto inteiro do `Either`/`fpdart` é que erro previsto não lança, é valor. O `load()` do guia faz `await getAllProducts()` e recebe um `Either`, e nunca lança por erro de domínio. Logo, neste desenho, o `onError` do observer fica **quieto por construção**.

Traduzindo: o `BlocObserver` é a **rede do imprevisto**, não do previsto. O previsto já está coberto pelo `Either` (a UI trata por tipo, como você viu na [seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit)). O que sobra para o `onError` é o bug genuíno, e mesmo esse, num cubit, tende a subir como erro assíncrono não-tratado e cair no `PlatformDispatcher.onError`/`runZonedGuarded` da [seção 5](#5-camada-base-do-app). As três redes da [seção 5](#5-camada-base-do-app) continuam valendo; o observer **acrescenta visibilidade**, não as substitui.

> **Por isso o `onChange` é a estrela, não o `onError`.** Numa arquitetura `Either`-first, o `onError` do cubit fala pouco, e é ótimo que fale pouco. O valor de observabilidade vem do `onChange`/`onCreate`/`onClose`, que te dão o filme do estado do app. Se você quer que o `onError` capture *de fato* o que rompe a lógica de estado, aí sim tem um argumento real para usar um **`Bloc`** (com `onTransition`/`onError` automáticos) na tela onde a auditoria importa, em vez do `Cubit`.

### `MultiBlocObserver`: observers de papel único

`Bloc.observer` é um **singleton**: um observer só. Quando você quer **vários papéis** (logar, mandar para analytics, reportar crash), compõe com `MultiBlocObserver`, dando a cada observer uma responsabilidade. É a mesma regra "um papel não sobreposto" dos packages ([seção 2](#2-packages-utilizados)):

```dart
Bloc.observer = MultiBlocObserver([
  LoggingObserver(),     // dart:developer, só em debug
  AnalyticsObserver(),   // onChange -> eventos de produto (telemetria)
  CrashlyticsObserver(), // onError  -> recordError
]);
```

Assim o `LoggingObserver` não sabe de analytics, o `AnalyticsObserver` não sabe de crash, e você liga/desliga cada um por ambiente (ex.: logar só em `kDebugMode`).

### Trade-offs de produção (seja honesto)

O observer é poderoso justamente porque vê tudo. E "tudo" tem custo:

- **`onChange` dispara para todo estado de todo cubit.** Num app movimentado, é muito log. Em produção, **filtre** (só `onError`, ou só certos tipos de bloc) ou **amostre**; despejar todas as transições num backend de telemetria é caro e ruidoso.
- **Estado pode conter dados pessoais (PII, informação que identifica a pessoa).** Logar `change.nextState` cru pode vazar dado de usuário (e-mail, token, endereço) para o destino dos seus logs. Se o estado carrega dado sensível, logue **um resumo** (`runtimeType`, ids), nunca o objeto inteiro. Isso vale em dobro quando o destino é um serviço externo (Crashlytics/Sentry).
- **É global e único.** Há um `Bloc.observer` para o app todo; não dá para ter observers "por módulo" sem compor à mão (via `MultiBlocObserver` + roteamento por `bloc.runtimeType`). É o preço de ser uma camada transversal, coerente com a ideia, mas bom você saber.

Em resumo: o `BlocObserver` é a peça que **fecha a observabilidade** do guia sem comprometer nenhuma fronteira. Liga no `main` junto das redes da [seção 5](#5-camada-base-do-app), dá o filme do estado via `onChange`, complementa (sem substituir) a captura global no `onError`, e escala por composição com `MultiBlocObserver`. Tudo isso desde que você trate ruído e PII como decisões de produção, não como detalhes.

---

## 11. Imutabilidade: `copyWith` manual e seus limites

A [seção 1](#1-convenções-de-código) fixou a regra (entidades e estados `final` + `const` + `Equatable`, sem `freezed`) e a [seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit) mostrou por que ela faz o rebuild do bloc funcionar. Falta fechar o assunto: como escrever isso à mão, e onde a imutabilidade cobra o seu preço.

### Por que ela é fundação, não enfeite

Três coisas que o guia já vende dependem dela:

- **O dedup do `Equatable` só existe com valor imutável.** Se o estado pudesse ser mutado no lugar, o `==` ficaria inconsistente e a promessa "estado igual não reconstrói" ([seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit)) deixaria de valer.
- **O fluxo unidirecional do bloc.** Você nunca altera um estado, sempre emite um novo. Imutável é o que transforma isso numa garantia, e não numa convenção que alguém esquece numa sexta à noite.
- **Segurança no `await`.** Um objeto imutável capturado antes de um `await` não muda embaixo de você enquanto a Future resolve.

### O `copyWith` manual, e a armadilha dos campos nulos

O `copyWith` que adicionamos na `Product` ([seção 7.1](#71-domínio-entidade)) é o caso fácil: como todos os campos são não-nulos, o padrão `campo ?? this.campo` ("use o que passaram, senão mantenha o atual") está correto, e continua Flutter-free, como o `domain` exige.

O buraco aparece no instante em que um campo é nullable. Imagine que `Product` ganhasse um `String? cupom`:

```dart
// ❌ consegue SETAR o cupom, mas nunca LIMPAR
Product copyWith({String? cupom}) =>
    Product(cupom: cupom ?? this.cupom /* , ... demais campos */);
```

`copyWith(cupom: null)` não diz "apague o cupom". Diz exatamente o mesmo que "não passei cupom nenhum", porque `null ?? this.cupom` devolve o valor atual. Setar funciona; limpar, não. É um bug clássico, e silencioso.

A saída idiomática no Flutter é o **`ValueGetter`**. Ele é só um typedef do `flutter/foundation`: `typedef ValueGetter<T> = T Function()`. O truque é embrulhar o valor numa função. A **presença da função** responde "o caller passou algo?", e **chamá-la** entrega o valor, que pode muito bem ser `null`:

```dart
// ✅ distingue "não mexi" de "quero limpar"
Product copyWith({ValueGetter<String?>? cupom}) =>
    Product(cupom: cupom != null ? cupom() : this.cupom /* , ... */);
```

Agora os três casos ficam distintos:

- `copyWith()`: o parâmetro `cupom` é `null`, ninguém passou nada, mantém o atual.
- `copyWith(cupom: () => 'BLACK10')`: seta o cupom.
- `copyWith(cupom: () => null)`: **limpa** o cupom.

O preço é um `() =>` mais verboso no call site, e só nos campos nullable. Compensa quando "apagar o campo" é uma operação de verdade no seu domínio.

> **Pureza de domínio, sem virar dogma.** "Flutter-free" no `domain` quer dizer **sem o framework** (`package:flutter`), ou seja, Dart puro ([seção 4](#4-estrutura-de-pastas)). Não quer dizer "sem packages": o `equatable` e o `fpdart` já vivem lá, e são Dart puro. A régua é uma só: o package puxa `package:flutter`? O `ValueGetter` puxa (mora no `flutter/foundation`), então, em vez de arrastar o framework inteiro por causa de um `T Function()`, declaramos o mesmo typedef de uma linha no `core` (`typedef ValueGetter<T> = T Function();`). Já o `@immutable` não puxa: ele vem do `package:meta` (Dart puro) e pode ser importado direto. E por que manter esse limite? Por dois motivos baratos e concretos: o domínio roda com `dart test` (sem subir o binding do Flutter, teste mais rápido) e a dependência aponta sempre pra dentro (o coração do app não conhece a UI). De bônus, dá para reusar o domínio num backend Dart, se um dia precisar. Não é purismo, é uma fronteira barata que se paga sozinha.

### Dois custos que valem dizer em voz alta

- **`final List` não é imutável.** No `ProductListLoaded`, o `final List<Product> products` tem a referência travada, mas o conteúdo não: `products.add(...)` muta a lista no lugar. E aí mora um bug fino: se você mutar a mesma lista e emitir um estado novo segurando **a mesma instância**, o `Equatable` compara, vê a mesma lista, e **não reconstrói**. A disciplina é "sempre crie uma lista nova, nunca mute a antiga". Para garantir de verdade, `List.unmodifiable(...)` (que estoura em runtime se alguém tentar mutar) ou o `IList` do `fast_immutable_collections`. O Object Calisthenics chama a versão saudável disso de **first-class collections**: dar à coleção uma classe própria, dona das suas invariantes.
- **Sem geração de código, cada campo novo são três lugares.** Adicionou um campo na entidade? Você mexe no construtor, no `props` e no `copyWith`. Esquecer o `copyWith` é o pior dos três, porque ele simplesmente para de copiar o campo novo e nada reclama. É o "custo recorrente sem build_runner" da [seção 26](#26-robustez-e-escala-o-que-é-estrutural-e-o-que-depende-de-disciplina), visto de perto.

### O analisador de aliado: `@immutable`

Na mesma linha do `Either` que obriga a tratar o erro e do `sealed` que obriga o `switch` exaustivo, dá para pôr o **analisador** para vigiar a imutabilidade de graça. A anotação `@immutable` (do `package:meta`, que é Dart puro, então cabe até no `domain`) faz o analyzer **reclamar** se a classe, ou qualquer subclasse dela, tiver um campo não-`final`:

```dart
@immutable
class Product extends Equatable {
  // qualquer campo declarado sem `final` aqui já vira um aviso do analyzer
}
```

Custo zero. É a mesma mecânica que faz o `Widget` do Flutter avisar quando você esquece um `final`.

### Quando o `copyWith` realmente paga

Sendo honesto com você: nos estados `sealed` simples (Loading, Loaded, Error) o `copyWith` quase não aparece, porque você emite outra variante em vez de remendar a atual. Ele brilha em dois lugares. Em entidades que você transforma (aplicar um desconto, mudar a quantidade de um item) e em **estados ricos** (uma tela de busca com filtros e paginação, onde você troca um pedaço e mantém o resto). É no exercício de Pedidos ([seção 18](#18-exercício-módulos-de-pedidos-e-clientes)) que ele aparece com regra de verdade: um item do pedido mudando a quantidade via `copyWith`, mantendo o resto intacto.

### `records` e value objects

Dois primos da imutabilidade que valem o seu radar. Os **`records`** do Dart 3 já nascem imutáveis e com igualdade estrutural de fábrica: ótimos para agrupar ou devolver vários valores de um método sem ter que criar uma classe só pra isso (devolver `(total, quantidade)` de um cálculo, por exemplo). Mas, para um conceito de domínio, você ainda quer um **tipo com nome**, e é aí que entram os **value objects**: tipos pequenos e imutáveis que embrulham um primitivo (`Money`, `Cpf`, `Email`), validam quando são criados e comparam por valor. Isso é exatamente a regra "wrap all primitives and strings" do Object Calisthenics (do Jeff Bay), o antídoto contra a *primitive obsession* (o vício de modelar tudo com tipos crus): em vez de espalhar `double` e `String` soltos pelo domínio, cada conceito ganha um tipo que carrega as próprias regras. A base `final` + `const` + `Equatable` que montamos é justamente o que deixa os value objects baratos de escrever aqui.

---

## Parte III: Navegação

Do shell de abas aos guards de produção, sem perder o deep link de vista.

---

## 12. Shell de navegação com `StatefulShellRoute`

A navegação principal do app é um **shell**: uma `NavigationBar` que fica **fixa** enquanto o conteúdo troca por aba. Em vez de uma `HomePage` com botões (um hub que seria só "mais um jeito de navegar"), a própria barra é o hub. Usamos `StatefulShellRoute.indexedStack`, que dá a cada aba o seu **próprio navigator**, com pilha e estado preservados ao alternar.

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
      // Tocar de novo na aba JÁ ativa volta a aba à sua raiz (comportamento padrão).
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
```

O `navigationShell` faz o trabalho pesado: `currentIndex` diz a aba ativa, `goBranch(i)` troca de aba. O `builder` do `StatefulShellRoute.indexedStack` (no `app_router.dart`, [seção 5](#5-camada-base-do-app)) entrega esse objeto já pronto.

### O benefício: estado e pilha por aba

Este é o ganho que justifica o `indexedStack`: cada aba lembra onde você estava. Navegue até o detalhe de um produto no Catálogo, troque para Pedidos, volte para o Catálogo: você cai de volta no detalhe, com a rolagem e o estado intactos. É o comportamento que o usuário espera de um app com abas, e vem de graça: cada branch mantém o seu navigator vivo.

### Os cuidados (onde dá ruim se você não souber)

Shell tem armadilhas que valem mais que o exemplo feliz:

1. **`destinations` e `branches` precisam ter o mesmo número, e na mesma ordem.** A `NavigationBar` acima tem 3 destinos; logo o `StatefulShellRoute` precisa de 3 branches. Se você ainda não implementou Pedidos/Clientes (o exercício da [seção 18](#18-exercício-módulos-de-pedidos-e-clientes)), use uma rota *placeholder* por branch, senão `goBranch(2)` aponta para um índice que não existe e estoura em runtime. Índice e ordem são a fonte nº 1 de bug aqui.

2. **Detalhe dentro da aba ou cobrindo o shell: você escolhe.** Como `/products/details/:id` é **subrota** de `/products` (dentro da branch do Catálogo, [seção 7.7](#77-fiação-rotas-injeção-e-o-barrel-público)), o detalhe empilha **dentro da aba** e a `NavigationBar` **continua visível**. É o padrão de apps com abas. Se você quiser que uma tela **cubra o shell** (checkout, câmera, um fluxo modal), declare-a no **navigator raiz**, passando a `parentNavigatorKey`:

   ```dart
   GoRoute(
     path: 'details/:id',
     parentNavigatorKey: rootNavigatorKey, // sobe ao navigator raiz: cobre a NavigationBar
     builder: ProductDetailsPage.pageBuilder,
   )
   ```

   Sem `parentNavigatorKey`, fica na branch (barra visível). É uma decisão de UX (a experiência do usuário) por rota: saber onde a rota é declarada é o que dá controle.

3. **Deep link tem que cair na branch certa.** Abrir `/orders/details/5` direto precisa ativar a branch de Pedidos e empilhar o detalhe nela. O `go_router` faz isso se a rota estiver declarada sob a branch correta. Tradução prática: cada módulo declara as suas rotas, e o shell as pendura na branch certa; declarou no lugar errado, o deep link abre na aba errada.

4. **Custo de memória: o preço do estado preservado.** O `IndexedStack` constrói a branch no primeiro acesso e a mantém viva depois. É exatamente isso que preserva o estado da aba, e é também memória **retida**: abas já visitadas não sofrem dispose enquanto você está no shell. Trade-off consciente entre UX e memória, e uma exceção honesta ao "dispose automático" da [seção 27](#27-economia-de-recursos-o-que-é-real-e-o-que-não-é): o estado de tela dentro de uma branch ativa não é descartado ao trocar de aba, só ao sair do shell.

> **A forma simples: `ShellRoute` (sem estado por aba).** Se as abas **não** precisam preservar pilha/estado (ao voltar para uma aba, tudo bem ela reiniciar na raiz), o `ShellRoute` "puro" é mais simples: um único navigator, sem branches. Troca o casco e reconstrói o conteúdo. Use-o para um drawer/app bar fixos sobre telas que não têm o que lembrar. Para abas de verdade (o caso comum), `StatefulShellRoute.indexedStack` é o que entrega a experiência esperada, por isso é o **padrão deste guia**.

---

## 13. Navegação com go_router: qual método usar

| Método | Comportamento | Quando usar |
|---|---|---|
| `context.go(path)` / `goNamed(name)` | Substitui a pilha | Redirecionamentos, splash → login, troca de aba raiz |
| `context.push(path)` / `pushNamed(name)` | Empilha (permite voltar) | Telas de detalhe, fluxos com "voltar" |

**Prefira as variantes `*Named`**, que desacoplam módulos: você navega de qualquer lugar passando `pathParameters`/`queryParameters` sem conhecer a estrutura interna do destino.

> **Strings mágicas, não.** Em escala, centralize os nomes em constantes (`AppRoutes.productDetails`) e exponha helpers (`AppRoutes.goToProductDetails(context, id)`), o jeito de tirar as strings cruas do meio do código sem depender do `go_router_builder`. O padrão completo está na [seção 14](#14-navegação-avançada-guards-onexception-e-rotas-por-constante).

### Armadilha: subrota também monta a rota-pai

`context.go('/products/details/1')` monta o pai antes da filha (a `ProductListPage` e depois a `ProductDetailsPage`), disparando um `load()` redundante na lista. Dois cenários, respostas diferentes:

1. **Navegação interna** → use `push`/`pushNamed`: empilha **só o destino**.
2. **Deep link real** (abrir a URL/recarregar no Web) → você não controla: o `go_router` precisa montar o pai para a pilha do "voltar" fazer sentido. Saídas: **(a)** declarar os detalhes como rota **irmã** top-level (sem pai, nada redundante; "voltar" não cai na lista), ou **(b)** tornar o pai **barato e idempotente** (rodar de novo dá o mesmo resultado, sem efeito colateral), e aqui o **repositório singleton** com cache faz o `load()` redundante servir do cache. Um guard no cubit ("já tenho dados? não recarrego") fecha de vez.

> O casco persistente (`NavigationBar` fixa, estado por aba) e seus cuidados estão na [seção 12](#12-shell-de-navegação-com-statefulshellroute), é o padrão de navegação deste guia.

---

## 14. Navegação avançada: guards, `onException` e rotas por constante

A [seção 12](#12-shell-de-navegação-com-statefulshellroute) montou o shell e a [seção 13](#13-navegação-com-go_router-qual-método-usar) mostrou como ir de tela em tela. Falta o que separa um protótipo de um app de produção: bloquear rota por autenticação, tratar rota que não existe, e tirar as strings cruas do meio do código. É o que o go_router resolve com `redirect` + `refreshListenable`, `onException` e um punhado de constantes.

### Auth guard: `redirect` + `refreshListenable`

O padrão é direto: um `redirect` global lê o estado de sessão e manda quem não está logado para `/login`. O `refreshListenable` faz o go_router **reavaliar** os redirects quando a sessão muda, então login e logout reagem na hora, sem você navegar na mão.

Primeiro, a sessão no mesmo formato de todo o resto do guia: um `SessionCubit` com estado `sealed` ([seção 1](#1-convenções-de-código)), registrado como singleton de app no `get_it`. Nada de inventar um segundo sistema de estado só para o auth.

```dart
// core/session/session_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

sealed class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

final class Authenticated extends SessionState {
  final String userId;
  const Authenticated(this.userId);
  @override
  List<Object?> get props => [userId];
}

final class Unauthenticated extends SessionState {
  const Unauthenticated();
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit() : super(const Unauthenticated());

  void login(String userId) => emit(Authenticated(userId));
  void logout() => emit(const Unauthenticated());
}
```

```dart
// no injection.dart raiz: um singleton de app (a sessão dura o app todo)
getIt.registerLazySingleton(SessionCubit.new);
```

Só que o `refreshListenable` do go_router pede um `Listenable`, e Cubit não é um (ele expõe `stream` e `state`, não `addListener`). Então precisamos de uma ponte do `stream` para `Listenable`. E é aqui que mora a distinção que mantém a premissa de pé: essa ponte é um `ChangeNotifier` mínimo, mas ele é cola para a API do go_router, não um segundo sistema de estado. O estado continua morando no Cubit; o `ChangeNotifier` só avisa o router que algo mudou (mesmo espírito do `BlocProvider`, que é cola do `flutter_bloc`).

```dart
// core/session/go_router_refresh_stream.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Ponte stream -> Listenable. Cola para o refreshListenable, não estado:
/// o estado é do SessionCubit; isto só dispara a reavaliação do redirect.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // estado inicial
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
```

Agora o router lê o `state` do Cubit no `redirect` e ouve o `stream` dele pela ponte:

```dart
// app_router.dart (trecho)
final session = getIt<SessionCubit>();

final GoRouter appRoutes = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/products',
  refreshListenable: GoRouterRefreshStream(session.stream), // re-roda o redirect quando a sessão muda
  redirect: (context, state) {
    final logado = session.state is Authenticated;
    final indoProLogin = state.matchedLocation == '/login';

    // Não logado e indo para uma rota protegida: manda pro login,
    // guardando o destino pretendido em `from` para voltar depois.
    if (!logado && !indoProLogin) {
      return '/login?from=${state.uri}';
    }
    // Já logado tentando ver o login: joga pra home.
    if (logado && indoProLogin) return '/products';

    return null; // segue o fluxo normal
  },
  routes: [ /* shell + /login */ ],
);
```

Três cuidados que evitam os bugs clássicos:

- **Anti-loop.** O `redirect` roda em toda navegação, inclusive ao ir para `/login`. Sem o `indoProLogin` e o `!indoProLogin`, redirecionar para `/login` dispara um novo redirect para `/login`, em laço infinito. Esse guard do destino é obrigatório.
- **Return-url (URL de retorno).** Guardamos o destino em `?from=...`. A tela de login, depois de chamar `session.login(...)`, lê esse `from` e faz `context.go(from)`, devolvendo a pessoa para onde ela queria ir. Sem isso, todo login termina na home, e o deep link para uma rota protegida perde o destino.
- **Barato e síncrono.** O `redirect` roda muito; leia o `state` em cache do Cubit, nunca I/O. Se a checagem de auth for assíncrona (validar token no servidor), resolva isso no bootstrap e emita o `SessionState` resultante, deixando o `redirect` só consultando.

> **Onde a sessão vive.** O `SessionCubit` é um singleton de app aqui (o estado de sessão dura o app todo), mas os serviços que nascem no login e morrem no logout (token, repositórios autenticados) são o caso de uso exato do **scope de sessão** da [seção 16a](#a-scope-de-sessão-registrar-no-login-descartar-no-logout): `pushNewScope` no login, `dropScope` no logout. O mesmo `emit` que muda o `SessionState` é o gancho natural para montar e descartar esse scope.

### `onException`: rota que não existe e falha de navegação

O `redirect` cuida de quem pode ver uma rota. O `onException` cuida de uma rota que **não existe** (um `/produtos` digitado errado, um deep link velho) ou de um redirect que estourou. Você recebe o próprio router e decide o que fazer, em vez de só pintar uma tela de erro:

```dart
final GoRouter appRoutes = GoRouter(
  // ...
  onException: (context, state, router) {
    log('Rota não encontrada: ${state.uri}', name: 'router');
    router.go('/products'); // leva para uma rota garantidamente válida
  },
);
```

Repare como isso espelha a estratégia de erro em duas camadas da [seção 9](#9-erros-em-duas-camadas-fpdart-para-os-previstos). O livro já trata o deep link **malformado por página** (o `int.tryParse` que cai no `_InvalidProductScreen`, [seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit)); o `onException` é a rede no nível do app, para a rota que nem chega a casar. Duas camadas de robustez de deep link, mesma filosofia.

- **Cuidado**: não redirecione para uma rota que também pode falhar (um `/404` que não existe vira outro `onException`). Aponte para algo garantidamente válido, como a home.

### Rotas por constante e helpers (sem `go_router_builder`)

A [seção 13](#13-navegação-com-go_router-qual-método-usar) avisou para não espalhar string mágica. Aqui está o padrão completo: cada módulo é dono dos seus nomes de rota e expõe **helpers** que embrulham a navegação com os params certos. É o `CatalogRoutes` da [seção 7.7](#77-fiação-rotas-injeção-e-o-barrel-público), agora sem string solta:

```dart
// dentro do catalog_module, exposto pelo barrel público
class CatalogRoutes {
  CatalogRoutes._();

  // os nomes, num lugar só
  static const products = 'products';
  static const productDetails = 'product-details';

  static GoRoute get route => GoRoute(
        path: '/products',
        name: products, // a constante, não a string crua
        builder: ProductListPage.pageBuilder,
        routes: [
          GoRoute(
            path: 'details/:id',
            name: productDetails,
            builder: ProductDetailsPage.pageBuilder,
          ),
        ],
      );

  // o helper: o caller navega sem conhecer o path nem montar o param à mão
  static void goToDetails(BuildContext context, int id) =>
      context.pushNamed(productDetails, pathParameters: {'id': '$id'});
}
```

Na tela, a navegação fica autodocumentada e segura a refactor:

```dart
// antes: context.pushNamed('product-details', pathParameters: {'id': product.id.toString()})
// depois:
onTap: () => CatalogRoutes.goToDetails(context, product.id),
```

- **Prós**: renomeou o path? Um lugar só. O destino mudou de param? O helper quebra na compilação até você corrigir. E o nome da rota nunca mais é digitado solto.
- **Contra honesto**: é manual. O `go_router_builder` checaria os params em compile-time de verdade, mas exige `build_runner`, fora da premissa deste guia. O par constante + helper entrega a maior parte disso a custo de algumas linhas.

### O `extra`, e por que ele briga com deep link

O `GoRoute` aceita um objeto via `extra:`, e é tentador mandar o `Product` inteiro para a tela de detalhes e pular o refetch (a nova busca dos dados). Resista. O `extra` não vai na URL: ele some no refresh do Web, no deep link real e no restart do app. Numa arquitetura que promete deep links de fábrica ([objetivo](#objetivo)), passar objeto de domínio por `extra` quebra justamente essa promessa, porque abrir a URL direto chega com `extra` nulo.

A disciplina é a que já praticamos: id no path, refetch no cubit. O `extra` só se justifica para navegação efêmera que nunca vai virar deep link, tipo um formulário de várias etapas (um wizard) no mesmo fluxo. Na dúvida, id na URL.

---

## Parte IV: Injeção, variações e testes

A regra de ouro que segura tudo, as armadilhas reais de produção e como verificar que funciona.

---

## 15. Injeção de dependências: quem localiza, quem injeta

Dois mecanismos, cada um no seu lugar:

- **`get_it` localiza serviços de vida longa** (repositórios, datasources, use cases, `Session`), sem `BuildContext`.
- **`BlocProvider` provê o estado de tela** (o cubit), atrelado à árvore, criado ao montar, descartado ao desmontar.

> **Regra de ouro do `get_it`.** Use o locator só no ponto de montagem (o `pageBuilder` / a factory do cubit). As classes nunca chamam `getIt<T>()` por dentro: recebem tudo por **construtor**. O locator *localiza*; o construtor *injeta*. Assim os testes instanciam com mocks sem tocar no locator, e o "service locator vira saco de tudo" não acontece.

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

> **Convenção: tipe a resolução.** Escreva sempre `getIt<GetAllProductsUseCase>()`, nunca o `getIt()` "pelado". O Dart consegue inferir o tipo pelo contexto (o parâmetro do construtor já é tipado), mas o explícito é melhor por três razões: ele **se autodocumenta** (você lê o que está sendo resolvido sem caçar a assinatura), é **seguro a refactor** (se o tipo do parâmetro mudar, o `getIt()` inferido segue em silêncio para o novo tipo e pode resolver o registro errado; o explícito reclama) e nunca quebra fora de contexto (`var x = getIt();` resolve `Object` e estoura em runtime). O custo é um par de `<>`; o ganho é uma resolução sem mágica.

---

## 16. Variações e armadilhas em produção

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

É aqui (e só aqui) que existe "dispose modularizado" de serviços ([seção 27](#27-economia-de-recursos-o-que-é-real-e-o-que-não-é)).

### b) `Either` x exceção: onde fica a fronteira

Adotamos `Either` nos **contratos de domínio**. Exceções não somem do mundo, elas existem na borda (um `Dio` lança `DioException`). A regra: a camada `data` é o tradutor que captura a exceção da infra e a converte em `Left(Failure)`. Acima do `data`, ninguém mais vê exceção; todo mundo vê `Either`. É o que mantém o `try/catch` confinado a um único lugar.

### c) Quando o use case vale a pena

Use case que só repassa o repositório é boilerplate (código repetitivo de cerimônia, sem regra). A camada se justifica com **regra de negócio** (orquestrar, validar, transformar), como a ordenação de `GetAllProductsUseCase` ou um `PlaceOrderUseCase`. Sem regra, é legítimo o cubit chamar o repositório direto (resolvido pelo `getIt`). Não adicione a camada por dogma.

### d) Buscar N coisas: em paralelo, não em série

Uma tela às vezes precisa de mais de uma fonte: um detalhe e seus relacionados, a lista e o perfil de quem está logado. O reflexo é pedir uma, esperar, pedir a outra, esperar. Aí a latência soma: duas chamadas de 300ms viram 600ms de spinner, à toa, porque uma não depende da outra.

Quando as buscas são independentes, dispare as duas juntas e espere o conjunto. A latência passa a ser a da mais lenta, não a soma:

```dart
// ❌ em série: a latência soma (300ms + 300ms ~ 600ms)
final produto = await getProductById(id);
final relacionados = await getRelatedProducts(id);

// ✅ em paralelo: a latência é a da mais lenta (~300ms)
final (produto, relacionados) =
    await (getProductById(id), getRelatedProducts(id)).wait;
```

O `(a, b).wait` é a forma do Dart 3 com **records** ([seção 11](#11-imutabilidade-copywith-manual-e-seus-limites)): preserva o tipo de cada resultado, sem cair em `dynamic`. Para uma lista homogênea (vários produtos por id, por exemplo), o `Future.wait` faz o mesmo e devolve uma lista:

```dart
final resultados = await Future.wait(ids.map(getProductById));
```

Duas ressalvas honestas. Só vale para chamadas **independentes**: se a segunda precisa do resultado da primeira, elas são sequenciais por natureza, e forçar paralelo não tem sentido. E como nossos use cases devolvem `Either` ([seção 9](#9-erros-em-duas-camadas-fpdart-para-os-previstos)), e não lançam por erro previsto, o `wait` completa entregando um `Either` por busca. Você ainda junta os resultados: o primeiro `Left` vira o estado de erro da tela, e só com todos em `Right` a tela monta. O paralelo encurta a espera; o tratamento de erro segue o mesmo do resto do guia.

---

## 17. Testes: bloc_test, mocktail e a regra de ouro

Testar este app é quase um anticlímax, e isso é o maior elogio possível. Testabilidade não é um assunto novo aqui: é a fatura de decisões que já tomamos. A regra de ouro do `get_it` ([seção 15](#15-injeção-de-dependências-quem-localiza-quem-injeta)) faz cada classe receber suas dependências por construtor, então no teste você só passa um mock. O `Either` ([seção 9](#9-erros-em-duas-camadas-fpdart-para-os-previstos)) transforma o caminho de erro em valor, fácil de simular. O `Equatable` ([seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit)) deixa a asserção exata. E o domínio Dart puro ([seção 11](#11-imutabilidade-copywith-manual-e-seus-limites)) roda com `dart test`, rápido, sem precisar inicializar o Flutter. Vamos sacar esse cheque.

### As ferramentas, e por que essas

- `test`: o executor de testes do Dart puro, para o domínio.
- `flutter_test`: para os testes de widget (a interface).
- `bloc_test`: o helper `blocTest`, que testa um cubit de forma declarativa (monta, age, espera os estados).
- `mocktail`: para os mocks, que são implementações falsas controladas pelo teste. O detalhe que importa: o `mocktail` não precisa de `build_runner`, diferente do `mockito`, que gera um arquivo `.mocks.dart`. É mock em tempo de execução, sem geração de código, fiel à premissa do guia. O custo é que a verificação acontece em runtime, não na compilação, mas você não paga code-gen por isso.

A pasta `test/` espelha a `lib/`: cada módulo carrega os próprios testes, autocontido, do mesmo jeito que carrega o próprio barrel.

### Domínio: testando a regra do use case

O `GetAllProductsUseCase` tem uma regra de verdade (a ordenação, [seção 7.3](#73-domínio-use-cases)), então ela merece teste. Mockamos o repositório, injetamos por construtor e olhamos os dois lados do `Either`. Roda com `dart test`, sem Flutter:

```dart
// test/modules/catalog_module/domain/use_cases/get_all_products_use_case_test.dart
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
// imports do domínio (Product, ProductRepository, GetAllProductsUseCase, Failure)...

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repo;
  late GetAllProductsUseCase useCase;

  setUp(() {
    repo = MockProductRepository();
    useCase = GetAllProductsUseCase(repository: repo); // injeção por construtor
  });

  test('ordena por disponibilidade e nome no caminho de sucesso', () async {
    when(() => repo.getAllProducts()).thenAnswer((_) async => const Right([
          Product(id: 1, name: 'Zebra', description: '', price: 1, stock: 0),
          Product(id: 2, name: 'Abacaxi', description: '', price: 1, stock: 5),
        ]));

    final result = await useCase();

    final nomes = result.getOrElse((_) => []).map((p) => p.name).toList();
    expect(nomes, ['Abacaxi', 'Zebra']); // em estoque primeiro, depois alfabético
  });

  test('repassa a falha intacta no caminho de erro', () async {
    when(() => repo.getAllProducts())
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase();

    expect(result, const Left(NetworkFailure()));
  });
}
```

Repare que o erro foi testado sem nenhum `try/catch`: o mock devolve `Left`, e a asserção é sobre um valor. É o `fpdart` pagando de novo.

### Cubit: o centro, com `bloc_test`

Aqui a regra de ouro brilha. O `build` monta o cubit injetando o use case mockado, sem tocar em locator nenhum. O `expect` afirma a sequência exata de estados, que casa por valor graças ao `Equatable`:

```dart
// test/modules/catalog_module/presentation/product_list/product_list_cubit_test.dart
class MockGetAllProductsUseCase extends Mock implements GetAllProductsUseCase {}

void main() {
  late MockGetAllProductsUseCase getAll;
  setUp(() => getAll = MockGetAllProductsUseCase());

  final produtos = [
    const Product(id: 1, name: 'Teclado', description: '', price: 1, stock: 1),
  ];

  blocTest<ProductListCubit, ProductListState>(
    'emite [Loading, Loaded] quando carrega com sucesso',
    build: () {
      when(() => getAll()).thenAnswer((_) async => Right(produtos));
      return ProductListCubit(getAllProducts: getAll);
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductListLoading(),
      ProductListLoaded(products: produtos),
    ],
  );

  blocTest<ProductListCubit, ProductListState>(
    'emite [Loading, Error] quando o use case falha',
    build: () {
      when(() => getAll())
          .thenAnswer((_) async => const Left(NetworkFailure()));
      return ProductListCubit(getAllProducts: getAll);
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ProductListLoading(),
      ProductListError(failure: NetworkFailure()),
    ],
  );
}
```

Dois testes cobrem o cubit inteiro, sucesso e erro, e nenhum deles montou o `get_it`. Esse "nenhum locator no teste" é o pagamento direto da regra de ouro ([seção 15](#15-injeção-de-dependências-quem-localiza-quem-injeta)): como o cubit recebe tudo por construtor, o teste passa o mock e acabou.

### Dados: testando o `zard` na fronteira

A camada `data` é onde mora a serialização, então é onde se testa que um payload ruim vira `Left(ValidationFailure)` em vez de estourar um erro cru ([seção 7.4](#74-dados-model-introduzindo-zard)):

```dart
test('payload com stock negativo vira ValidationFailure', () {
  final result = ProductModel.tryParse(
    {'id': 1, 'name': 'X', 'description': '', 'price': 1.0, 'stock': -3},
  );
  expect(result.isLeft(), isTrue);
});
```

Sem o schema, esse teste exigiria provocar um `TypeError` e capturá-lo. Com o `zard`, o erro é um valor previsto, e o teste é uma linha.

### Interface: um widget test por estado

Como a tela é um `switch` sobre estado `sealed`, dá para testar cada ramo isolado. O `MockCubit` (vem do `bloc_test`) emite o estado que você quer, e você verifica o que aparece:

```dart
class MockProductListCubit extends MockCubit<ProductListState>
    implements ProductListCubit {}

testWidgets('mostra o spinner no estado Loading', (tester) async {
  final cubit = MockProductListCubit();
  whenListen(
    cubit,
    const Stream<ProductListState>.empty(),
    initialState: const ProductListLoading(),
  );

  await tester.pumpWidget(MaterialApp(
    home: BlocProvider<ProductListCubit>.value(
      value: cubit,
      child: const ProductListPage(),
    ),
  ));

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

Um teste assim por estado (Loading, Loaded, Error) cobre a tela. O `sealed` ajuda de novo: adicionou um estado e esqueceu de cobri-lo? É o mesmo tipo te lembrando.

### A pirâmide, e as pegadinhas honestas

A intuição de quanto testar de cada: muitos testes de domínio e de cubit (são rápidos e baratos, sem inicializar o Flutter no domínio), alguns de widget, poucos de integração. E três pegadinhas que economizam uma tarde:

- **`registerFallbackValue`.** Se você usar o matcher `any()` com um tipo seu (não primitivo), o `mocktail` exige registrar um valor de fallback antes (`registerFallbackValue(FakeProduct())`), senão o teste estoura. Pegadinha clássica de quem começa.
- **Esqueceu o `Equatable`?** O `expect` do `bloc_test` compara estados por valor. Sem `Equatable`, dois estados idênticos viram diferentes e o teste falha com uma mensagem confusa. É a [seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit) cobrando a fatura dela.
- **Navegação é território de integração.** Testar `redirect` e guards do go_router ([seção 14](#14-navegação-avançada-guards-onexception-e-rotas-por-constante)) de ponta a ponta é teste de integração, mais caro. Se quiser cobrir a lógica do `redirect` barato, extraia-a numa função pura e teste isolada.

O resumo é o de sempre neste guia: a parte difícil do teste já foi resolvida lá atrás, quando você escolheu injetar por construtor, carregar o erro no tipo e comparar por valor. O teste só recolhe o que esses acertos plantaram.

---

## 18. Exercício: módulos de Pedidos e Clientes

Replique o módulo de catálogo. **Módulo de Pedidos** (`/orders`, subrota `details/:id`): entidade `Order` + `OrderItem`; contrato `OrderRepository` retornando `Either<Failure, T>`; `OrderRepositoryImpl` mockado com `OrderModel` validado por `zard`; use case com regra de verdade (`PlaceOrderUseCase` validando estoque, calculando total/desconto); páginas com `pageBuilder`; cubits com estado `sealed`, `Either` e guarda `isClosed`. Não esqueça os **barrels** de cada pasta e o **barrel público** expondo só `OrdersRoutes` + `registerOrdersModule`. **Módulo de Clientes** (`/customers`): mesma receita, mais simples. Por fim, registre as rotas no `app_router.dart` (uma branch do shell por módulo) e os módulos no `injection.dart`. E espelhe a pasta `test/`: escreva, para cada módulo, os testes de use case e de cubit como na [seção 17](#17-testes-bloc_test-mocktail-e-a-regra-de-ouro).

---

## Parte V: Levando para produção

O que separa um protótipo de um app na loja: ambientes, idioma, segurança, monitoramento, feature flags, testes A/B e performance.

---

## 19. Ambientes e flavors

Um app de verdade roda em mais de um ambiente: o `dev` que aponta para a API de teste, o `staging` que valida antes do lançamento, e o `prod` que vai para a loja. Cada um quer uma URL de API, um nome e ícone, e um destino de log diferentes. A forma de separar isso sem espalhar `if (ambiente == ...)` pelo código é com **flavors** (variantes de build) e um `AppConfig` imutável.

### Um ponto de entrada por ambiente, um bootstrap só

Em vez de um `main.dart`, você tem um ponto de entrada por ambiente, e todos chamam um `bootstrap` compartilhado. O ambiente só monta o `AppConfig` e entrega:

```dart
// lib/bootstrap.dart: a subida compartilhada (o que era o main da seção 5)
Future<void> bootstrap(AppConfig config) async {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    getIt.registerSingleton<AppConfig>(config); // config visível para todos
    Bloc.observer = const AppBlocObserver();
    setupLocator();
    // FlutterError.onError / PlatformDispatcher.onError (seção 5)
    runApp(const AppWidget());
  }, (e, st) => log('Uncaught', name: 'app', error: e, stackTrace: st));
}
```

```dart
// lib/main_dev.dart
void main() => bootstrap(const AppConfig(
      ambiente: 'dev',
      apiBaseUrl: 'https://api.dev.loja.com',
    ));

// lib/main_prod.dart
void main() => bootstrap(const AppConfig(
      ambiente: 'prod',
      apiBaseUrl: 'https://api.loja.com',
    ));
```

O `AppConfig` é uma entidade imutável (`final` + `const`, [seção 11](#11-imutabilidade-copywith-manual-e-seus-limites)) registrada como singleton de app no `get_it`. Qualquer serviço que precise da URL lê `getIt<AppConfig>()`, do mesmo jeito que lê qualquer outro serviço de vida longa ([seção 15](#15-injeção-de-dependências-quem-localiza-quem-injeta)). Nada de variável global solta.

Você roda cada ambiente apontando o entrypoint e o flavor nativo:

```bash
flutter run -t lib/main_dev.dart --flavor dev
flutter build apk -t lib/main_prod.dart --flavor prod
```

### Config por arquivo

Para não chumbar a config no código, o jeito moderno é o `--dart-define-from-file`, que injeta valores em tempo de compilação, lidos por `String.fromEnvironment`:

```bash
flutter run --dart-define-from-file=config/dev.json
```

O `config/dev.json` (fora do controle de versão, se tiver algo sensível) guarda os pares de chave e valor, e o `AppConfig` os lê. É a alternativa sem nenhuma dependência nova.

> **O flavor nativo é trabalho de plataforma.** O `--flavor dev` exige um `productFlavor` no `build.gradle` (Android) e um scheme no Xcode (iOS), cada um com seu identificador, nome e ícone. É um boilerplate por plataforma, feito uma vez. O Dart resolve a config; o nativo resolve a identidade do app na loja.

E uma ressalva que conecta com a segurança ([seção 21](#21-segurança-blindando-o-app)): valor passado por `--dart-define` fica embutido no binário. Serve para URL e flags, nunca para segredo de verdade.

---

## 20. Internacionalização

Se o app vai além de um público só, o texto não pode morar chumbado nos widgets. A internacionalização (i18n, abreviação de *internationalization*, com 18 letras entre o "i" e o "n") tira as frases da interface e as coloca em arquivos por idioma, com o pt-BR como base.

### A exceção consciente ao "sem geração de código"

Aqui a gente abre, de propósito, uma exceção à regra de não gerar código, e ela se justifica: manter à mão um mapa de centenas de frases por idioma é pior do que deixar uma ferramenta gerar a classe de acesso. A base é o `flutter_localizations` (do SDK) mais o package `intl`, com as traduções em arquivos **ARB** (*Application Resource Bundle*, um JSON de chave para texto):

```json
// lib/l10n/intl_pt.arb
{
  "catalogoTitulo": "Catálogo",
  "esgotado": "Esgotado",
  "semConexao": "Sem conexão. Tente de novo."
}
```

```json
// lib/l10n/intl_en.arb
{
  "catalogoTitulo": "Catalog",
  "esgotado": "Out of stock",
  "semConexao": "No connection. Try again."
}
```

### A extensão Flutter Intl do VSCode

Para não rodar comandos à mão, use a extensão Flutter Intl (da Localizely) no VSCode. Ela cria a estrutura de ARB, regera a classe de acesso toda vez que você salva uma tradução, e tem comando para adicionar um idioma novo. O resultado é uma classe `S` que você usa na tela:

```dart
// antes (frase chumbada, da seção 7.6):
appBar: AppBar(title: const Text('Catálogo')),
// depois:
appBar: AppBar(title: Text(S.of(context).catalogoTitulo)),
```

A ligação no `MaterialApp.router`:

```dart
MaterialApp.router(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  // ...
);
```

> **Onde o idioma encaixa na arquitetura.** A regra de idioma da [seção 1](#1-convenções-de-código) continua: identificadores e domínio em pt-BR. O que muda é só o texto que o usuário lê, que sai do código para o ARB. Lembra do `_messageFor(Failure)` da [seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit), que mapeava cada falha para uma frase? Com i18n, ele passa a devolver a chave de tradução, e a UI continua escolhendo a mensagem por tipo de `Failure`, agora traduzida.

Plurais e gênero têm sintaxe própria no ARB (o formato ICU, *International Components for Unicode*), então "1 item" e "3 itens" saem certos sem `if`. E como a `S` é gerada, errar o nome de uma chave quebra na compilação, não em runtime.

---

## 21. Segurança: blindando o app

Robustez não é só não quebrar, é não vazar. Esta seção é sobre blindar o app, e ela começa pela verdade mais importante: o binário que está na mão do usuário é inspecionável. Segurança no cliente é defesa em camadas; a fronteira real é o servidor. Nunca embarque confiança no app.

Com isso firmado, o que dá para fazer do lado do cliente:

- **Segredos não moram no app.** Chave de API, secret, token fixo: nada disso no código nem em `--dart-define` ([seção 19](#19-ambientes-e-flavors)), porque os dois ficam no binário, extraíveis. O que é sensível fica no servidor, atrás de um endpoint seu.
- **Token de sessão em armazenamento seguro.** O token do usuário logado vai no `flutter_secure_storage` (Keychain no iOS, Keystore no Android), nunca no `SharedPreferences`, que é texto puro. Esse armazenamento entra como um serviço no `get_it` e alimenta a `Session` da [seção 14](#14-navegação-avançada-guards-onexception-e-rotas-por-constante).
- **Só HTTPS, e considere o pinning.** Todo tráfego em HTTPS (o "S" de seguro, com transporte cifrado). Para apps sensíveis, *certificate pinning* (fixar o certificado do servidor) num interceptor do `Dio` (um ponto que mexe em toda requisição), na camada `data`, que é o tradutor de tudo que é rede ([seção 16b](#b-either-x-exceção-onde-fica-a-fronteira)).
- **Valide o que entra.** O `zard` no limite do `data` ([seção 7.4](#74-dados-model-introduzindo-zard)) não é só contra API que muda: é contra payload malicioso. Dado de fora é não confiável até validado.
- **Não logue segredo nem dado pessoal.** A ressalva de PII (dados pessoais) da observabilidade ([seção 10](#10-observabilidade-o-blocobserver-global)) é também de segurança: token e e-mail no log são vazamento.
- **Ofusque o release.** O `flutter build --obfuscate --split-debug-info=...` embaralha os nomes no binário, encarecendo a engenharia reversa. Não é blindagem mágica, é mais uma camada.

> **A blindagem mora na fronteira certa.** Repare que cada item acima cai numa fronteira que a arquitetura já tem: validação no `data`, segredo no servidor, token num serviço do `get_it`, sessão no guard. Segurança não vira uma camada nova bagunçada; ela se distribui pelas fronteiras que você já desenhou.

---

## 22. Monitoramento e alertas em produção

A [seção 5](#5-camada-base-do-app) instalou as redes que capturam todo erro, e a [seção 10](#10-observabilidade-o-blocobserver-global) acrescentou o `BlocObserver`. Lá, o destino era o `log()`. Em produção, o destino vira uma ferramenta que te avisa quando algo quebra na mão do usuário. Esta seção saca essa promessa.

### Trocar o destino, não o ponto de instalação

O ponto de instalação não muda: os três callbacks do `main` e o `onError` do observer. Só o corpo troca de `log()` para a ferramenta:

```dart
FlutterError.onError = (details) {
  FirebaseCrashlytics.instance.recordError(details.exception, details.stack);
};
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

As ferramentas mais comuns: **Firebase Crashlytics** (crashes e erros não fatais, de graça), **Sentry** (erros com mais contexto, e também performance) e o **Firebase Analytics** para eventos de uso. A escolha é de time; o ponto de entrada é o mesmo nas três.

### Migalhas de contexto, com cuidado

O `onChange` do `BlocObserver` ([seção 10](#10-observabilidade-o-blocobserver-global)) é uma fonte natural de *breadcrumbs* (migalhas, o rastro de eventos que antecedeu o crash): cada transição de estado vira uma migalha, e quando o erro chega, você vê o filme até ali. Vale o lembrete da própria seção 10: nunca mande dado pessoal nessas migalhas.

### Alertas que valem a pena

Capturar não basta; alguém precisa ser avisado. O que configurar:

- **Crash-free users** (a porcentagem de usuários sem nenhum crash) abaixo de um limite, por exemplo 99,5%, dispara alerta no Slack ou e-mail.
- **Tipo de erro novo** ou **regressão** (um erro que tinha sumido e voltou) avisa na hora.
- **Pico na taxa de erro** depois de um lançamento sinaliza para considerar um rollback (voltar à versão anterior).

> **Alerta demais é o mesmo que alerta nenhum.** Se tudo dispara notificação, o time aprende a ignorar. Comece com poucos alertas de alto valor (crash-free e regressão) e só adicione o resto quando doer. Monitorar é escolher o que merece te acordar de madrugada.

---

## 23. Feature flags: mudar o app sem novo lançamento

No [seção 19](#19-ambientes-e-flavors) a configuração era decidida no build: o flavor escolhe a URL e o ícone, e isso fica gravado no binário. Tem um limite aí. Para mudar qualquer coisa decidida no build, você gera uma versão nova e passa de novo pela revisão da loja, que pode levar dias. Uma feature flag (chave de funcionalidade) cobre o outro lado: é um valor que o app busca de um servidor enquanto roda e que muda o comportamento sem um novo lançamento. O flavor é configuração de build; a flag é configuração de runtime (o tempo em que o app está na mão do usuário). Os dois convivem.

A ferramenta aqui é o Firebase Remote Config, do mesmo ecossistema que já apareceu no monitoramento ([seção 22](#22-monitoramento-e-alertas-em-produção)): a chave mora no servidor, e o app lê o valor.

### Por que usar, e onde dói

Antes do código, a conta honesta. Feature flags trocam complexidade de lançamento por complexidade de código e de operação. Quando o controle que elas dão vale mais que esse custo, compensam. Quando viram um fim em si, atrapalham.

O que elas resolvem:

- **Desacoplam o deploy do lançamento.** Você sobe o código com a feature desligada e a liga quando quiser. No mobile isso vale ouro, porque o caminho até a loja é lento e a flag te devolve o controle do "quando".
- **Liberação gradual.** Em vez de ligar para todo mundo de uma vez, você abre para 1%, observa erro e métrica, e sobe para 10%, 50%, 100%. Se algo degrada, o estrago atingiu uma fração da base.
- **Kill switch.** Uma feature quebrou em produção? Você desliga na hora, sem esperar um hotfix passar pela revisão da loja. É o complemento do rollback que o [seção 22](#22-monitoramento-e-alertas-em-produção) mencionou.
- **Segmentação.** Ligar só para um país, uma versão do app ou um grupo de testadores internos, sem espalhar `if` pelo código.
- **Merges menores.** Dá para integrar trabalho ainda incompleto atrás de uma flag desligada, evitando aquele branch que vive semanas e dói no merge.

O que elas cobram:

- **Dívida de flags.** Cada flag é um `if` a mais, e o número de caminhos possíveis cresce rápido. Flag que ninguém remove vira código morto que ninguém entende.
- **Bug mais difícil de reproduzir.** O que roda na mão do usuário depende de um estado remoto que não está no binário nem no commit. "Aqui funciona" pode ser só uma flag diferente.
- **Estado inicial e rede.** O app precisa de um valor padrão para funcionar no primeiro abrir e offline, e de cuidado para a tela não "piscar" quando o valor remoto chega depois.
- **Governança.** Sem dono, data de validade e faxina, o conjunto de flags vira um pântano. A ferramenta é barata; a disciplina é o custo recorrente.

Com isso na mesa, vamos ao como.

### A flag atrás de uma interface

A regra é a mesma do repositório ([seção 8](#8-domínio-e-dados-a-regra-que-não-pode-vazar)): o app não conhece o Firebase, conhece um contrato. Você declara uma interface de flags e a injeta pelo `get_it`, do jeito de sempre ([seção 15](#15-injeção-de-dependências-quem-localiza-quem-injeta)).

```dart
// core/feature_flags/feature_flags.dart: o contrato, sem nada de Firebase
abstract class FeatureFlags {
  bool get novoCheckout;
  String get varianteBotaoCompra; // 'controle' ou 'destaque'
}
```

```dart
// core/feature_flags/remote_config_flags.dart: a implementação concreta
class RemoteConfigFlags implements FeatureFlags {
  RemoteConfigFlags(this._remoteConfig);
  final FirebaseRemoteConfig _remoteConfig;

  @override
  bool get novoCheckout => _remoteConfig.getBool('novo_checkout');

  @override
  String get varianteBotaoCompra =>
      _remoteConfig.getString('variante_botao_compra');
}
```

```dart
// no setupLocator (seção 15): o resto do app só enxerga a interface
getIt.registerSingleton<FeatureFlags>(
  RemoteConfigFlags(FirebaseRemoteConfig.instance),
);
```

O ganho é o de sempre: trocar o Firebase por outra ferramenta (ConfigCat, Flagsmith, um endpoint seu) é reescrever uma classe e mudar uma linha no locator. Nada mais no app sabe quem entrega a flag, e o domínio continua livre do framework.

### Defaults primeiro, fetch depois

A flag depende de rede, e rede falha. Por isso o Remote Config sempre tem um valor padrão embutido no app, usado no primeiro abrir e quando o fetch não volta. O padrão de uma feature nova é, quase sempre, desligada.

```dart
// no bootstrap, antes do runApp (seção 19)
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.setDefaults(const {
  'novo_checkout': false,             // feature nova nasce desligada
  'variante_botao_compra': 'controle',
});
await remoteConfig.setConfigSettings(RemoteConfigSettings(
  fetchTimeout: const Duration(seconds: 10),
  minimumFetchInterval: const Duration(hours: 1),
));
// não bloqueia a subida: busca em segundo plano e usa o default até chegar
remoteConfig.fetchAndActivate();
```

Repare que não damos `await` no `fetchAndActivate`. O app sobe na hora com os defaults, e os valores do servidor entram quando a busca termina. Para uma mudança valer em segundos, sem esperar o próximo ciclo, existe o Remote Config em tempo real:

```dart
// opcional: aplica a mudança nos apps abertos quase na hora
remoteConfig.onConfigUpdated.listen((_) => remoteConfig.activate());
```

É esse modo em tempo real que faz o kill switch valer a pena: você desliga a feature no painel e os aparelhos abertos obedecem em segundos.

### Onde uma flag muda o comportamento

Três usos honestos cobrem quase tudo.

O primeiro é trocar um pedaço de tela. Você lê a flag pela interface e escolhe o widget:

```dart
if (getIt<FeatureFlags>().novoCheckout) {
  return const NovoCheckoutPage();
}
return const CheckoutPage();
```

O segundo é esconder uma rota inteira ainda não liberada, no `redirect` do go_router ([seção 14](#14-navegação-avançada-guards-onexception-e-rotas-por-constante)), do mesmo jeito que um guard de sessão:

```dart
redirect: (context, state) {
  final indoProNovoCheckout = state.matchedLocation == '/checkout/novo';
  if (indoProNovoCheckout && !getIt<FeatureFlags>().novoCheckout) {
    return '/checkout'; // devolve para o fluxo antigo
  }
  return null;
},
```

Vale o mesmo cuidado do [seção 14](#14-navegação-avançada-guards-onexception-e-rotas-por-constante): o `redirect` roda muito, então a leitura tem que ser barata e síncrona. O `getBool` do Remote Config lê o valor já em memória, sem I/O, então cabe ali sem peso.

O terceiro é o kill switch: uma flag que existe só para desligar uma feature em emergência. Não precisa de código especial, é a mesma leitura de `bool`; o que muda é a intenção e a pressa (por isso o modo em tempo real). Quando o alerta do [seção 22](#22-monitoramento-e-alertas-em-produção) disparar, alguém vira a chave no painel e o incidente para de sangrar enquanto o time investiga.

### Liberação gradual e segmentação, na prática

No Remote Config a liberação gradual sai de duas formas. A manual usa uma Condição do tipo "usuário em percentil aleatório menor ou igual a X%": você entrega o valor novo só a esse X e vai subindo o X com calma, e quem entrou em 10% continua dentro quando você vai para 50%. A melhor usa o recurso de Lançamentos, que faz essa rampa monitorando o crash-free pelo Crashlytics e deixa pausar ou reverter sozinho se a métrica cair. É o canário do [seção 22](#22-monitoramento-e-alertas-em-produção) com rede de segurança.

A segmentação vem das mesmas Condições: versão do app, plataforma, país e idioma, data, públicos e propriedades do Google Analytics, e aparelhos de teste específicos. Dá para ligar uma feature só no Android, só no Brasil, só da versão 3.2 em diante.

Dois limites honestos, para não vender mágica. Tudo é puxado pelo cliente: o valor só passa a valer depois que o app busca e ativa, na velocidade do `minimumFetchInterval` ou do tempo real, então a liberação não é instantânea na base inteira, é na medida em que os aparelhos buscam. E a segmentação é por atributo de aparelho e por público do Analytics, não por usuário individual escolhido a dedo, como fazem ferramentas dedicadas (LaunchDarkly e parecidas). Para grande porte com targeting fino por usuário, vale comparar.

### Pagando a dívida de flags

Esse é o contra que mais machuca no longo prazo, então merece disciplina explícita.

> **Toda flag nasce com data de morte.** Cada flag tem um dono e um prazo. Quando a feature chega a 100% e prova que ficou, você apaga a flag e o ramo antigo do código, no mesmo PR. Flag de rollout que vira permanente é dívida disfarçada: daqui a um ano ninguém lembra se dá para remover, e o medo de mexer congela o código. A faxina não é opcional, é parte de usar flags.

### Testando código com flag

Como a flag está atrás de uma interface injetada, o teste não toca no Firebase. Você faz um mock com `mocktail` ([seção 17](#17-testes-bloc_test-mocktail-e-a-regra-de-ouro)) e cobre os dois ramos:

```dart
class MockFeatureFlags extends Mock implements FeatureFlags {}

test('mostra o novo checkout quando a flag está ligada', () {
  final flags = MockFeatureFlags();
  when(() => flags.novoCheckout).thenReturn(true);
  // injeta flags no lugar da implementação real e verifica o ramo novo
});
```

Os dois caminhos que a flag cria ficam testáveis sem rede, com a mesma regra de ouro do resto do projeto: o construtor recebe a dependência, e o teste passa um dublê.

> **Flag não é segredo nem permissão.** Valor de Remote Config é visível no aparelho, então nunca coloque chave de API ou senha ali, pela mesma razão do [seção 21](#21-segurança-blindando-o-app). E uma flag ligada não autoriza nada sozinha: quem decide se o usuário pode mesmo usar a feature é o servidor. A flag escolhe o que aparece; a fronteira de verdade continua no backend.

---

## 24. Testes A/B: decidir com dados

Toda equipe tem aquela discussão sobre qual botão converte mais, se o checkout deve ter uma ou duas etapas, qual texto vende melhor. No fim, quem decide costuma ser quem fala mais alto ou quem tem mais tempo de casa. Um teste A/B troca o achismo por evidência: você mostra a versão A para um grupo de usuários e a B para outro, mede qual sai melhor numa métrica que importa, e deixa o dado decidir.

E aqui o capítulo anterior se paga. Um teste A/B é a flag do [seção 23](#23-feature-flags-mudar-o-app-sem-novo-lançamento) com o valor escolhido pela ferramenta de experimento, mais uma métrica medida. A infraestrutura você já montou; falta o método.

### A ferramenta certa, e o que ela não é

A ferramenta é o Firebase A/B Testing, e ela não é um produto solto: é uma camada montada sobre o Remote Config (que entrega a variante) e o Google Analytics (que mede o resultado), os dois que já estão no projeto. Ela cobre três tipos de experimento: de Remote Config (variar o comportamento do app por um parâmetro, o nosso caso), de Cloud Messaging (variar uma notificação) e de In-App Messaging (variar uma mensagem dentro do app).

> **Não é teste A/B de backend.** O Firebase A/B Testing decide e mede no cliente, no app instalado. Se o que você quer testar é a lógica do servidor (um ranking calculado na API, uma regra de preço, um motor de recomendação), ele não serve, e forçar leva a conclusão errada. Experimento de servidor roda na sua própria infraestrutura ou numa plataforma feita para isso. É a mesma ideia da arquitetura toda: cada coisa na fronteira certa.

### Como montar: hipótese, variante e público

Um bom teste começa por uma hipótese única e uma métrica-alvo, escritas antes de começar. Por exemplo: "trocar o checkout de duas etapas por uma aumenta a taxa de compras concluídas". Sem isso, você só coleta números e procura algum que pareça bom depois, que é o jeito mais rápido de se enganar.

A variante chega pela flag do [seção 23](#23-feature-flags-mudar-o-app-sem-novo-lançamento). O app lê `flags.varianteBotaoCompra` como sempre e nem sabe que está num experimento; quem decide quem recebe o quê é o painel. A atribuição é fixa por usuário: o Firebase sorteia a variante por um hash do identificador da instalação, então a mesma pessoa vê sempre a mesma versão, mesmo fechando e abrindo o app.

A métrica você não precisa amarrar à mão. O Firebase liga os eventos do Analytics à variante por baixo dos panos, então basta o app já registrar o evento-meta que você mede normalmente:

```dart
// o evento que o experimento vai comparar entre as variantes
await FirebaseAnalytics.instance.logEvent(name: 'compra_concluida');
```

No alvo do experimento entram duas escolhas que mudam a leitura: a porcentagem de exposição (quanto da base entra no teste) e o público. E aqui mora um detalhe importante: testar usuários novos é diferente de testar os antigos. O usuário antigo já tem hábito, então uma mudança sofre o efeito novidade (ele reage só porque algo mudou, e isso passa). O usuário novo não tem com o que comparar. Escolher o público é parte do desenho, não um detalhe. Vale lembrar que públicos do Analytics levam de um a dois dias para encher, e que um evento de ativação restringe a medição a quem fez uma ação, sem impedir que o parâmetro chegue aos demais.

### A estatística sem virar estatístico: de bayesiano a frequentista

Aqui vale uma nota de história, porque muita gente aprendeu o Firebase de um jeito que mudou. Até novembro de 2023, o A/B Testing usava estatística bayesiana, herdada do Google Optimize. Ele reportava algo como "probabilidade de a variante superar o controle", calculado por um método de amostragem que você não conseguia refazer por fora. Funcionava, mas era uma caixa-preta: dava para confiar, não para conferir.

De lá para cá, ele passou a usar inferência frequentista, e isso é bom para quem quer entender o resultado. O número central agora é o p-value, com nível de significância de 0,05 (confiança de 95%). Em português claro: um p-value abaixo de 0,05 quer dizer que, se na verdade não houvesse diferença nenhuma entre as variantes, a chance de ver uma diferença tão grande quanto a observada, só por acaso, seria menor que 5%. Quando essa diferença para o controle é significativa, o Firebase aponta a variante como líder (e, havendo várias, escolhe a de menor p-value). Junto, ele mostra o intervalo de confiança de 95% do ganho, com o pior e o melhor caso, que vale mais que o número seco. Por baixo, é um teste t para métricas contínuas (tempo, valor gasto) e um teste z de proporções para conversões (comprou ou não). Você não precisa decorar isso, mas agora dá para verificar a conta, em vez de engolir o veredito.

### Por que rodar pelo menos duas semanas

O Firebase recomenda no mínimo 14 dias para um experimento de Remote Config (7 dias para os de mensagem) e processa os dados por no máximo 90 dias, encerrando sozinho depois disso. O número não é capricho.

Duas semanas é o tempo de pegar uma amostra representativa e medir efeito que dura, não só o susto inicial. O comportamento de uma terça é diferente do de um sábado, então você quer cobrir o ciclo da semana inteiro, de preferência dois fins de semana. E é o prazo que dilui o efeito novidade, aquela alta que aparece só porque a coisa mudou e some depois. O Firebase hoje aponta o líder assim que detecta significância, mas isso não te autoriza a encerrar no terceiro dia.

> **Não espie e pare cedo.** Olhar o painel todo dia e encerrar no primeiro resultado bonito infla o falso positivo: com tentativas suficientes, o acaso uma hora desenha uma diferença que não existe. Defina a duração antes, deixe rodar, e mude uma variável por vez. Testar três coisas ao mesmo tempo te diz que algo mudou, não qual delas moveu o ponteiro.

### Como conferir os dados

O primeiro lugar é o painel do A/B Testing, atualizado uma vez por dia. Ele separa dois blocos: os dados observados (as médias de cada métrica, vindas direto do Analytics) e os dados de inferência (o p-value e o intervalo de confiança). É ali que aparecem o líder e a faixa de ganho esperada.

Quando o painel não basta e você quer saber o porquê, o experimento vira uma propriedade de usuário no Analytics, no formato `firebase_exp_...`, cujo valor é o índice da variante (começando do zero). Com ela, você filtra qualquer relatório ou funil do Google Analytics por variante e vê onde, no caminho, uma ganhou ou perdeu da outra. Para análise livre, o BigQuery (no plano Blaze) recebe os eventos brutos e aceita a consulta que você quiser, e o próprio console gera uma query de exemplo para começar. O painel dá o veredito; o Analytics e o BigQuery dão a explicação.

### Boas práticas, privacidade e a faxina

Para o teste valer alguma coisa, ele precisa de volume. Um app com pouco tráfego não chega a um p-value abaixo de 0,05 num prazo razoável, e aí o experimento vira teatro de rigor. Para baixo volume, é mais honesto liberar em fases (o rollout do [seção 23](#23-feature-flags-mudar-o-app-sem-novo-lançamento)) e ouvir o usuário de perto do que rodar um A/B sem força estatística. Uma hipótese clara, uma variável por vez, e paciência.

Tem também a parte de respeito ao usuário. A atribuição de variante e os eventos do Analytics são dados dele, então valem o consentimento previsto na LGPD (a lei brasileira de proteção de dados) e a mesma regra de PII (dados pessoais) do [seção 22](#22-monitoramento-e-alertas-em-produção): nunca mande nome, e-mail ou documento como parâmetro de evento. É a fronteira de segurança do [seção 21](#21-segurança-blindando-o-app) de novo, agora na telemetria.

E, no fim, a faxina. Quando o teste dá veredito, o Firebase deixa você lançar a variante vencedora, o que fixa aquele valor no Remote Config para todo mundo. Aí fecha o ciclo do capítulo anterior: a flag cumpriu o papel, então remova a flag e o ramo perdedor do código. Experimento que ninguém encerra é só mais uma dívida de flag esquecida.

---

## 25. Performance: medindo com o Flutter DevTools

A regra de ouro da performance é a mesma de qualquer otimização: meça antes de mexer. O palpite quase sempre erra o gargalo. A ferramenta para medir é o **Flutter DevTools**, e o primeiro acerto é rodar em *profile mode* (`flutter run --profile`), num aparelho real, nunca em debug, que é propositalmente lento e mente sobre os tempos.

O que olhar em cada aba:

- **Performance.** Mostra cada frame renderizado. O alvo é caber em 16ms (60 quadros por segundo) ou 8ms (em telas de 120Hz). Frame que estoura isso é *jank* (a travada que o usuário sente). A aba separa o trabalho da thread de UI (o seu código Dart) do da thread de raster (o desenho na tela), apontando qual é o gargalo.
- **CPU profiler.** Acha a função que está comendo tempo, para você saber onde mexer.
- **Memory.** Mostra o heap (a memória alocada) e ajuda a flagrar vazamento. É aqui que dá para conferir uma promessa do guia: o dispose automático do estado de tela ([seção 27](#27-economia-de-recursos-o-que-é-real-e-o-que-não-é)). Abra uma tela, volte, e veja o cubit sair da memória.
- **Track widget rebuilds.** Conta quantas vezes cada widget reconstrói. Aqui se vê, na prática, o dedup do `Equatable` ([seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit)): estado igual não reconstrói, e o contador prova.

### O que a arquitetura já te deu de graça

Boa parte do que costuma travar um app já está resolvido pelas escolhas anteriores:

- O `const` nos construtores ([seção 11](#11-imutabilidade-copywith-manual-e-seus-limites)) evita reconstrução: widget `const` não é refeito.
- O `ListView.builder` ([seção 7.6](#76-apresentação-estado-e-página-com-fpdart-no-cubit)) constrói só os itens visíveis, então uma lista de mil produtos não pesa.
- O dedup do `Equatable` corta o rebuild redundante.

Quando ainda assim houver jank, os ajustes finos: `buildWhen` no `BlocBuilder` para reconstruir só quando a parte que importa muda, e `RepaintBoundary` em volta de algo caro de desenhar que muda sozinho. Mas só depois de medir, porque otimizar no escuro é tempo jogado fora.

---

## Parte VI: Veredito honesto e referências

Até onde isso escala, o que de fato economiza, e para onde ir depois.

---

## 26. Robustez e escala: o que é estrutural e o que depende de disciplina

Vou ser direto: esta arquitetura escala, mas parte disso vem de graça e parte depende de você manter a disciplina. Separo as duas, porque vender só a primeira metade seria desonesto.

**Escala sozinho (estrutural):** crescimento **linear** por módulo (nova pasta + uma rota + um register; nunca tocar no existente); camadas com dependência só pra dentro (troca de fonte de dados não sobe); desacoplamento por nome de rota; **barrels** impondo a fronteira de cada módulo; estado previsível pela prescritividade do bloc.

**Depende de disciplina (seja honesto com o time):**

- **O `get_it` é o ponto de falha de escala.** Sem a regra de ouro ([seção 15](#15-injeção-de-dependências-quem-localiza-quem-injeta)), degenera num registro global gigante. Com ela, escala bem. Exige cultura, não só código.
- **"Módulo" aqui é convenção de pasta, reforçada por barrel, não package isolado.** O barrel **desencoraja** importar o interno de outro módulo, mas não **impede** fisicamente (dá para furar importando o caminho completo do arquivo). Em times grandes onde isso vira problema, o próximo passo é promover cada módulo a um **package** do workspace (fronteira que o compilador faz cumprir), fora do escopo aqui.
- **Sem code-gen tem custo recorrente**: `copyWith` manual, registro de DI manual, schemas `zard` à mão. Previsível e barato, mas existe.

Veredito: base robusta e honesta para grande porte, contanto que o time abrace a regra de ouro do `get_it` e respeite os barrels. Não é "robusto mágico", é "robusto se você mantém a fronteira".

---

## 27. Economia de recursos: o que é real e o que não é

A economia existe, mas vem de **dois mecanismos**, e um terceiro que muita gente assume e não acontece.

**Real (e automático):**

- **Lazy: paga só pelo que abre.** Tela não visitada não instancia cubit; `registerLazySingleton` só cria o serviço no primeiro `getIt()`. Um app de 30 módulos não carrega 30 módulos.
- **Dispose automático do estado de tela.** O `BlocProvider` chama `close()` no cubit ao sair da árvore: streams cancelam, listeners liberam. Você **não acumula** cubits de telas fechadas.

**NÃO acontece (a correção):**

- **Serviços singleton no `get_it` NÃO sofrem dispose ao sair do módulo.** Vivem o app inteiro de propósito, é cache compartilhado, não vazamento. O **estado de tela** é descartado (bloc); os **serviços** persistem.
- **Dispose de serviços por módulo/sessão é opt-in, via scopes** ([seção 16a](#a-scope-de-sessão-registrar-no-login-descartar-no-logout)).
- **Um shell (`StatefulShellRoute.indexedStack`) mantém as abas visitadas vivas.** Trocar de aba não descarta a branch (é o que preserva o estado dela, [seção 12](#12-shell-de-navegação-com-statefulshellroute)); o dispose do estado de tela vale ao **sair** do shell, não ao alternar abas.

| Recurso | Quem cria | Quando é descartado |
|---|---|---|
| Cubit/estado da tela | `BlocProvider` no `pageBuilder` | Automático, ao sair da tela (`close()`) |
| Estado de uma aba do shell | branch do `StatefulShellRoute` | Ao sair do shell, não ao trocar de aba |
| Use case (factory) | `getIt()` no ponto de montagem | Nada a descartar (sem estado) |
| Repositório/serviço (singleton de app) | `registerLazySingleton` | Vive o app todo (intencional) |
| Serviço de sessão (singleton de scope) | `pushNewScope` no login | `dropScope` no logout (opt-in) |

A frase honesta: a economia vem do lazy + do dispose automático do estado de tela. Os serviços são persistência intencional. Prometa isso, e o app entrega; prometa "dispose de tudo ao trocar de módulo", e você está mentindo para o leitor.

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
| **Shell `StatefulShellRoute.indexedStack`** | Abas com pilha e estado próprios; cuidados na seção 12 |
| **Auth guard (`redirect` + `refreshListenable`)** | Rota protegida decide por estado de sessão; deep-link-safe, com return-url |
| **Testes (`bloc_test` + `mocktail`)** | Mock injetado por construtor; estados conferidos por valor |
| **`fpdart Either` (erros previstos)** | Compilador obriga a tratar; nada vaza cru na UI |
| **Captura global no `main` (erros imprevistos)** | Nada morre em silêncio; pronto para Crashlytics |
| **`BlocObserver` global (`Bloc.observer`)** | Observabilidade transversal: `onChange` audita o estado; `onError` é a quarta rede |
| **`zard` no limite do data** *(opcional)* | Valida payload; erro descritivo em vez de cast cru |
| **`equatable`** | Dedupe de rebuild do estado funciona de verdade |
| **Imutabilidade manual (`copyWith`, `@immutable`)** | Estado comparável e previsível; `ValueGetter` para limpar campo nullable |
| **`registerLazySingleton` + scopes** | Lazy; scope dá dispose de sessão (opt-in) |
| **Guarda `isClosed` antes de `emit`** | Evita `StateError` quando a tela fecha no `await` |
| **`Cubit` + estados `sealed`** | Estado simples, previsível, exaustivo |
| **Flavors + `AppConfig`** | dev/staging/prod sem `if` espalhado; config injetada por ambiente |
| **Internacionalização (`intl` + ARB)** | texto fora do código; a exceção consciente do guia |
| **Segurança nas fronteiras** | segredo no servidor, token em armazenamento seguro, validação no `data` |
| **Monitoramento (Crashlytics/Sentry)** | mesmo ponto de instalação da seção 5; troca só o destino, com alertas |
| **Feature flags (Remote Config)** | liga e desliga sem novo lançamento; rollout gradual e kill switch atrás de uma interface |
| **Testes A/B (Firebase A/B Testing)** | decide por experimento, não por achismo; a variante é uma flag, a métrica vem do Analytics |
| **Performance (Flutter DevTools)** | meça em profile mode; `const` e dedup do `equatable` já ajudam |

Um app modular, baixo acoplamento, domínio limpo, erros em duas camadas, pronto para deep links e fácil de testar, escalável para grande porte enquanto o time mantém a regra de ouro do `get_it` e os barrels, só com pacotes consolidados (o `zard` é a única aposta mais nova, e opcional), sem um único `.g.dart`.

---

## 28. Versões de referência (junho de 2026)

| Package | Versão | Observação |
|---|---|---|
| `go_router` | **17.3.0** | `onException`, `redirect`+`refreshListenable`, `StatefulShellRoute.indexedStack`. Versão mínima: Flutter 3.38 / Dart 3.10. |
| `get_it` | **9.2.1** | Scopes, async singletons, lazy singletons. |
| `flutter_bloc` / `bloc` | **9.1.1 / 9.2.1** | `Bloc.observer` + `MultiBlocObserver` para observabilidade. |
| `equatable` | **2.0.8** | Estados/eventos `sealed` e value objects. |
| `fpdart` | **1.2.0** | `Either<Failure, T>` para o erro previsto, na assinatura. |
| `zard` | *ver pub.dev* | Port do [Zod](https://zod.dev); jovem, confira a API atual. |
| `provider` | **6.1.5+1** | Só como dependência transitiva do `flutter_bloc`. |
| `injectable` / `freezed` / `go_router_builder` | n/a | Exigem `build_runner`, **fora da premissa**. |

## 29. Próximos capítulos

- **CI/CD** (integração e entrega contínuas): automatizar build, testes e publicação a cada push, para a disciplina deste guia ser verificada por máquina, não por memória.
- **Acessibilidade**: `Semantics`, contraste e navegação por leitor de tela, para o app servir a mais gente.
- **Cache e offline**: estratégia de cache no repositório (que já é o singleton dono dos dados, [seção 7.5](#75-dados-implementação-do-repositório)) e fila de sincronização, para o app funcionar sem rede.

---

## Sobre o autor

Euclides Catunda é um profissional de tecnologia da informação com mais de 28 anos de carreira, marcada pela versatilidade e por um envolvimento constante com o desenvolvimento de software. Sua trajetória vai da infraestrutura e do suporte técnico à gestão de equipes e à construção de sistemas complexos para os mais variados setores.

Como gerente de tecnologia no setor público, coordenou equipes multidisciplinares e liderou iniciativas pioneiras: sistemas de gestão da rede escolar e do transporte municipal, um serviço de ouvidoria via 0800 e a instalação das primeiras 100 lousas digitais interativas do país. Tem orgulho especial da participação no Programa Bolsa Escola Municipal, que beneficiou mais de 16 mil famílias. A experiência se estende à segurança pública, com um sistema de controle de acesso para penitenciárias em Pernambuco, além da saúde, do setor de concursos públicos e do varejo. No desenvolvimento do aplicativo mobile para vendedores da Americanas S/A, aplicou arquitetura e código limpo, gestão de estado e cobertura completa de testes, unitários e de integração, a mesma combinação que sustenta este livro.

Hoje, como Developer Specialist no Grupo Boticário, dedica-se à criação de aplicativos móveis em Flutter. Seus projetos estão em [github.com/euclidesgc](https://github.com/euclidesgc), e ele está em [linkedin.com/in/euclidesgc](https://www.linkedin.com/in/euclidesgc/) para uma conversa, um tópico novo ou um erro encontrado.

---

## Agradecimentos

Este livro não existiria sem o trabalho de quem mantém o ecossistema Dart e Flutter, e em especial as pessoas por trás de `go_router`, `get_it`, `bloc`, `equatable` e `fpdart`, cujas decisões de design moldaram boa parte do que está aqui.

Obrigado também aos colegas que revisaram ideias, brigaram com elas em code review e me obrigaram a justificar cada regra. E a você, que decidiu investir o seu tempo aqui: que estas páginas te poupem algumas das tardes que elas me custaram.
