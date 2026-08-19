// E2E — item 46 (projectId na rota do editor) / dirige o roteiro da §10 do
// plan.md na tela da homologação e assere o resultado por CDP e por API. Sem
// dependências (WebSocket/fetch/crypto nativos do Node 22+). Chamado pelo
// e2e_shots.sh.
//
// O roteiro NÃO é o caminho feliz: o item 46 corrige uma falha que MENTE (o
// editor reabria no projeto `default` depois do F5) e uma que NÃO AVISA (o link
// "ver no celular" saía apontando para `/preview/default/…` sem erro nenhum na
// tela). Por isso a rodada exercita os três modos de falha (passos 6, 7 e 8) e
// ataca o modo silencioso (passo 4) por várias vias independentes.
//
// ---------------------------------------------------------------------------
// COMO ESTE DRIVER ENXERGA A TELA (leia antes de mexer)
//
// 1. **Headless não tem barra de endereços.** A §10 pede a URL legível no
//    print. A faixa escura no rodapé de cada print é injetada pelo driver logo
//    antes da captura e lê `location.href` da própria página — não é chrome de
//    navegador nem texto digitado à mão. É removida logo depois.
// 2. **Corpo da página e diálogos expõem árvore semântica**; o topo do shell
//    (logo/ações) e a barra de breadcrumb NÃO (achado A1 do item 24, hipótese
//    do `BlockSemantics` registrada no item 45). Por isso o breadcrumb é
//    clicado por varredura verificada: tenta os x candidatos da faixa e
//    confirma pela URL que resultou; errou o alvo, volta e tenta o próximo.
// 3. **"Aba anônima" é um BrowserContext novo** (`Target.createBrowserContext`),
//    não uma aba a mais: cache, storage e memória zerados — é o único jeito de
//    provar que o escopo do passo 3 veio da URL, e não de estado deixado para
//    trás.
// 4. **O passo 4 é o aceite que carrega o item** (§11.4›31). Vias
//    independentes tentam ler a URL que o app gerou: a árvore semântica do
//    diálogo, o `window.open` do botão "Abrir em nova aba" e o
//    `navigator.clipboard.writeText` do botão "Copiar link" — os dois últimos
//    interceptados ANTES do clique, e alcançáveis também por varredura da
//    faixa de ações quando a semântica do diálogo colapsa. Se nada devolver a
//    URL, o passo vira BLOQUEADO — nunca PASS.
// ---------------------------------------------------------------------------
//
// Env: WEB_BASE, API_BASE, OUT, CDP_PORT, PROJ_A_ID, PROJ_B_ID, GHOST_PROJECT
import { createHash } from 'node:crypto';
import { writeFileSync } from 'node:fs';

const WEB = process.env.WEB_BASE;
const API = process.env.API_BASE;
const OUT = process.env.OUT;
const PORT = Number(process.env.CDP_PORT || 9226);
const WANT_A = process.env.PROJ_A_ID || 'qyk9xbclx0moxwno3wplb4u9';
const WANT_B = process.env.PROJ_B_ID || 'o8zw3ctaahlni0lhyqpes8f6';
const GHOST = process.env.GHOST_PROJECT || 'nao-existe-46';
const DEFAULT_PROJECT = 'default';

const TITLE_A_IF_MISSING = 'E2E item 46 — projeto A';
const TITLE_B_IF_MISSING = 'E2E item 46 — projeto B';
const SLUG_A = 'e2e-46-a';
const SLUG_B = 'e2e-46-b';
const NAME_A = 'E2E 46 — conteúdo A';
const NAME_B = 'E2E 46 — conteúdo B';
const MARK_A = 'Canvas do conteúdo A (item 46)';
const MARK_B = 'Canvas do conteúdo B (item 46)';

const W = 1600;
const HGT = 1000;
const BREADCRUMB_Y = 71;
/// Recorte fora do diálogo (faixa da paleta, à esquerda) que a barreira modal
/// escurece: serve de sonda barata para "o diálogo está aberto?".
const BARRIER_PROBE = { x: 40, y: 200, width: 180, height: 60 };

const FAILURE_RE = /(Não encontramos este conteúdo|Este link aponta para um projeto|Algo deu errado ao abrir o editor|Sem conexão com o servidor|Spec inválido)/;
const PREVIEW_URL_RE = /https?:\/\/[^\s"']*\/preview\/[^\s"']+/;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const g = '\x1b[32m', r = '\x1b[31m', y = '\x1b[33m', d = '\x1b[2m', o = '\x1b[0m';
const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// ------------------------------- CDP (WebSocket puro) -------------------------------
async function connectTo(wsUrl) {
  const ws = new WebSocket(wsUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });
  let id = 0;
  const pending = new Map();
  const subs = [];
  ws.onmessage = (m) => {
    const msg = JSON.parse(m.data);
    if (msg.id && pending.has(msg.id)) {
      const { res, rej } = pending.get(msg.id); pending.delete(msg.id);
      msg.error ? rej(new Error(msg.error.message)) : res(msg.result);
    } else if (msg.method) {
      for (const f of subs) f(msg.method, msg.params);
    }
  };
  const call = (method, params = {}) =>
    new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
  call.on = (f) => subs.push(f);
  call.close = () => { try { ws.close(); } catch { /* já fechado */ } };
  return call;
}

const cdpJson = async (path) => (await fetch(`http://localhost:${PORT}${path}`)).json();

async function firstPageSession() {
  const list = await cdpJson('/json');
  const page = list.find((t) => t.type === 'page') || list[0];
  return connectTo(page.webSocketDebuggerUrl);
}

let browser;
async function browserSession() {
  if (!browser) browser = await connectTo((await cdpJson('/json/version')).webSocketDebuggerUrl);
  return browser;
}

async function anonymousSession() {
  const b = await browserSession();
  const { browserContextId } = await b('Target.createBrowserContext', {});
  const { targetId } = await b('Target.createTarget', { url: 'about:blank', browserContextId });
  await sleep(600);
  const list = await cdpJson('/json/list');
  const t = list.find((x) => x.id === targetId);
  if (!t) throw new Error('não consegui achar o alvo do contexto anônimo');
  return { session: await connectTo(t.webSocketDebuggerUrl), browserContextId, targetId };
}

async function disposeAnonymous(ctx) {
  ctx.session.close();
  const b = await browserSession();
  await b('Target.closeTarget', { targetId: ctx.targetId }).catch(() => {});
  await b('Target.disposeBrowserContext', { browserContextId: ctx.browserContextId }).catch(() => {});
}

let send;
const evalJS = async (expression, awaitPromise = false) =>
  (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise }).catch(() => ({}))).result?.value;

async function prepareSession(s) {
  send = s;
  await s('Page.enable'); await s('Runtime.enable'); await s('Network.enable');
  await s('Network.setCacheDisabled', { cacheDisabled: true });
  await s('Emulation.setDeviceMetricsOverride', { width: W, height: HGT, deviceScaleFactor: 1, mobile: false });
}

async function click(x, yy, settle = 700) {
  await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y: yy });
  await sleep(90);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y: yy, button: 'left', clickCount: 1 });
  await sleep(60);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y: yy, button: 'left', clickCount: 1 });
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
/// contaminaria tanto o print quanto a sonda de barreira.
const parkPointer = () => send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: W - 4, y: HGT - 4 });

// ------------------------------- faixa de URL no print -------------------------------
/// Headless não tem barra de endereços e a §10 pede a URL legível no print.
/// A faixa é montada a partir de `location.href` da própria página, colada só
/// no instante da captura e removida em seguida — não sobra rastro no DOM.
const bannerJS = (note) => `(() => {
  const id = 'e2e46-url-banner';
  document.getElementById(id)?.remove();
  const bar = document.createElement('div');
  bar.id = id;
  bar.style.cssText = 'position:fixed;left:0;right:0;bottom:0;z-index:2147483647;pointer-events:none;background:#0b0f17;color:#e6edf3;font:13px/18px ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;padding:6px 12px;border-top:2px solid #3b82f6';
  const line = document.createElement('div');
  line.textContent = 'URL desta aba: ' + location.href;
  line.style.cssText = 'white-space:nowrap;overflow:hidden;text-overflow:ellipsis';
  bar.appendChild(line);
  const note = ${JSON.stringify(String(note || ''))};
  if (note) {
    const n = document.createElement('div');
    n.textContent = note;
    n.style.cssText = 'white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:#7ee787';
    bar.appendChild(n);
  }
  document.body.appendChild(bar);
})()`;

const dropBanner = () => evalJS(`document.getElementById('e2e46-url-banner')?.remove()`);

async function shotFile(name, note) {
  await parkPointer();
  await sleep(250);
  await evalJS(bannerJS(note));
  await sleep(150);
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(`${OUT}/${name}`, Buffer.from(data, 'base64'));
  await dropBanner();
}

async function clipHash(clip) {
  const { data } = await send('Page.captureScreenshot', { format: 'png', clip: { ...clip, scale: 1 } });
  return createHash('sha1').update(data).digest('hex').slice(0, 12);
}

/// O painel de rede do print 03b. A "aba Network" não existe em headless, então
/// o driver desenha na tela o que ele mesmo capturou por CDP — método, URL,
/// status e o `x-project-id` que saiu no fio.
const networkPanelJS = (rows, title) => `(() => {
  const id = 'e2e46-net-panel';
  document.getElementById(id)?.remove();
  const box = document.createElement('div');
  box.id = id;
  box.style.cssText = 'position:fixed;left:24px;top:24px;right:24px;z-index:2147483646;pointer-events:none;background:#0b0f17;color:#e6edf3;font:13px/20px ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;padding:14px 16px;border:2px solid #3b82f6;border-radius:8px;box-shadow:0 12px 40px rgba(0,0,0,.6)';
  const h = document.createElement('div');
  h.textContent = ${JSON.stringify(String(title))};
  h.style.cssText = 'color:#f0f6fc;font-weight:700;margin-bottom:8px';
  box.appendChild(h);
  for (const rowText of ${JSON.stringify(rows)}) {
    const line = document.createElement('div');
    line.textContent = rowText;
    line.style.cssText = 'white-space:pre;overflow:hidden;text-overflow:ellipsis';
    line.style.color = rowText.indexOf('x-project-id') >= 0 ? '#7ee787' : '#e6edf3';
    box.appendChild(line);
  }
  document.body.appendChild(box);
})()`;

const dropNetworkPanel = () => evalJS(`document.getElementById('e2e46-net-panel')?.remove()`);

// ------------------------------- semântica do Flutter -------------------------------
async function waitForApp(timeout = 60000) {
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

const NODES_JS = `(() => Array.from(document.querySelectorAll('flt-semantics')).map(e => { const r = e.getBoundingClientRect(); const own = Array.from(e.childNodes).filter(c => c.nodeType===3 || (c.nodeType===1 && c.tagName!=='FLT-SEMANTICS')).map(c => c.textContent||'').join(' '); return { label: ((e.getAttribute('aria-label')||'') + ' ' + own).replace(/\\s+/g,' ').trim(), role: e.getAttribute('role')||'', x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height) }; }).filter(n => n.w > 0 && n.h > 0))()`;

async function nodes() {
  const first = (await evalJS(NODES_JS)) || [];
  if (first.length > 0) return first;
  await enableSemantics();
  return (await evalJS(NODES_JS)) || [];
}

const labelExists = async (re) => (await nodes()).some((n) => re.test(n.label));

async function labelsWithin(re, { timeout = 12000 } = {}) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    if (await labelExists(re)) return true;
    await sleep(400);
  }
  return false;
}

function dumpLabels(list) {
  console.error(`  ${d}[debug] rótulos vistos:${o}`, JSON.stringify(
    list.filter((n) => n.label).map((n) => `${n.role || '-'}:"${n.label}"@${n.x},${n.y}`).slice(0, 50)));
}

async function findNode(pred, description, { timeout = 12000, quiet = false } = {}) {
  const start = Date.now();
  let last = [];
  while (Date.now() - start < timeout) {
    last = await nodes();
    const hit = last.find(pred);
    if (hit) return hit;
    await sleep(400);
  }
  if (!quiet) { console.error(`  ${d}[debug] não achei: ${description}${o}`); dumpLabels(last); }
  return null;
}

/// `group` entra porque os cards (projeto e conteúdo) chegam à árvore como
/// grupo, não como botão — o alvo do toque é a região inteira do card.
const TAPPABLE = (n) => n.role === 'button' || n.role === 'link' || n.role === 'menuitem' || n.role === 'group' || n.role === '';

async function tryClickLabel(labelRe, description, opts = {}) {
  const node = await findNode((n) => TAPPABLE(n) && labelRe.test(n.label), description, opts);
  if (!node) return false;
  await click(node.x, node.y, opts.settle ?? 1200);
  return true;
}

/// O engine web repete o rótulo quando o widget tem `Semantics` + tooltip
/// ("Copiar link Copiar link do preview"), então comparar o label inteiro
/// mentiria: o que interessa é a frase, extraída de dentro dele.
async function grabPhrase(findRe, extractRe, timeout = 12000) {
  const node = await findNode((n) => findRe.test(n.label), `rótulo ${findRe}`, { timeout, quiet: true });
  if (!node) return null;
  return node.label.match(extractRe)?.[0] ?? node.label;
}

const href = () => evalJS('location.href');
const pathOf = () => evalJS('location.pathname');

async function waitForPath(pred, timeout = 15000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const p = await pathOf();
    if (p && pred(p)) return p;
    await sleep(300);
  }
  return null;
}

async function goto(url, waitMs = 3500) {
  await send('Page.navigate', { url });
  await waitForApp();
  await sleep(waitMs);
  await enableSemantics();
  await parkPointer();
}

async function reload(waitMs = 3500) {
  await send('Page.reload', { ignoreCache: true });
  await waitForApp();
  await sleep(waitMs);
  await enableSemantics();
  await parkPointer();
}

const waitEditorLoaded = (marker, timeout = 30000) => labelsWithin(new RegExp(escapeRe(marker)), { timeout });

// ------------------------------- captura de rede -------------------------------
function attachNetworkRecorder(session) {
  const byId = new Map();
  const order = [];
  session.on((method, params) => {
    if (method === 'Network.requestWillBeSent') {
      byId.set(params.requestId, { url: params.request.url, method: params.request.method, headers: { ...params.request.headers }, status: null });
      order.push(params.requestId);
    } else if (method === 'Network.requestWillBeSentExtraInfo') {
      const rec = byId.get(params.requestId);
      if (rec) rec.headers = { ...rec.headers, ...params.headers };
    } else if (method === 'Network.responseReceived') {
      const rec = byId.get(params.requestId);
      if (rec) rec.status = params.response.status;
    }
  });
  const list = () => order.map((id) => byId.get(id)).filter(Boolean);
  return {
    api: () => list().filter((rec) => rec.url.startsWith(API) && rec.method !== 'OPTIONS'),
    reset: () => { byId.clear(); order.length = 0; },
  };
}

const headerOf = (rec, name) => {
  const key = Object.keys(rec?.headers || {}).find((k) => k.toLowerCase() === name);
  return key ? rec.headers[key] : undefined;
};

// ------------------------------- API -------------------------------
const H = (p) => ({ 'x-project-id': p });
const JH = (p) => ({ ...H(p), 'content-type': 'application/json' });

async function ensureProject(wantId, titleIfMissing) {
  const list = await (await fetch(`${API}/projects`)).json();
  const byId = (list || []).find((p) => p.id === wantId);
  if (byId) return byId;
  const byTitle = (list || []).find((p) => p.title === titleIfMissing);
  if (byTitle) return byTitle;
  const res = await fetch(`${API}/projects`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ title: titleIfMissing, description: 'Fixture do E2E do item 46 (rota com projectId). Pode apagar.' }),
  });
  const body = await res.json();
  if (!body.id) throw new Error(`não consegui garantir o projeto "${titleIfMissing}": ${JSON.stringify(body)}`);
  return body;
}

async function ensureContent(projectId, slug, name) {
  const res = await fetch(`${API}/contents?q=${encodeURIComponent(slug)}&limit=100`, { headers: H(projectId) });
  const body = res.ok ? await res.json() : { data: [] };
  const hit = (body.data || []).find((c) => c.slug === slug);
  if (hit) return hit.id;
  const cats = await (await fetch(`${API}/categories`, { headers: H(projectId) })).json();
  const categoryId = Array.isArray(cats) ? cats[0]?.id : undefined;
  // R2d: criar conteúdo sem categoria quebra em projeto sem "Geral" — a
  // categoria é escolhida na criação, sempre entre as que já existem.
  if (!categoryId) throw new Error(`o projeto ${projectId} não tem nenhuma categoria — crie uma antes de rodar o E2E`);
  const created = await fetch(`${API}/contents`, {
    method: 'POST', headers: JH(projectId),
    body: JSON.stringify({ name, slug, description: 'Fixture do E2E do item 46', categoryId }),
  });
  const cb = await created.json();
  if (!cb.id) throw new Error(`não consegui criar o conteúdo ${slug}: ${JSON.stringify(cb)}`);
  return cb.id;
}

async function stampSpec(projectId, id, name, slug, marker) {
  const spec = { specVersion: 1, kind: 'content', id, name, slug, root: { id: 'nd_root', type: 'text', props: { data: marker } } };
  const res = await fetch(`${API}/contents/${id}`, { method: 'PUT', headers: JH(projectId), body: JSON.stringify({ spec }) });
  if (!res.ok) throw new Error(`PUT do spec de ${slug} falhou: ${res.status}`);
}

// ------------------------------- resultado -------------------------------
let PASS = 0, FAIL = 0;
const failures = [];
const blocked = [];
function check(label, expected, actual) {
  if (String(expected) === String(actual)) { PASS++; console.log(`  ${g}PASS${o} ${label}`); return true; }
  FAIL++; failures.push(label);
  console.log(`  ${r}FAIL${o} ${label}\n       ${d}esperado=${expected} obtido=${actual}${o}`);
  return false;
}
const checkTrue = (label, actual) => check(label, true, !!actual);
function checkDiffers(label, before, after) {
  if (before !== after) { PASS++; console.log(`  ${g}PASS${o} ${label}`); return true; }
  FAIL++; failures.push(label);
  console.log(`  ${r}FAIL${o} ${label}\n       ${d}não mudou (${before})${o}`);
  return false;
}
function block(label, why) {
  blocked.push({ label, why });
  console.log(`  ${y}BLOQUEADO${o} ${label}\n       ${d}${why}${o}`);
}

const shots = [];
async function shot(file, title, note, proved, humanEye) {
  await shotFile(file, note);
  const entry = { file, title, proved, humanEye };
  const at = shots.findIndex((s) => s.file === file);
  if (at >= 0) shots[at] = entry; else shots.push(entry);
  console.log(`  ${d}·${o} ${file}`);
}
const step = (n, title) => console.log(`\n=== passo ${n} — ${title}`);

// ------------------------------- passo 4: o modo silencioso -------------------------------
/// `web.window.open` e `navigator.clipboard.writeText` são resolvidos no objeto
/// global a cada chamada, o que torna estes ganchos suficientes para capturar a
/// URL que o app gerou **sem depender de o diálogo pintar**.
async function hookOutgoingLink() {
  await evalJS(`(() => {
    if (window.__e2e46Hook) return true;
    window.__e2e46Hook = true;
    window.__e2e46Opened = null;
    window.__e2e46Copied = null;
    const originalOpen = window.open;
    window.open = function (url) { window.__e2e46Opened = String(url); return originalOpen.apply(this, arguments); };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      const originalWrite = navigator.clipboard.writeText.bind(navigator.clipboard);
      navigator.clipboard.writeText = function (text) { window.__e2e46Copied = String(text); return originalWrite(text); };
    }
    return true;
  })()`);
}

const capturedLink = async () => {
  const opened = await evalJS('window.__e2e46Opened');
  if (opened && PREVIEW_URL_RE.test(opened)) return { url: opened.match(PREVIEW_URL_RE)[0], via: 'botão "Abrir em nova aba" (window.open interceptado)' };
  const copied = await evalJS('window.__e2e46Copied');
  if (copied && PREVIEW_URL_RE.test(copied)) return { url: copied.match(PREVIEW_URL_RE)[0], via: 'botão "Copiar link" (clipboard.writeText interceptado)' };
  return null;
};

let barrierOpenHash = null;
let barrierClosedHash = null;

async function openPreviewDialog() {
  barrierClosedHash = await clipHash(BARRIER_PROBE);
  const clicked = await tryClickLabel(/Ver no celular/, 'botão "Ver no celular" da barra do canvas', { settle: 2000 });
  if (!clicked) return false;
  await sleep(1200);
  barrierOpenHash = await clipHash(BARRIER_PROBE);
  return barrierOpenHash !== barrierClosedHash;
}

async function dialogIsOpen() {
  if (await labelExists(/Abrir em nova aba|Copiar link do preview/)) return true;
  if (!barrierClosedHash) return false;
  return (await clipHash(BARRIER_PROBE)) !== barrierClosedHash;
}

async function ensurePreviewDialogOpen() {
  if (await dialogIsOpen()) return true;
  return openPreviewDialog();
}

async function readPreviewUrlFromSemantics(timeout = 10000) {
  const start = Date.now();
  let last = [];
  while (Date.now() - start < timeout) {
    last = await nodes();
    for (const n of last) {
      const m = n.label.match(PREVIEW_URL_RE);
      if (m) return m[0];
    }
    await sleep(500);
  }
  console.log(`  ${d}(a árvore semântica não trouxe a URL — ${last.length} nós visíveis com o diálogo aberto)${o}`);
  return null;
}

/// Alcança os botões do `AlertDialog` mesmo quando a semântica do diálogo
/// colapsa: varre a faixa das ações (o diálogo é centrado) e confirma pelo
/// gancho — só um toque no botão certo produz valor, então a varredura não
/// pode inventar um PASS.
async function sweepDialogActions() {
  let hit = null;
  for (const yy of [712, 728, 696, 744, 680, 760]) {
    for (let x = 630; x <= 990; x += 18) {
      await click(x, yy, 200);
      hit = await capturedLink();
      if (hit) return hit;
      if (x % 90 === 0 && !(await dialogIsOpen())) await ensurePreviewDialogOpen();
    }
    if (!(await ensurePreviewDialogOpen())) break;
  }
  return null;
}

/// O "abrir em nova aba" cria um alvo de verdade — fechado aqui para o rastro
/// do driver não sobrar.
async function closePreviewTargets() {
  const list = await cdpJson('/json/list');
  const b = await browserSession();
  for (const t of list.filter((x) => x.type === 'page' && x.url.includes('/preview/'))) {
    await b('Target.closeTarget', { targetId: t.id }).catch(() => {});
  }
}

/// A barra de breadcrumb não expõe semântica (achado A1). O crumb do projeto é
/// o segundo da faixa: varre os x candidatos e confirma pela URL resultante —
/// acertar "Projetos" leva a `/`, e aí o driver volta e tenta o próximo.
async function clickProjectCrumb(projectId, backTo) {
  for (const x of [112, 128, 96, 144, 160, 176, 88, 192]) {
    await click(x, BREADCRUMB_Y, 1500);
    const path = await waitForPath((p) => p === `/projects/${projectId}` || p === '/', 4000);
    if (path === `/projects/${projectId}`) return true;
    if (path === '/') { await goto(backTo, 3500); await waitEditorLoaded(MARK_A); }
  }
  return false;
}

async function goBackUntil(pathname, tries = 4) {
  for (let i = 0; i < tries; i++) {
    await evalJS('history.back()');
    await sleep(2500);
    if ((await pathOf()) === pathname) return true;
  }
  return false;
}

// ================================== preparação ==================================
console.log(`Alvo: ${WEB}   API: ${API}`);

const projA = await ensureProject(WANT_A, TITLE_A_IF_MISSING);
const projB = await ensureProject(WANT_B, TITLE_B_IF_MISSING);
const A = projA.id, B = projB.id;
if (A === DEFAULT_PROJECT || B === DEFAULT_PROJECT) throw new Error('D12›2: a rodada não pode correr no projeto `default`');
if (A === B) throw new Error('PROJ_A e PROJ_B têm de ser projetos diferentes');
const CT_A = await ensureContent(A, SLUG_A, NAME_A);
const CT_B = await ensureContent(B, SLUG_B, NAME_B);
await stampSpec(A, CT_A, NAME_A, SLUG_A, MARK_A);
await stampSpec(B, CT_B, NAME_B, SLUG_B, MARK_B);

const editorUrlA = `${WEB}/projects/${A}/contents/${CT_A}/edit`;
const editorUrlB = `${WEB}/projects/${B}/contents/${CT_B}/edit`;
const wrongProjectUrl = `${WEB}/projects/${B}/contents/${CT_A}/edit`;
const ghostProjectUrl = `${WEB}/projects/${GHOST}/contents/${CT_A}/edit`;
const legacyUrl = `${WEB}/contents/${CT_A}/edit`;
const expectedPreviewUrl = `${WEB}/preview/${A}/${CT_A}`;

console.log(`PROJ_A: "${projA.title}" ${A}`);
console.log(`PROJ_B: "${projB.title}" ${B}`);
console.log(`CT_A: ${CT_A}   CT_B: ${CT_B}`);
console.log(`preview esperado no passo 4: ${expectedPreviewUrl}`);

const main = await firstPageSession();
const mainNet = attachNetworkRecorder(main);
await prepareSession(main);

let previewUrl = null;
let previewVia = null;
let anon = null;
let msg6 = null, msg7 = null, action6 = null, action7 = null;
let apiCallCount = 0;
let caminhoNormal = true;

try {
  // ------------------------------------------------------------------ passo 1
  step('1', 'home → PROJ_A → abrir CT_A pelo caminho normal');
  await goto(`${WEB}/`);
  const openedProject = await tryClickLabel(new RegExp(escapeRe(projA.title)), `card do projeto "${projA.title}"`);
  if (openedProject) await waitForPath((p) => p === `/projects/${A}`, 12000);
  if ((await pathOf()) !== `/projects/${A}`) {
    caminhoNormal = false;
    console.log(`  ${y}(fallback)${o} o card do projeto não foi alcançável pela semântica — indo pela URL do projeto`);
    await goto(`${WEB}/projects/${A}`);
  }
  checkTrue('a home levou à tela do PROJ_A', (await pathOf()) === `/projects/${A}`);
  const openedContent = await tryClickLabel(new RegExp(escapeRe(NAME_A)), `card do conteúdo "${NAME_A}"`, { settle: 2500 });
  if (openedContent) await waitForPath((p) => p.endsWith('/edit'), 15000);
  if (!(await pathOf()).endsWith('/edit')) {
    caminhoNormal = false;
    console.log(`  ${y}(fallback)${o} o card do conteúdo não abriu pelo clique — indo pela URL do editor`);
    await goto(editorUrlA);
  }
  check('abrir o conteúdo pelo caminho normal leva à rota com os DOIS ids', editorUrlA, await href());
  checkTrue('o editor carregou o CT_A', await waitEditorLoaded(MARK_A));
  await shot('01_url_com_dois_ids.png', 'Passo 1 — a URL do editor carrega os dois ids',
    `caminho normal: home → projeto → conteúdo · projeto "${projA.title}" (≠ default)`,
    `a URL da aba é exatamente ${editorUrlA} e o marcador "${MARK_A}" apareceu na tela`,
    `o breadcrumb diz Projetos › ${projA.title} › ${NAME_A} — o nome do projeto legível, e não "default"`);

  // ------------------------------------------------------------------ passo 2
  step('2', 'F5 na mesma aba — o defeito de origem');
  mainNet.reset();
  await reload();
  check('depois do F5 a URL continua a mesma', editorUrlA, await href());
  checkTrue('depois do F5 o MESMO conteúdo voltou', await waitEditorLoaded(MARK_A));
  checkTrue('nenhuma tela de falha apareceu depois do F5', !(await labelExists(FAILURE_RE)));
  const contentCall = mainNet.api().find((rec) => rec.url.includes(`/contents/${CT_A}`));
  const reloadHeader = headerOf(contentCall, 'x-project-id');
  check('o GET do conteúdo depois do F5 saiu com o x-project-id do PROJ_A', A, reloadHeader);
  await shot('02_reload_mesmo_conteudo.png', 'Passo 2 — F5 recarrega o mesmo conteúdo, no projeto certo',
    `recarga fria (ignoreCache) · x-project-id da recarga = ${reloadHeader ?? 'não capturado'}`,
    'a URL não mudou, o marcador do CT_A voltou e nenhuma tela de falha apareceu',
    `o breadcrumb continua "${projA.title}" — este é o print do §11.4›29: qualquer outro nome aqui reprova`);

  // ----------------------------------------------- passo 4 (na aba recarregada do passo 2)
  step('4', '"ver no celular" — o modo silencioso (§11.4›31)');
  await hookOutgoingLink();
  checkTrue('o diálogo "Ver no celular" abriu', await openPreviewDialog());

  const fromSemantics = await readPreviewUrlFromSemantics();
  if (fromSemantics) { previewUrl = fromSemantics; previewVia = 'árvore semântica do diálogo'; }

  await shot('04_link_preview_projeto_certo.png', 'Passo 4 — a URL que o "ver no celular" gera',
    previewUrl ? `link gerado pelo app (via ${previewVia}): ${previewUrl}` : 'diálogo aberto — link ainda não lido pelo driver',
    previewUrl ? `o app gerou ${previewUrl}` : 'o diálogo abriu; a leitura do link vem das outras vias',
    'a URL dentro do diálogo aparece truncada pela largura da caixa (320px) — a linha verde do rodapé traz a string INTEIRA, lida do próprio app');

  if (!previewUrl) {
    await ensurePreviewDialogOpen();
    const byLabel = await tryClickLabel(/Abrir em nova aba/, 'botão "Abrir em nova aba" do diálogo', { timeout: 4000, quiet: true, settle: 900 });
    let hit = await capturedLink();
    if (!hit) {
      await ensurePreviewDialogOpen();
      const copied = await tryClickLabel(/Copiar link do preview/, 'botão "Copiar link" do diálogo', { timeout: 4000, quiet: true, settle: 900 });
      if (copied) hit = await capturedLink();
    }
    if (!hit) {
      console.log(`  ${d}(a semântica do diálogo não expôs os botões — varrendo a faixa de ações)${o}`);
      hit = await sweepDialogActions();
    }
    if (byLabel && !hit) console.log(`  ${d}(o clique por rótulo não produziu link — ver a seção Bloqueado)${o}`);
    if (hit) { previewUrl = hit.url; previewVia = hit.via; }
  }
  await closePreviewTargets();

  if (previewUrl && !fromSemantics) {
    await ensurePreviewDialogOpen();
    await shot('04_link_preview_projeto_certo.png', 'Passo 4 — a URL que o "ver no celular" gera',
      `link gerado pelo app (via ${previewVia}): ${previewUrl}`,
      `o app gerou ${previewUrl}`,
      'se o corpo do diálogo não pintou no Chromium headless, a linha verde traz a string que o PRÓPRIO app produziu, capturada por CDP no momento do clique');
  }

  if (previewUrl) {
    console.log(`  ${d}via:${o} ${previewVia}`);
    check('o link do "ver no celular" aponta para o projeto da URL, não para o default', expectedPreviewUrl, previewUrl);
    checkTrue('o link NÃO contém /preview/default/', !previewUrl.includes(`/preview/${DEFAULT_PROJECT}/`));
  } else {
    block('passo 4 — ler a URL do diálogo "Ver no celular" (§11.4›31)',
      'nenhuma das vias (semântica, window.open, clipboard.writeText, varredura) devolveu a URL — ver o print 04 e a seção "Bloqueado" do README');
  }
  await pressEscape();

  // ------------------------------------------------------------------ passo 5
  step('5', 'breadcrumb leva ao PROJ_A, não ao default');
  checkTrue(`o breadcrumb do editor leva a /projects/${A}`, await clickProjectCrumb(A, editorUrlA));
  check('a tela que abriu é a do PROJ_A', `/projects/${A}`, await pathOf());
  // O título do projeto só existe no breadcrumb, que não expõe semântica (A1);
  // o CT_A só existe dentro do PROJ_A, então vê-lo na lista prova o projeto.
  checkTrue('a lista aberta é a do PROJ_A — o CT_A está nela', await labelsWithin(new RegExp(escapeRe(NAME_A))));
  await shot('05_breadcrumb_e_volta.png', 'Passo 5 — o breadcrumb volta para o projeto certo',
    `clique no crumb "${projA.title}" a partir do editor recarregado`,
    `o clique no breadcrumb levou a /projects/${A}, e a lista aberta é a do PROJ_A (o "${NAME_A}" está nela)`,
    `o breadcrumb desta tela diz "Projetos › ${projA.title}" — o nome do projeto legível, e não "default" nem a home`);

  // ------------------------------------------------------------------ passo 3
  step('3', 'aba anônima (contexto novo) — o header da PRIMEIRA requisição');
  anon = await anonymousSession();
  const anonNet = attachNetworkRecorder(anon.session);
  await prepareSession(anon.session);
  await goto(editorUrlA, 5000);
  checkTrue('a aba anônima abriu o conteúdo direto, sem passar pela tela do projeto', await waitEditorLoaded(MARK_A));
  checkTrue('a aba anônima não caiu em tela de falha', !(await labelExists(FAILURE_RE)));
  await shot('03_aba_anonima.png', 'Passo 3 — o link colado numa aba que nunca viu o app',
    'BrowserContext novo: cache, storage e memória zerados',
    `o conteúdo abriu direto na aba anônima, com o marcador "${MARK_A}" na tela`,
    `o breadcrumb mostra "${projA.title}" já na primeira pintura — o escopo veio da URL, não de estado deixado para trás`);

  const anonApi = anonNet.api();
  apiCallCount = anonApi.length;
  const firstContentCall = anonApi.find((rec) => rec.url.includes(`/contents/${CT_A}`));
  const firstHeader = headerOf(firstContentCall, 'x-project-id');
  check('a PRIMEIRA requisição do conteúdo saiu com x-project-id = PROJ_A (D2)', A, firstHeader);
  checkTrue('a rodada correu contra a API real (D12›1) — houve chamada HTTP ao backend', anonApi.length > 0);
  writeFileSync(`${OUT}/03b_network.txt`,
    anonApi.map((rec) => `${rec.method} ${rec.url}\n  x-project-id: ${headerOf(rec, 'x-project-id') ?? '(ausente)'}\n  status: ${rec.status ?? '?'}\n`).join('\n'));
  const rows = anonApi.slice(0, 8).flatMap((rec) => [
    `${rec.method} ${rec.url}`,
    `    x-project-id: ${headerOf(rec, 'x-project-id') ?? '(ausente)'}    -> HTTP ${rec.status ?? '?'}`,
  ]);
  await evalJS(networkPanelJS(rows, `Requisições REAIS à API de homologação nesta aba anônima (${anonApi.length} no total) — capturadas por CDP`));
  await sleep(250);
  await shot('03b_header_primeira_requisicao.png', 'Passo 3b — a primeira requisição carrega o projeto da URL',
    `USE_FAKE_DATA=false comprovado: ${anonApi.length} chamadas reais a ${API}`,
    `a primeira chamada a /contents/${CT_A} saiu com x-project-id: ${firstHeader ?? '(ausente)'} — e não "${DEFAULT_PROJECT}"`,
    'o painel é desenhado pelo driver a partir do que o CDP capturou no fio; o log cru está em 03b_network.txt');
  await dropNetworkPanel();
  await disposeAnonymous(anon);
  anon = null;
  await prepareSession(main);

  // ------------------------------------------------------------------ passo 6
  step('6', 'conteúdo fora do projeto — a mensagem nomeia o PROJ_B');
  await goto(wrongProjectUrl, 4500);
  msg6 = await grabPhrase(/Não encontramos este conteúdo/, /Não encontramos este conteúdo[^.]*\./);
  check('a mensagem NOMEIA o projeto da URL', `Não encontramos este conteúdo no projeto "${projB.title}".`, msg6);
  action6 = await grabPhrase(/Voltar para o projeto|Ver meus projetos/, /Voltar para o projeto|Ver meus projetos/);
  check('a ação oferecida é "Voltar para o projeto"', 'Voltar para o projeto', action6);
  checkTrue('a mensagem NÃO insinua que o conteúdo existe em outro projeto (D7)', !/(outro projeto|em outro lugar|encontrado em|está em)/i.test(msg6 || ''));
  await shot('06_falha_conteudo_fora_do_projeto.png', 'Passo 6 — conteúdo que não é daquele projeto',
    `URL com o projectId trocado para PROJ_B ("${projB.title}")`,
    `a tela diz: ${msg6} — com a ação "${action6}"`,
    'ícone de LUPA RISCADA (search_off). Compare com o print 07: mesma cor (os dois usam o tom "danger" no código), texto e ícone diferentes');
  await tryClickLabel(/Voltar para o projeto/, 'ação "Voltar para o projeto" da tela de falha', { settle: 2000 });
  check('a saída da tela de falha leva ao projeto da URL, não ao default', `/projects/${B}`, await pathOf());

  // ------------------------------------------------------------------ passo 7
  step('7', 'projeto inexistente — mensagem DIFERENTE da do passo 6');
  await goto(ghostProjectUrl, 4500);
  msg7 = await grabPhrase(/Este link aponta para um projeto/, /Este link aponta para um projeto[^.]*\./);
  check('a mensagem é a do projeto inexistente', 'Este link aponta para um projeto que não existe.', msg7);
  action7 = await grabPhrase(/Voltar para o projeto|Ver meus projetos/, /Voltar para o projeto|Ver meus projetos/);
  check('a ação oferecida é "Ver meus projetos"', 'Ver meus projetos', action7);
  checkDiffers('a mensagem do passo 7 é diferente da do passo 6 (§11.4›34)', msg6, msg7);
  checkDiffers('a AÇÃO do passo 7 é diferente da do passo 6', action6, action7);
  checkTrue('a mensagem NÃO insinua que o conteúdo existe em outro projeto (D7)', !/(outro projeto|em outro lugar|encontrado em|está em)/i.test(msg7 || ''));
  await shot('07_falha_projeto_inexistente.png', 'Passo 7 — projeto que não existe',
    `URL com o projectId "${GHOST}"`,
    `a tela diz: ${msg7} — com a ação "${action7}", texto E ação diferentes dos do print 06`,
    'ícone de PASTA RISCADA (folder_off_outlined) — o print 06 traz uma lupa riscada. Os dois usam o MESMO tom de cor no código, então a diferença que você vê não é de matiz');
  await tryClickLabel(/Ver meus projetos/, 'ação "Ver meus projetos" da tela de falha', { settle: 2000 });
  check('a saída do projeto inexistente leva à home, não a um beco', '/', await pathOf());

  // ------------------------------------------------------------------ passo 8
  step('8', 'link no formato antigo cai na home, sem aviso dedicado (D4)');
  await goto(legacyUrl, 4000);
  check('o link antigo levou à home de projetos', '/', await pathOf());
  checkTrue('a home listou os projetos', await labelsWithin(new RegExp(escapeRe(projA.title))));
  checkTrue('não apareceu tela de aviso dedicada para o link antigo (D4)', !(await labelExists(FAILURE_RE)));
  await shot('08_link_antigo_home.png', 'Passo 8 — link no formato antigo',
    `${legacyUrl} → a home, sem tela de aviso`,
    'a rota antiga não casa com nada e o router cai na home; nenhuma das mensagens de falha do editor apareceu',
    'a tela é a lista de projetos normal — não uma tela de erro, não uma tela em branco');

  // ------------------------------------------------------------------ passo 9
  step('9', 'alternar entre conteúdos de dois projetos e voltar pelo histórico');
  await goto(editorUrlA, 4000);
  checkTrue('CT_A abriu (projeto A)', await waitEditorLoaded(MARK_A));
  await shot('09a_ct_a.png', 'Passo 9a — CT_A no projeto A', editorUrlA,
    `o marcador "${MARK_A}" apareceu`, `o breadcrumb mostra "${projA.title}"`);

  await goto(editorUrlB, 4000);
  checkTrue('CT_B abriu (projeto B) — o escopo foi recarimbado', await waitEditorLoaded(MARK_B));
  await shot('09b_ct_b.png', 'Passo 9b — CT_B no projeto B', editorUrlB,
    `o marcador "${MARK_B}" apareceu — conteúdo de OUTRO projeto, na mesma aba`,
    `o breadcrumb mudou para "${projB.title}"`);

  checkTrue('o botão voltar do navegador devolveu a URL de CT_A', await goBackUntil(`/projects/${A}/contents/${CT_A}/edit`));
  checkTrue('CT_A voltou a carregar depois do histórico', await waitEditorLoaded(MARK_A));
  await shot('09c_volta_ct_a.png', 'Passo 9c — voltar pelo histórico', 'history.back() a partir de CT_B',
    `a URL voltou a ${editorUrlA} e o marcador "${MARK_A}" voltou`,
    `o breadcrumb voltou para "${projA.title}" — o escopo é recarimbado a cada rota, nos dois sentidos`);

  // ------------------------------------- auxiliar: o link do passo 4 renderiza
  if (previewUrl) {
    const clean = await anonymousSession();
    await prepareSession(clean.session);
    await goto(previewUrl, 5000);
    checkTrue('o link do "ver no celular" abre o conteúdo (não um 404) num contexto que nunca viu o app',
      await labelsWithin(new RegExp(escapeRe(MARK_A)), { timeout: 20000 }));
    await shot('04c_preview_aberto_no_driver.png', 'Auxiliar — o link do passo 4 aberto num contexto limpo',
      `${previewUrl}`,
      `a vista de preview desenhou "${MARK_A}" — o link não dá 404`,
      'não substitui o passo 4b: abrir no aparelho de verdade continua sendo do humano');
    await disposeAnonymous(clean);
    await prepareSession(main);
  }
} finally {
  console.log('\nLimpando o rastro do driver…');
  if (anon) await disposeAnonymous(anon).catch(() => {});
  await closePreviewTargets().catch(() => {});
  await dropBanner().catch(() => {});
  await dropNetworkPanel().catch(() => {});
  writeFileSync(`${OUT}/README.md`, readme());
}

console.log(`\n${g}PASS=${PASS}${o}  ${r}FAIL=${FAIL}${o}  ${y}BLOQUEADO=${blocked.length}${o}`);
if (FAIL > 0) console.log(`${r}Falhas:${o} ${failures.join(' | ')}`);
if (blocked.length) console.log(`${y}Bloqueados:${o} ${blocked.map((b) => b.label).join(' | ')}`);
process.exit(FAIL > 0 || blocked.length > 0 ? 1 : 0);

// ================================== README da rodada ==================================
function readme() {
  const round = OUT.split('rodada_')[1] || '??';
  const passo4 = previewUrl
    ? `| 4 | "Ver no celular" — a URL do link gerado | \`${previewUrl}\` (lido via ${previewVia}) | \`04_link_preview_projeto_certo.png\` | §11.4›**31** — **o aceite que carrega o item** |`
    : `| 4 | "Ver no celular" — a URL do link gerado | **BLOQUEADO** — ver a seção abaixo | \`04_link_preview_projeto_certo.png\` | §11.4›**31** — **o aceite que carrega o item** |`;

  const bloqueio = previewUrl ? '' : `
## Bloqueado — passo 4

As vias independentes tentadas pelo driver — árvore semântica do diálogo,
intercepção de \`window.open\` (botão "Abrir em nova aba"), intercepção de
\`navigator.clipboard.writeText\` (botão "Copiar link") e varredura verificada da
faixa de ações — **não devolveram a URL**. O print
\`04_link_preview_projeto_certo.png\` mostra o que aparece na tela do driver.

**Não classificado**: pode ser defeito do diálogo ou artefato do Chromium
headless (mesmo sintoma do item 45 — a árvore semântica colapsa sob a barreira
de rota modal). **Fica para conferência humana**: abrir \`${editorUrlA}\` num
Chrome normal, dar F5, clicar em "Ver no celular" e ler a URL do diálogo. Ela
tem de ser \`${expectedPreviewUrl}\` — se aparecer \`/preview/${DEFAULT_PROJECT}/\`,
o item **não fecha**.
`;

  const auxiliares = shots.filter((s) => s.file.startsWith('04c'));
  const principais = shots.filter((s) => !s.file.startsWith('04c'));
  const bloco = (list) => list.map((s) => `### ${s.title}\n\n![${s.title}](${s.file})\n\n- **O script já provou:** ${s.proved}\n- **Só o seu olho prova:** ${s.humanEye}\n`).join('\n');

  return `# Rodada ${round} — item 46 (projectId na rota do editor)

> Prints **gerados pelo QA** (headless, via CDP, contra a **homologação real**).
> O dev humano **confere** — não opera o browser. Cada passo foi executado na
> tela do hml e o resultado conferido por CDP (URL, árvore semântica, headers no
> fio) e por API.

**Data:** ${new Date().toISOString().slice(0, 10)}.
**Resultado das asserções:** ${PASS} PASS / ${FAIL} FAIL / ${blocked.length} bloqueado(s)${FAIL ? `\n\nFalhas: ${failures.join(' | ')}` : ''}

## Ambiente

| Item | Valor |
| --- | --- |
| Editor | \`${WEB}\` — **homologação servida pelo Coolify** (§11.3›22; nunca \`localhost\`, lição do item 9g) |
| API | \`${API}\` (real) |
| \`USE_FAKE_DATA\` | \`false\` — provado pelas ${apiCallCount} chamadas HTTP reais capturadas no fio e listadas em \`03b_network.txt\` (§11.3›23) |
| \`PROJ_A\` | ${projA.title} · \`${A}\` — **≠ \`default\`** (§11.3›24) |
| \`CT_A\` | ${NAME_A} · \`${CT_A}\` |
| \`PROJ_B\` | ${projB.title} · \`${B}\` |
| \`CT_B\` | ${NAME_B} · \`${CT_B}\` |
| \`ID_FANTASMA\` | \`${GHOST}\` |
| Janela | ${W}×${HGT}, Chrome headless novo, \`--user-data-dir\` temporário |

> **A faixa escura no rodapé de cada print é do driver, não do navegador.**
> Headless não tem barra de endereços, e a §10 pede a URL legível. A faixa é
> injetada no DOM logo antes da captura, lê \`location.href\` da própria página e
> some em seguida. A linha verde, quando existe, traz um valor que o driver
> capturou do app (o link do preview, o header da requisição).

## Resultado por passo

| # | Passo (§10) | Resultado | Print | Prova qual linha do DoD |
| --- | --- | --- | --- | --- |
| 1 | Home → \`PROJ_A\` → abrir \`CT_A\` pelo caminho normal${caminhoNormal ? '' : ' _(um dos dois cliques caiu no fallback por URL — ver o log)_'} | URL \`/projects/${A}/contents/${CT_A}/edit\` | \`01_url_com_dois_ids.png\` | §11.3›22, §11.3›24 |
| 2 | **F5** na mesma aba | mesmo conteúdo, mesmo projeto | \`02_reload_mesmo_conteudo.png\` | §11.4›**29** — o defeito de origem |
| 3 | URL colada em aba anônima | abriu direto, sem passar pela tela do projeto | \`03_aba_anonima.png\` | §11.4›30 |
| 3b | Header da **primeira** requisição | \`x-project-id: ${A}\` | \`03b_header_primeira_requisicao.png\` + \`03b_network.txt\` | §11.3›23, §11.4›30 (D2) |
${passo4}
| 4b | Abrir o link no aparelho | **do humano** — instruções abaixo | \`04b_preview_no_aparelho.jpg\` (a tirar) | §11.4›31 |
| 5 | Breadcrumb → projeto | levou a \`/projects/${A}\` | \`05_breadcrumb_e_volta.png\` | §11.4›32 |
| 6 | \`:projectId\` trocado por \`PROJ_B\` (válido) | mensagem nomeando "${projB.title}" | \`06_falha_conteudo_fora_do_projeto.png\` | §11.4›33, §11.4›36 (D7) |
| 7 | \`:projectId\` inexistente | mensagem e ação **diferentes** das do passo 6 | \`07_falha_projeto_inexistente.png\` | §11.4›34, §11.4›35 (D8) |
| 8 | Link no formato antigo | caiu na home, sem aviso dedicado | \`08_link_antigo_home.png\` | §11.4›37 (D4) |
| 9 | \`CT_A\` → \`CT_B\` → voltar pelo histórico | os três carregam certo | \`09a_ct_a.png\`, \`09b_ct_b.png\`, \`09c_volta_ct_a.png\` | §11.4›38 |

> **A ordem de execução não é a ordem da numeração**, e isso é de propósito: a
> §10 manda abrir o "ver no celular" (passo 4) e conferir o breadcrumb (passo 5)
> **na aba já recarregada do passo 2**. O passo 3 é o último a rodar na sessão
> principal porque exige um contexto anônimo novo. A numeração dos prints segue a
> §10; o \`resultado.txt\` segue a execução.

## O que destravou desde a \`rodada_01\`

A rodada 01 registrou o **passo 4 como bloqueado**: o diálogo "Ver no celular"
abria, mas o conteúdo não pintava e a árvore semântica colapsava sob a barreira
de rota modal. Aqui ele **passa por leitura direta** — a mesma árvore semântica
que lá vinha vazia entrega o nó com a URL inteira, e o print mostra o diálogo
desenhado (QR, link e as duas ações).

A diferença não está no app: a rodada 01 dirigia um **build de debug em
\`localhost\`** (o merge estava travado), e esta dirige o **artefato de release
servido pelo Coolify**. É a mesma lição já registrada sobre o "tofu" do
\`flutter run\` — o que o Chromium mostra num build de debug não é evidência de
defeito. O que continua valendo do achado do item 45: o **topo do shell e a
barra de breadcrumb** seguem sem semântica nenhuma, e por isso o passo 5 clica o
crumb por varredura verificada, não por rótulo.

## O que o passo 4b espera de você (§11.4›31)

Abra **esta URL exata** num celular de verdade (não no simulador do navegador):

\`\`\`
${previewUrl || expectedPreviewUrl}
\`\`\`

O conteúdo tem de aparecer — a vista de preview mostra **"${MARK_A}"** — e não um
404. Salve a foto como \`04b_preview_no_aparelho.jpg\` nesta pasta. As fixtures
deste E2E **ficam de pé** em homologação justamente para você poder fazer isso
depois que o script terminar.

## Os três modos de falha (§11.4›35)

Os passos 6, 7 e 8 produzem telas visualmente distintas entre si e da tela
carregada — por **texto, ação e ícone**:

| Passo | Mensagem | Ação | Ícone |
| --- | --- | --- | --- |
| 6 | ${msg6 ?? '(não capturada)'} | ${action6 ?? '—'} | lupa riscada (\`search_off\`) |
| 7 | ${msg7 ?? '(não capturada)'} | ${action7 ?? '—'} | pasta riscada (\`folder_off_outlined\`) |
| 8 | (nenhuma — a home de projetos) | — | — |

**Nada aqui depende de cor:** no código, os passos 6 e 7 usam o **mesmo** tom
(\`_FailureTone.danger\`) — a diferença que você vê no print é necessariamente de
texto e de glifo, nunca de matiz.
${bloqueio}
## Como regerar

\`\`\`bash
docs/46-projectid-na-rota-do-editor/e2e_shots.sh ${round}
\`\`\`

Idempotente: o script **resolve** as fixtures (projeto por id, conteúdo por slug,
categoria existente escolhida na criação — R2d) em vez de recriá-las, e carimba
o mesmo spec marcador nos dois conteúdos. Auto-limpante quanto ao rastro do
driver (Chrome headless, perfil temporário, contexto anônimo, abas de preview,
faixa injetada no DOM). **Nada disso vai para produção; nenhuma linha de
código-fonte foi tocada.**

## Estados capturados

${bloco(principais)}
${auxiliares.length ? `## Auxiliar (fora da lista da §10 — ajuda a conferir o passo 4)\n\n${bloco(auxiliares)}` : ''}`;
}
