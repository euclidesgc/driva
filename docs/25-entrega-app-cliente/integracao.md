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
  driva_client: ^0.1.0
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
      ref: v0.1.0
```

Fixe sempre uma `ref`. Sem ela o `pub get` segue o branch padrão, e a sua build
muda de comportamento sem você ter mexido em nada.

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

O `error` entregue ao `errorBuilder` serve para diagnóstico — mandar para o seu
Crashlytics/Sentry, escrever no log. Não construa lógica de negócio em cima do
tipo dele: o package resolve as falhas por dentro e não expõe a hierarquia de
erros interna como contrato público.

`DrivaContent` cabe em qualquer lugar da árvore — dentro de um `Scaffold`, de
uma aba, de um `ListView`. Ele desenha o conteúdo do spec e mais nada; a
`AppBar`, a navegação e o chrome do seu app continuam sendo seus.

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

### Os três casos, e o que o usuário final vê

| Situação | O que o package faz | O que o usuário vê |
| --- | --- | --- |
| **Sem cache e sem fallback** (primeira abertura, offline) | memória vazia → disco vazio → rede falha → não há o que desenhar | o seu `errorBuilder`. Sem `errorBuilder`: **nada** — um espaço vazio, e uma linha no log. Nunca uma exceção, nunca a tela vermelha do Flutter |
| **Com cache** (já abriu antes, agora offline) | o disco entrega na hora; a revalidação falha em background e vira log | a **última versão publicada que o app chegou a baixar**, imediata. Ele nem percebe que está offline |
| **Com fallback** (primeira abertura, offline, fallback embarcado) | memória e disco vazios, rede falha → cai no fallback do `Driva.init` | a tela do fallback — a que estava valendo no dia em que você gerou o binário |

Quando há cache **e** fallback, o cache ganha: ele é mais novo.

Nada disso interrompe o seu app. É a garantia central do runtime: **o
`driva_client` nunca derruba a tela do cliente.** Falha de rede, timeout, JSON
malformado, servidor fora do ar — tudo termina em um dos três degraus acima, e o
pior deles é um `SizedBox.shrink()` com log.

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
  chave ou o conteúdo.

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
- `apps/driva_demo_app/` — app real que consome a rota pública; o `README.md`
  dele mostra o padrão de `--dart-define-from-file` e o script que descobre a
  chave.
- `packages/sdui_core/lib/src/catalog/widget_catalog.dart` — o catálogo de
  widgets: o que pode existir num spec.
- `backend/src/public/public.controller.ts` — a rota pública, a fonte da verdade
  do apêndice acima.
- `docs/plans/25-entrega-app-cliente/plan.md` — o plano e as decisões travadas
  que este guia documenta.
