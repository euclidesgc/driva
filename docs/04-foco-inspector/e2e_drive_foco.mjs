// E2E — Foco no Inspector / prova de INTERAÇÃO (headless, via CDP puro).
// Reproduz o bug relatado: digitar num campo de propriedade fazia o editor
// perder o foco a cada tecla (só o 1º dígito colava). Aqui digitamos "10"
// caractere a caractere no campo numérico "Espaço entre filhos" (spacing) do
// root column — que o Inspector já mostra ao abrir o editor, sem drag — e
// fotografamos: no código corrigido o valor acumula "10" e o foco permanece.
//
// Coordenadas acopladas ao layout 1366x900 (device-scale-factor=1). Se a UI
// mudar de posição, ajuste os cliques. É o preço de dirigir um canvas Flutter
// (CanvasKit, sem DOM por widget); em troca, zero clique manual do dev.
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
  await sleep(40);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
}
// Digita caractere a caractere: cada Input.insertText dispara um onChanged no
// Flutter — é exatamente isso que recriava o campo (e derrubava o foco) no bug.
async function type(text) { for (const ch of text) { await send('Input.insertText', { text: ch }); await sleep(120); } }
async function shot(name) {
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(`${OUT}/${name}`, Buffer.from(data, 'base64'));
  console.log('  ✓', name);
}
async function goto(url, waitMs = 8000) { await send('Page.navigate', { url }); await sleep(waitMs); }

async function listIds() { const r = await fetch(`${API}/contents`, { headers: H }); return (await r.json()).map((c) => c.id); }
async function clean() { for (const id of await listIds()) await fetch(`${API}/contents/${id}`, { method: 'DELETE', headers: H }); }
async function seed(name, slug) {
  const r = await fetch(`${API}/contents`, { method: 'POST', headers: { ...H, 'content-type': 'application/json' }, body: JSON.stringify({ name, slug }) });
  return (await r.json()).id;
}

send = await connect();
await send('Page.enable'); await send('Runtime.enable');

// Semeia um conteúdo e abre o editor nele — o Inspector já mostra o root column,
// cujo campo "Espaço entre filhos" (spacing, numérico) é o alvo.
await clean();
const id = await seed('Foco Inspector', 'foco-inspector');
await goto(`${WEB}/contents/${id}/edit`, 9000);
await shot('01_editor_inspector.png');   // estado inicial (descoberta de coords)

// Coordenadas do campo "Espaço entre filhos" no Inspector (painel direito).
// Ajustadas pela rodada de descoberta (ver 01_editor_inspector.png).
const FX = Number(process.env.FIELD_X || 1230);
const FY = Number(process.env.FIELD_Y || 250);

await click(FX, FY); await sleep(400);
await shot('02_campo_focado.png');       // campo com foco (cursor)

await type('10'); await sleep(500);
await shot('03_valor_10.png');           // PROVA: "10" acumulou; foco não caiu

// Continua digitando para reforçar (vira "105") — se o foco caísse, não colaria.
await type('5'); await sleep(500);
await shot('04_valor_105.png');

process.exit(0);
