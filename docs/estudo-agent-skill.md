# Estudo: Agent × Skill — o que dizem as documentações oficiais

> Arquivo pedido como `docs/estudo-sgent-skill.md`; criado como **`estudo-agent-skill.md`** (corrigido o typo "sgent" → "agent"). Renomeie se preferir o nome original.

## Objetivo e método

Validar, com rigor de fonte primária, a analogia que vai pro livro sobre **agent** e **skill**. A fonte da verdade é a **documentação oficial** de quatro ferramentas: **Claude Code** (Anthropic), **Codex** (OpenAI), **Gemini CLI** (Google) e **Cursor**. Cada afirmação vem com **citação verbatim + URL**.

> 🌐 **Formato bilíngue.** As citações ficam **no original em inglês** (para serem citáveis de verdade no livro) e trazem a **tradução em português entre «aspas angulares»** logo depois, para leitura fácil. A tradução é de apoio; a citação oficial é a inglesa.

> ⚠️ **Antes de publicar:** as citações do Claude foram conferidas direto na doc; as de Codex, Gemini e Cursor vieram de pesquisa assistida. Reconfira o texto exato de cada trecho na URL viva antes de imprimir — docs de IA mudam de redação com frequência.

---

## TL;DR — o veredito da sua analogia

Sua formulação:

> *"Um agent é um tipo de instrução com linguagem natural que deve ter um objetivo específico, ser responsável por fazer alguma coisa ou trazer alguma informação, enquanto uma skill é basicamente formada por instruções e exemplos de um processo que pode ser replicado."*

- **A metade "skill" está correta.** As quatro docs descrevem skill exatamente assim: um procedimento/instrução reutilizável. ✅
- **A metade "agent" está imprecisa — e é uma gafe em potencial.** Nenhuma das quatro docs define agent como "uma instrução". Todas o definem como um **executor**: um assistente/worker com **contexto próprio, ferramentas próprias e modelo próprio**, a quem se **delega** uma tarefa e que **devolve um resultado**. A instrução é o que *configura* o agente — não é o agente. ⚠️
- **O critério que separa os dois não é "ter objetivo específico"** (skill também tem). É: **agent = quem executa (com contexto isolado)** × **skill = como se faz (procedimento carregado no contexto de quem executa)**.
- **Fato forte pro livro:** três das quatro ferramentas (Claude, Codex, Cursor) usam **o mesmo nome e o mesmo formato de arquivo — `SKILL.md`** — e o Gemini tem "Agent Skills" com o mesmo `SKILL.md`. É praticamente um padrão de mercado convergente (o *Agent Skills open standard*).

---

## 1. Análise rigorosa, item a item

**"skill = instruções e exemplos de um processo que pode ser replicado" → correto.**
As quatro docs corroboram literalmente:
- **Claude:** *"instructions, checklist, or multi-step procedure"* «instruções, checklist ou procedimento de vários passos» — <https://code.claude.com/docs/en/skills>
- **Codex:** *"A skill packages instructions, resources, and optional scripts so Codex can follow a workflow reliably."* «Uma skill empacota instruções, recursos e scripts opcionais para o Codex seguir um fluxo de trabalho de forma confiável.» — <https://developers.openai.com/codex/skills>
- **Gemini:** *"A 'skill' is a self-contained directory that packages instructions and assets into a discoverable capability."* «Uma 'skill' é um diretório autocontido que empacota instruções e recursos numa capacidade descobrível.» — <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md>
- **Cursor:** *"A skill is a portable, version-controlled package that teaches agents how to perform domain-specific tasks."* «Uma skill é um pacote portátil e versionado que ensina os agentes a executar tarefas específicas de um domínio.» — <https://cursor.com/docs/skills>

**"agent = um tipo de instrução…" → impreciso, por dois motivos:**

1. **Agent não é instrução; é executor.** Todas as docs o definem como um *assistente/worker* com contexto e ferramentas próprios:
   - **Claude:** *"specialized AI assistants that handle specific types of tasks"* «assistentes de IA especializados que lidam com tipos específicos de tarefas» / *"runs in its own context window with a custom system prompt, specific tool access"* «roda na própria janela de contexto, com um system prompt customizado e acesso a ferramentas específicas» — <https://code.claude.com/docs/en/sub-agents>
   - **Cursor:** *"Subagents are specialized AI assistants that Cursor's agent can delegate tasks to."* «Subagents são assistentes de IA especializados aos quais o agent do Cursor pode delegar tarefas.» / *"Each subagent operates in its own context window"* «Cada subagent opera na própria janela de contexto» — <https://cursor.com/docs/agent/subagents>
   - **Gemini:** *"Subagents are 'specialists' that the main Gemini agent can hire for a specific job."* «Subagents são 'especialistas' que o agente principal do Gemini pode contratar para um trabalho específico.» / *"a separate context loop"* «um loop de contexto separado» — <https://github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md>
   - **Codex (Agents SDK):** *"a large language model (LLM) configured with instructions, tools, and optional runtime behavior"* «um grande modelo de linguagem (LLM) configurado com instruções, ferramentas e comportamento de execução opcional» — <https://openai.github.io/openai-agents-python/agents/>

   Repare: a instrução aparece como **um dos ingredientes que configuram** o agente (*"configured with instructions, tools"* «configurado com instruções, ferramentas»), não como o agente em si.

2. **"ter objetivo específico / fazer ou trazer algo" não discrimina.** Uma skill também tem objetivo e também produz um resultado. Esse critério não distingue os dois. O que distingue é **onde a coisa roda**: o agent roda **num contexto isolado próprio** e devolve só o resumo; a skill é **injetada no contexto de quem já está trabalhando**.
   - **Claude:** *"the subagent does that work in its own context and returns only the summary"* «o subagente faz esse trabalho no próprio contexto e devolve apenas o resumo» — <https://code.claude.com/docs/en/sub-agents>
   - **Cursor:** *"When applied, rule contents are included at the start of the model context."* «Quando aplicada, o conteúdo da regra é incluído no início do contexto do modelo.» (a instrução entra no contexto do executor) — <https://cursor.com/docs/rules.md>

---

## 2. A distinção que realmente separa (são três camadas, não duas)

O par "agent × skill" fica mais claro quando você acrescenta uma terceira peça — as **regras do projeto** — porque as quatro ferramentas têm as três:

| Camada | Pergunta que responde | O que é | Custo de contexto |
|---|---|---|---|
| **Agent / Subagent** | **QUEM faz** | Executor: modelo + ferramentas + system prompt + **contexto isolado**. Delega-se uma tarefa; ele trabalha sozinho e **devolve o resultado**. | Isola o trabalho pesado — o principal só recebe o resumo |
| **Skill** | **COMO se faz** | Procedimento/receita reutilizável (instruções + exemplos), empacotado (`SKILL.md`), **carregado sob demanda** por invocação (`/nome`) ou por match de descrição. Não executa sozinha — ela *ensina* o executor. | Quase zero até ser ativada (só a descrição fica no contexto) |
| **Regras do projeto** | **O que vale SEMPRE** | Convenções/fatos do repositório, **sempre carregados** no contexto (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, Cursor *Rules*). | Pago em **todo** turno — por isso, curto |

**Ponto de ouro:** as três são **complementares, não excludentes**. Um agent *usa* skills; uma skill pode até *rodar dentro* de um agent isolado (ex.: `context: fork` no Claude). A pergunta não é "isto é agent ou skill?", e sim "eu preciso de **quem** faça (agent), do **como** (skill), ou de uma regra **sempre-ligada**?".

- **Codex**, sobre skill × arquivo de regras: *"These are complementary, not competing."* «São complementares, não concorrentes.» — <https://developers.openai.com/codex/concepts/customization>

---

## 3. As quatro ferramentas, lado a lado

> Nas células, a citação em inglês; a tradução das expressões-chave está no texto acima.

| Ferramenta | Agent / Subagent (executor) | Skill (procedimento) | Regras de projeto (sempre-ativas) |
|---|---|---|---|
| **Claude Code** | *"specialized AI assistants… its own context window, custom system prompt, specific tool access"* | **Skill** (`SKILL.md`): *"instructions, checklist, or multi-step procedure… body loads only when it's used"* | `CLAUDE.md` |
| **OpenAI Codex** | *"OpenAI's coding agent"* / SDK: *"LLM configured with instructions, tools"* | **Skill** (`SKILL.md`): *"packages instructions, resources… follow a workflow reliably"* (custom prompts **deprecados** em favor de skills) | `AGENTS.md`: *"rules you want Codex to follow every time in a repo"* «regras que você quer que o Codex siga toda vez num repositório» |
| **Gemini CLI** | **Subagents**: *"'specialists' that the main Gemini agent can hire"* / *"a separate context loop"* | **Agent Skills** (`SKILL.md`): *"on-demand expertise"* «expertise sob demanda» + **Custom Commands** (atalho `/` de prompt) | `GEMINI.md`: *"hierarchical memory loaded from GEMINI.md files"* «memória hierárquica carregada de arquivos GEMINI.md» |
| **Cursor** | **Subagents**: *"specialized AI assistants… Each subagent operates in its own context window"* | **Skills** (`SKILL.md`): *"teaches agents how to perform domain-specific tasks"* + **Commands** (slash) | **Rules**: *"rule contents are included at the start of the model context"* |

**Leitura da tabela:** as colunas se repetem em todas as linhas. **Executor**, **procedimento** e **regras** são conceitos universais; muda o nome e alguns detalhes, não a natureza. E, de novo: **três das quatro chamam o procedimento de "Skill" e usam `SKILL.md`.**

---

## 4. Reformulações prontas para o livro

Escolha o tom. Todas dizem a mesma coisa, corrigindo a metade "agent":

**Versão de uma linha (a que eu usaria como âncora):**
> **Um agent é *quem* faz; uma skill é *como* se faz. As regras do projeto são *o que vale sempre*.**

**Versão analogia de time (casa com o resto da sua Seção V):**
> Pense num agent como um **colega de time**: tem a própria mesa (o contexto dele), as próprias ferramentas e um foco. Você delega uma tarefa e ele volta com o resultado pronto. A skill é o **manual da casa** — o "como a gente faz isso aqui" — que quem estiver trabalhando abre e segue. E as regras do projeto são o **regimento colado na parede**: todo mundo lê, o tempo todo.

**Versão técnica precisa (pra quando você define os termos no capítulo 21):**
> **Agent:** um modelo acoplado a um loop, com ferramentas e **contexto próprios**, a quem se delega uma tarefa; trabalha com autonomia e devolve um resultado. É uma *entidade* (um "quem").
> **Skill:** um documento reutilizável (instruções + exemplos de um processo) que é **carregado no contexto de quem executa** quando relevante, para a saída sair sempre no mesmo padrão. É um *procedimento* (um "como"), não um executor.

**O que evitar (a gafe):** dizer que "agent é uma instrução". A instrução **configura** o agent; ela vive na skill ou nas regras. O agent é o executor que *segue* instruções, não a instrução.

---

## 5. Nota sobre a configuração no Claude Code (o seu caso)

Como você vai escrever configurando para o Claude Code, vale registrar com precisão:

- No Claude Code, **comandos foram unificados em skills**: *"Custom commands have been merged into skills."* «Os comandos customizados foram unificados nas skills.» — <https://code.claude.com/docs/en/skills>. Um `/nome` é uma skill.
- Uma skill pode marcar **`disable-model-invocation: true`** no frontmatter, que a torna **manual** (só entra via `/nome`; o Claude não a carrega sozinho).
- **Sua recomendação** (deixar a auto-invocação **ligada**, com uma `description` boa no frontmatter do `tech-manager` para o modelo decidir quando acioná-lo) é **legítima e é o comportamento padrão** de uma skill: *"the description helps Claude decide when to load the skill automatically"* «a descrição ajuda o Claude a decidir quando carregar a skill automaticamente» — <https://code.claude.com/docs/en/skills>. É uma escolha de produto: `disable-model-invocation: true` = disciplina (você sempre digita `/tech-manager`); auto-invocação = conveniência (o gerente "acorda" quando o pedido casa com a descrição). Deixe claro no livro que é um **trade-off**, não um certo/errado.

> Detalhe fino que combina com o seu capítulo 23: se a skill do gerente precisa **rodar na própria conversa** (para conversar com você e orquestrar), ela **não** deve usar `context: fork` — o `fork` a mandaria para um subagente isolado, que é justamente o que o livro diz para evitar no gerente.

---

## 6. Ressalvas para não escorregar

- **Nomenclatura varia.** Cursor tem **Rules + Skills + Commands**; Gemini tem **subagents + agent skills + custom commands + GEMINI.md + extensions**; Codex **deprecou custom prompts** em favor de skills; Claude **unificou commands em skills**. No livro, ancore no **conceito** (executor / procedimento / regra) e trate os nomes como sotaques da mesma língua — que é, aliás, a tese da sua "nota sobre ferramentas" no cap. 21.
- **Dois níveis de "agent".** Às vezes "agent" é o **produto inteiro** (o *"coding agent"* «o agente de código»), às vezes é o **subagente configurável** que você cria. Deixe explícito de qual você fala.
- **A fórmula literal "modelo + instruções + ferramentas"** só foi confirmada no **Agents SDK** da OpenAI (docs de Python); as páginas de produto do Codex descrevem "coding agent" sem repetir a fórmula. Se citar, cite do SDK.

---

## Fontes (para reconferência)

**Claude Code** — <https://code.claude.com/docs/en/sub-agents> · <https://code.claude.com/docs/en/skills>
**OpenAI Codex** — <https://developers.openai.com/codex> · <https://developers.openai.com/codex/skills> · <https://developers.openai.com/codex/concepts/customization> · <https://agents.md> · <https://openai.github.io/openai-agents-python/agents/>
**Gemini CLI** — <https://github.com/google-gemini/gemini-cli/blob/main/docs/core/subagents.md> · <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md> · <https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/custom-commands.md> · <https://google-gemini.github.io/gemini-cli/docs/cli/commands.html>
**Cursor** — <https://cursor.com/docs/agent/overview> · <https://cursor.com/docs/agent/subagents> · <https://cursor.com/docs/skills> · <https://cursor.com/docs/rules.md>
