# Roadmap — driva

Rastreamento vivo do que está **feito**, **em andamento** e **por fazer**. A lista está ordenada **por dependência**: o que vem antes destrava o que vem depois. Cada item traz, entre parênteses, o número original em `docs/03-melhorias/` para rastreabilidade.

**Legenda:** `[ ]` não iniciada · `[-]` em andamento · `[x]` concluída.

> **Documento vivo.** Mantido atualizado pela IA a cada fechamento de trabalho (junto da faxina de branches): marca o item entregue como `[x]`, o item da vez como `[-]`, e — quando surgem features novas — reescreve o texto para dar clareza e **reordena** para o ponto de precedência correto. Ver `CLAUDE.md` › _Método de trabalho_.

## Base já entregue

- `[x]` **Fundação I1 — Conteúdos (rename página→conteúdo + identidade slug/CUID2).** No ar em homologação; renderer SDUI, editor de 3 painéis, catálogo com 14 widgets, backend `/v1/contents`. É o alicerce sobre o qual todo o resto abaixo é construído.

---

## Marco 0 — Fundação e correções que destravam tudo

_Sem dependências entre si; vêm primeiro porque tornam todo o resto viável ou agradável de construir._

- `[ ]` **1. Corrigir o bug de foco no Inspector (0-dep).** _(item 16)_ Ao digitar em qualquer campo de propriedade (ex.: elevação do card), o editor perde o foco após cada tecla e exige reclicar. Causa: a `ValueKey` do `TextFormField` inclui o valor, então cada `onChanged` recria o campo. **Precede o item 9 (catálogo)** — sem isso, editar propriedades é inviável.
- `[ ]` **2. Enxugar loadings e rebuilds da navegação.** _(item 10)_ Remover o loading desnecessário ao criar conteúdo (ele pisca antes de ir ao construtor) e cortar rebuilds à toa nas telas de carregamento. A transição em si já está boa — o alvo é o flash de load.
- `[ ]` **3. Tema light + dark com persistência.** _(item 0)_ Hoje só existe `AppTheme.light`. Adicionar o dark e persistir a opção ao sair (introduz a camada de preferências local que o **item 15 (offline-first)** reaproveita).

## Marco 1 — Polimento do construtor (canvas)

_Depende só do editor atual; independente de backend e de categorias._

- `[ ]` **4. Altura máxima do mock do dispositivo.** _(item 12)_ Limitar a altura do mock para não rolar a tela em monitores grandes (mantendo rolagem só quando a tela do usuário for menor que o mock).
- `[ ]` **5. Feedback visual ao soltar um componente no mock.** _(item 11)_ Componente solto no dispositivo mostra borda tracejada + uma tag pequena com o nome, para o usuário perceber que há algo ali.
- `[ ]` **6. Molduras de dispositivo realistas.** _(item 13)_ Trocar as 3 caixas de tamanho por molduras críveis de Android, iPhone e Tablet (aproximar do device real, como no app de exemplo).
- `[ ]` **7. Painel de preview do JSON em tempo real.** _(item 14)_ Exibir o JSON do spec sendo gerado, numa aba/janela destacável — lado a lado com o mock ou alternando entre eles (estilo painéis do VS Code). **Precede o item 8.**
- `[ ]` **8. JSON somente-leitura, copiável e com syntax highlight.** _(item 15)_ Depende do painel do item 7.

## Marco 2 — Catálogo de widgets (track contínuo)

- `[ ]` **9. Ampliar o catálogo usando o FlutterFlow como referência.** _(item -1)_ Guiar-se pelo FlutterFlow para decidir quais widgets teremos e como suas propriedades são modeladas/editadas. Track contínuo que alimenta paleta e Inspector. **Depende do item 1** (edição de propriedade precisa funcionar).

## Marco 3 — Organização de conteúdos: categorias, busca e paginação

_Track interdependente que exige mudança de backend antes do frontend. Categoria de conteúdo é conceito **novo** (não existe no ContentSpec nem no Prisma hoje)._

- `[ ]` **10. API de conteúdos com filtro, busca, ordenação e paginação.** _(item 7)_ O endpoint passa a aceitar categoria, termo de busca, ordenação e paginação; cada clique numa categoria dispara uma request. **Fundação do backend — precede os itens 11 a 16.**
- `[ ]` **11. Árvore de categorias e subcategorias na home (lado esquerdo).** _(item 1)_ Depende do item 10 (categoria como dado).
- `[ ]` **12. Categoria "Todos" como primeiro item, selecionada por padrão.** _(item 6)_ Depende do item 11.
- `[ ]` **13. Selecionar categoria filtra a lista à direita.** _(item 3)_ Ao clicar numa categoria, o lado direito mostra só os conteúdos dela. Depende dos itens 10 e 11.
- `[ ]` **14. Atribuir conteúdo a uma categoria.** _(item 2)_ Pelo formulário ao criar **ou** arrastando o conteúdo para a categoria. Depende dos itens 10 e 11.
- `[ ]` **15. Busca e ordenação de conteúdos.** _(item 4)_ Depende do item 10.
- `[ ]` **16. Listagem infinita (paginação).** _(item 5)_ Depende do item 10.
- `[ ]` **17. Offline-first na tela de conteúdos.** _(item 8)_ Cache local; atualiza apenas ao salvar. Depende da lista já com filtro/busca/paginação (itens 13–16) e reaproveita a persistência do item 3.
- `[ ]` **18. Pull-to-refresh que refaz o cache.** _(item 9)_ Puxar para atualizar força a ida à API e reconstrói o cache local. Depende do item 17.

## Marco 4 — Componentes (widgets reutilizáveis)

_A maior frente; depende do construtor maduro (Marcos 1–2) e das categorias (Marco 3)._

- `[ ]` **19. Home passa a exibir Conteúdos e Componentes.** _(item 17)_ Divisão de nível superior entre as duas coisas. Depende da lista de conteúdos madura.
- `[ ]` **20. Componente como widget reutilizável, com construtor próprio.** _(item 18)_ Mesma premissa de Conteúdo; um componente é um widget que poderá ser usado como conteúdo. Depende do item 19.
- `[ ]` **21. Diferenciar construtor de Componente e de Conteúdo; nova aba "Componentes" no editor.** _(item 19)_ Componentes criados pelo usuário aparecem numa aba "Componentes", ao lado de Widgets e Árvore, prontos para uso no construtor de conteúdo. Depende do item 20 e das abas do editor.
- `[ ]` **22. Lista de componentes no padrão da lista de Widgets.** _(item 20)_ Ao salvar um componente, escolher/criar categoria e definir ícone ou imagem, para ele aparecer bonito na lista como os widgets. Depende do item 20 e da infra de categorias (itens 11/14).
