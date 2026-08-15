# E2E do item 38 — o que sobra para o dev humano

> Este arquivo é executável sem reler o `plan.md`. O QA já rodou o roteiro da §10
> inteiro na tela da homologação e gerou **todos** os prints. Você **confere** os
> prints e faz **um** teste com as suas mãos — o único que máquina nenhuma pega.

## 1. Rodar (opcional — a rodada 01 já está gravada)

```bash
docs/15-destravar-construtor/e2e_hml.sh          # contrato por API — 27 asserções
docs/15-destravar-construtor/e2e_shots.sh 02     # regera os prints numa rodada nova
```

Os dois rodam contra o **hml real** (`hml.driva.duckdns.org`), criam **um** conteúdo
de teste no projeto `default` e o apagam no fim. Nada sobra em homologação, nada
disso vai para produção. A rodada 01 (28/28 PASS) está em
[`evidencias/rodada_01/`](evidencias/rodada_01/) com `README.md`, `resultado.txt` e
o snapshot dos scripts.

## 2. Conferir os prints (15 min)

Abra [`evidencias/rodada_01/README.md`](evidencias/rodada_01/README.md) e desça a
lista. Cada imagem vem com duas linhas: **"o script já provou"** (a asserção que
rodou contra a API — não precisa reconferir) e **"só o seu olho prova"** (é para
isso que você está olhando).

Os **quatro prints que o DoD exige** estão aí, e é neles que vale demorar:

| Passo do DoD | Print | O que tem de estar na imagem |
|---|---|---|
| **4** — um único `Ctrl+Z` | `04_undo_unico.png` | Sobrou **só o Text** no canvas e na árvore. Não é `column[Text]`: o agrupamento **e** a inserção voltaram com uma tecla. (O script conferiu o spec: `text`.) |
| **6** — `Ctrl+G` | `06c_ctrl_g_envolve.png` e `06d_ctrl_g_inerte_no_campo.png` | No primeiro, a barra de status diz **"Envolvido numa Column."**. No segundo, o cursor está no campo **Texto** do inspector e **nada** mudou na árvore. **A parte do Chrome não reagir é o item 3 abaixo — não está nos prints.** |
| **9** — marcação de erro | `09a` (canvas), `09c` (árvore), `09b` (barra), `09d`, `09e` | O selo vermelho no **nó do canvas** *e* o ícone na **linha da árvore** — não só o rodapé. Em `09b` a barra lista "1 erro · 1 aviso" com ícone **e** texto. Em `09e` a marcação **some** depois do `Ctrl+G`. |
| **11** — reabre após reload | `11_reabre_apos_reload.png` | Depois do F5, a árvore volta com `Conteúdo (Column) › Text, Image`, o canvas desenha e a barra diz "Nenhum problema". Nenhuma tela de conteúdo inválido. |

O resto (`01`, `02`, `03`, `05`, `07a-c`, `08`, `10a-d`, `12`) é caminho feliz — passe
o olho e siga.

## 3. O teste que só você pode fazer: `Ctrl+G` num Chrome de verdade (3 min)

**Por que só você:** atalho de navegador é engolido pelo Chrome antes de o app ver, e
teclado sintético (CDP) não passa pelo mesmo caminho do teclado real. Foi assim que o
`Ctrl+Shift+W` do plano de gaveta morreu (D8). Nenhuma asserção deste E2E cobre isto.

1. Abra `https://hml.driva.duckdns.org` no **seu** Chrome, entre num projeto e abra
   qualquer conteúdo no editor.
2. Clique num widget no canvas (ou numa linha da árvore) para selecioná-lo.
3. Tecle **`Ctrl+G`**.

**Tem de acontecer:** o widget é envolvido numa Column e a barra de status diz
*"Envolvido numa Column."*.

**Não pode acontecer nada do Chrome:** não abre a barra de busca, não pula para "próxima
ocorrência" de uma busca aberta, não favorita, não fecha aba, não abre janela nova, não
baixa nada. A URL não muda.

4. Ainda no editor, clique dentro do campo **Texto** do inspector (cursor piscando) e
   tecle `Ctrl+G` de novo. **Esperado:** nada acontece — nem envolve, nem digita
   caractere nenhum. (Guarda `_isEditingText`.)

Se qualquer uma dessas linhas falhar, **é bug** — anote e devolva para a próxima rodada.

## 4. O que NÃO é bug (já registrado no plano, §5 › F5)

Não reporte como regressão:

- **Aviso em `expanded` válido marca só na árvore.** Um `expanded` dentro de
  `Row`/`Column` mas sem filho ganha aviso na linha da árvore e **não** no canvas — ali
  ele continua bypassado pelo `SelectableNode` para não derrubar a árvore por
  `ParentDataWidget`.
- **Selo e rótulo do nó dividem a mesma faixa** (um à esquerda, outro à direita, acima
  do nó) e podem se sobrepor num nó estreito.
- **Selo de nó de tamanho zero flutua.** Um `expanded`/`spacer` sem filho desenha nada;
  o selo fica pairando sobre o vizinho (é o que você vê em `09a`). Com filho, ele ancora
  direito (`09d`).
- **`expanded`/`spacer` solto fora de flex agora é arrastável pelo canvas** (antes só
  pela árvore). É efeito colateral consciente da VR-15-02.

## 5. Dois achados do QA — para você decidir, não bloqueiam

- **A1 — o passo 7 do roteiro da §10 não é executável como está escrito.** Paleta e
  Árvore são **abas do mesmo painel esquerdo**: com a árvore aberta, a paleta não existe
  na tela, então "soltar um widget **da paleta** na linha da árvore" é impossível nesta
  UI. O script exercitou no lugar o gesto que existe de verdade — arrastar um **nó já
  existente** para a linha e para o rodapé da árvore, com a cadeia de slots esgotada
  (`card > padding > text`) — e os três pontos deram o mesmo `column[card(padding), text]`
  (prints `07a`, `07b`, `07c`). De quebra, isso cobre na tela o braço `DropRequiresWrap`
  do `moveNode` que a F7 anotou como "alcançável pelo usuário e sem teste".
  **Decisão sua:** corrigir o texto da §10 ou mudar a UI.
- **A2 — acessibilidade do selo em nó de tamanho zero.** O selo de `09a` aparece no
  pixel, mas não entra na árvore semântica (leitor de tela não anuncia o problema
  daquele nó). Com o nó desenhando (`09d`) ele entra normalmente. Fica como dívida de
  a11y, não como bloqueio do item.

## 6. Se algo falhar

Não mexa nos scripts. Diga **qual print** e **o que viu**; o time analisa
`resultado.txt` + prints + código, corrige e avisa quando a **rodada 02** estiver
pronta (`e2e_shots.sh 02`). Rodada nunca sobrescreve rodada.
