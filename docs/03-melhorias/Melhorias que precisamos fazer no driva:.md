Melhorias que precisamos fazer no driva:

-1) Você usar o FlutterFlow como principal fonte de inspiração a respeito de quais Widgets teremos e como podemos modificar as propriedades deles.
0) Precisamos de pelo menos dois temas aqui, o light e o dark. Persista a opção selecionada ao sair.
1) Na página inicial do Driva, precisamos de uma árvore de categorias no lado esquerdo, para os conteúdos possam ser organizados em categorias e sub-categorias;
2) Podemos atribuir um conteúdo a uma categoria tanto na hora de criar, pelo formulário, ou arrastando um conteúdo para uma categoria.
3) Ao selecionar uma catgeoria no lado esquerdo, o lado direito exibe apenas os conteúdos da categoria selecionada.
4) Precisamos de formas de pesquisar conteúdos e também de ordenação.
5) A lista de conteúdos deve ser uma listagem infinita.
6) O primeiro item da árvore de categorias é a categoria 'Todos', é a que vem selecionada por padrão
7) a api de conteúdos deve aceitar todos esses parametros, uma request é feita quando se clica em uma categoria
8) Por questões de performance, podemos trabalhar com offline first nessa tela. Atualizações apenas quando clicar em salvar.
9) A lista de categorias deve um pull to refresh que tentar refazer o cache. É uma forma do usuário forçar a atualização das informações locais, ou seja, quando ele faz um pull to refresh, o chamada vai pra api e refaz o cache local.
10) As telas de loading, estão esquisitas, acho que tem muita coisa sendo rebuildada sem necessidade. Percebi que quando clica em criar no form de novo conteúdo, a tela entra em load, e logo em seguida vai para tela de construção. Esse loading, talvez não seja necessário, e eu acho que ele que está causando esse efeito estranho. A transição de telas ficou ótima.
11) Na tela de edição, quando arrastamos os componentes para o mock do dispositivo, não aparece nenhum sinal de que tem alguma coisa lá.
Seria interessante deixar o componente com uma linha tracejada e talvez uma pequena tag com o nome do componente para que seja possível o usuário ver que ali tem alguma coisa.
12) O tamnho do mock do aparelho celular está muito grande na altura, seria interessante que ele tivesse um tamanho mais limitado na altura, para que não fosse preciso rolar a tela mesmo quando estamos em dispositivos com telas grandes. Não quero uma altura dinamica porque se um user estiver com uma tela muito pequena, o melhor é fazer rolagem mesmo, mas aqui não é o caso, estou num monitor de 27 polegadas, e mock não cabe todo na altura da tela. Precisamos ajustar isso pra algum tipo de altura máxima.
13) Como vc criou estes mocks? São os mesmos utilizados pelo WidgetMill? (que é o app de exemplo) Lembro que tínhamos 3 opções, android, iphone e tablet. Agora só temos 3 caixas distintas de tamanhos diferentes apenas, não aproxima nem um pouco da realidade. Melhore isso.
14) Precisamos de algum lugar pra exibir o json que está sendo gerado em tempo real. A parte da tela onde fica o celular pra gente montar os widgets, poderia estar em uma espécie de aba, ou janela destacável para que o usuário escolha se quer ver lado a lado ou se prefere alternar entre as telas, vendo o celular ou vendo o json. (Funcionamento semelhante as janelas no Vs Code)
15) O json é somente leitura, mas pode ser copiado e ele é exibido de forma legível, se puder com sintaxe highlight.
16) As propriedades estão com algum problema quando tempo modificar, por exemplo, se eu for tentar digitar o valor 10 na elevação do card, depois que eu informo o valor 1, o edit perde o foco e eu tenho que clicar de novo nele. Todos estão assim.
17) Na página inicial agora pode exibir duas coisas: Conteúdos e Componentes.
18) Componentes segue mais ou menos a mesma premissa dos Conteúdos. Um componente é basicamente um widget que poderá ser utilizado como conteúdo.
19) Precisamos diferenciar o construtor de Componentes e o Construtor de Conteúdo, por que eles fazem praticamente a mesma coisa, mas os componentes que o usuário criar aqui, poderão ser utilizados na página de conteudos, em uma nova aba chamada Componentes, ao lado de Widgets e Árvore.
20) A lista de componentes é exibida da mesma forma que a lista de Widgets, por tando ao salvar um componente o user pode escolher ou criar uma categoria pra ele, e definir um icone ou imagem para ele aparecer na lista bonitinho como é feito na lista de widgets.
