# Rodada 01 — item 46 (projectId na rota do editor)

⚠️ **Esta rodada NÃO atesta o DoD.** Foi executada com o editor rodando **local**
(`flutter run`, `config/hml.json`) contra a **API real de homologação**, porque o merge para
`develop` estava travado por indisponibilidade do GitHub. O DoD (§11.3 do `plan.md`) exige a
UI servida por homologação — lição permanente do item 9g. Vale como **pré-checagem**: prova a
lógica antes de gastar o ciclo de deploy.

**Executada por:** driver Playwright (MCP), conduzido pelo tech manager.
**Data:** 2026-08-17. **Branch:** `bugfix/46-projectid-na-rota-do-editor`.

## Ambiente

| Item | Valor |
| --- | --- |
| Editor | `http://localhost:44723` (`flutter run`, `--dart-define-from-file=config/hml.json`) |
| API | `https://api-hml.driva.duckdns.org` (real) |
| `USE_FAKE_DATA` | `false` — confirmado pelas requisições reais no console do Dio |
| `PROJ_A` | Portal da RE · `qyk9xbclx0moxwno3wplb4u9` |
| `CT_A` | E2E 46 — conteúdo A · `p5ha2j9x7dgjkaqla0gy2wyt` |
| `PROJ_B` | E2E item 46 — projeto B · `o8zw3ctaahlni0lhyqpes8f6` |
| `CT_B` | E2E 46 — conteúdo B · `b7pxnjxd94qb53c7c60vtp27` |

## Resultado por passo

| # | Passo | Resultado | Print | Prova qual linha do DoD |
| --- | --- | --- | --- | --- |
| 1 | Home → `PROJ_A` → abrir `CT_A` pelo caminho normal | ✅ URL `/projects/qyk9…/contents/p5ha…/edit` | `01_url_com_dois_ids.png` | §11.3 › 22 |
| 2 | Reload frio na mesma URL | ✅ mesmo conteúdo, breadcrumb "Portal da RE" | `02_reload_mesmo_conteudo.png` | §11.3 › 23 — **o defeito de origem** |
| 3 | Boot frio: header da **primeira** requisição | ✅ `GET /v1/contents/p5ha…` saiu com `x-project-id: qyk9xbclx0moxwno3wplb4u9`, 200 | log do Dio (abaixo) | §11.3 › 24 (D2) |
| 4 | "Ver no celular" — o link gerado | ⚠️ **não verificado** — ver "Bloqueado" | — | §11.3 › 31 — **o aceite que carrega o item** |
| 4b | Abrir o link no aparelho | ⛔ não aplicável local (link aponta para `localhost`) | — | §11.3 › 32 |
| 5 | Breadcrumb aponta para `PROJ_A` | ✅ visível nos prints 02 e 09 | `02`, `09a` | §11.3 › 25 |
| 6 | `:projectId` trocado por `PROJ_B` (válido) | ✅ "Não encontramos este conteúdo no projeto «E2E item 46 — projeto B»", ícone de busca riscada, ação "Voltar para o projeto" | `06_falha_conteudo_fora_do_projeto.png` | §11.3 › 27 (D7) |
| 7 | `:projectId` inexistente | ✅ "Este link aponta para um projeto que não existe", ícone de pasta riscada, ação "Ver meus projetos" | `07_falha_projeto_inexistente.png` | §11.3 › 28 (D7) |
| 8 | Link no formato antigo `/contents/:id/edit` | ✅ caiu em `/` (home), sem aviso | `08_link_antigo_home.png` | §11.3 › 29 (D4) |
| 9 | `CT_A` → `CT_B` → voltar pelo histórico | ✅ os dois carregam; a volta entra em `CT_B` (projeto B) com breadcrumb correto | `09a_ct_a.png`, `09b_ct_b.png`, `09c_volta_historico.png` | §11.3 › 30 |

**Os três modos de falha (6, 7, 8) são visualmente distintos** entre si e da tela carregada:
mensagem, ícone e rótulo da ação mudam nos três. Nenhum depende de cor para se distinguir.

### Evidência do passo 3

```
uri: https://api-hml.driva.duckdns.org/v1/contents/p5ha2j9x7dgjkaqla0gy2wyt
 x-project-id: qyk9xbclx0moxwno3wplb4u9
statusCode: 200
```

Boot frio, sem passar pela tela do projeto: o escopo veio da URL, não de estado em memória.

## Bloqueado — passo 4

Clicar em **"Ver no celular"** abre a rota modal (a tela escurece, e `Escape` a fecha), mas o
**conteúdo do diálogo não pinta** no Chromium do driver. Sem exceção no console. Como a
árvore semântica colapsa para um nó só sob a barreira (o mesmo sintoma do **item 45**), o
driver também não consegue ler o link por semântica.

**Não está classificado**: pode ser defeito real do diálogo ou artefato do navegador do
driver. **Precisa de conferência manual** — abrir "Ver no celular" num Chrome normal e ler a
URL do diálogo. É o aceite 31, o modo silencioso, e o único que a evidência de hoje não cobre.

## Achados fora do escopo do item 46

1. **Overflow no topo do mock em janela estreita.** A 873 px de largura, a barra de
   ferramentas do canvas mostra a faixa listrada de overflow do Flutter (`RIGHT OVERFLOWED
   BY…`) sobre os controles de zoom. Some a 1600 px. Território do **item 41** (a F3 prometeu
   matar overflows) — não é regressão desta fase, mas está no ar.
2. **Item 45 confirmado em dois pontos.** A barra de topo (Salvar/Publish/⋮) não aparece na
   árvore de acessibilidade; e, ao abrir uma rota modal, a árvore inteira colapsa para um
   único nó — consistente com a hipótese do `BlockSemantics` registrada no roadmap.
