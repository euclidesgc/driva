# Integração — colocar conteúdo do driva dentro do seu app Flutter

Este é o guia de quem está **de fora**: você tem um app Flutter, alguém da sua
equipe monta telas no editor do driva, e você quer que o app desenhe essas
telas. O caminho é o package `driva_client`.

O ciclo inteiro cabe em duas linhas: `Driva.init(...)` uma vez, no `main`, e
`DrivaContent(slug: '...')` onde a tela deve aparecer. O resto — HTTP, cache,
revalidação, o que fazer quando a rede cai — é responsabilidade do package.

Leitura de dez minutos. As seções são independentes; se você só quer o exemplo
mínimo, ele está no `README.md` do package.

---

## 1. Adicionar o package ao app

O `driva_client` **não está publicado no pub.dev**. Ele é consumido de duas
formas, conforme onde o seu app mora.

**Dentro deste repositório** (é o caso do `apps/driva_demo_app`), pelo
workspace do pub:

```yaml
dependencies:
  driva_client: ^0.2.0
```

com o package listado no `workspace:` do `pubspec.yaml` da raiz e o
`resolution: workspace` no `pubspec.yaml` do seu app — o mesmo padrão que
`sdui_core` e `sdui_flutter` já seguem.

**Fora deste repositório**, por dependência de git, fixada numa tag:

```yaml
dependencies:
  driva_client:
    git:
      url: https://github.com/<org>/driva.git
      path: packages/driva_client
      ref: <tag-de-release-do-driva>
```

Fixe sempre uma `ref`. Sem ela o `pub get` segue o branch padrão, e a sua build
muda de comportamento sem você ter mexido em nada. Atenção a uma confusão fácil:
a `ref` é uma **tag de release do repositório** (`v0.3.0`, `v0.4.0`, …), que não
é a mesma numeração da **versão do package**. Para saber qual versão do
`driva_client` uma tag carrega, olhe o `version:` de
`packages/driva_client/pubspec.yaml` naquela tag.

> **A versão atual do package é `0.2.0`.** Ela traz uma mudança de
> comportamento — não de assinatura — em relação à `0.1.0`: a falha de
> carregamento passou a ter **causa tipada** (§4) e `load()` deixou de terminar
> em silêncio quando nada pôde ser servido (§5). Nenhuma assinatura pública
> mudou, então atualizar não quebra compilação.

O package traz `sdui_core` e `sdui_flutter` junto — você não precisa declará-los
para renderizar. Só declare `sdui_flutter` explicitamente se for montar um
`SduiRegistry` próprio (ver §3).

---

## 2. A chave publicável: onde obter e por que ela vai embarcada no app

Cada projeto do driva tem uma **chave publicável** (`publishableKey`), gerada na
criação do projeto. É ela que diz à API qual projeto o seu app consome — não há
`projectId` no caminho da URL, e a rota pública **não aceita** um projeto vindo
do cliente.

### Onde obter

A chave aparece na resposta de `GET /v1/projects` da API do editor, um campo
`publishableKey` em cada projeto:

```bash
curl -sS https://<sua-api>/v1/projects | python3 -m json.tool
```

O `apps/driva_demo_app` automatiza isso: `apps/driva_demo_app/tool/run_demo.sh`
busca a chave do ambiente e a injeta como `--dart-define` na hora de rodar ou de
gerar o APK. É um bom modelo para o script de build do seu app.

### Por que ela pode ir embarcada

Porque ela é pública por natureza — e isso é uma decisão de projeto, não um
descuido. A chave publicável:

- **só lê conteúdo publicado.** Rascunho não sai pela rota pública. Se alguém
  salvar uma tela no editor sem publicar, o app não vê a mudança;
- **nunca escreve.** Não existe `POST`/`PUT`/`DELETE` na superfície pública;
- **nunca lista projetos** nem revela nada além do projeto dela;
- **não distingue "chave errada" de "conteúdo inexistente".** As duas coisas
  devolvem `404`, então sondar a API com uma chave inventada não conta nada a
  ninguém.

O pior que alguém extraindo a chave do seu APK consegue fazer é ler as mesmas
telas que qualquer usuário do seu app já vê. É o mesmo modelo de uma chave de
API de mapas ou de analytics.

Duas coisas que continuam valendo mesmo assim:

- **a chave é por ambiente.** A de homologação não é a de produção. Trate como
  configuração de build;
- **chave não entra no repositório.** Ela vai por `--dart-define`, seguindo o
  padrão que o `driva_demo_app` já usa: os `config/<env>.json` versionados
  trazem um placeholder, e quem preenche é o script de build.

```json
{
  "API_BASE_URL": "https://<sua-api>",
  "PUBLISHABLE_KEY": "cole-aqui-a-chave-do-projeto"
}
```

```bash
flutter run --dart-define-from-file=config/hml.json
```

### O prefixo `pk_` — e por que ele poupa você de um bug caro

Toda chave publicável real começa com **`pk_`** (é `pk_` mais 32 bytes
aleatórios em base64url, gerado pelo backend na criação do projeto). O
placeholder do arquivo versionado, não.

Isso te dá uma verificação **local, antes de qualquer chamada de rede**: se a
chave que chegou por `--dart-define` não começa com `pk_`, ela não é uma chave —
é o placeholder que ninguém substituiu no build. Trate esse caso como um estado
próprio da tela ("falta a chave, veja como obtê-la"), sem montar `DrivaContent`.

Não é preciosismo. A API responde **`404`** para chave inexistente, exatamente
como responde para slug não publicado (é decisão de segurança, §Apêndice), então
sem essa verificação um binário com o placeholder embarcado abre com a mesma
"tela vazia" de um slug que ninguém publicou, e ninguém consegue dizer qual dos
dois é. Já custou uma tarde de investigação neste projeto — e a lição virou
código: `apps/driva_demo_app/tool/run_demo.sh` aborta o build quando a chave não
vem no formato `pk_`, em vez de assar o placeholder dentro do APK.

> **Rotação de chave ainda não existe.** Não há endpoint para trocar a chave de
> um projeto. Se a sua precisar mudar, hoje isso é operação de banco. Está
> registrado como pendência do item 25.

---

## 3. `Driva.init` e os campos do `DrivaConfig`

`Driva.init` é chamado **uma vez**, antes de `runApp`. Ele é idempotente: chamar
de novo com a mesma configuração não faz mal. Usar `DrivaContent` sem ter
chamado `init` lança um `StateError` com a mensagem dizendo o que fazer — é erro
de programação, não de runtime, e aparece na primeira execução.

```dart
import 'package:driva_client/driva_client.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Driva.init(
    DrivaConfig(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      publishableKey: const String.fromEnvironment('PUBLISHABLE_KEY'),
    ),
  );

  runApp(const MyApp());
}
```

O `WidgetsFlutterBinding.ensureInitialized()` é obrigatório: o cache em disco
usa um canal de plataforma, e ele não existe antes do binding.

### Os campos

| Campo | Obrigatório | O que é |
| --- | --- | --- |
| `baseUrl` | sim | A raiz da sua API, **sem** o `/v1` e sem barra no fim (`https://api.exemplo.com`). O package monta `/v1/public/contents/<slug>` a partir daí. |
| `publishableKey` | sim | A chave da §2. Vai no header `x-driva-key` de toda requisição. |
| `fallbacks` | não | Mapa `slug → spec JSON` embarcado no app. Ver §6. |
| `registry` | não | Um `SduiRegistry` do `sdui_flutter` com os seus builders. O default é o `defaultRegistry`, que cobre todo o catálogo. Ver abaixo. |
| `cache` | não | Onde o conteúdo é guardado entre execuções. O default persiste em disco; existe uma implementação em memória para testes. Ver §5. |

**Sobre o `registry`.** Passe um só se o seu app precisar desenhar um tipo de
widget de forma diferente do padrão, ou se você quiser cortar builders que não
usa. Um registry incompleto tem consequência visível: um nó cujo `type` está no
catálogo mas não tem builder no seu registry vira uma caixa com a borda vermelha
e o texto `Tipo desconhecido: "<type>"` na tela — o renderer não deixa a tela
inteira cair por causa de um nó, mas também não esconde o buraco. Na dúvida, não
passe `registry` nenhum.

### Testar o seu app sem rede de verdade: o `httpClient`

`Driva.init` aceita um segundo parâmetro, **nomeado e opcional**, fora do
`DrivaConfig`:

```dart
static Future<void> init(DrivaConfig config, {http.Client? httpClient})
```

Ele é repassado ao repositório interno. É o que permite ao **seu** teste de
widget simular a rede — responder `200` com um spec de mentira, devolver `404`,
ou lançar como se o aparelho estivesse offline — sem servidor no ar e sem
depender de homologação. Em produção não passe nada: sem `httpClient`, o package
cria o seu próprio `http.Client`.

Duas coisas que o teste precisa saber:

- **`Driva.init` é idempotente** — se já houve um `init`, o segundo é ignorado
  **inteiro**, inclusive o `httpClient` novo. Por isso todo teste começa (ou
  termina) com `Driva.resetForTesting()`, que zera o singleton;
- **passe `cache: MemoryCacheStore()`** — o cache padrão persiste em disco por
  um canal de plataforma, que não existe no ambiente do `flutter test`.

```dart
import 'package:driva_client/driva_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(Driva.resetForTesting);
  tearDown(Driva.resetForTesting);

  testWidgets('a tela mostra o aviso quando o conteúdo não existe', (
    tester,
  ) async {
    await Driva.init(
      DrivaConfig(
        baseUrl: 'https://api.example.com',
        publishableKey: 'pk_test',
        cache: MemoryCacheStore(),
      ),
      httpClient: MockClient((request) async => http.Response('', 404)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DrivaContent(
            slug: 'home',
            errorBuilder: (context, error) =>
                const Text('Conteúdo indisponível'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conteúdo indisponível'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

`MockClient` vem de `package:http/testing.dart` — declare `http` em
`dev_dependencies` do seu app.

---

## 4. Desenhar o conteúdo: `DrivaContent`

```dart
DrivaContent(
  slug: 'home',
  onAction: (action) => debugPrint('ação: ${action.type}'),
  loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
  errorBuilder: (context, error) => const Center(
    child: Text('Não foi possível carregar esta tela.'),
  ),
)
```

- **`slug`** — o identificador da tela no editor. É o mesmo slug que aparece na
  URL do conteúdo lá dentro. É a única coisa obrigatória.
- **`onAction`** — chamado quando o usuário toca em algo que o spec declarou
  como evento. **Hoje ele nunca dispara** — ver §8.
- **`loadingBuilder`** — o que mostrar enquanto não há nada para desenhar. Só
  aparece na **primeira** abertura de um slug sem cache: com cache, o conteúdo
  vem imediatamente e não existe estado de carregando. Sem `loadingBuilder`, o
  espaço fica vazio até chegar a resposta.
- **`errorBuilder`** — o que mostrar quando não sobrou nada para desenhar: sem
  cache, sem fallback, e a rede falhou. **Passe sempre.** Ele é a diferença
  entre "o usuário vê um aviso e um botão de tentar de novo" e "a tela fica em
  branco e ninguém sabe por quê".

### O que o `errorBuilder` recebe: `DrivaLoadFailure` e a causa

**A partir da `0.2.0`** o objeto entregue ao `errorBuilder` é um
`DrivaLoadFailure`, e ele diz **por que** falhou:

```dart
class DrivaLoadFailure implements Exception {
  const DrivaLoadFailure({required this.slug, required this.cause});
  final String slug;
  final DrivaLoadCause cause;
}

enum DrivaLoadCause { network, notFound, invalidSpec, serverError }
```

Antes disso o `errorBuilder` recebia sempre o mesmo `StateError` genérico, e não
havia como o seu app distinguir "o celular está sem rede" de "esse slug não
existe" — as duas coisas viravam a mesma tela. **A assinatura não mudou**:
`DrivaErrorBuilder` continua sendo `Widget Function(BuildContext, Object)`, então
um app que ignora o tipo do erro continua compilando e funcionando igual. Quem
quiser a causa faz um `is`/`switch`.

| `cause` | O que aconteceu | O que costuma ser | O que mostrar ao usuário |
| --- | --- | --- | --- |
| `network` | o `http.Client` lançou; nunca chegou a existir uma resposta HTTP | celular offline, DNS, timeout, API fora do ar | "sem conexão" + **tentar de novo** |
| `notFound` | o servidor respondeu `404` | slug sem publicação **ou** chave publicável inválida — as duas, indistinguíveis (ver abaixo) | "esta tela não está disponível", nomeando as duas causas |
| `invalidSpec` | veio `200`, mas o corpo não virou um `ContentSpec` válido | `specVersion` publicada mais nova que a do app instalado (§7), widget fora do catálogo desta versão, JSON corrompido | "atualize o app" — tentar de novo não resolve |
| `serverError` | qualquer outro status ≠ `200`/`304` — e o balde do que o package não conseguiu classificar | `500`, `502`, gateway do seu proxy | "instabilidade momentânea" + **tentar de novo** |

```dart
DrivaContent(
  slug: 'home',
  errorBuilder: (context, error) => switch (error) {
    DrivaLoadFailure(cause: DrivaLoadCause.notFound) => const MyContentMissingView(),
    DrivaLoadFailure(cause: DrivaLoadCause.invalidSpec) => const MyAppOutdatedView(),
    _ => const MyConnectionErrorView(),
  },
)
```

Três cuidados que valem a pena:

1. **`404` não separa "chave errada" de "slug não publicado", e não vai
   separar.** É decisão de segurança da rota pública (§Apêndice): distinguir as
   duas coisas entregaria a quem sonda a API de fora um jeito de descobrir quais
   projetos existem. Consequência para você: o texto do estado `notFound` deve
   nomear **as duas** possibilidades, e o caso "esqueci de substituir o
   placeholder da chave" você resolve **antes**, pelo prefixo `pk_` (§2), sem
   chamada de rede nenhuma.
2. **Mantenha um caminho `default`.** O parâmetro é tipado como `Object` de
   propósito: hoje o package só emite `DrivaLoadFailure`, mas o contrato não
   promete que nunca chegará outra coisa, e um `switch` sem saída derruba o seu
   `errorBuilder` — que é justamente a tela que existe para nada cair.
3. **Instrumente.** `DrivaLoadFailure` carrega o `slug`, e `toString()` já sai
   como `DrivaLoadFailure(slug: home, cause: DrivaLoadCause.notFound)` — mande
   para o seu Crashlytics/Sentry. Com a causa separada, `invalidSpec` subindo na
   base inteira é o alerta de que alguém publicou conteúdo à frente da versão
   que está nas lojas (§7), e você só descobre isso do lado do app: o servidor
   devolveu `200` para todo mundo.

`DrivaContent` cabe em qualquer lugar da árvore — dentro de um `Scaffold`, de
uma aba, de um `ListView`. Ele desenha o conteúdo do spec e mais nada; a
`AppBar`, a navegação e o chrome do seu app continuam sendo seus.

### Recarregar sob demanda (pull-to-refresh, botão "atualizar")

`DrivaContent` já revalida sozinho toda vez que é montado: ele mostra o cache na
hora e consulta o servidor em seguida. O que ele **não** tem hoje é um método
público para você mandar revalidar sem remontá-lo.

O padrão para um botão de recarregar é **trocar a `Key`**, o que remonta o widget
e dispara uma resolução nova (memória → disco → rede):

```dart
int _reloadNonce = 0;

DrivaContent(
  key: ValueKey('$slug-$_reloadNonce'),
  slug: slug,
)

// no onPressed do botão:
setState(() => _reloadNonce++);
```

Isso é comportamento **suportado**, não truque: `load(slug)` devolve um `Stream`
novo a cada escuta, e o widget cancela a assinatura anterior ao ser descartado.
Trocar apenas o `slug` também basta — a troca de slug já força a nova resolução
sem precisar do nonce.

> **Limitação conhecida.** Uma API explícita (algo como um `DrivaContentController`
> com `refresh()`) seria mais direta e é o caminho natural quando o package for
> publicado no pub. Enquanto ela não existe, a `Key` é a forma recomendada — e é
> a que o `apps/driva_demo_app` usa.

---

## 5. O que acontece sem rede

A resolução tem **três degraus, nessa ordem: memória → disco → rede.** O
primeiro que tiver o conteúdo desenha a tela; a rede é consultada **em paralelo**
para revalidar (o padrão *stale-while-revalidate*). A consequência prática é que,
da segunda abertura em diante, a tela aparece instantaneamente, mesmo com a rede
ruim ou ausente.

A revalidação usa o `ETag` que o servidor manda: se nada mudou, a resposta é
`304` sem corpo, e **o widget não reconstrói** — nenhum piscar, nenhum reflow.
Se mudou, o spec novo é gravado no cache e a tela troca sozinha.

O cache é chaveado por chave publicável **e** slug, então dois projetos
diferentes no mesmo app não se misturam. E se uma entrada gravada não passar
pela validação do kernel — arquivo corrompido, formato inesperado —, ela é
**apagada** e o fluxo segue para a rede ou para o fallback. O package nunca
desenha um spec que não foi validado.

### Os casos, e o que o usuário final vê

| Situação | O que o package faz | O que o usuário vê |
| --- | --- | --- |
| **Sem cache e sem fallback** (primeira abertura, offline) | memória vazia → disco vazio → rede falha → não há o que desenhar: `load()` fecha o stream com `DrivaLoadFailure(cause: DrivaLoadCause.network)` | o seu `errorBuilder`, agora sabendo a causa. Sem `errorBuilder`: **nada** — um espaço vazio, e uma linha no log. Nunca uma exceção na sua árvore de widgets, nunca a tela vermelha do Flutter |
| **Slug que não existe (ou chave inválida)** | a rede responde `404` → `DrivaLoadFailure(cause: DrivaLoadCause.notFound)` | o seu `errorBuilder`, e desta vez dá para dizer "esta tela não existe" em vez de "sem conexão" |
| **Spec que o app não entende** (`specVersion` nova, widget fora do catálogo) | o parse recusa → cai no fallback se houver; senão, `DrivaLoadFailure(cause: DrivaLoadCause.invalidSpec)` | a tela do fallback ou o seu `errorBuilder`. Nunca uma tela meio-desenhada (§7) |
| **Com cache** (já abriu antes, agora offline) | o disco entrega na hora; a revalidação falha em background e vira log | a **última versão publicada que o app chegou a baixar**, imediata. Ele nem percebe que está offline |
| **Com fallback** (primeira abertura, offline, fallback embarcado) | memória e disco vazios, rede falha → cai no fallback do `Driva.init` | a tela do fallback — a que estava valendo no dia em que você gerou o binário |

Quando há cache **e** fallback, o cache ganha: ele é mais novo. E vale a regra
que atravessa a tabela inteira: **enquanto alguma fonte serviu conteúdo, não há
falha.** `DrivaLoadFailure` só nasce no caso em que nada, absolutamente nada,
pôde ser desenhado.

Nada disso interrompe o seu app. É a garantia central do runtime: **o
`driva_client` nunca derruba a tela do cliente.** Falha de rede, timeout, JSON
malformado, servidor fora do ar — tudo termina em um dos degraus acima, e o pior
deles é um `SizedBox.shrink()` com log.

### Se você usa o repositório direto, sem o `DrivaContent`

`Driva.instance.repository.load(slug)` devolve um `Stream<ContentSpec>`, e isso
é superfície pública — dá para consumi-lo à mão, num cubit ou num
`StreamBuilder` seu, em vez de usar o widget pronto. **Aqui houve mudança de
comportamento na `0.2.0`, e ela pede atenção:**

- **antes:** na falha total o stream simplesmente **completava sem emitir
  nada**. Um `StreamBuilder` ficava para sempre no estado de carregando, e
  ninguém era avisado de nada. Era falha silenciosa, e foi por isso que mudou;
- **agora:** o stream **fecha pelo canal de erro**, com `DrivaLoadFailure`.

Ou seja: se você escuta esse stream por conta própria, **trate o erro**. Um
`Stream` que fecha com erro sem `onError` (ou um `await for` sem `try`) vira
erro assíncrono não capturado — no seu `runZonedGuarded`, no console, e em nada
de útil na tela.

```dart
Driva.instance.repository.load('home').listen(
  (spec) => emit(ContentLoaded(spec)),
  onError: (Object error) => emit(
    ContentFailed(
      error is DrivaLoadFailure ? error.cause : DrivaLoadCause.serverError,
    ),
  ),
);
```

Quem usa `DrivaContent` não precisa fazer nada: o widget já escuta o `onError` e
entrega o objeto ao seu `errorBuilder` — é exatamente essa a diferença entre as
duas superfícies.

---

## 6. Fallback embarcado: como e por que

Fallback é uma cópia do spec, em JSON, que viaja **dentro** do binário do app.
Ele é o último degrau antes de não haver nada.

Coloque o arquivo nos assets:

```
assets/driva/home.json
```

```yaml
flutter:
  assets:
    - assets/driva/
```

Carregue e registre no `init` — o package recebe o JSON **já decodificado**, ele
não lê o asset por você:

```dart
import 'dart:convert';

import 'package:driva_client/driva_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final home = jsonDecode(
    await rootBundle.loadString('assets/driva/home.json'),
  ) as Map<String, dynamic>;

  await Driva.init(
    DrivaConfig(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      publishableKey: const String.fromEnvironment('PUBLISHABLE_KEY'),
      fallbacks: {'home': home},
    ),
  );

  runApp(const MyApp());
}
```

**Como obter o JSON.** É o campo `spec` da resposta da rota pública. Com a tela
publicada e a chave em mãos:

```bash
curl -sS -H "x-driva-key: $PUBLISHABLE_KEY" \
  https://<sua-api>/v1/public/contents/home \
  | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["spec"], indent=2, ensure_ascii=False))' \
  > assets/driva/home.json
```

Vale automatizar esse passo no seu pipeline de release, para o fallback não
envelhecer sem ninguém notar.

**Por que isso importa.** Sem fallback, a primeira abertura do app sem rede é uma
tela vazia — e "primeira abertura" inclui todo usuário que acabou de instalar,
que trocou de celular ou que limpou os dados. Com fallback, ele vê uma tela real,
só possivelmente desatualizada. Para a home, o onboarding e qualquer caminho de
que o app não pode abrir mão, **embarque o fallback.**

E existe um segundo motivo, que é o assunto da próxima seção.

---

## 7. ⚠️ O caso perigoso: o servidor publica um `specVersion` mais novo que o app instalado

Este é o cenário que mais assusta em Server-Driven UI, e ele é real. Merece ser
entendido antes de você colocar o primeiro app na loja.

### O que acontece

O spec carrega um campo `specVersion`. O app carrega uma constante equivalente,
`kSpecVersion` (`packages/sdui_core/lib/src/schema/spec_version.dart` — hoje
vale `1`), **congelada no momento em que o binário foi gerado**. O servidor não
sabe — e não tem como saber — qual versão cada instalação carrega.

Se um dia o driva subir para `specVersion: 2` e alguém publicar uma tela nesse
formato, o app que está na loja com `kSpecVersion: 1` recebe esse JSON e o
kernel o recusa:

```
specVersion 2 não suportada (atual: 1)
```

O runtime trata isso como **falha de parse** — exatamente como trataria um JSON
corrompido. Ou seja: não renderiza, apaga a entrada do cache, e desce os degraus
da §5 — **fallback → `errorBuilder` → `SizedBox.shrink()` com log.** Não sobe
exceção, o app não quebra, nenhuma tela meio-desenhada aparece.

Se não houver fallback, a causa que chega ao seu `errorBuilder` é
`DrivaLoadCause.invalidSpec` — e é **a única das quatro em que "tentar de novo"
não adianta nada**: o servidor vai devolver o mesmo `200` com o mesmo spec na
próxima tentativa. O caminho de saída honesto para o usuário é pedir a
atualização do app, não um botão de recarregar.

### O mesmo buraco tem uma entrada mais larga: widget novo no catálogo

Não é preciso um bump de `specVersion` para cair aqui. O kernel valida cada nó
contra o catálogo de widgets, e um `type` desconhecido é recusado com

```
root.children[2]: tipo "carousel" fora do catálogo
```

Isso é `Left` do parse do **conteúdo inteiro** — não é degradação parcial. Se o
seu time publicar uma tela usando um widget que só existe numa versão do driva
mais nova que a do app instalado, **a tela inteira cai no fallback**, não só o
widget novo.

(Não confunda com a caixa `Tipo desconhecido: "<type>"` da §3: aquela aparece
quando o tipo *está* no catálogo mas falta um builder no seu `registry`
customizado. Aí sim é degradação de um nó só.)

### O que você, desenvolvedor, precisa fazer a respeito

1. **Embarque fallback nas telas críticas.** É a única coisa que transforma
   "tela vazia" em "tela do release anterior". Vale mais aqui do que no caso
   offline, porque essa falha atinge **todos** os usuários da versão antiga ao
   mesmo tempo, e no melhor dos casos de conectividade.
2. **Passe sempre `errorBuilder`**, com uma mensagem honesta e um caminho de
   saída (tentar de novo, ou um pedido de atualização do app). Falha silenciosa
   é o defeito difícil de descobrir.
3. **Instrumente o `errorBuilder`.** Mande o erro para a sua ferramenta de
   monitoramento. É como você vai saber que uma parcela da base parou de
   renderizar — o servidor devolveu `200` para todo mundo, então não haverá
   nada de anormal do lado dele.
4. **Trate bump de `specVersion` ou widget novo como release coordenado.**
   Publique o app primeiro, espere a adoção, publique o conteúdo depois. Não
   existe hoje, do lado do servidor, um mecanismo que sirva spec diferente por
   versão de app — **a coordenação é sua**, e é uma conversa entre quem edita
   conteúdo e quem publica o app.
5. **Não faça de uma tela remota o único caminho para um fluxo crítico** sem
   fallback embarcado. Se o pagamento só existe no spec, o pagamento é tão
   disponível quanto o parse do spec.

---

## 8. O que ainda não funciona (diga ao seu time antes que ele descubra sozinho)

Duas limitações grandes, ditas sem rodeio.

### Ações são inertes — um botão publicado hoje não faz nada

O renderer já sabe entregar uma ação: o builder de `button` chama o `onAction`
com o conteúdo de `events['onPressed']`
(`packages/sdui_flutter/lib/src/builders/button.dart`). O que falta é a outra
ponta — **o editor ainda não deixa autorar evento nenhum**. O spec que sai do
driva hoje vem sem `events`, e por isso o `onAction` do seu app **nunca é
chamado**.

Na prática: você pode publicar um botão bonito, e ele será um botão que não
navega, não abre nada e não avisa ninguém. O parâmetro `onAction` já existe no
contrato de propósito, para que a chegada das ações não exija uma versão nova do
package — mas até lá, **não prometa comportamento de botão para o seu time de
conteúdo.**

Está no roadmap como **item 28 — Eventos e ações editáveis no Inspector**
(`docs/roadmap.md`).

### Binding de dados não resolve — `{{user.name}}` aparece literalmente na tela

O editor já reconhece e deixa escrever `{{expressão}}` num campo de texto, e o
kernel guarda isso como **dado**. Mas **o renderer não resolve nada**: não há
contexto de dados, não há de onde tirar o valor. Um texto publicado como
`Olá, {{user.name}}` chega ao usuário final como as sete letras `Olá, ` seguidas
de `{{user.name}}`.

Está no roadmap como **item 29 — Contexto de dados e binding com contrato**.

Enquanto isso não existir, trate todo conteúdo do driva como **estático**: texto,
imagem, layout. Dado que muda por usuário continua vindo do código do seu app.

---

## 9. Limitação de plataforma: esta fatia mira Flutter nativo

O alvo suportado é **app Flutter nativo — mobile e desktop.** É o que foi
construído, testado e exercitado ponta a ponta.

**Flutter Web de terceiro não está resolvido.** Um app web servido do seu
domínio faz a requisição a partir do navegador do usuário, e aí entra o CORS: a
forma correta é o driva registrar as **origens autorizadas por projeto** e
responder de acordo. Isso não existe — não há onde cadastrar origem, e portanto
não há como o driva distinguir o seu site do site de qualquer outra pessoa.

Consequência prática: **não coloque um app Flutter Web de produção em cima
disto ainda.** O comportamento de CORS da rota pública é provisório e pode
mudar quando o cadastro de origens for implementado, o que quebraria a sua
página sem aviso. Para desenvolver e testar rodando em Chrome, funciona.

Outras plataformas (React Native, SDK web em JavaScript, nativo iOS/Android
puro) não têm cliente. A rota pública é HTTP comum e qualquer um pode consumi-la,
mas aí o cache, a revalidação, o fallback e a validação do spec passam a ser
seus.

---

## Apêndice — a rota pública, para quem quiser conferir

Você não precisa disto para usar o package. Está aqui para depurar, para montar
um script de release, ou para consumir a API de outra plataforma.

**Uma tela pelo slug**

```
GET /v1/public/contents/<slug>
x-driva-key: <chave publicável>
```

```json
{
  "id": "...",
  "name": "Home",
  "slug": "home",
  "updatedAt": "2026-08-19T12:00:00.000Z",
  "spec": { "specVersion": 1, "kind": "content", "...": "..." }
}
```

- `updatedAt` é o instante da **publicação**, não o do último autosave do
  rascunho. Salvar sem publicar não muda a resposta nem invalida o cache de
  ninguém.
- `ETag` vem em toda resposta `200`. Repita a requisição com
  `If-None-Match: <etag>` e o servidor devolve **`304` sem corpo** se nada
  mudou. É o que o package faz sozinho.
- `Cache-Control: public, max-age=60, must-revalidate`.
- **`404`** para: slug inexistente, conteúdo sem versão publicada, chave
  ausente, chave inválida, chave de outro projeto e projeto arquivado. É um
  `404` só, de propósito — a resposta não conta a quem sonda se o problema foi a
  chave ou o conteúdo. No package, todos esses casos chegam ao `errorBuilder`
  como `DrivaLoadCause.notFound` (§4); a única forma de separar o caso "a chave
  nem é uma chave" é a checagem local do prefixo `pk_`, da §2.

**A lista do que está publicado**

```
GET /v1/public/contents
x-driva-key: <chave publicável>
```

```json
{ "data": [{ "id": "...", "name": "Home", "slug": "home", "updatedAt": "..." }] }
```

Sem o campo `spec` — é um índice. Útil para o seu app descobrir quais telas
existem sem baixar todas.

**Não faça polling agressivo.** O package já revalida na hora certa e usa o
`ETag` para não trafegar corpo à toa; um loop de requisições do lado do app é a
forma mais fácil de derrubar o serviço para todos os projetos.

---

## Referências

- `packages/driva_client/README.md` — a versão curta, com o exemplo mínimo.
- `packages/driva_client/lib/src/driva_load_failure.dart` — `DrivaLoadFailure` e
  `DrivaLoadCause`, a fonte da verdade da tabela de causas da §4.
- `packages/driva_client/test/driva_content_test.dart` — o `Driva.init(...,
  httpClient:)` da §3 exercitado de verdade, incluindo o `404` que entrega
  `DrivaLoadCause.notFound` ao `errorBuilder`.
- `apps/driva_demo_app/` — app real que consome a rota pública; o `README.md`
  dele mostra o padrão de `--dart-define-from-file` e o script que descobre a
  chave.
- `packages/sdui_core/lib/src/catalog/widget_catalog.dart` — o catálogo de
  widgets: o que pode existir num spec.
- `backend/src/public/public.controller.ts` — a rota pública, a fonte da verdade
  do apêndice acima.
- `docs/plans/25-entrega-app-cliente/plan.md` — o plano e as decisões travadas
  que este guia documenta.
