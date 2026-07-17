# Migrar configuração Claude Code → ZCode (driva)

**Escopo:** Projeto + globais. **Não-destrutivo:** originais do Claude (`.claude/`, `CLAUDE.md`, `~/.claude/`) ficam intactos — apenas adiciono as contrapartes ZCode em paralelo.

---

## Parte A — Escopo de projeto (`/home/euclidesgc/Development/driva`)

### A1. `AGENTS.md` (novo, na raiz)
- Copiar o conteúdo de `CLAUDE.md` (15KB, pt-BR).
- **1 ajuste de caminho** na linha 53: `.claude/skills/tech-manager/` → `.zcode/commands/tech-manager.md` (vira comando) e `.claude/agents/` → `.zcode/agents/`.

### A2. `.zcode/skills/` — 9 skills (cópia verbatim)
Mesmo formato ZCode (`name` + `description` no frontmatter — idêntico ao Claude). Copiar estas 9 sem alteração (nenhuma referencia `.claude/`):
`criar-modulo`, `escrever-testes`, `iniciar-bugfix`, `iniciar-feature`, `iniciar-hotfix`, `instrumentar-e2e`, `manter-docs-vivas`, `publicar-release`, `revisar-fase`.

### A3. `.zcode/commands/tech-manager.md` — 1 comando (conversão skill→command)
`tech-manager` tinha `disable-model-invocation: true` (flag inexistente em skills ZCode). O equivalente correto para invocação explícita `/tech-manager <pedido>` é um **command**:
- Frontmatter: `description` (mesmo texto) + `argument-hint: "<pedido>"`.
- Corpo: copiar o SKILL.md, **1 ajuste** na linha 7: `.claude/agents/` → `.zcode/agents/`.

### A4. `.zcode/agents/` — 8 agentes (cópia verbatim, best-effort)
Copiar `ciso`, `tech-lead`, `product-manager`, `qa`, `especialista-apresentacao`, `especialista-dados`, `especialista-dominio`, `especialista-infra`. Frontmatter (`name`/`model`/`description`) é exatamente o que o ZCode reconhece. Nenhum referencia `.claude/`.

> ⚠️ **Caveat declarado:** o ZCode **não documenta** descoberta de agentes em `.zcode/agents/` (só skills e commands têm scan-order documentado; o campo `agents` de plugin é listado como "registrado, não executado"). Copio mesmo assim porque é grátis, não-destrutivo e preserva as definições (o fluxo `/tech-manager` referencia esses agentes via `subagent_type`). Se o ZCode não os auto-descobrir, ficam inertes até o suporte existir — sem dano.

---

## Parte B — Escopo global (`~/.zcode/cli/config.json`)

### B0. Backup
- `cp ~/.zcode/cli/config.json ~/.zcode/cli/config.json.bak` antes de mesclar (prudência).

### B1. Mesclar servidores MCP → `mcp.servers`
Adicionar ao config existente (que hoje só tem `plugins`), preservando o bloco `plugins` intacto:
```json
"mcp": {
  "servers": {
    "dart": {
      "type": "stdio",
      "command": "/home/euclidesgc/.puro/shared/caches/78fc3012e45889657f72359b005af7beac47ba3d/dart-sdk/bin/dartaotruntime",
      "args": [ "/home/euclidesgc/.puro/shared/caches/78fc3012e45889657f72359b005af7beac47ba3d/dart-sdk/bin/snapshots/dart_mcp_server_aot.dart.snapshot" ],
      "env": {}
    },
    "code-review-graph": {
      "type": "stdio",
      "command": "uvx",
      "args": [ "code-review-graph", "serve" ],
      "env": {}
    }
  }
}
```
(Estes eram globais no `~/.claude.json`; replica no global ZCode. São auto-conectados por padrão.)

### B2. Mesclar hooks → `hooks.events.*` (com `hooks.enabled: true`)
A estrutura interna Claude (`matcher` + array `hooks` com `type: command`) é **compatível** com o ZCode. A diferença: o ZCode envolve tudo em `hooks.events.<Evento>` e exige `hooks.enabled: true` (hooks via config ficam desabilitados por padrão). Portar os 7 hooks:
- **PreToolUse / `Bash`**: `rtk hook claude`
- **PreToolUse / `Bash`**: hook inline Python que emite contexto `MANDATORY: graphify...` quando grep/rg/find/fd é invocado e `graphify-out/graph.json` existe
- **PreToolUse / `Read|Glob`**: hook inline Python que força `graphify` antes de ler código-fonte
- **PostToolUse / `Edit|Write`**: `code-review-graph update --skip-flows` (`timeout: 30`)
- **PostToolUse / `Edit|Write`**: `graphify update .` (`timeout: 30`)
- **SessionStart**: `code-review-graph status` (`timeout: 10`)
- **SessionStart**: `node ~/.claude/.claude-manager/session-start-tap.js`

Eventos Claude usados (`PreToolUse`, `PostToolUse`, `SessionStart`) — **todos suportados** pelo ZCode (são 3 dos 7 eventos nativos). Os matchers (`Bash`, `Edit|Write`, `Read|Glob`, `""`) são regex válidos no ZCode.

> ⚠️ **Risco declarado (verificar pós-implementação):**
> 1. `rtk hook claude` é nomeado para Claude — pode esperar um schema de stdin específico. Verificar se o ZCode envia o mesmo payload JSON (`tool_input.command` para Bash) e se `rtk` tem modo ZCode.
> 2. Os hooks Python fazem parse defensivo de `tool_input` do stdin; o formato exato do stdin do ZCode é não-documentado — os hooks podem não disparar o `additionalContext` corretamente se o schema diferir.
> 3. `SessionStart` no ZCode casa contra `startup|resume|clear|compact`; matcher vazio = casa tudo (igual ao Claude). OK.
>
> Ação recomendada após aplicar: abrir uma sessão ZCode no driva, rodar um grep, e confirmar se o contexto `MANDATORY: graphify` aparece. Se não, ajustar o parse do stdin.

---

## O que NÃO é portado (e por quê)
- **`permissions.allow/deny/ask/defaultMode`** (~200 entradas): o ZCode **não tem allowlist de permissões** em config. Permissões em ZCode são tratadas em runtime via hooks (`PreToolUse`/`PermissionRequest` retornando allow/ask/deny) ou pelo modo do cliente. Recriar o allowlist via hooks é outro projeto — fica fora deste.
- **`additionalDirectories`, `env`, `model`, `language`, `effortLevel`, `tui`, etc.**: settings de cliente Claude sem contrapartida documentada em `config.json` do ZCode (equivalentes, se houver, vivem na UI do cliente).
- **`enabledPlugins`**: já gerenciado no config ZCode atual (`playwright` já habilitado). Sem ação.
- **`.vscode/settings.json`**, **`scripts/gates_guard.sh`**: não são recursos Claude (helper de editor / script de projeto). Sem ação.

---

## Ordem de execução
1. A1 (AGENTS.md) → A2 (9 skills) → A3 (command tech-manager) → A4 (8 agents)
2. B0 (backup config) → B1 (MCP) → B2 (hooks)
3. Verificação: listar os arquivos criados e mostrar o `config.json` final mesclado.

Tudo é adição/cópia — nenhum arquivo original do Claude é tocado.