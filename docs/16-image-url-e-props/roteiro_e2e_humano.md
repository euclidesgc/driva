# Roteiro de E2E humano — item 39 (URL da imagem e props)

> **Executável sem reler o `plan.md`.** Tudo que a máquina conseguia verificar já foi
> verificado e fotografado pelo QA, contra a **homologação real**. O que sobra aqui é o
> que exige olho — e um passo que exige celular.
>
> Tempo: **~10 minutos** (mais ~15 se você for fazer o passo do celular).

---

## Passo 1 — a cancela. Abra UM print e decida.

Abra:

```
docs/16-image-url-e-props/evidencias/rodada_01/24_quatro_estados_lado_a_lado.png
```

São os quatro estados da imagem no editor, **mesmo nó, mesmo tamanho, mesmo recorte**:
vazio · carregando · falhou · carregado.

**A pergunta, e é só esta:** para alguém que não leu o código, os quatro quadros contam
**quatro histórias diferentes**?

- Se **dois quaisquer se parecerem** → o item 39 **reprova** e o resto deste roteiro não
  importa: era literalmente o bug relatado ("digito a URL e o quadrado cinza continua lá").
- Se os quatro se distinguem → siga.

**O que o script já provou por você:** os quatro recortes são **bytes diferentes** (comparação
dos seis pares) e cada um tem assinatura de rede própria — nenhuma requisição (vazio),
requisição em voo (carregando), resposta 200 (carregado), resposta 502 (falhou).
**O que só o seu olho prova:** que a *diferença* é **legível como significado**, não só como
pixel.

---

## Passo 2 — os prints, em ordem, pelo README da rodada

```
docs/16-image-url-e-props/evidencias/rodada_01/README.md
```

Cada print traz duas linhas: **"O script já provou"** e **"Só o seu olho prova"**. Leia só a
segunda — a primeira já está verde.

Os cinco que valem parar:

| Print | Olhe para |
| --- | --- |
| `19_caso_b_carregado.png` | **É o caso do relato.** URL de um host **sem** CORS (o "copiar endereço da imagem" de um site qualquer). A imagem tem de aparecer de verdade |
| `20b_estado_falhou.png` | O motivo está **legível**? Você entenderia o que houve sem abrir o DevTools? |
| `20c_tooltip_do_erro.png` | O balão mostra o motivo **e a URL que você digitou** no fim da mensagem |
| `11a_props_f4.png` | Quatro props num print: largura 100%, **cantos arredondados cortando a imagem**, fundo escuro atrás do PNG transparente, logo encostado à direita |
| `13b_rede_via_proxy.png` | Todas as imagens saíram por `…/v1/media/proxy`, e **zero** chamadas diretas ao host |

> **Não abra bug por causa disto:** no print do erro, o motivo cita
> `…/v1/media/proxy?url=…`. É a URL que o Flutter **de fato** tentou buscar — a do proxy. Sua
> URL original aparece no campo próprio e no tooltip. E isso **só aparece no editor**; o app
> publicado nunca mostra URL nem mensagem crua.

---

## Passo 3 — o achado que precisa da sua decisão

**O script reprovou 3 asserções, todas do mesmo ponto: `Largura` = `0` e `Largura` = `abc`.**

Compare os dois prints, lado a lado:

```
evidencias/rodada_01/23a_largura_zero.png     ← digitei 0
evidencias/rodada_01/23b_largura_abc.png      ← digitei abc
```

O que o plano exige (D15 / DoD 23): `0` mostra **"Ajustado para o mínimo (1)"** como
`helperText`; `abc` mostra **`errorText`**; e os **dois sinais têm de se distinguir**.

O que os prints mostram: **nenhuma das duas mensagens aparece.** O campo fica com o texto que
você digitou (`0`, `abc`) e o spec grava `1` — sem avisar. Os dois casos produzem **a mesma
tela**.

**Por que aconteceu** (já apurado, não precisa investigar): a mensagem existe, mas mora no
`NumberEditor`. A F4 migrou `image.width`/`height` de `doubleNum` para `dimension` (decisão
D3) — e o `DimensionEditor` clampa igual, mas **não tem** `helperText` nem `errorText`. O sinal
que a F1 entregou foi perdido na F4, no mesmo item.

**Sua decisão:** isto bloqueia o item 39, ou vira item próprio? (É a mesma tese do item —
"parar de falhar calado" — só que no campo, não na imagem.)

---

## Passo 4 — o único passo que exige as suas mãos: o celular (DoD 26)

Máquina nenhuma pega este: exige aparelho ou emulador e o app móvel.

1. Suba o `driva_demo_app` apontando para o **mesmo conteúdo** que você viu no editor (uma
   página com `image` de URL pública).
2. Deixe o log de rede à vista.
3. **Esperado:** a imagem carrega **e a requisição vai DIRETO ao host** — sem passar por
   `…/v1/media/proxy`.

**Por que importa:** o proxy é chrome do **editor**. Se ele vazasse para o app publicado,
todo tráfego de imagem de todo cliente passaria pelo nosso backend — conta de banda e ponto
único de falha. O caminho do editor já está provado (`13b_rede_via_proxy.png`); falta o do
cliente.

---

## Passo 5 — dois toques de teclado (30 segundos)

Teclado sintético não passa pelo mesmo caminho do teclado real, então isto o script não prova:

1. Abra o editor no hml, mude alguma coisa e aperte **Ctrl+S**. **Esperado:** salva, e o
   Chrome **não** abre a caixa "Salvar página como…".
2. Com o cursor **dentro** do campo "URL da imagem", aperte **Ctrl+S** de novo. **Esperado:**
   o comportamento é o mesmo — o atalho não some por o cursor estar num campo.

---

## Se algo reprovar

Não conserte na mão. Registre no PR e devolva ao time: o tech-lead corrige, o QA ajusta o
script e abre a **`rodada_02`**. A `rodada_01` **não é apagada** — o histórico de rodadas é o
rastro do que quebrou.

## Se tudo passar

Atesta por escrito no `final_report.md`, **com data**. Só o dev humano atesta E2E. Só depois
disso a **F5** (bateria automatizada) pode ser escrita.

---

## Como regerar tudo, se quiser ver com os próprios olhos

```bash
docs/16-image-url-e-props/e2e_hml.sh          # contrato por API (~1 min)
docs/16-image-url-e-props/e2e_shots.sh        # os prints (~7 min, abre a próxima rodada)
```

Os dois são idempotentes e auto-limpantes: criam **um** conteúdo de teste no projeto `default`
do hml e o apagam no fim. Nada sobra em homologação, nada vai para produção, nenhuma linha de
código-fonte foi tocada.
