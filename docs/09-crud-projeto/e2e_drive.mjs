// E2E — Projetos / captura VISUAL do fluxo na TELA (headless, via CDP puro).
// Dirige o fluxo de Projetos dentro do canvas Flutter da HOMOLOGAÇÃO e fotografa —
// sem dependências (WebSocket/fetch nativos do Node 22+). Chamado pelo e2e_shots.sh.
//
// Diferente do driver de Conteúdos (docs/02), este NÃO sobe stack local — dirige a
// homologação REAL (o mesmo artefato que o Coolify serve). De propósito: foi a
// ausência de um E2E que abrisse a UI e batesse no hml que deixou as três quebras
// do #43 passarem (ver memória `e2e-precisa-exercitar-de-verdade`).
//
// Cria um projeto DE TESTE (título $TITLE), fotografa criar → abrir → arquivar →
// área de arquivados → excluir definitivamente, e LIMPA o próprio rastro (purga por
// título via API, no começo E no fim). NUNCA toca o projeto `default` (seed do hml).
//
// ROBUSTEZ: em vez de coordenadas fixas (frágeis num canvas), habilita a ÁRVORE
// SEMÂNTICA do Flutter e localiza cada alvo em runtime — botões por rótulo/role,
// campos pelo <input>/<textarea> do DOM, ações do diálogo pelo botão primário (o
// mais à direita). Layout pode mudar de posição que o driver continua achando.
//
// Env: WEB_BASE, API_BASE, OUT, CDP_PORT, TITLE
import { writeFileSync } from 'node:fs';

const WEB = process.env.WEB_BASE;               // ex.: https://hml.driva.duckdns.org
const API = process.env.API_BASE;               // ex.: https://api-hml.driva.duckdns.org/v1
const OUT = process.env.OUT;
const PORT = Number(process.env.CDP_PORT || 9222);
const TITLE = process.env.TITLE || 'E2E 9g Projeto';
const SEED = 'default';                          // projeto-seed, jamais tocado

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------------- CDP (WebSocket puro) ----------------
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
const move = (x, y) => send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
async function click(x, y) {
  // O canvas Flutter exige mouseMoved ANTES do press (hit-test do pointer).
  await move(x, y); await sleep(60);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await sleep(40);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
}
async function type(text) { for (const ch of text) { await send('Input.insertText', { text: ch }); await sleep(25); } }
async function shot(name) {
  const { data } = await send('Page.captureScreenshot', { format: 'png' });
  writeFileSync(`${OUT}/${name}`, Buffer.from(data, 'base64'));
  console.log('  ✓', name);
}

// ---------------- Semântica do Flutter (localização robusta) ----------------
async function enableSemantics() {
  // Após cada navegação, a semântica volta desligada — reativa clicando o placeholder
  // ("Enable accessibility") e confirma que a árvore apareceu. Faz retry: o placeholder
  // pode não existir ainda logo após o load.
  for (let i = 0; i < 15; i++) {
    await evalJS(`(() => { const p = document.querySelector('flt-semantics-placeholder') || document.querySelector('[aria-label="Enable accessibility"]'); if (p) p.click(); return !!p; })()`);
    await sleep(700);
    const n = await evalJS(`document.querySelectorAll('flt-semantics[role]').length`);
    if (n && n > 0) return;
  }
  console.warn('  (aviso) semântica não confirmada — seguindo mesmo assim');
}
async function goto(url, waitMs = 5000) { await send('Page.navigate', { url }); await sleep(waitMs); await enableSemantics(); }

const NODES_JS = `(() => Array.from(document.querySelectorAll('flt-semantics')).map(e => { const r = e.getBoundingClientRect(); return { label: (e.getAttribute('aria-label')||'').replace(/\\s+/g,' ').trim(), role: e.getAttribute('role')||'', x: Math.round(r.x+r.width/2), y: Math.round(r.y+r.height/2), w: Math.round(r.width), h: Math.round(r.height) }; }))()`;
const nodes = async () => (await evalJS(NODES_JS)) || [];

// Nota: botões SÓ-texto (ex.: "Novo projeto", o lápis) não expõem aria-label de
// forma confiável no Flutter web — só os com tooltip (Arquivados, Tema) e os cards
// (grupo) o fazem. Por isso localizamos: header por REGIÃO, card por LABEL, o lápis
// pelos LIMITES do card, e ações de diálogo por ROLE+posição. Nada de pixel fixo.
async function pickNode(pred, rank, { timeout = 8000, label = '?' } = {}) {
  const start = Date.now();
  let last = [];
  while (Date.now() - start < timeout) {
    last = await nodes();
    const cands = last.filter(pred);
    if (cands.length) { if (rank) cands.sort((a, b) => rank(b) - rank(a)); return cands[0]; }
    await enableSemantics();          // re-garante que a árvore esteja ligada
    await sleep(300);
  }
  const seen = last.filter((n) => n.role).map((n) => `${n.role}:"${n.label.slice(0, 30)}" @${n.x},${n.y} ${n.w}x${n.h}`);
  console.error(`  [debug] nós vistos:`, JSON.stringify(seen.slice(0, 25)));
  throw new Error(`alvo não encontrado: ${label}`);
}
async function clickNode(pred, label, rank) { const n = await pickNode(pred, rank, { label }); await click(n.x, n.y); return n; }

// Botões do diálogo topo, ordenados por x. Primário = mais à direita; secundário/terciário à esquerda.
const DLG_BTNS_JS = `(()=>{const d=[...document.querySelectorAll('flt-semantics[role=alertdialog],flt-semantics[role=dialog]')].pop();if(!d)return[];return [...d.querySelectorAll('flt-semantics[role=button]')].map(b=>{const r=b.getBoundingClientRect();return{x:Math.round(r.x+r.width/2),y:Math.round(r.y+r.height/2),w:Math.round(r.width)}}).filter(b=>b.w<300).sort((a,b)=>a.x-b.x)})()`;
async function dialogButtons(timeout = 6000) {
  const start = Date.now();
  while (Date.now() - start < timeout) { const bs = (await evalJS(DLG_BTNS_JS)) || []; if (bs.length) return bs; await sleep(300); }
  throw new Error('diálogo sem botões');
}
async function clickDialogButton(which) { // 'primary' (direita), 'left' (esquerda), ou índice
  const bs = await dialogButtons();
  const b = which === 'primary' ? bs[bs.length - 1] : which === 'left' ? bs[0] : bs[which];
  if (!b) throw new Error(`botão de diálogo ausente: ${which}`);
  await click(b.x, b.y); return b;
}

// Campos de texto: pelo <input>/<textarea> real do DOM (Flutter os posiciona no lugar do widget).
const INPUTS_JS = `Array.from(document.querySelectorAll('input,textarea')).map(e=>{const r=e.getBoundingClientRect();return{x:Math.round(r.x+r.width/2),y:Math.round(r.y+r.height/2)}})`;
async function fillFirstInput(text) {
  let ins = []; for (let i = 0; i < 20 && !ins.length; i++) { ins = (await evalJS(INPUTS_JS)) || []; if (!ins.length) await sleep(300); }
  if (!ins.length) throw new Error('nenhum campo de texto no diálogo');
  await click(ins[0].x, ins[0].y); await sleep(300); await type(text);
}

// ---------------- API (limpeza determinística por título) ----------------
async function fetchProjects(status) { const r = await fetch(`${API}/projects?status=${status}`); return r.ok ? await r.json() : []; }
async function purgeTestProjects() {
  for (const p of await fetchProjects('active')) if (p.id !== SEED && p.title === TITLE) await fetch(`${API}/projects/${p.id}/archive`, { method: 'POST' });
  for (const p of await fetchProjects('archived')) if (p.id !== SEED && p.title === TITLE) await fetch(`${API}/projects/${p.id}`, { method: 'DELETE' });
}
async function activeTitles() { return (await fetchProjects('active')).map((p) => p.title); }

// ================================ Roteiro ================================
send = await connect();
await send('Page.enable'); await send('Runtime.enable');

console.log(`Limpando rastro anterior (título "${TITLE}")…`);
await purgeTestProjects();

try {
  // 01 — home de Projetos (ícone de tema visível = fix #44/#45; sem cinza)
  await goto(`${WEB}/`, 5500);
  await shot('01_home_projetos.png');

  // 02 — diálogo "Novo projeto" abre SEM RenderErrorBox cinza (regressão #46).
  // O botão é o mais à direita do header (y<60) — casamos por região, não por label.
  await clickNode((n) => n.role === 'button' && n.y < 60, 'botão Novo projeto (header dir.)', (n) => n.x);
  await sleep(1500);
  await shot('02_dialogo_novo_projeto.png');

  // 03 — título preenchido (campo Título = 1º input do diálogo)
  await fillFirstInput(TITLE); await sleep(500);
  await shot('03_titulo_preenchido.png');

  // 04 — salvar (botão primário, à direita) → card aparece na home
  await clickDialogButton('primary'); await sleep(2800); await enableSemantics();
  await shot('04_projeto_criado.png');
  if (!(await activeTitles()).includes(TITLE)) throw new Error('projeto de teste não foi criado (API não o vê em active)');

  // 05 — abrir o projeto → tela do projeto (árvore de categorias + painel).
  // Card = grupo cujo label contém o título; clica um pouco abaixo do centro.
  const card = await pickNode((n) => n.role === 'group' && n.label.includes(TITLE), null, { label: `card ${TITLE}` });
  await click(card.x, card.y + 30);
  await sleep(3200); await enableSemantics();
  await shot('05_projeto_aberto.png');

  // 06 — voltar, editar → Arquivar (à esquerda) → confirmar (primário) → some da home.
  // O lápis não tem label confiável: calculamos o topo-direito do card (nossos limites).
  await goto(`${WEB}/`, 5000);
  const card2 = await pickNode((n) => n.role === 'group' && n.label.includes(TITLE), null, { label: `card ${TITLE} (p/ lápis)` });
  await click(Math.round(card2.x + card2.w / 2 - 28), Math.round(card2.y - card2.h / 2 + 28)); // lápis (topo-direito)
  await sleep(1500);
  await clickDialogButton('left');          // "Arquivar" (à esquerda no rodapé do diálogo de edição)
  await sleep(1500);
  await clickDialogButton('primary');       // confirma "Arquivar" (rightmost do diálogo de confirmação)
  await sleep(2500); await enableSemantics();
  await shot('06_arquivado_some_da_home.png');
  if ((await activeTitles()).includes(TITLE)) throw new Error('projeto de teste ainda ativo após arquivar (a UI não arquivou)');

  // 07 — área de Arquivados (Restaurar + Excluir definitivamente).
  // O link "Arquivados" tem tooltip → label confiável.
  await clickNode((n) => n.role === 'button' && /arquivad/i.test(n.label), 'link Arquivados');
  await sleep(3000); await enableSemantics();
  await shot('07_area_arquivados.png');

  // 08 — excluir definitivamente (confirmação dupla: digitar o título)
  // lixeira = botão estreito no card arquivado (não é a seta de voltar, no topo)
  const trash = await pickNode((n) => n.role === 'button' && n.y > 100 && n.w > 0 && n.w <= 60, null, { label: 'lixeira do card arquivado' });
  await click(trash.x, trash.y); await sleep(1500);
  await clickDialogButton('primary');       // "Continuar" (1ª confirmação)
  await sleep(1500);
  await fillFirstInput(TITLE); await sleep(500);   // digitar o título p/ habilitar
  await clickDialogButton('primary');       // "Excluir definitivamente"
  await sleep(2500); await enableSemantics();
  await shot('08_excluido_limpo.png');
} finally {
  console.log('Limpando rastro final…');
  await purgeTestProjects();
}

process.exit(0);
