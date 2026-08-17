// E2E — item 24 (publicação e versionamento) / dirige o fluxo na tela da
// homologação e assere o estado por API depois de cada passo. Sem dependências
// (WebSocket/fetch/crypto nativos do Node 22+). Chamado pelo e2e_shots.sh.
//
// O roteiro vai além do caminho feliz de propósito: os dois MODOS DE FALHA que
// o item 24 introduziu na barra de status (`EditorNoticeKind.publishFailed` e
// `restoreFailed`) são exercitados de verdade, cortando a rota por CDP
// (`Network.setBlockedURLs`). Cada um rende um print que tem de ser
// visualmente distinto do print do sucesso equivalente — item do DoD.
//
// ---------------------------------------------------------------------------
// COMO ESTE DRIVER ENXERGA A TELA (leia antes de mexer)
//
// 1. **Diálogos e o corpo da página** expõem árvore semântica: o alvo sai do
//    rótulo (`Publicar conteúdo`, `Versão 2`, `Restaurar`…), não de pixel.
// 2. **O topo do shell NÃO expõe semântica nenhuma** — nem os botões
//    (Salvar/Publicar/⋮), nem o indicador de status ("No ar (v3)"), nem os
//    breadcrumbs. Idem a **barra de status do editor** (o rodapé com
//    "Nenhum problema" e os avisos de falha). É o achado A1 do `test_plan.md`
//    (o `BlockSemantics` da barreira de rota derruba a casca do shell). Até
//    ele ser corrigido, esses dois pedaços são tratados por:
//    · **clique varrido e verificado** — tenta os x candidatos da faixa de
//      ações e confirma pelo diálogo que abriu (diálogo tem semântica);
//      errou o alvo, manda Esc e tenta o próximo. A faixa é ancorada à
//      direita e desliza com a largura do texto de status, por isso varredura
//      e não coordenada fixa.
//    · **impressão digital de faixa de pixels** — o hash de um recorte da
//      tela prova "mudou" / "não mudou" sem precisar ler o texto. É assim que
//      o roteiro assere, por máquina, que falhar é visualmente diferente de
//      dar certo.
// ---------------------------------------------------------------------------
//
// Auto-limpante: cria UM conteúdo de teste (slug $SLUG) e o apaga no fim, e
// purga qualquer rastro do mesmo slug no começo. NUNCA toca outro conteúdo.
//
// Env: WEB_BASE, API_BASE, PROJECT, SLUG, OUT, CDP_PORT
import { createHash } from 'node:crypto';
import { writeFileSync } from 'node:fs';

const WEB = process.env.WEB_BASE;
const API = process.env.API_BASE;
const PROJECT = process.env.PROJECT || 'default';
const SLUG = process.env.SLUG || 'e2e-24-publicacao';
const NAME = 'E2E 24 publicação';
const NOTE = 'primeira publicação pelo editor';
const OUT = process.env.OUT;
const PORT = Number(process.env.CDP_PORT || 9224);
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

async function click(x, y, settle = 700) {
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
  await sleep(90);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await sleep(60);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  await sleep(settle);
}

async function pressEscape() {
  const p = { key: 'Escape', code: 'Escape', windowsVirtualKeyCode: 27, nativeVirtualKeyCode: 27 };
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...p });
  await sleep(40);
  await send('Input.dispatchKeyEvent', { type: 'keyUp', ...p });
  await sleep(700);
}

/// Estaciona o ponteiro longe de qualquer controle: hover muda cor de botão e
/// contaminaria a impressão digital das faixas.
const parkPointer = () => send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 683, y: 700 });

async function shotFile(name) {
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(`${OUT}/${name}`, Buffer.from(data, 'base64'));
}

/// Impressão digital de um recorte da tela. Não lê o texto — prova que aquele
/// pedaço mudou (ou não mudou) entre dois momentos. É o substituto honesto da
/// asserção de rótulo enquanto o topo e o rodapé não expõem semântica (A1).
async function stripHash(clip) {
  await parkPointer();
  await sleep(250);
  const { data } = await send('Page.captureScreenshot', { format: 'png', clip: { ...clip, scale: 1 } });
  return createHash('sha1').update(data).digest('hex').slice(0, 12);
}

/// Faixa do indicador de status do topo — ancorada à direita, antes do botão
/// de tema. Cobre os três estados ("Nunca publicado" / "Alterações não
/// publicadas" / "No ar (vN)").
const TOP_STATUS_STRIP = { x: 1090, y: 6, width: 225, height: 44 };
/// Faixa do rodapé do editor: resumo de diagnósticos + recado de falha.
const STATUS_BAR_STRIP = { x: 0, y: 870, width: 620, height: 30 };

/// Corta a rota no nível do browser: a requisição nem sai, o Dio recebe erro
/// de rede e o cubit cai no ramo de falha. É o jeito de provocar
/// `publishFailed`/`restoreFailed` sem tocar em uma linha de código do app.
const blockRoutes = (urls) => send('Network.setBlockedURLs', { urls });

// ------------------------------- semântica do Flutter -------------------------------
async function waitForApp(timeout = 45000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const up = await evalJS(`!!(document.querySelector('flt-glass-pane') || document.querySelector('flt-semantics-placeholder'))`);
    if (up) return true;
    await sleep(500);
  }
  console.warn('  (aviso) o app não terminou de subir no prazo — seguindo mesmo assim');
  return false;
}

async function enableSemantics() {
  for (let i = 0; i < 25; i++) {
    await evalJS(`(() => { const p = document.querySelector('flt-semantics-placeholder') || document.querySelector('[aria-label="Enable accessibility"]'); if (p) p.click(); return !!p; })()`);
    await sleep(600);
    const n = await evalJS(`document.querySelectorAll('flt-semantics[role]').length`);
    if (n && n > 0) return;
  }
  console.warn('  (aviso) semântica não confirmada — seguindo mesmo assim');
}

/// O engine web deste Flutter escreve o rótulo ora em `aria-label`, ora como
/// texto do próprio elemento (label representation). Ler os dois é o que faz
/// `Publicar`, `Versão 2` e o selo do card aparecerem.
const NODES_JS = `(() => Array.from(document.querySelectorAll('flt-semantics')).map(e => { const r = e.getBoundingClientRect(); const own = Array.from(e.childNodes).filter(c => c.nodeType===3 || (c.nodeType===1 && c.tagName!=='FLT-SEMANTICS')).map(c => c.textContent||'').join(' '); return { label: ((e.getAttribute('aria-label')||'') + ' ' + own).replace(/\\s+/g,' ').trim(), role: e.getAttribute('role')||'', disabled: e.getAttribute('aria-disabled')==='true', x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height) }; }).filter(n => n.w > 0 && n.h > 0))()`;
/// Árvore vazia quase sempre é semântica ainda não ligada (o placeholder só
/// existe depois que o app sobe) — religa e tenta de novo antes de desistir.
async function nodes() {
  const first = (await evalJS(NODES_JS)) || [];
  if (first.length > 0) return first;
  await enableSemantics();
  return (await evalJS(NODES_JS)) || [];
}

const labelExists = async (re) => (await nodes()).some((n) => re.test(n.label));

async function labelsWithin(re, { timeout = 10000 } = {}) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    if (await labelExists(re)) return true;
    await sleep(400);
  }
  return false;
}

async function findNode(pred, description, { timeout = 12000 } = {}) {
  const start = Date.now();
  let last = [];
  while (Date.now() - start < timeout) {
    last = await nodes();
    const hit = last.find(pred);
    if (hit) return hit;
    await sleep(400);
  }
  console.error('  [debug] rótulos vistos:', JSON.stringify(
    last.filter((n) => n.label).map((n) => `${n.role || '-'}:"${n.label}"@${n.x},${n.y}`).slice(0, 40)));
  throw new Error(`alvo não encontrado na árvore semântica: ${description}`);
}

const TAPPABLE = (n) => n.role === 'button' || n.role === 'menuitem' || n.role === '';

async function clickLabel(labelRe, description, where = () => true) {
  const node = await findNode((n) => where(n) && TAPPABLE(n) && labelRe.test(n.label), description);
  await click(node.x, node.y);
  return node;
}

/// Um botão de confirmação de diálogo mora sempre na mesma faixa do
/// "Cancelar" — é assim que se distingue o "Restaurar" da confirmação dos
/// vários "Restaurar" das linhas do histórico atrás dela.
async function clickConfirm(labelRe, description) {
  const cancel = await findNode((n) => n.role === 'button' && /^Cancelar$/.test(n.label), 'botão Cancelar do diálogo');
  const hit = (await nodes()).find((n) => n.role === 'button' && labelRe.test(n.label) && Math.abs(n.y - cancel.y) <= 24);
  if (!hit) throw new Error(`botão de confirmação não encontrado na faixa do Cancelar: ${description}`);
  await click(hit.x, hit.y, 1000);
  return hit;
}

/// Ação que mora na MESMA LINHA de um rótulo (a linha da versão no histórico).
async function clickInRowOf(anchorRe, labelRe, description) {
  const anchor = await findNode((n) => anchorRe.test(n.label), `linha ${anchorRe}`);
  const hit = (await nodes()).find((n) => n.role === 'button' && labelRe.test(n.label) && Math.abs(n.y - anchor.y) <= 40);
  if (!hit) throw new Error(`ação não encontrada na linha: ${description}`);
  await click(hit.x, hit.y);
  return hit;
}

/// Varredura verificada da faixa de ações do topo (ver o cabeçalho: o topo não
/// tem semântica e desliza com a largura do texto de status). Só toca a região
/// dos dois últimos botões — Desfazer/Refazer ficam bem à esquerda de 980 e
/// nunca entram na varredura, para nenhum clique perdido mexer no documento.
const TOP_BAR_Y = 27;
const SCAN = { publish: [1067, 1097, 1037, 1127, 1007, 1157, 987], more: [1144, 1174, 1114, 1194, 1084] };

async function openFromTopBar(which, expectRe, description) {
  for (const x of SCAN[which]) {
    await click(x, TOP_BAR_Y, 900);
    if (await labelsWithin(expectRe, { timeout: 2500 })) return x;
    await pressEscape();
  }
  throw new Error(`não consegui abrir ${description} pela faixa de ações do topo`);
}

/// O selo de publicação do card. O `InkWell` do card funde a semântica dos
/// filhos num rótulo só, então o selo é extraído de dentro do rótulo do card
/// do CONTEÚDO DE TESTE — a lista tem outros cards com selo, e um `some(…)`
/// global provaria o card errado.
async function cardBadge({ timeout = 12000 } = {}) {
  const start = Date.now();
  let last = [];
  while (Date.now() - start < timeout) {
    last = await nodes();
    const card = last.find((n) => n.label.includes(SLUG) && n.label.includes(NAME));
    const match = card?.label.match(/(?:No ar|Rascunho): .*?(?= Modificado em)/);
    if (match) return match[0];
    await sleep(400);
  }
  console.error('  [debug] rótulos vistos:', JSON.stringify(
    last.filter((n) => n.label).map((n) => `"${n.label}"`).slice(0, 20)));
  return 'selo não encontrado no card do conteúdo de teste';
}

async function goto(url, waitMs = 6000) {
  await send('Page.navigate', { url });
  await waitForApp();
  await sleep(waitMs);
  await enableSemantics();
  await parkPointer();
}

// ------------------------------- API -------------------------------
const listSameSlug = async () => {
  const r = await fetch(`${API}/contents?q=${encodeURIComponent(SLUG)}&limit=100`, { headers: H });
  const body = r.ok ? await r.json() : { data: [] };
  return (body.data || []).filter((c) => c.slug === SLUG);
};
async function purge() {
  for (const c of await listSameSlug()) await fetch(`${API}/contents/${c.id}`, { method: 'DELETE', headers: H });
}
async function resolveCategoryId() {
  const r = await fetch(`${API}/categories`, { headers: H });
  const list = r.ok ? await r.json() : [];
  return Array.isArray(list) ? list[0]?.id : undefined;
}
let contentId = '';
async function createContent() {
  const categoryId = await resolveCategoryId();
  const r = await fetch(`${API}/contents`, {
    method: 'POST', headers: JSON_H,
    body: JSON.stringify({ name: NAME, slug: SLUG, description: 'E2E do item 24', ...(categoryId ? { categoryId } : {}) }),
  });
  const body = await r.json();
  if (!body.id) throw new Error(`não consegui criar o conteúdo de teste: ${JSON.stringify(body)}`);
  contentId = body.id;
}
const specOf = (marker) => ({
  specVersion: 1, kind: 'content', id: contentId, name: NAME, slug: SLUG,
  root: { id: 'nd_root', type: 'text', props: { data: marker } },
});
async function putSpec(marker) {
  const r = await fetch(`${API}/contents/${contentId}`, {
    method: 'PUT', headers: JSON_H, body: JSON.stringify({ spec: specOf(marker) }),
  });
  if (!r.ok) throw new Error(`PUT do spec falhou: ${r.status}`);
  // D7 compara timestamps com resolução de ms — o publish precisa cair depois.
  await sleep(120);
}
const getContent = async () => (await fetch(`${API}/contents/${contentId}`, { headers: H })).json();
const draftMarker = async () => (await getContent()).spec?.root?.props?.data ?? 'sem spec';
const publishedVersion = async () => (await getContent()).publishedVersion?.version ?? null;
const versionList = async () =>
  ((await (await fetch(`${API}/contents/${contentId}/versions?limit=100`, { headers: H })).json()).data) || [];
const versionSpecMarker = async (version) => {
  const body = await (await fetch(`${API}/contents/${contentId}/versions/${version}`, { headers: H })).json();
  return body.spec?.root?.props?.data ?? 'sem spec';
};

const editorUrl = () => `${WEB}/projects/${PROJECT}/contents/${contentId}/edit`;
const projectUrl = () => `${WEB}/projects/${PROJECT}`;

// ------------------------------- resultado -------------------------------
let PASS = 0, FAIL = 0;
const g = '\x1b[32m', r = '\x1b[31m', d = '\x1b[2m', o = '\x1b[0m';
const failures = [];
function check(label, expected, actual) {
  if (String(expected) === String(actual)) { PASS++; console.log(`  ${g}PASS${o} ${label}`); }
  else { FAIL++; failures.push(label); console.log(`  ${r}FAIL${o} ${label}\n       ${d}esperado=${expected} obtido=${actual}${o}`); }
}
function checkDiffers(label, before, after) {
  if (before !== after) { PASS++; console.log(`  ${g}PASS${o} ${label}`); }
  else { FAIL++; failures.push(label); console.log(`  ${r}FAIL${o} ${label}\n       ${d}a faixa não mudou (hash ${before})${o}`); }
}
const shots = [];
async function shot(file, title, proved, humanEye) {
  await parkPointer();
  await sleep(250);
  await shotFile(file);
  shots.push({ file, title, proved, humanEye });
  console.log(`  ${d}·${o} ${file}`);
}
function step(n, title) { console.log(`\n=== ${n} — ${title}`); }

// ================================== roteiro ==================================
send = await connect();
await send('Page.enable'); await send('Runtime.enable'); await send('Network.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1366, height: 900, deviceScaleFactor: 1, mobile: false });

console.log(`Alvo: ${WEB}  API: ${API}  projeto: ${PROJECT}  slug: ${SLUG}`);
await blockRoutes([]);
await purge();
await createContent();
await putSpec('VERSAO-1');
console.log(`Conteúdo de teste: ${contentId}`);

try {
  step('1', 'lista de conteúdos — conteúdo nunca publicado traz o selo "Rascunho"');
  await goto(projectUrl());
  check('o selo do card é "Rascunho" (ícone + texto, nunca só cor)',
    'Rascunho: Nunca publicado', await cardBadge());
  await shot('01_lista_selo_rascunho.png', 'Lista: selo "Rascunho"',
    'o card do conteúdo de teste expõe `Rascunho: Nunca publicado` na árvore semântica',
    'o selo é discreto, ao lado da categoria, e legível — ícone + texto');

  step('2', 'editor abre em "Nunca publicado"');
  await goto(editorUrl());
  const topNuncaPublicado = await stripHash(TOP_STATUS_STRIP);
  await shot('02_editor_nunca_publicado.png', 'Editor: "Nunca publicado"',
    'o editor abriu no conteúdo de teste, que a API reporta como publishedVersion == null',
    'o topo diz "Nunca publicado" com o ícone de olho fechado, e o botão Publicar está clicável (contorno, não apagado)');
  check('a API confirma que nada está no ar', null, await publishedVersion());

  step('3', 'confirmar a publicação — o diálogo anuncia a versão que nasce');
  await openFromTopBar('publish', /Publicar conteúdo/, 'o diálogo de publicação');
  check('o diálogo anuncia a versão 1', true, await labelsWithin(/Isso cria a versão 1 e coloca ela no ar/));
  await shot('03_dialogo_publicar_v1.png', 'Diálogo de publicação',
    'o diálogo diz "Isso cria a versão 1 e coloca ela no ar"',
    'o campo de nota mostra o contador de 200 caracteres e o botão "Publicar" está em destaque');
  await click(683, 490, 400);
  await send('Input.insertText', { text: NOTE });
  await sleep(400);
  await clickConfirm(/^Publicar$/, 'botão Publicar do diálogo');
  await sleep(1800);

  step('4', 'publicado — versão 1 no ar e o topo muda de estado');
  check('a API confirma a versão 1 no ar', 1, await publishedVersion());
  const versoes1 = await versionList();
  check('existe exatamente uma versão', 1, versoes1.length);
  check('a nota digitada no diálogo chegou na versão', NOTE, versoes1[0]?.note);
  const topNoArV1 = await stripHash(TOP_STATUS_STRIP);
  checkDiffers('o indicador do topo mudou ao publicar', topNuncaPublicado, topNoArV1);
  await shot('04_topo_no_ar_v1.png', 'Publicado: "No ar (v1)"',
    'a API devolve publishedVersion.version == 1, a nota foi gravada e a faixa do indicador do topo mudou de imagem',
    'o topo agora diz "No ar (v1)" em verde COM ícone de check — compare com o print 13 (falha), que é o mesmo lugar da tela em outro estado');

  step('5', 'a lista de conteúdos passa a mostrar "No ar" sem request extra');
  await goto(projectUrl());
  check('o selo do card virou "No ar"',
    'No ar: No ar — o que está publicado bate com o rascunho', await cardBadge());
  await shot('05_lista_selo_no_ar.png', 'Lista: selo "No ar"',
    'o mesmo card agora expõe `No ar: …` — o dado vem do summary da própria lista, sem request extra',
    'o selo mudou de ícone e de cor, e o tooltip conta a nuance');

  step('6', 'rascunho alterado por fora — o editor reabre em "Alterações não publicadas"');
  await putSpec('VERSAO-2');
  await goto(editorUrl());
  const topAlteracoes = await stripHash(TOP_STATUS_STRIP);
  checkDiffers('o indicador do topo distingue "alterações não publicadas" de "no ar"', topNoArV1, topAlteracoes);
  await shot('06_alteracoes_nao_publicadas.png', 'Editor: alterações não publicadas',
    'com o rascunho mais novo que o publicado, a faixa do indicador é diferente das duas anteriores',
    'o topo diz "Alterações não publicadas" — o terceiro estado, distinguível por ícone, não só pela frase');

  step('7', 'publicar de novo — versão 2');
  await openFromTopBar('publish', /Publicar conteúdo/, 'o diálogo de publicação');
  check('o diálogo anuncia a versão 2', true, await labelsWithin(/Isso cria a versão 2 e coloca ela no ar/));
  await clickConfirm(/^Publicar$/, 'botão Publicar do diálogo');
  await sleep(1800);
  check('a API confirma a versão 2 no ar', 2, await publishedVersion());
  check('agora são duas versões', 2, (await versionList()).length);
  const topNoArV2 = await stripHash(TOP_STATUS_STRIP);
  checkDiffers('o indicador do topo mudou de novo ao publicar', topAlteracoes, topNoArV2);
  await shot('07_topo_no_ar_v2.png', 'Publicado: "No ar (v2)"',
    'a API tem duas versões e o indicador do topo mudou de imagem outra vez',
    'o topo diz "No ar (v2)" — o número acompanhou a versão, não ficou preso na v1');

  step('8', 'histórico de versões — as duas, mais nova primeiro, com o selo "No ar"');
  await openFromTopBar('more', /Mais opções/, 'o menu "Mais opções"');
  check('o menu oferece despublicar (o conteúdo está no ar)', true, await labelsWithin(/Despublicar/));
  await shot('08_menu_mais_opcoes.png', 'Menu "Mais opções"',
    'o menu expõe "Ver histórico de versões" e "Despublicar"',
    'despublicar está escondido atrás do menu, nunca no botão principal (decisão do §8 do plano)');
  await clickLabel(/Ver histórico de versões/, 'opção "Ver histórico de versões"');
  check('o histórico lista a versão 2', true, await labelsWithin(/Versão 2/));
  check('o histórico lista a versão 1', true, await labelsWithin(/Versão 1/));
  await shot('09_historico_de_versoes.png', 'Histórico de versões',
    'o diálogo lista "Versão 2" e "Versão 1", com a nota da primeira publicação',
    'a v2 (a mais nova) está no topo e é a única com o selo "No ar"; cada linha tem data e o botão Restaurar');

  step('9', 'restaurar a v1 — confirmação própria, porque descarta o rascunho');
  await clickInRowOf(/Versão 1/, /^Restaurar$/, 'botão Restaurar da linha da v1');
  check('a confirmação nomeia a versão', true, await labelsWithin(/Restaurar a versão 1\?/));
  await shot('10_confirmar_restauro.png', 'Confirmação de restauro',
    'o diálogo diz "Restaurar a versão 1?" e avisa que o publicado não muda',
    'a confirmação é uma etapa separada de fechar o histórico — não dá para restaurar por engano');
  await clickConfirm(/^Restaurar$/, 'botão Restaurar da confirmação');
  await sleep(2500);

  step('10', 'restaurado — o rascunho virou a v1 e o que está no ar continua a v2 (D4)');
  check('o histórico fechou sozinho no sucesso', false, await labelExists(/Histórico de versões/));
  check('o rascunho no servidor é o spec da v1', 'VERSAO-1', await draftMarker());
  check('o que está no ar continua a v2', 2, await publishedVersion());
  check('restaurar não criou versão nova', 2, (await versionList()).length);
  const barraAposRestauroOk = await stripHash(STATUS_BAR_STRIP);
  await shot('11_restaurado_no_canvas.png', 'Restaurado para o rascunho',
    'o diálogo fechou, o rascunho do servidor voltou a ser o spec da v1 e publishedVersion continua 2',
    'o canvas passou a desenhar o conteúdo da v1, o rodapé NÃO tem aviso de erro e o botão Desfazer ficou habilitado');

  step('11', 'republicar o rollback — publish salva o rascunho sujo antes (P3)');
  await openFromTopBar('publish', /Publicar conteúdo/, 'o diálogo de publicação');
  await clickConfirm(/^Publicar$/, 'botão Publicar do diálogo');
  await sleep(2500);
  check('a API confirma a versão 3 no ar', 3, await publishedVersion());
  check('a v3 publicou o conteúdo restaurado da v1', 'VERSAO-1', await versionSpecMarker(3));
  const topNoArV3 = await stripHash(TOP_STATUS_STRIP);
  await shot('12_republicado_v3.png', 'Rollback publicado como v3',
    'publicar com o rascunho sujo salvou antes: a v3 carrega o spec da v1 (rollback em duas etapas, D4)',
    'o topo diz "No ar (v3)" e o rodapé continua sem aviso de erro');

  step('12', 'MODO DE FALHA 1 — publish que falha tem de ser visível');
  await blockRoutes(['*/publish']);
  await putSpec('RASCUNHO-QUE-NAO-SOBE');
  await goto(editorUrl());
  const topAntesDaFalha = await stripHash(TOP_STATUS_STRIP);
  const barraAntesDaFalha = await stripHash(STATUS_BAR_STRIP);
  await openFromTopBar('publish', /Publicar conteúdo/, 'o diálogo de publicação');
  await clickConfirm(/^Publicar$/, 'botão Publicar do diálogo');
  await sleep(3000);
  const barraDepoisDaFalha = await stripHash(STATUS_BAR_STRIP);
  checkDiffers('a barra de status mudou — a falha aparece na tela', barraAntesDaFalha, barraDepoisDaFalha);
  check('o indicador do topo NÃO mudou — a falha não mentiu que publicou',
    topAntesDaFalha, await stripHash(TOP_STATUS_STRIP));
  check('nenhuma versão foi criada', 3, (await versionList()).length);
  check('a API continua com a v3 no ar', 3, await publishedVersion());
  await shot('13_publish_falhou.png', 'FALHA de publicação (modo de falha 1)',
    'com a rota /publish cortada, a faixa do rodapé mudou (o aviso apareceu), a faixa do topo NÃO mudou (continua "Alterações não publicadas") e nenhuma versão nasceu',
    'o rodapé traz "Falha ao publicar. Tente novamente." com ÍCONE de erro em vermelho — inconfundível com os prints 04/07/12, onde o topo fica verde e o rodapé fica limpo');

  step('13', 'MODO DE FALHA 2 — restore que falha mantém o histórico aberto');
  await blockRoutes(['*/restore']);
  await openFromTopBar('more', /Mais opções/, 'o menu "Mais opções"');
  await clickLabel(/Ver histórico de versões/, 'opção "Ver histórico de versões"');
  await clickInRowOf(/Versão 1/, /^Restaurar$/, 'botão Restaurar da linha da v1');
  await clickConfirm(/^Restaurar$/, 'botão Restaurar da confirmação');
  await sleep(3000);
  check('o histórico CONTINUA aberto na falha', true, await labelExists(/Histórico de versões/));
  check('o rascunho não foi tocado', 'RASCUNHO-QUE-NAO-SOBE', await draftMarker());
  await shot('14_restore_falhou_dialogo_aberto.png', 'FALHA de restauro (modo de falha 2)',
    'com a rota /restore cortada, o diálogo de histórico NÃO fecha e o rascunho do servidor continua intacto — compare com o passo 10, onde o sucesso fecha o diálogo',
    'o diálogo segue aberto sobre a tela e o aviso de erro aparece atrás dele, no rodapé');
  await clickLabel(/^Fechar$/, 'botão Fechar do histórico');
  await sleep(1000);
  const barraDepoisDoRestoreFalho = await stripHash(STATUS_BAR_STRIP);
  checkDiffers('o rodapé mostra a falha do restauro (e não o rodapé limpo do sucesso)',
    barraAposRestauroOk, barraDepoisDoRestoreFalho);
  await shot('15_restore_falhou_barra.png', 'FALHA de restauro no rodapé',
    'fechado o diálogo, a faixa do rodapé continua diferente da que o restauro bem-sucedido deixou',
    'o rodapé traz "Falha ao restaurar essa versão. Tente novamente." com ícone de erro; no print 11 (sucesso) não há aviso nenhum');

  step('14', 'despublicar — sai do ar sem perder o histórico');
  await blockRoutes([]);
  await openFromTopBar('more', /Mais opções/, 'o menu "Mais opções"');
  await clickLabel(/Despublicar/, 'opção "Despublicar" do menu');
  check('a confirmação de despublicar aparece', true, await labelsWithin(/Despublicar conteúdo\?/));
  await shot('16_confirmar_despublicar.png', 'Confirmação de despublicar',
    'o diálogo avisa que o conteúdo some da API pública agora e que o histórico fica guardado',
    'a confirmação deixa claro que a ação é reversível — não assusta mais do que precisa');
  await clickConfirm(/^Despublicar$/, 'botão Despublicar da confirmação');
  await sleep(2500);
  check('a API não tem mais versão no ar', null, await publishedVersion());
  check('as três versões continuam guardadas', 3, (await versionList()).length);
  checkDiffers('o indicador do topo voltou a um estado diferente de "No ar"', topNoArV3, await stripHash(TOP_STATUS_STRIP));
  await shot('17_despublicado.png', 'Despublicado',
    'publishedVersion virou null, as 3 versões continuam na API e o indicador do topo mudou de imagem',
    'o topo volta a "Nunca publicado"; nada no editor sugere que o histórico foi perdido');

  step('15', 'a lista volta ao selo "Rascunho"');
  await goto(projectUrl());
  check('o selo do card voltou a "Rascunho"', 'Rascunho: Nunca publicado', await cardBadge());
  await shot('18_lista_volta_rascunho.png', 'Lista: de volta a "Rascunho"',
    'despublicar refletiu na lista de conteúdos, pelo mesmo summary',
    'o card fecha o ciclo no mesmo estado visual do print 01');
} finally {
  console.log('\nLimpando o rastro…');
  await blockRoutes([]).catch(() => {});
  await purge();
  writeFileSync(`${OUT}/README.md`, readme());
}

console.log(`\n${g}PASS=${PASS}${o}  ${r}FAIL=${FAIL}${o}`);
if (FAIL > 0) console.log(`${r}Falhas:${o} ${failures.join(' | ')}`);
process.exit(FAIL > 0 ? 1 : 0);

function readme() {
  const linhas = shots.map((s) => `### ${s.title}\n\n![${s.title}](${s.file})\n\n- **O script já provou:** ${s.proved}\n- **Só o seu olho prova:** ${s.humanEye}\n`);
  return `# Rodada ${OUT.split('rodada_')[1] || '??'} — E2E do item 24 (publicação e versionamento)

> Prints **gerados pelo QA** (headless, via CDP, contra a homologação real). O dev
> humano **confere** — não opera o browser. Cada passo foi executado na tela e o
> estado resultante foi conferido por API.

**Resultado das asserções:** ${PASS} PASS / ${FAIL} FAIL${FAIL ? `\n\nFalhas: ${failures.join(' | ')}` : ''}

## Como regerar

\`\`\`bash
docs/24-publicacao-versionamento/e2e_hml.sh          # contrato por API (idempotente)
docs/24-publicacao-versionamento/e2e_shots.sh 01     # estes prints, na rodada 01
\`\`\`

Os dois criam um único conteúdo de teste (slug \`${SLUG}\`) no projeto
\`${PROJECT}\` do hml e o apagam no fim. Nada sobra em homologação; nada disso vai
para produção.

## Os dois modos de falha (item do DoD)

O item 24 nasceu com duas falhas silenciosas, corrigidas antes deste E2E. O
roteiro **provoca as duas de verdade** (cortando a rota por CDP) para que o
print prove que falhar é visualmente diferente de dar certo:

| Caminho | Sucesso | Falha |
| --- | --- | --- |
| Publicar | \`04_topo_no_ar_v1.png\`, \`07_topo_no_ar_v2.png\`, \`12_republicado_v3.png\` | \`13_publish_falhou.png\` |
| Restaurar | \`11_restaurado_no_canvas.png\` | \`14_restore_falhou_dialogo_aberto.png\`, \`15_restore_falhou_barra.png\` |

## O que o script NÃO consegue provar (é o seu olho)

O topo do shell e o rodapé do editor **não expõem árvore semântica** (achado A1
do \`test_plan.md\`): o script prova que a faixa da tela **mudou** ou **não
mudou**, nunca o texto que está escrito nela. Ler "No ar (v3)", "Alterações não
publicadas" e "Falha ao publicar. Tente novamente." nos prints é a parte que
sobra para você.

## Estados capturados

${linhas.join('\n')}`;
}
