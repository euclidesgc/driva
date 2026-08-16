# Feedback do dev humano — rodada 01 (2026-08-16)

> Uso real do builder em homologação, depois das F1, F1b, F2 e F4 no ar. Doze pontos, em
> cinco frentes. **Não é lista de bugs**: dois deles reabrem decisões travadas, e um
> destrava outro que estava barrado por um motivo que deixou de valer.

---

## 1. Painel de widgets (paleta)

### 1.1 A contração dos grupos não sobrevive à troca de aba — **defeito**

> _"se eu alternar entre widgets e árvore os grupos sempre são expandidos"_

`_collapsedCategories` mora no `State` do `WidgetPalettePanel`, e Widgets/Árvore são abas do
**mesmo** painel: trocar de aba descarta o `State`. A F4 registrou "a persistência é a F6",
mas isso era sobre **sessões** — perder o colapso ao ir na árvore e voltar é perda **dentro
da mesma sessão**, e o usuário lê como defeito, não como funcionalidade ausente.

Duas camadas, e a primeira não pode esperar a F6:

- **sobreviver à troca de aba** — subir o estado acima do `TabBarView`, ou
  `AutomaticKeepAliveClientMixin`;
- **sobreviver à sessão** — `shared_preferences`, que é a F6.

### 1.2 Contrair o painel **até sumir**, não só estreitar — **reabre a A3**

> _"ele fica mais estreito ao ponto de exibir 2 componentes por linha e isso é bom, mas eu
> quero ter a opção de estreitar ele ao máximo até que todos os componentes sumam mesmo.
> Acho que o FlutterFlow faz algo parecido"_

A **A3** (discovery) decidiu **faixa fina de ícones, não sumir**, com uma razão explícita:
_"com a paleta sumida não há de onde arrastar widget"_.

**Essa razão deixa de valer se o 5.2 entrar** (arrastar da árvore). Ver §5.3.

Ação: conferir o comportamento do FlutterFlow antes de desenhar, como ele pediu.

---

## 2. Painel de propriedades (Inspector)

### 2.1 Seções contraídas também precisam persistir

> _"Da mesma forma que o painel de widgets persiste as listas contraídas aqui tb precisa"_

O Inspector já tem seções colapsáveis desde o item 9b, e o `plan.md` já registra a pergunta
em aberto: **global por rótulo** ou **por tipo de nó**? Continua pendente.

Vale a mesma distinção do 1.1: reabrir o Inspector ao trocar de nó **já** reexpande hoje.

### 2.2 Contrair totalmente o painel — mesma coisa do 1.2

> _"o mesmo em relação a expansão do painel como um todo, hoje ele tem uma largura mínima
> mas além disso, eu gostaria de poder contrair totalmente"_

O Inspector **não** tem o problema do 1.2: ninguém arrasta a partir dele. Sumir de vez aqui
não depende de nada.

---

## 3. Editor de imagem — travar proporção

> _"preciso de uma forma de travar a proporção, para quando o user mudar a altura, a largura
> seja ajustada proporcionalmente e vice-versa. Talvez um checkbox com ícone de cadeado,
> [ ] manter proporção"_

**Perguntas de desenho que o plano precisa fechar antes de codar:**

- **Qual proporção?** A do arquivo (exige a imagem carregada e o `ImageStream` resolvido —
  e ela **não existe** enquanto a URL falha) ou a razão atual entre os dois campos?
- **`width`/`height` são `DimensionValue`** desde a F4 do item 39: aceitam `200`, `"100%"` e
  `"inf"`. **Travar proporção entre `"100%"` e `"inf"` não significa nada.** O cadeado
  provavelmente só faz sentido com **ambos em pixels** — e aí precisa desabilitar-se
  sozinho, com o motivo visível (a lição do item 39: controle que não age não pode parecer
  que age).
- **Onde mora o estado?** É por nó (parte do spec) ou preferência do editor? Se for spec,
  muda o schema e atravessa a fronteira do app cliente.

---

## 4. Preview no celular — três ajustes

### 4.1 O botão de atualizar incomoda → **pull-to-refresh**

> _"um botão pra atualizar que incomoda. Talvez um simples pushtorefresh resolva"_

A pílula "Verificado às HH:MM · toque para atualizar" foi desenhada assim porque o preview
mostra o **último salvo** e não havia gesto. `RefreshIndicator` é mais natural no celular.

**Cuidado:** o conteúdo SDUI pode ter scroll próprio, ou não ter scroll nenhum — o
`RefreshIndicator` precisa de um `Scrollable`. Conteúdo curto não puxa.

### 4.2 A barra de navegação aparece

> _"ele ainda mostra a barra de navegação"_

**Ambíguo — precisa confirmar com ele qual das duas:** a barra de gestos/botões do Android
(que só some com `SystemChrome.setEnabledSystemUIMode(immersive)`) ou algum chrome nosso
que sobrou na rota.

### 4.3 Esconder a barra de endereços do navegador

> _"queria saber se tem alguma forma de não exibir a barra de endereços pra dar um aspecto
> mais próximo da realidade"_

**Sim, e o caminho é PWA:** `manifest.json` com `"display": "standalone"` + "Adicionar à
tela inicial". A Fullscreen API funciona **só** a partir de gesto do usuário e não sobrevive
a recarga — para "abri o link e já está limpo", só o manifest resolve.

O `web/manifest.json` do editor já existe; a rota `/preview` precisaria de `start_url`
própria, ou vira um segundo alvo instalável.

---

## 5. Mock do dispositivo e a árvore

### 5.1 O mock não desenha a status bar do sistema

> _"essa janela com o frame do celular não exibir o cabeçalho padrão que aparece no celular
> onde o relógio e dados da bateria conexões etc aparece, acho que mostrar isso deixaria
> mais realístico e inclusive daria para ter uma melhor noção do componente SafeArea"_

O `DevicePreset.safeAreaPadding` (item 8f) **já injeta** o recuo real no `MediaQuery` — o
`SafeArea` do conteúdo já respeita. Falta **desenhar** o que ocupa aquele espaço.

É o argumento mais forte do pedido: hoje o `SafeArea` reserva uma faixa vazia, e **não dá
para ver por quê**. Com relógio e bateria desenhados, o recuo passa a ter causa visível.

### 5.2 A coluna de atalho "Envolver em" não ficou boa

> _"a forma como estamos colocando uma coluna com essa tecla de atalhos, isso não ficou bom"_

É o comando da **F2 do item 38** (`Ctrl+G` / botão "Envolver em Column/Row"). Ele resolveu o
beco sem saída, mas a ergonomia não agradou.

### 5.3 A proposta dele — arrastar direto para a árvore, com "Wrap with"

> _"acho que podemos trocar o painel 'Árvore' de posição com o painel de propriedades. Sendo
> assim, eu poderia arrastar um componente direto pra árvore e ao ficar em cima de um
> componente existente apareceria a opção Wrap with"_

**Este é o item que destrava o 1.2.** A A3 recusou "paleta some de vez" porque não haveria de
onde arrastar. Se a **árvore** vira alvo de arraste **e** fica visível ao lado da paleta (em
vez de ser aba irmã dela), a paleta pode sumir sem perder a origem do gesto.

**O que já existe e favorece:** o `wrapNode` do kernel (F1 do item 38) e o `DropRequiresWrap`
(F3) — a operação está pronta, é só o gesto que muda. As frestas de inserção da árvore
também já existem (item 8e).

**O que precisa de discovery:** trocar Árvore ↔ Propriedades de lado mexe no `AppShell` e no
`ResizableSplitView`, encosta na F3/F5/F6 do item 41, e muda o layout que os goldens
capturam. E "Wrap with" ao pairar é gesto novo, não variação do drop atual.

---

## Ordem sugerida (para o tech-lead avaliar)

**Não** é ordem de chegada — é o que uma coisa destrava na outra:

1. **1.1** (persistência entre abas) — defeito, barato, independente.
2. **5.1** (status bar no mock) — independente, e o ganho pedagógico do `SafeArea` é imediato.
3. **4.1 / 4.3** (pull-to-refresh + PWA) — independentes entre si e do resto.
4. **2.1 / 2.2** (persistência e colapso do Inspector) — encaixam na F5/F6 já planejadas.
5. **3** (travar proporção) — precisa de discovery próprio pelas três perguntas da §3.
6. **5.3** (árvore como alvo de arraste) — **discovery obrigatório**; destrava o **1.2**.
7. **1.2** (paleta some de vez) — **depois** do 5.3, senão reabre a A3 sem resolver o motivo dela.
