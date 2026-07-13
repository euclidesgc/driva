# Rodada 03 — E2E visual reutilizável de Projetos (contra o hml)

> **Débito 9g fechado.** Prints **gerados pelo QA** (headless, via CDP, sem intervenção
> manual). O dev só **confere**. Diferente das rodadas 01/02 (contrato de API do 9d/9e,
> em `localhost`), esta dirige a **homologação REAL** — o mesmo artefato que o Coolify
> serve — e é o que faltava para fechar o buraco de método que deixou as três quebras
> do #43 passarem (ver memória `e2e-precisa-exercitar-de-verdade`).

## Como regerar

```bash
# smoke de contrato contra o hml (18/18 PASS, auto-limpante)
docs/09-crud-projeto/e2e_hml.sh

# prints visuais do fluxo na TELA (headless-chrome + CDP, auto-limpante)
docs/09-crud-projeto/e2e_shots.sh 03
```

Ambos criam **um** projeto de teste (`E2E 9g Projeto`) e purgam o próprio rastro no
começo e no fim. **Nunca** tocam o projeto `default`. Alvos localizados pela **árvore
semântica do Flutter** + `<input>` do DOM (nada de pixel fixo) — layout pode mudar de
posição que o driver continua achando.

## Estados capturados (fluxo fim-a-fim)

| # | Print | Verifica |
|---|-------|----------|
| 01 | `01_home_projetos.png` | Home de cards; ícone de tema visível (fix #44/#45), sem cinza |
| 02 | `02_dialogo_novo_projeto.png` | Diálogo "Novo projeto" **abre sem `RenderErrorBox` cinza** (regressão #46) |
| 03 | `03_titulo_preenchido.png` | Título digitado no campo certo |
| 04 | `04_projeto_criado.png` | Salvar → card aparece na home (**+ assert por API**: projeto em `active`) |
| 05 | `05_projeto_aberto.png` | Tela do projeto: árvore de categorias + painel de conteúdos |
| 06 | `06_arquivado_some_da_home.png` | Editar → Arquivar → confirmar → some da home, badge "Arquivados (1)" (**+ assert por API**) |
| 07 | `07_area_arquivados.png` | `/projects/archived` com Restaurar + lixeira |
| 08 | `08_excluido_limpo.png` | Excluir definitivamente (confirmação dupla) → empty state "Nenhum projeto arquivado" |

## Resultado

- **API (`e2e_hml.sh`):** 18 PASS / 0 FAIL contra `https://api-hml.driva.duckdns.org/v1`.
- **Visual (`e2e_shots.sh`):** 8/8 prints, 0 erro; asserts de criação e arquivamento
  batidos contra a API no meio do fluxo.
- **Rastro:** hml volta ao estado inicial (só o `default`); nenhum dado de teste deixado.
