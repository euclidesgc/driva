// E2E — Conteúdos / captura dos estados de INTERAÇÃO (headless, via CDP puro).
// Dirige cliques/digitação/drag dentro do canvas Flutter e fotografa — sem
// dependências (WebSocket/fetch nativos do Node 22+). Chamado pelo e2e_shots.sh.
//
// Coordenadas são acopladas ao layout em 1366x900 (device-scale-factor=1) — se a
// UI mudar de posição, ajuste os cliques aqui. É o preço de dirigir um canvas
// (sem DOM por widget); em troca, zero clique manual do dev.
//
// Env: WEB_BASE, API_BASE, PROJECT, OUT, CDP_PORT
import { writeFileSync } from 'node:fs';

const WEB = process.env.WEB_BASE, API = process.env.API_BASE;
const PROJECT = process.env.PROJECT, OUT = process.env.OUT;
const PORT = Number(process.env.CDP_PORT || 9222);
const H = { 'x-project-id': PROJECT };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

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
const move = (x, y, b) => send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y, ...(b ? { button: b } : {}) });
async function click(x, y) {
  await move(x, y);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await sleep(30);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
}
async function drag(x1, y1, x2, y2, steps = 25) {
  await move(x1, y1);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: x1, y: y1, button: 'left', clickCount: 1 });
  for (let i = 1; i <= steps; i++) { await move(x1 + ((x2 - x1) * i) / steps, y1 + ((y2 - y1) * i) / steps, 'left'); await sleep(20); }
  await sleep(80);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: x2, y: y2, button: 'left', clickCount: 1 });
}
async function type(text) { for (const ch of text) { await send('Input.insertText', { text: ch }); await sleep(25); } }
async function shot(name) {
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(`${OUT}/${name}`, Buffer.from(data, 'base64'));
  console.log('  ✓', name);
}
async function goto(url, waitMs = 7000) { await send('Page.navigate', { url }); await sleep(waitMs); }

async function listIds() { const r = await fetch(`${API}/contents`, { headers: H }); return (await r.json()).map((c) => c.id); }
async function clean() { for (const id of await listIds()) await fetch(`${API}/contents/${id}`, { method: 'DELETE', headers: H }); }
async function seed(name, slug) {
  await fetch(`${API}/contents`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: JSON.stringify({ name, slug }) });
}
async function homeId() { const r = await fetch(`${API}/contents`, { headers: H }); return (await r.json()).find((c) => c.slug === 'home')?.id; }

send = await connect();
await send('Page.enable'); await send('Runtime.enable');

// A — slug derivado ao vivo enquanto digita o Nome (lista vazia → botão central)
await clean();
await goto(`${WEB}/contents`, 8000);
await click(683, 466); await sleep(1200);      // "Novo conteúdo" (empty state)
await click(683, 286); await sleep(200);        // campo Nome
await type('Home — vitrine da loja'); await sleep(600);
await shot('05_slug_ao_vivo.png');
await click(742, 526); await sleep(500);         // Cancelar

// B — colisão de slug: submeter "home" repetido resolve p/ home-2 e abre o editor
await clean(); await seed('Home', 'home');
await goto(`${WEB}/contents`, 7000);
await click(1267, 27); await sleep(1200);        // "Novo conteúdo" (topo-direita)
await click(683, 286); await sleep(200);
await type('Home'); await sleep(400);
await click(832, 526); await sleep(2600);         // Criar → 409 → auto home-2 → editor
await shot('06_colisao_home2.png');

// C — drag-drop da paleta → preview renderiza; Salvar → "Salvo"
const id = await homeId();
await goto(`${WEB}/contents/${id}/edit`, 7000);
await drag(49, 539, 525, 450, 25); await sleep(1200);   // tile "Text" → canvas
await shot('07_drag_preview.png');
await click(1190, 27); await sleep(1800);               // botão "Salvar"
await shot('08_salvo.png');

process.exit(0);
