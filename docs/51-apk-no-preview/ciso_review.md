# CISO review — item 51, F1 (CI publica o APK)

**Gate:** gate obrigatório da fase, exigido pelo `plan.md` §5 antes da PR 1 (F1) poder
abrir. Branch `feature/51-ci-publica-apk` (base `develop`), commits `eb6f2cd` (T1.1,
`run_demo.sh`), `c4c8113` (T1.2, job novo `.github/workflows/ci.yml`), `29e80d5` (T1.3,
docs/CHANGELOG). Repo consolidado, working tree limpa no momento da revisão.

**Calibragem.** Pipeline de CI/CD, não fluxo de publicação/serving de dado de cliente —
não há PII envolvida, e o artefato publicado é um app de demonstração fixo, não um
conteúdo de um tenant real. Mas o diff **ganha superfície de escrita no repositório**
(`contents: write`) e **publica um binário público**, o que é exatamente o tipo de mudança
que o CLAUDE.md classifica como merecedora do rigor máximo. Apliquei cadência **plena**:
li o diff inteiro dos três commits, o `ci.yml` completo (não só o hunk), e cruzei contra o
backend (`public.controller.ts`, `public.service.ts`, `projects.controller.ts`) para
confirmar com código — não só com o PRD — que a chave embarcada é read-only e que o
endpoint de descoberta é de fato aberto.

## R4 — `contents: write` na CI

Confirmado por grep direto, não só pela leitura do plano:

```
$ grep -n "permissions:\|secrets\.\|github.token" .github/workflows/ci.yml
36:permissions:              # topo do arquivo — contents: read
206:    permissions:          # dentro do job publish-demo-apk
249:          GH_TOKEN: ${{ github.token }}
```

- `permissions: contents: write` está **só** dentro do job `publish-demo-apk` (linha
  206-207). O bloco do topo (linha 36-37) continua `contents: read`, e é a única
  ocorrência de `permissions:` fora de um job.
- `grep -n "secrets\."` no arquivo inteiro devolve **zero** linhas — nenhum job usa
  segredo guardado, nem o novo nem os antigos.
- `if: github.event_name == 'push' && github.ref == 'refs/heads/develop'` (linha 205) é
  exato: não roda em `pull_request` (nenhum evento de PR, de fork ou não, alcança o job) e
  não roda em push para `main` (só `refs/heads/develop`, não `main`).
- O passo de publicação usa `GH_TOKEN: ${{ github.token }}` — o token automático e
  efêmero do Actions, escopado pelo `permissions:` do job, nunca `secrets.GITHUB_TOKEN`
  explícito nem um PAT guardado.
- `PROJECT_TITLE`/`SLUG` chegam ao script via bloco `env:` (variáveis de ambiente), não
  interpolados direto na string do `run:` — evita a classe clássica de script injection
  de GitHub Actions (`${{ }}` colado no corpo do shell). Boa prática, não pedida
  explicitamente pelo PRD, registrada aqui como reforço.
- O comentário das linhas 28-35 foi reescrito e diz a verdade nova: nomeia o job que
  escreve, diz que o escopo é local a ele, e que o token é o automático do Actions — não
  ficou uma invariante que mentia (o risco que o D4 do plano previu).
- `needs: flutter`: nenhum binário de um commit com Dart vermelho é publicado.

**Veredito R4: mitigado, mitigação confirmada no código.**

## R6 — dependência do `GET /v1/projects` sem autenticação

Verifiquei no backend, não só no PRD:

- `backend/src/projects/projects.controller.ts`, `GET /projects` (linha 39) — só
  `@UseGuards(ThrottlerGuard)` no endpoint de detalhe (linha 63-70); a listagem (linha
  39-48) não tem guard de autenticação nenhum. Devolve `publishableKey` de **todos** os
  projetos (`projects.service.ts:37`, campo `publishableKey: true` no select).
- Esse endpoint **não nasce nesta fase** — já era consumido por
  `apps/driva_demo_app/tool/run_demo.sh` desde o item 25 (comentário de topo do script,
  linha 4-7, pré-existente). O que a F1 faz é adicionar um **novo call site institucional**
  (o job de CI), não abrir o endpoint.
- `grep -n "v1/projects" .github/workflows/ci.yml` devolve zero linhas — o workflow não
  reimplementa a descoberta, só chama `run_demo.sh` (D2 do plano, confirmado).
- O risco está **registrado por escrito** em três lugares antes de chegar aqui:
  `prd.md` › Riscos › R6, `specs.md` › A7 (nota lateral), e `plan.md` §2.5/D2 — todos
  dizem explicitamente "débito do item 26, não nasce aqui, mas este job passa a
  depender dele; quando a auth chegar, este call site quebra". Não é um risco escondido.

**Veredito R6: não é mitigável dentro do escopo desta fase (a correção é o item 26), e
está corretamente documentado como dependência, não escondido. Aceito como está, sem
bloqueio.**

## A7 — APK público com `publishableKey` embarcada

- Confirmado em `backend/src/public/public.controller.ts`: o controller que consome
  `x-driva-key` só expõe `GET /public/contents` (lista) e `GET /public/contents/:slug`
  (detalhe) — nenhum verbo de escrita usa esse header. `keyOf()` (linha 66-70) só valida
  presença; a autorização real é `public.service.ts:projectIdFor`, que resolve a chave
  para um `projectId` e escopa a consulta a esse projeto — sem escrita em nenhum caminho.
- Ou seja, a alegação do `specs.md` (A7: "chave que só lê conteúdo publicado, nunca
  escreve") é verdadeira no código, não só na intenção.
- Nenhum segredo real (chave de assinatura, credencial de API, token de longa duração)
  entra no binário: o único dado embarcado é a `PUBLISHABLE_KEY` (prefixo `pk_`,
  validado por `run_demo.sh:46`) e a `API_BASE_URL` pública de homologação — nenhum dos
  dois é segredo pela definição do próprio produto (mesmo desenho de `/v1/public`, já em
  produção desde o item 25).
- A release é criada com `--prerelease` (linha 253), então não disputa o selo `Latest`
  com a release SemVer do produto — condiz com o critério de aceite 2 do PRD.
- A tag não se move (`gh release view` idempotente + `--clobber` só no upload do asset),
  e cada execução atualiza a nota com SHA + data UTC — dá rastreabilidade de qual commit
  gerou o binário no ar, sem depender de versão/data na UI do editor (D5 do plano).

**Veredito A7: exposição aceitável, como o PRD já havia argumentado, e confirmada no
código — nenhum segredo real viaja no binário nem no release.**

## Achados adicionais (fora dos três nomeados no gate)

Nenhum bloqueante.

- **INFO — chave nunca aparece inteira em log.** `run_demo.sh:51` só imprime
  `${key:0:14}…`; `grep -n '\$key'` no arquivo não mostra impressão do valor inteiro em
  nenhum ponto, inclusive no novo trecho de verificação de conteúdo (linha 61, a chave só
  vai no header `x-driva-key`, nunca em texto de log). Sem `set -x` no script, então o
  runner do Actions também não vaza o valor via trace de shell.
- **INFO — nenhuma dependência nova.** O diff da fase não toca `pubspec.yaml`/
  `pubspec_overrides.yaml`/`package.json` — só workflow YAML, um script shell e docs.
  Sem superfície de supply-chain nova além das actions já usadas nos outros jobs
  (`actions/checkout@v4`, `actions/setup-java@v4`, `subosito/flutter-action@v2`, já
  pinadas por tag major nos jobs existentes, mesmo padrão do repositório).
- **INFO — sem instrumentação de teste sobrevivendo.** O diff inteiro é infraestrutura de
  build (workflow + script) e docs; não há toggle, flag de debug nem tela escondida.
  Não se aplica a ressalva de "remoção de instrumentação antes do fechamento" — não há
  E2E nesta fase (D13/E2E suspenso), e o script novo é o próprio artefato de produção,
  não um mock a remover depois.
- **INFO — `concurrency` do job novo.** `group: publish-demo-apk` +
  `cancel-in-progress: true` (linha 208-210) evita a corrida de duas publicações
  sobrepostas deixando o binário mais velho por cima — mitigação correta de uma falha
  silenciosa (as duas execuções sairiam verdes), embora não seja um risco de segurança
  em si.
- **Não é achado, é confirmação:** o job `android` (cancela de PR) continua
  `--debug`, sem `permissions:` próprio, e nenhum outro job ganhou escrita —
  `grep -n "permissions:"` no arquivo mostra só as duas ocorrências citadas acima.

## Veredito

**Gate liberado.** R4 mitigado e confirmado por grep direto no `ci.yml` (não só pela
leitura do plano); R6 é débito pré-existente do item 26, corretamente documentado como
dependência nova deste job, não escondido, e fora do escopo de correção desta fase; A7
confirmado no código do backend (`publicController`/`publicService`) como exposição
somente-leitura, sem segredo real embarcado. Nenhuma correção obrigatória antes da
PR 1 abrir.
