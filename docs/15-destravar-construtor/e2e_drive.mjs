// E2E — item 38 (destravar o construtor) / dirige os GESTOS na tela da homologação
// e assere o SPEC por API depois de cada um, sem dependências (WebSocket/fetch
// nativos do Node 22+). Chamado pelo e2e_shots.sh.
//
// Este item é quase todo interação de canvas — arrastar da paleta, soltar sobre nó,
// Ctrl+G, Ctrl+Z, selecionar. Quase nada é observável por API sozinho: a saída de
// cada gesto é o spec salvo. Então o roteiro da §10 do plan.md vira, aqui, um par
// por passo: **gesto no canvas + asserção do spec** (Ctrl+S → GET /contents/:id).
// O print é a evidência do que a asserção não enxerga (selo, rótulo, notice).
//
// O que fica de fora, de propósito: o Chrome reagir (ou não) ao Ctrl+G. Atalho de
// navegador é engolido antes de o app ver, e teclado sintético via CDP não passa
// pelo mesmo caminho do teclado real — nenhuma asserção aqui prova isso. É item do
// roteiro humano (roteiro_e2e_humano.md, passo H1).
//
// Coordenadas são acopladas ao layout em 1366x900 (device-scale-factor=1, forçado
// por Emulation.setDeviceMetricsOverride). Onde dá, o alvo sai da ÁRVORE SEMÂNTICA
// do Flutter (linhas da árvore expõem `Bloco <label>`; os selos expõem `Erro`/`Aviso`);
// a paleta não expõe rótulo por tile, então ela é por coordenada.
//
// Auto-limpante: cria UM conteúdo de teste (slug $SLUG) e o apaga no fim, e purga
// qualquer rastro do mesmo slug no começo. NUNCA toca outro conteúdo.
//
// Env: WEB_BASE, API_BASE, PROJECT, SLUG, OUT, CDP_PORT
import { writeFileSync } from 'node:fs';

const WEB = process.env.WEB_BASE;
const API = process.env.API_BASE;
const PROJECT = process.env.PROJECT || 'default';
const SLUG = process.env.SLUG || 'e2e-38-canvas';
const NAME = 'E2E 38 canvas';
const OUT = process.env.OUT;
const PORT = Number(process.env.CDP_PORT || 9223);
const H = { 'x-project-id': PROJECT };
const JSON_H = { ...H, 'content-type': 'application/json' };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ------------------------------- CDP (WebSocket puro) -------------------------------
async function connect() {
  const list = await (await fetch(`http://localhost:${PORT}/json`)).json();
  const page = list.find((t) => t.type === 'page') || list[0];
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
  let id = 0; const pending = new Map();
  ws.onmessage = (m) => {
    const msg = JSON.parse(m.data);
    if (msg.id && pending.has(msg.id)) {
      const { res, rej } = pending.get(msg.id); pending.delete(msg.id);
      msg.error ? rej(new Error(msg.error.message)) : res(msg.result);
    }
  };
  return (method, params = {}) =>
    new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
}

let send;
const evalJS = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true })).result?.value;
const move = (x, y, dragging) =>
  send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y, ...(dragging ? { button: 'left', buttons: 1 } : {}) });

async function click(x, y) {
  await move(x, y); await sleep(90);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await sleep(60);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  await sleep(600);
}

async function hover(x, y, ms = 1200) { await move(x, y); await sleep(ms); }

/// `Draggable` puro em toda parte (paleta, árvore, canvas): press → passos de
/// mouseMoved (o primeiro precisa passar do kTouchSlop de 18px) → release.
async function drag(x1, y1, x2, y2, steps = 30) {
  await move(x1, y1); await sleep(150);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: x1, y: y1, button: 'left', clickCount: 1 });
  await sleep(150);
  for (let i = 1; i <= steps; i++) {
    await move(Math.round(x1 + ((x2 - x1) * i) / steps), Math.round(y1 + ((y2 - y1) * i) / steps), true);
    await sleep(25);
  }
  await sleep(250);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: x2, y: y2, button: 'left', clickCount: 1 });
  await sleep(900);
}

const VK = { c: 67, d: 68, g: 71, s: 83, v: 86, y: 89, z: 90 };

/// O Ctrl precisa ir como tecla própria: só `modifiers: 2` no evento da letra não
/// arma o HardwareKeyboard do Flutter Web e o SingleActivator(control: true) não casa.
async function ctrl(letter, { shift = false } = {}) {
  const mods = 2 | (shift ? 8 : 0);
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', modifiers: 2, key: 'Control', code: 'ControlLeft', location: 1, windowsVirtualKeyCode: 17, nativeVirtualKeyCode: 17 });
  await sleep(50);
  if (shift) {
    await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', modifiers: mods, key: 'Shift', code: 'ShiftLeft', location: 1, windowsVirtualKeyCode: 16, nativeVirtualKeyCode: 16 });
    await sleep(50);
  }
  const p = { modifiers: mods, key: letter, code: `Key${letter.toUpperCase()}`, windowsVirtualKeyCode: VK[letter], nativeVirtualKeyCode: VK[letter] };
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...p });
  await sleep(60);
  await send('Input.dispatchKeyEvent', { type: 'keyUp', ...p });
  await sleep(40);
  if (shift) await send('Input.dispatchKeyEvent', { type: 'keyUp', modifiers: 2, key: 'Shift', code: 'ShiftLeft', location: 1, windowsVirtualKeyCode: 16, nativeVirtualKeyCode: 16 });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', modifiers: 0, key: 'Control', code: 'ControlLeft', location: 1, windowsVirtualKeyCode: 17, nativeVirtualKeyCode: 17 });
  await sleep(700);
}

async function shotFile(name) {
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(`${OUT}/${name}`, Buffer.from(data, 'base64'));
}

// ------------------------------- semântica do Flutter -------------------------------
async function enableSemantics() {
  for (let i = 0; i < 15; i++) {
    await evalJS(`(() => { const p = document.querySelector('flt-semantics-placeholder') || document.querySelector('[aria-label="Enable accessibility"]'); if (p) p.click(); return !!p; })()`);
    await sleep(600);
    const n = await evalJS(`document.querySelectorAll('flt-semantics[role]').length`);
    if (n && n > 0) return;
  }
  console.warn('  (aviso) semântica não confirmada — seguindo mesmo assim');
}

const NODES_JS = `(() => Array.from(document.querySelectorAll('flt-semantics')).map(e => { const r = e.getBoundingClientRect(); return { label: (e.getAttribute('aria-label')||'').replace(/\\s+/g,' ').trim(), role: e.getAttribute('role')||'', x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height) }; }))()`;
const nodes = async () => (await evalJS(NODES_JS)) || [];

async function pickNode(pred, label, { timeout = 8000 } = {}) {
  const start = Date.now();
  let last = [];
  while (Date.now() - start < timeout) {
    last = await nodes();
    const hit = last.find(pred);
    if (hit) return hit;
    await enableSemantics();
    await sleep(300);
  }
  console.error('  [debug] nós vistos:', JSON.stringify(last.filter((n) => n.label).map((n) => `${n.role}:"${n.label}"@${n.x},${n.y}`).slice(0, 30)));
  throw new Error(`alvo não encontrado na árvore semântica: ${label}`);
}

const REGION = { tree: (n) => n.x < 282, canvas: (n) => n.x > 286 && n.x < 1040 };

/// O rótulo `Bloco <x>` da linha só aparece na linha SELECIONADA (as demais são
/// mescladas pelo engine, e a selecionada ainda troca de `button` para `group`),
/// então as linhas saem pela geometria: caixas de 280x34 no painel esquerdo, em
/// ordem de topo — índice 0 = raiz, depois a ordem de profundidade da árvore. A
/// linha "Página" não entra (é fixa, fora da lista).
async function treeRows() {
  return (await nodes())
    .filter((n) => REGION.tree(n) && ['button', 'group'].includes(n.role) && n.w >= 260 && n.h >= 30 && n.h <= 40)
    .sort((a, b) => a.y - b.y);
}
async function treeRow(index, label) {
  for (let i = 0; i < 12; i++) {
    const rows = await treeRows();
    if (rows[index]) return rows[index];
    await sleep(400);
  }
  throw new Error(`linha ${index} da árvore não apareceu (${label}); linhas vistas: ${(await treeRows()).length}`);
}
async function selectTreeRow(index, label) {
  const row = await treeRow(index, label);
  await click(row.x, row.y);
  return row;
}

/// O selo de diagnóstico é um `Tooltip`: a mensagem agregada do nó vira o rótulo
/// acessível, no canvas e na linha da árvore. É por ela que checamos a marcação.
const DIAG = { erro: 'só funciona dentro de uma Row ou Column', aviso: 'está sem filho e não desenha nada' };
const diagnosticsIn = async (region) =>
  (await nodes()).filter((n) => REGION[region](n) && (n.label.includes(DIAG.erro) || n.label.includes(DIAG.aviso)));

async function goto(url, waitMs = 9000) {
  await send('Page.navigate', { url });
  await sleep(waitMs);
  await enableSemantics();
}

// ------------------------------- coordenadas do layout -------------------------------
// Derivadas do layout em 1366x900: painel esquerdo 0..280, centro 286..1040,
// inspector 1046..1366; top bar 0..56; abas do painel esquerdo em y=107.
const UI = {
  tabWidgets: [70, 107],
  tabTree: [210, 107],
  paletteTile: {                    // paleta sem filtro, rolada no topo
    text: [50, 253], image: [134, 253], icon: [218, 253], button: [50, 327],
    container: [50, 421], column: [134, 421], row: [218, 421],
    padding: [134, 569], center: [218, 569], expanded: [218, 643],
  },
  deviceEmpty: [537, 700],          // dentro da tela do device, abaixo do conteúdo
  deviceTop: [537, 281],            // primeiro nó desenhado (raiz de uma linha só)
  treeFooterDrop: [140, 838],       // DropZone do rodapé da árvore
  inspectorWrapButton: [1294, 118], // "Envolver em Column ou Row" (PopupMenuButton)
  inspectorRemoveButton: [1334, 118],
  inspectorFirstField: [1206, 296], // campo "Texto" do nó text (1º da 1ª seção)
  statusBarSummary: [60, 886],
};

// ------------------------------- API -------------------------------
const listSameSlug = async () => {
  const r = await fetch(`${API}/contents?q=${encodeURIComponent('E2E 38')}&limit=100`, { headers: H });
  const body = r.ok ? await r.json() : { data: [] };
  return (body.data || []).filter((c) => c.slug === SLUG);
};
async function purge() {
  for (const c of await listSameSlug()) await fetch(`${API}/contents/${c.id}`, { method: 'DELETE', headers: H });
}
async function resolveCategoryId() {
  const r = await fetch(`${API}/categories`, { headers: H });
  const list = r.ok ? await r.json() : [];
  return list[0]?.id;
}
let contentId = '';
async function createContent() {
  const categoryId = await resolveCategoryId();
  const r = await fetch(`${API}/contents`, {
    method: 'POST', headers: JSON_H,
    body: JSON.stringify({ name: NAME, slug: SLUG, description: 'E2E do item 38', ...(categoryId ? { categoryId } : {}) }),
  });
  const body = await r.json();
  if (!body.id) throw new Error(`não consegui criar o conteúdo de teste: ${JSON.stringify(body)}`);
  contentId = body.id;
}
const getSpec = async () => (await (await fetch(`${API}/contents/${contentId}`, { headers: H })).json()).spec;
async function putRoot(root) {
  const spec = { specVersion: 1, kind: 'content', id: contentId, name: NAME, slug: SLUG, ...(root ? { root } : {}) };
  const r = await fetch(`${API}/contents/${contentId}`, { method: 'PUT', headers: JSON_H, body: JSON.stringify({ spec }) });
  if (!r.ok) throw new Error(`PUT do spec falhou: ${r.status}`);
}
const editorUrl = () => `${WEB}/projects/${PROJECT}/contents/${contentId}/edit`;

/// Forma legível da árvore: `column[text,image]`, `padding(expanded(text))`.
const shape = (n) => !n ? 'vazio' :
  `${n.type}${n.child ? `(${shape(n.child)})` : ''}${n.children?.length ? `[${n.children.map(shape).join(',')}]` : ''}`;

/// O spec só reflete o gesto depois do Ctrl+S — não há autosave no editor.
async function saveAndShape() {
  await ctrl('s');
  for (let i = 0; i < 20; i++) {
    await sleep(500);
    const spec = await getSpec();
    if (spec) return shape(spec.root);
  }
  return 'sem resposta';
}

// ------------------------------- resultado -------------------------------
let PASS = 0, FAIL = 0;
const g = '\x1b[32m', r = '\x1b[31m', d = '\x1b[2m', o = '\x1b[0m';
const failures = [];
function check(label, expected, actual) {
  if (String(expected) === String(actual)) { PASS++; console.log(`  ${g}PASS${o} ${label}`); }
  else { FAIL++; failures.push(label); console.log(`  ${r}FAIL${o} ${label}\n       ${d}esperado=${expected} obtido=${actual}${o}`); }
}
const shots = [];
async function shot(file, title, proved, humanEye) {
  await shotFile(file);
  shots.push({ file, title, proved, humanEye });
  console.log(`  ${d}·${o} ${file}`);
}
function step(n, title) { console.log(`\n${'='.repeat(3)} ${n} — ${title}`); }

// ================================== roteiro ==================================
send = await connect();
await send('Page.enable'); await send('Runtime.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1366, height: 900, deviceScaleFactor: 1, mobile: false });

console.log(`Alvo: ${WEB}  API: ${API}  projeto: ${PROJECT}  slug: ${SLUG}`);
await purge();
await createContent();
console.log(`Conteúdo de teste: ${contentId}`);

try {
  step('§10.1', 'conteúdo novo, página vazia (sem root)');
  check('a página nasce sem root', 'vazio', shape((await getSpec()).root));
  await goto(editorUrl());
  await shot('01_pagina_vazia.png', 'Página vazia', 'spec sem `root` (GET /contents/:id)',
    'canvas com o convite "Arraste um widget da paleta até aqui" e o rodapé da árvore dizendo "Solte um widget aqui para começar"');

  step('§10.2', 'arrastar Text da paleta → vira a raiz');
  await drag(...UI.paletteTile.text, ...UI.deviceEmpty);
  check('o primeiro widget solto virou a raiz', 'text', await saveAndShape());
  await shot('02_text_vira_raiz.png', 'Text vira a raiz', 'root.type == "text"',
    'o Text aparece no canvas E na árvore; o inspector abre no nó recém-criado');

  step('§10.3', 'arrastar Image sobre o mock → agrupa em vez de recusar (F4/D5)');
  await drag(...UI.paletteTile.image, ...UI.deviceEmpty);
  check('o drop na raiz-folha agrupou numa column', 'column[text,image]', await saveAndShape());
  await shot('03_drop_agrupou_column.png', 'Drop agrupa em vez de recusar', 'root virou column[text,image]',
    'a barra de status explica: "Text não recebia esse widget — os dois foram agrupados numa Column."');

  step('§10.4', 'UM Ctrl+Z desfaz agrupamento + inserção (D4) — print do DoD');
  await ctrl('z');
  check('um único Ctrl+Z voltou ao text sozinho (não a column[text])', 'text', await saveAndShape());
  await shot('04_undo_unico.png', 'Um único Ctrl+Z', 'depois de UM Ctrl+Z o spec é `text` — não `column[text]`: wrap+drop são uma entrada só',
    'o canvas mostra só o Text; o botão de refazer fica habilitado');

  step('§10.5', 'Ctrl+Y refaz o agrupamento');
  await ctrl('y');
  check('o redo trouxe o agrupamento de volta', 'column[text,image]', await saveAndShape());
  await shot('05_redo.png', 'Ctrl+Y refaz', 'root voltou a column[text,image]', 'o Image reaparece no canvas e na árvore');

  step('§10.6a', 'comando "Envolver em Row" pelo inspector (F2)');
  await click(...UI.tabTree);
  await selectTreeRow(1, 'o Text dentro da column');
  await click(...UI.inspectorWrapButton);
  await sleep(700);
  await shot('06a_menu_envolver.png', 'Menu "Envolver em…"', 'o botão de envolver existe no cabeçalho do inspector',
    'o menu abre com Column (mostrando "Ctrl+G") e Row');
  const rowItem = await pickNode((n) => n.role === 'menuitem' && /^row/i.test(n.label), 'item de menu "Row"');
  await click(rowItem.x, rowItem.y);
  check('"Envolver em Row" produziu row[text] sem mexer no irmão', 'column[row[text],image]', await saveAndShape());
  await shot('06b_envolvido_em_row.png', 'Envolver em Row', 'o nó apontado virou row[text] e o Image ficou onde estava (D3)',
    'a Row fica selecionada no inspector logo após o comando, e a barra diz "Envolvido numa Row."');

  step('§10.6b', 'Ctrl+G envolve em Column (D8)');
  await click(...UI.tabTree);
  await selectTreeRow(1, 'a Row recém-criada');
  await ctrl('g');
  check('Ctrl+G envolveu o nó selecionado numa column', 'column[column[row[text]],image]', await saveAndShape());
  await shot('06c_ctrl_g_envolve.png', 'Ctrl+G envolve', 'Ctrl+G disparou o mesmo wrap do botão, em column',
    'a barra de status diz "Envolvido numa Column." — e o Chrome não reagiu (isto o script NÃO prova: ver H1 do roteiro humano)');

  step('§10.6c', 'Ctrl+G é inerte com o cursor num campo de texto (guarda _isEditingText)');
  await click(...UI.tabTree);
  await selectTreeRow(3, 'o Text lá no fundo');
  await click(...UI.inspectorFirstField);
  await sleep(400);
  check('o foco está num campo de texto real', 'INPUT', await evalJS(`document.activeElement.tagName`));
  const before = shape((await getSpec()).root);
  await ctrl('g');
  check('Ctrl+G dentro do campo não envolveu nada', before, await saveAndShape());
  await shot('06d_ctrl_g_inerte_no_campo.png', 'Ctrl+G inerte no campo', 'com o cursor no campo "Texto", Ctrl+G não alterou o spec',
    'o campo continua com o cursor e nada muda na árvore');
  await evalJS('document.activeElement.blur()');
  await sleep(400);

  step('§10.7', 'a regra única do 8e: o mesmo agrupamento nos três pontos de drop');
  const leafRoot = { id: 'nd_1', type: 'text', props: { data: 'Texto' } };
  // Paleta e árvore são ABAS do mesmo painel: soltar um tile da paleta na árvore é
  // impossível nesta UI (ver achado A1 no roteiro humano). O que a árvore permite —
  // e é o que importa — é arrastar um nó JÁ EXISTENTE para um alvo sem slot livre.
  const chainRoot = { id: 'nd_card', type: 'card', props: {}, child: { id: 'nd_pad', type: 'padding', props: {}, child: { ...leafRoot } } };

  await putRoot(chainRoot); await goto(editorUrl());
  await click(...UI.tabTree);
  const alvoCard = await treeRow(0, 'a raiz card');
  const origemText = await treeRow(2, 'o text lá no fundo');
  await drag(origemText.x, origemText.y, alvoCard.x, alvoCard.y);
  check('drop na LINHA DA ÁRVORE, com a cadeia de slots esgotada, agrupou', 'column[card(padding),text]', await saveAndShape());
  await shot('07a_drop_na_linha_da_arvore.png', 'Drop na linha da árvore', 'arrastar o Text sobre o Card (cadeia sem slot livre) produziu column[card(padding), text] — o painel da árvore usa a mesma regra do canvas',
    'a linha da árvore acende como alvo durante o arraste e a barra explica o agrupamento');

  await putRoot(chainRoot); await goto(editorUrl());
  await click(...UI.tabTree);
  await sleep(400);
  await drag(...UI.deviceTop, ...UI.treeFooterDrop);
  check('drop no RODAPÉ DA ÁRVORE agrupou igual', 'column[card(padding),text]', await saveAndShape());
  await shot('07b_drop_no_rodape_da_arvore.png', 'Drop no rodapé da árvore', 'arrastar do canvas para o rodapé deu o mesmo column[card(padding), text]',
    'o rodapé diz "Soltar aqui adiciona ao fim do conteúdo" e acende no arraste');

  await putRoot(leafRoot); await goto(editorUrl());
  await drag(...UI.paletteTile.image, ...UI.deviceTop);
  check('drop SOBRE O NÓ DO CANVAS agrupou igual', 'column[text,image]', await saveAndShape());
  await shot('07c_drop_sobre_o_no_do_canvas.png', 'Drop sobre o nó do canvas', 'soltar o tile em cima do próprio nó (e não no vazio) deu o mesmo column[text,image]',
    'o nó do canvas acende como alvo durante o arraste');

  step('§10.8', 'Ctrl+C / Ctrl+V com a raiz folha cola agrupando (não recusa)');
  await putRoot(leafRoot); await goto(editorUrl());
  await click(...UI.tabTree);
  await selectTreeRow(0, 'a raiz text');
  await ctrl('c'); await sleep(400);
  await ctrl('v');
  check('a colagem sobre raiz folha agrupou', 'column[text,text]', await saveAndShape());
  await shot('08_colar_agrupa.png', 'Colar agrupa', 'Ctrl+V sobre raiz folha produziu column[text,text] — não emite mais recusa',
    'a barra de status explica o agrupamento em vez de reclamar');

  step('§10.9', 'marcação de problema no próprio nó (F5) — print do DoD');
  await putRoot({ id: 'nd_p', type: 'padding', props: {} });
  await goto(editorUrl());
  await drag(...UI.paletteTile.expanded, ...UI.deviceEmpty);
  check('o expanded entrou no padding (fora de Row/Column)', 'padding(expanded)', await saveAndShape());
  await shot('09a_erro_no_canvas.png', 'Erro marcado no canvas', 'o expanded caiu fora de Row/Column e o conteúdo passou a ter 1 erro · 1 aviso',
    'o selo vermelho aparece no canto do nó **no canvas**; como este expanded ainda não tem filho, ele desenha com altura zero e o selo flutua — limitação conhecida (§5 › F5), não é bug');

  await click(...UI.statusBarSummary); await sleep(800);
  await shot('09b_lista_de_problemas.png', 'Erro e aviso na barra', 'o resumo abre a lista de problemas do conteúdo',
    'erro e aviso se distinguem por ÍCONE + TEXTO, não só por cor ("1 erro · 1 aviso")');
  await click(...UI.statusBarSummary); await sleep(600);

  await click(...UI.tabTree); await sleep(600);
  const treeDiag = await diagnosticsIn('tree');
  check('a árvore ganhou marcação de diagnóstico', true, treeDiag.length > 0);
  check('a marcação da árvore agrega o erro E o aviso do mesmo nó', true,
    treeDiag.some((n) => n.label.includes(DIAG.erro)) && treeDiag.some((n) => n.label.includes(DIAG.aviso)));
  await shot('09c_erro_na_arvore.png', 'Erro marcado na árvore', 'a linha da árvore do Expanded carrega a mensagem do erro e a do aviso',
    'o ícone fica na linha, antes da lixeira; a marcação existe nos DOIS painéis, não só no rodapé');

  // Um expanded sem filho desenha com altura zero: para o selo do canvas ter onde
  // ancorar, o nó precisa de conteúdo — e isso se consegue por gesto, arrastando um
  // nó existente para dentro dele pela árvore.
  await click(...UI.tabWidgets); await sleep(400);
  await drag(...UI.paletteTile.text, ...UI.deviceEmpty);
  check('o text solto na raiz ocupada agrupou de novo', 'column[padding(expanded),text]', await saveAndShape());
  await click(...UI.tabTree); await sleep(600);
  const alvoExpanded = await treeRow(2, 'o expanded');
  const origemTextoNovo = await treeRow(3, 'o text novo');
  await drag(origemTextoNovo.x, origemTextoNovo.y, alvoExpanded.x, alvoExpanded.y);
  check('o text entrou no slot livre do expanded', 'column[padding(expanded(text))]', await saveAndShape());
  await click(...UI.tabWidgets); await sleep(600);
  const canvasDiag = await diagnosticsIn('canvas');
  check('com o nó desenhando, o selo do canvas aparece', true, canvasDiag.length > 0);
  await shot('09d_selo_ancorado_no_canvas.png', 'Selo ancorado no nó do canvas', 'com o expanded desenhando (agora tem filho), o selo de erro aparece preso ao nó, no canvas',
    'o selo fica no topo-direito do nó e convive com o rótulo do nó, à esquerda — os dois na mesma faixa (§5 › F5)');

  await click(...UI.tabTree); await sleep(600);
  await selectTreeRow(2, 'o expanded');
  await ctrl('g');
  check('envolver o expanded numa column corrigiu a estrutura', 'column[padding(column[expanded(text)])]', await saveAndShape());
  check('o erro sumiu da árvore', 0, (await diagnosticsIn('tree')).filter((n) => n.label.includes(DIAG.erro)).length);
  await click(...UI.tabWidgets); await sleep(600);
  check('o erro sumiu do canvas', 0, (await diagnosticsIn('canvas')).filter((n) => n.label.includes(DIAG.erro)).length);
  await shot('09e_marcacao_some.png', 'A marcação some ao corrigir', 'depois do Ctrl+G o expanded está dentro de uma Column e nenhuma marcação de erro sobrou — nem na árvore, nem no canvas',
    'a barra de status volta para "Nenhum problema"');

  step('§10.10', '"Esvaziar conteúdo" na raiz (F6/D9)');
  await putRoot({ id: 'nd_c', type: 'column', props: {}, children: [
    { id: 'nd_1', type: 'text', props: { data: 'Texto' } },
    { id: 'nd_2', type: 'image', props: {} },
  ] });
  await goto(editorUrl());
  await click(...UI.tabTree);
  const raiz = await selectTreeRow(0, 'a raiz column');
  await hover(raiz.x + 120, raiz.y, 1400);
  await shot('10a_tooltip_esvaziar_na_arvore.png', 'Rótulo na linha da árvore', 'a lixeira da raiz existe na linha da árvore',
    'o tooltip diz "Esvaziar conteúdo (Delete)" — e não "Remover bloco"');
  await hover(...UI.inspectorRemoveButton, 1400);
  await shot('10b_tooltip_esvaziar_no_inspector.png', 'Rótulo no inspector', 'a lixeira da raiz existe no cabeçalho do inspector',
    'o tooltip diz "Esvaziar conteúdo (Delete)" — o mesmo texto dos dois lados');
  await click(...UI.inspectorRemoveButton);
  check('esvaziar a raiz apagou o conteúdo inteiro, sem diálogo', 'vazio', await saveAndShape());
  await shot('10c_conteudo_esvaziado.png', 'Conteúdo esvaziado', 'o spec ficou sem root — e nenhum diálogo apareceu (D9)',
    'a página volta ao estado vazio, com o convite da paleta');
  await ctrl('z');
  check('um Ctrl+Z devolveu o conteúdo', 'column[text,image]', await saveAndShape());
  await shot('10d_undo_restaura.png', 'Ctrl+Z devolve', 'o conteúdo voltou inteiro',
    'nada se perdeu: os dois filhos voltam na mesma ordem');

  step('§10.11', 'salvar e recarregar: o conteúdo reabre idêntico (D1) — print do DoD');
  const antesDoReload = shape((await getSpec()).root);
  await goto(editorUrl());
  await click(...UI.tabTree); await sleep(800);
  const linhas = await treeRows();
  check('o spec não mudou com o reload', 'column[text,image]', shape((await getSpec()).root));
  check('o spec salvo é o mesmo de antes do reload', antesDoReload, shape((await getSpec()).root));
  check('o editor reabriu a árvore inteira (column + text + image)', 3, linhas.length);
  await shot('11_reabre_apos_reload.png', 'Reabre após reload', `o conteúdo reabriu com a árvore montada (${linhas.length} linhas) e o spec idêntico ao de antes do reload`,
    'nada de tela de erro nem de conteúdo inválido: o canvas volta a desenhar e a árvore mostra Conteúdo (Column) › Text, Image');

  step('§10.12', 'reordenar por drag dentro da column criada pelo wrap');
  const textoRow = await treeRow(1, 'o text');
  const imagemRow = await treeRow(2, 'o image');
  await drag(textoRow.x, textoRow.y, imagemRow.x, imagemRow.y);
  check('a column criada pelo wrap reordena como qualquer outra', 'column[image,text]', await saveAndShape());
  await shot('12_reordenar_na_column.png', 'Reordenar dentro da column', 'a ordem virou column[image,text]',
    'o arraste dentro da árvore se comporta como numa Column montada à mão');
} finally {
  console.log('\nLimpando o rastro…');
  await purge();
  writeFileSync(`${OUT}/README.md`, readme());
}

console.log(`\n${g}PASS=${PASS}${o}  ${r}FAIL=${FAIL}${o}`);
if (FAIL > 0) console.log(`${r}Falhas:${o} ${failures.join(' | ')}`);
process.exit(FAIL > 0 ? 1 : 0);

function readme() {
  const linhas = shots.map((s) => `### ${s.title}\n\n![${s.title}](${s.file})\n\n- **O script já provou:** ${s.proved}\n- **Só o seu olho prova:** ${s.humanEye}\n`);
  return `# Rodada ${OUT.split('rodada_')[1] || '??'} — E2E do item 38 (destravar o construtor)

> Prints **gerados pelo QA** (headless, via CDP, contra a homologação real). O dev
> humano **confere** — não opera o browser. Cada gesto do roteiro da §10 do
> \`plan.md\` foi executado na tela e o **spec resultante foi conferido por API**.

**Resultado das asserções:** ${PASS} PASS / ${FAIL} FAIL${FAIL ? `\n\nFalhas: ${failures.join(' | ')}` : ''}

## Como regerar

\`\`\`bash
docs/15-destravar-construtor/e2e_hml.sh          # contrato por API (idempotente)
docs/15-destravar-construtor/e2e_shots.sh 01     # estes prints, na rodada 01
\`\`\`

Os dois criam um único conteúdo de teste no projeto \`default\` do hml e o apagam no
fim. Nada sobra em homologação; nada disso vai para produção.

## O que o script NÃO consegue provar (é o seu roteiro)

Está em [\`roteiro_e2e_humano.md\`](../../roteiro_e2e_humano.md): o \`Ctrl+G\` sem o
Chrome reagir é o caso que teste nenhum pega — teclado sintético não passa pelo
mesmo caminho do teclado real.

## Estados capturados

${linhas.join('\n')}`;
}
