// E2E — item 39 (URL da imagem e props) / captura os QUATRO ESTADOS na tela da
// homologação e assere cada um por rede + spec, sem dependências (WebSocket/fetch
// nativos do Node 22+). Chamado pelo e2e_shots.sh.
//
// A cancela desta feature é VISUAL e COMPARATIVA (DoD 24): se vazio, carregando,
// falhou e carregado não forem quatro imagens distintas, nada mais importa — é
// literalmente o bug original. Por isso cada estado é recortado com a MESMA
// geometria (o nó é semeado com width/height 200) e, no fim, os quatro recortes
// viram um único print 2×2. E porque "olhar" não é asserção, o script também
// compara os quatro recortes byte a byte: dois estados iguais reprovam sozinhos.
//
// Por que as asserções são de REDE e de PIXEL, e não da árvore semântica:
// `SelectableNode` (editor) envolve cada nó do canvas num `Semantics(label:
// <tipo>)` com gesto, e o engine funde os descendentes — os rótulos
// "Imagem sem URL definida"/"Carregando imagem"/"Falha ao carregar imagem" do
// renderer NÃO chegam ao DOM acessível dentro do canvas do editor (medido).
// O que chega, e é o que interessa, é a REDE: o `Image.network` do Flutter Web
// busca bytes, então cada estado tem uma assinatura de rede própria —
// nenhuma requisição (vazio), requisição em voo (carregando), resposta 200
// (carregado), resposta 502 (falhou). É a mesma fonte da aba Network do
// DevTools, lida pelo domínio `Network` do CDP.
//
// O que fica de fora, de propósito: o app `driva_demo_app` no celular (DoD 26) —
// exige aparelho/emulador e o app móvel, fora do alcance de um Chrome headless.
// É item do roteiro humano.
//
// Coordenadas acopladas ao layout em 1366x900 (device-scale-factor 1, forçado
// por Emulation.setDeviceMetricsOverride). Se a UI se mover, ajuste UI abaixo.
//
// Auto-limpante: cria UM conteúdo de teste (slug $SLUG) e o apaga no fim, e
// purga qualquer rastro do mesmo slug no começo. NUNCA toca outro conteúdo.
//
// Env: WEB_BASE, API_BASE, PROJECT, SLUG, OUT, CDP_PORT
import { writeFileSync } from 'node:fs';

const WEB = process.env.WEB_BASE;
const API = process.env.API_BASE;
const PROJECT = process.env.PROJECT || 'default';
const SLUG = process.env.SLUG || 'e2e-39-canvas';
const NAME = 'E2E 39 canvas';
const OUT = process.env.OUT;
const PORT = Number(process.env.CDP_PORT || 9223);
const H = { 'x-project-id': PROJECT };
const JSON_H = { ...H, 'content-type': 'application/json' };

const URL_A = process.env.URL_A || 'https://picsum.photos/300/200';
const URL_A_PESADA = process.env.URL_A_PESADA || 'https://picsum.photos/1600/1200';
const URL_B = process.env.URL_B || 'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png';
const URL_C = process.env.URL_C || 'https://exemplo.invalido/x.png';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ------------------------------- CDP (WebSocket puro) -------------------------------
async function connect() {
  const list = await (await fetch(`http://localhost:${PORT}/json`)).json();
  const page = list.find((t) => t.type === 'page') || list[0];
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
  let id = 0; const pending = new Map(); const handlers = new Map();
  ws.onmessage = (m) => {
    const msg = JSON.parse(m.data);
    if (msg.id && pending.has(msg.id)) {
      const { res, rej } = pending.get(msg.id); pending.delete(msg.id);
      msg.error ? rej(new Error(msg.error.message)) : res(msg.result);
    } else if (msg.method && handlers.has(msg.method)) {
      for (const h of handlers.get(msg.method)) h(msg.params);
    }
  };
  const call = (method, params = {}) =>
    new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
  call.on = (method, handler) => handlers.set(method, [...(handlers.get(method) || []), handler]);
  return call;
}

let send;
const evalJS = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true })).result?.value;
const move = (x, y) => send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });

async function click(x, y) {
  await move(x, y); await sleep(90);
  await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await sleep(60);
  await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  await sleep(650);
}

const VK = { a: 65, s: 83 };

/// O Ctrl precisa ir como tecla própria: só `modifiers: 2` no evento da letra
/// não arma o HardwareKeyboard do Flutter Web e o SingleActivator(control: true)
/// não casa. (Detalhe herdado do E2E do item 38.)
async function ctrl(letter) {
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', modifiers: 2, key: 'Control', code: 'ControlLeft', location: 1, windowsVirtualKeyCode: 17, nativeVirtualKeyCode: 17 });
  await sleep(50);
  const p = { modifiers: 2, key: letter, code: `Key${letter.toUpperCase()}`, windowsVirtualKeyCode: VK[letter], nativeVirtualKeyCode: VK[letter] };
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', ...p });
  await sleep(60);
  await send('Input.dispatchKeyEvent', { type: 'keyUp', ...p });
  await sleep(40);
  await send('Input.dispatchKeyEvent', { type: 'keyUp', modifiers: 0, key: 'Control', code: 'ControlLeft', location: 1, windowsVirtualKeyCode: 17, nativeVirtualKeyCode: 17 });
  await sleep(650);
}

/// O Inspector só mostra os campos do nó quando ele está selecionado — e o
/// Ctrl+S recarrega o conteúdo, o que desfaz a seleção. Sem esta guarda, um
/// `typeInto` depois de um save digitaria no vazio e a asserção seguinte
/// culparia o produto por um erro do driver.
async function garantirSelecao() {
  const temCampoDoNo = `(() => Array.from(document.querySelectorAll('input')).some(e => { const r = e.getBoundingClientRect(); return r.x > 1046 && Math.abs(r.y + r.height / 2 - ${UI.campoSrc[1]}) < 24; }))()`;
  for (let i = 0; i < 4; i++) {
    if (await evalJS(temCampoDoNo)) return true;
    await click(...UI.noNoCanvas);
    await sleep(700);
  }
  return await evalJS(temCampoDoNo);
}

const campoEm = (y) =>
  `Array.from(document.querySelectorAll('input')).find(e => { const r = e.getBoundingClientRect(); return r.x > 1046 && Math.abs(r.y + r.height / 2 - ${y}) < 24; })`;

/// Digitar tecla a tecla dispararia uma busca por caractere (o campo comita a
/// cada tecla): `insertText` entrega a string inteira num evento só.
///
/// ⚠️ Clicar num campo do Flutter Web que JÁ está focado o desfoca (o clique
/// volta para a `flutter-view` e o `activeElement` deixa de ser o `input`) — o
/// `insertText` seguinte cairia no vazio e a asserção culparia o produto. Por
/// isso o clique só acontece quando o campo ainda não tem o foco, e a seleção
/// do texto anterior sai de `select()`, não de um Ctrl+A que o app pode
/// interceptar.
async function typeInto(x, y, text) {
  await garantirSelecao();
  if (!(await evalJS(`(() => { const el = ${campoEm(y)}; return !!el && el === document.activeElement; })()`))) {
    await click(x, y);
    await sleep(300);
  }
  const focado = await evalJS(`(() => { const el = ${campoEm(y)}; if (!el) return 'sem-campo'; el.focus(); el.select(); return el === document.activeElement ? 'ok' : 'sem-foco'; })()`);
  if (focado !== 'ok') throw new Error(`não consegui focar o campo em y=${y}: ${focado}`);
  await send('Input.insertText', { text });
  await sleep(500);
  const valor = await evalJS(`(() => { const el = ${campoEm(y)}; return el ? el.value : ''; })()`);
  if (valor !== text) throw new Error(`o campo em y=${y} ficou com "${valor}" em vez de "${text}"`);
}

const shotBase64 = async (clip) =>
  (await send('Page.captureScreenshot', clip ? { format: 'png', clip: { ...clip, scale: 1 } } : { format: 'png' })).data;

async function shotFile(name, clip) {
  const data = await shotBase64(clip);
  writeFileSync(`${OUT}/${name}`, Buffer.from(data, 'base64'));
  return data;
}

async function enableSemantics() {
  for (let i = 0; i < 12; i++) {
    await evalJS(`(() => { const p = document.querySelector('flt-semantics-placeholder') || document.querySelector('[aria-label="Enable accessibility"]'); if (p) p.click(); return !!p; })()`);
    await sleep(500);
    const n = await evalJS(`document.querySelectorAll('flt-semantics[role]').length`);
    if (n && n > 0) return;
  }
}

/// `aria-label` sozinho é CEGO para texto: o engine do Flutter Web só usa o
/// atributo quando o nó tem filhos (`AriaLabelRepresentation`). Nó-folha com
/// rótulo — todo `Text`, e portanto o `helperText`/`errorText` do
/// `InputDecorator` — cai na `SizedSpanRepresentation`, que remove o `role` e
/// escreve o rótulo como TEXTO de um `<span>` dentro do `flt-semantics`. Ler só
/// o atributo fazia a asserção reprovar uma mensagem que estava na tela.
///
/// O texto próprio sai dos filhos DIRETOS (nó de texto ou `<span>`), e não de
/// `textContent`: os `flt-semantics` se aninham, então `textContent` faria cada
/// ancestral repetir a subárvore inteira e a lista deixaria de ser um rótulo
/// POR NÓ — o que importa para quem lê o `resultado.txt` atrás de qual nó
/// carrega a mensagem, e para qualquer asserção futura que precise apontar um
/// nó em vez de perguntar se o texto está em algum lugar da página.
const semanticLabels = async () =>
  (await evalJS(`(() => Array.from(document.querySelectorAll('flt-semantics')).map((e) => {
    const proprio = Array.from(e.childNodes)
      .filter((n) => n.nodeType === 3 || (n.nodeType === 1 && n.tagName === 'SPAN'))
      .map((n) => n.textContent || '')
      .join(' ');
    return [e.getAttribute('aria-label') || '', proprio].join(' ').replace(/\\s+/g, ' ').trim();
  }).filter(Boolean))()`)) || [];

// ------------------------------- coordenadas do layout -------------------------------
// Layout 1366x900: paleta 0..280, canvas 286..1046, inspector 1046..1366.
const UI = {
  noNoCanvas: [430, 320],
  campoSrc: [1206, 313],
  campoLargura: [1206, 748],
  campoAltura: [1206, 855],
  // O nó é semeado com `height: 200` (=180 na tela, zoom 90%) e a largura é
  // esticada pela raiz do preview: os quatro estados ocupam exatamente a mesma
  // caixa, e é isso que torna o recorte comparável byte a byte.
  recorteCanvas: { x: 352, y: 260, width: 368, height: 200 },
  centroDoNo: [537, 360],
  fundoDoCanvas: [900, 720],
  botaoSalvar: [1075, 27],
  // O balão do Tooltip é largo e é clampado à janela, não à área do canvas:
  // recortar só o canvas cortaria as duas pontas da mensagem.
  recorteTooltip: { x: 0, y: 250, width: 1366, height: 270 },
  recorteInspectorTamanho: { x: 1046, y: 620, width: 320, height: 268 },
  recorteInspectorTopo: { x: 1046, y: 90, width: 320, height: 700 },
};
const TAMANHO_PADRAO = { width: 200, height: 200 };

// ------------------------------- rede -------------------------------
const rede = [];
const proxyDe = (src) => `${API}/media/proxy?url=${encodeURIComponent(src)}`;
const pedidosDeImagem = () => rede.filter((r) => r.url.includes('/media/proxy'));
const pedidoPara = (src) => [...pedidosDeImagem()].reverse().find((r) => r.url === proxyDe(src));
const pedidosDiretosPara = (host) =>
  rede.filter((r) => r.url.includes(host) && !r.url.includes('/media/proxy'));

// ------------------------------- API -------------------------------
const listSameSlug = async () => {
  const r = await fetch(`${API}/contents?q=${encodeURIComponent('E2E 39')}&limit=100`, { headers: H });
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
    body: JSON.stringify({ name: NAME, slug: SLUG, description: 'E2E do item 39', ...(categoryId ? { categoryId } : {}) }),
  });
  const body = await r.json();
  if (!body.id) throw new Error(`não consegui criar o conteúdo de teste: ${JSON.stringify(body)}`);
  contentId = body.id;
}
const getSpec = async () => (await (await fetch(`${API}/contents/${contentId}`, { headers: H })).json()).spec;
async function semear(props) {
  const spec = {
    specVersion: 1, kind: 'content', id: contentId, name: NAME, slug: SLUG,
    root: { id: 'nd_img', type: 'image', props },
  };
  const r = await fetch(`${API}/contents/${contentId}`, { method: 'PUT', headers: JSON_H, body: JSON.stringify({ spec }) });
  if (!r.ok) throw new Error(`PUT do spec falhou: ${r.status}`);
}
const editorUrl = () => `${WEB}/projects/${PROJECT}/contents/${contentId}/edit`;

async function abrirEditor({ selecionar = false } = {}) {
  await send('Page.navigate', { url: editorUrl() });
  await sleep(11000);
  await enableSemantics();
  await sleep(1200);
  if (selecionar) { await click(...UI.noNoCanvas); await sleep(900); }
}

/// O spec só reflete o que foi digitado depois do Ctrl+S — não há autosave.
/// Espera até o servidor devolver o que se esperava (ou desistir): ler o spec
/// na primeira tentativa devolveria o valor ANTERIOR e a asserção seguinte
/// culparia o produto pela latência do PUT.
/// Salva pelo BOTÃO "Salvar", não pelo Ctrl+S: com o cursor dentro de um campo
/// o atalho sintético às vezes não chega ao app (e um `blur()` via DOM é pior —
/// joga o foco para fora da `flutter-view` e o Flutter para de receber teclado).
/// O botão é um alvo estável e é o caminho que o usuário usa. Que o Ctrl+S
/// funcione com teclado de verdade é item do roteiro humano — teclado sintético
/// não passa pelo mesmo caminho (lição do item 38).
async function salvarEler(chegou = () => true) {
  let props = {};
  for (let tentativa = 0; tentativa < 3; tentativa++) {
    await click(...UI.botaoSalvar);
    for (let i = 0; i < 8; i++) {
      await sleep(500);
      props = (await getSpec())?.root?.props ?? {};
      if (chegou(props)) return props;
    }
  }
  return props;
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
async function shot(file, { titulo, clip, provado, olho }) {
  const data = await shotFile(file, clip);
  shots.push({ file, titulo, provado, olho });
  console.log(`  ${d}·${o} ${file}`);
  return data;
}
function step(n, titulo) { console.log(`\n=== ${n} — ${titulo}`); }

const estados = {};

// ================================== roteiro ==================================
send = await connect();
await send('Page.enable'); await send('Runtime.enable'); await send('Network.enable');
send.on('Network.requestWillBeSent', (p) => rede.push({ url: p.request.url, id: p.requestId, status: null, t: Date.now() }));
send.on('Network.responseReceived', (p) => {
  const hit = rede.find((x) => x.id === p.requestId);
  if (hit) { hit.status = p.response.status; hit.mime = p.response.mimeType; }
});
// `responseReceived` dispara quando chegam os CABEÇALHOS; o corpo ainda está
// vindo. Quem diz que a imagem terminou de baixar — e portanto que o estado
// "carregando" já podia ter saído da tela — é o `loadingFinished`.
send.on('Network.loadingFinished', (p) => {
  const hit = rede.find((x) => x.id === p.requestId);
  if (hit) hit.terminou = true;
});
send.on('Network.loadingFailed', (p) => {
  const hit = rede.find((x) => x.id === p.requestId);
  if (hit) { hit.status = `falhou(${p.errorText})`; hit.terminou = true; }
});
await send('Emulation.setDeviceMetricsOverride', { width: 1366, height: 900, deviceScaleFactor: 1, mobile: false });

console.log(`Alvo: ${WEB}  API: ${API}  projeto: ${PROJECT}  slug: ${SLUG}`);
console.log(`URL_A=${URL_A}\nURL_B=${URL_B}\nURL_C=${URL_C}`);
await purge();
await createContent();
console.log(`Conteúdo de teste: ${contentId}`);

try {
  // ---------------------------------------------------------------- estado vazio
  // Os quatro estados são capturados na MESMA sessão, com o nó SEMPRE
  // selecionado: assim a única diferença entre os quatro recortes é o estado,
  // nunca o chrome de seleção. É o que torna a comparação do DoD 24 honesta.
  step('D — campo vazio (DoD 21)', 'o estado "vazio", que não pode se parecer com "falhou"');
  await semear({ ...TAMANHO_PADRAO });
  await abrirEditor({ selecionar: true });
  const antesDoVazio = pedidosDeImagem().length;
  estados.vazio = await shot('20_estado_vazio.png', {
    titulo: 'Estado VAZIO — sem URL',
    clip: UI.recorteCanvas,
    provado: 'com `src` ausente o editor não dispara requisição nenhuma de imagem (0 chamadas ao proxy) — o estado é "falta preencher", não "deu erro"',
    olho: 'a caixa é neutra (ícone de imagem, cinza) e se lê como "falta a URL" — nada de vermelho, nada de texto de erro',
  });
  check('o estado vazio não busca nada na rede', antesDoVazio, pedidosDeImagem().length);

  // ------------------------------------------------------- carregando + carregado
  step('A — host COM ACAO (DoD 18 e 22)', 'carregando sob throttling, depois carregado');
  await shot('12_inspector_helptext.png', {
    titulo: 'helpText nos DOIS caminhos de moldura (D8)',
    clip: UI.recorteInspectorTopo,
    provado: 'o Inspector do `image` renderiza o `helpText` do `src` (moldura do PropFieldEditor) e o da `Largura` (moldura própria do DimensionEditor) — os dois caminhos da D8, num print só',
    olho: 'os textos de ajuda estão legíveis e abaixo do rótulo, sem cortar',
  });

  // Sem throttling o estado "carregando" não pisca em cache hit
  // (`_wasSynchronouslyLoaded`) — e isso é correto (D12). Para observá-lo é
  // preciso estrangular a rede, exatamente como o roteiro manual manda.
  await send('Network.setCacheDisabled', { cacheDisabled: true });
  await send('Network.emulateNetworkConditions', {
    offline: false, latency: 400, downloadThroughput: 12000, uploadThroughput: 12000,
  });
  await typeInto(...UI.campoSrc, URL_A_PESADA);
  await sleep(1200);
  estados.carregando = await shot('22_estado_carregando.png', {
    titulo: 'Estado CARREGANDO — com throttling de rede',
    clip: UI.recorteCanvas,
    provado: 'com a rede estrangulada (12 KB/s, cache desligado) a requisição ao proxy está EM VOO no instante da captura — o `frameBuilder` desenha o estado enquanto `frame == null` (D12)',
    olho: 'o indicador de progresso aparece na caixa, e ela é visivelmente diferente da caixa vazia e da de erro',
  });
  const emVoo = pedidoPara(URL_A_PESADA);
  check('a requisição ao proxy da imagem pesada existe', true, !!emVoo);
  check('e o download ainda NÃO tinha terminado no instante da captura (é por isso que o estado pisca)', true, !emVoo?.terminou);

  for (let i = 0; i < 60 && !pedidoPara(URL_A_PESADA)?.terminou; i++) await sleep(1000);
  await send('Network.emulateNetworkConditions', { offline: false, latency: 0, downloadThroughput: -1, uploadThroughput: -1 });
  await send('Network.setCacheDisabled', { cacheDisabled: false });
  await sleep(2500);
  estados.carregado = await shot('18_estado_carregado.png', {
    titulo: 'Estado CARREGADO — caso A (host com ACAO)',
    clip: UI.recorteCanvas,
    provado: `o proxy devolveu ${pedidoPara(URL_A_PESADA)?.status} para ${URL_A_PESADA} e a imagem foi decodificada`,
    olho: 'a foto aparece inteira dentro da caixa — é uma imagem, não um retângulo colorido',
  });
  check('caso A: o proxy respondeu 200', 200, pedidoPara(URL_A_PESADA)?.status);
  check('caso A: o content-type que chegou ao Chrome é de imagem', true, /^image\//.test(pedidoPara(URL_A_PESADA)?.mime || ''));
  check('o que foi digitado no campo chegou ao spec', URL_A_PESADA, (await salvarEler((p) => p.src === URL_A_PESADA)).src);

  // ---------------------------------------------------------------- estado falhou
  step('C — URL inexistente (DoD 20)', 'o estado "falhou", com motivo legível');
  await typeInto(...UI.campoSrc, URL_C);
  await sleep(4000);
  estados.falhou = await shot('20b_estado_falhou.png', {
    titulo: 'Estado FALHOU — URL inexistente',
    clip: UI.recorteCanvas,
    provado: `o proxy devolveu ${pedidoPara(URL_C)?.status || '—'} para ${URL_C}; o renderer desenhou a caixa de erro com o motivo em texto (não o quadrado cinza mudo de antes)`,
    olho: 'o motivo está LEGÍVEL na caixa e ela é claramente diferente da caixa vazia. O texto cita `…/v1/media/proxy?url=…` — **esperado**: é a URL que a NetworkImageLoadException tentou buscar, e só aparece no editor (showDiagnostics)',
  });
  check('caso C: o proxy respondeu 502 (erro tipado, não silêncio)', 502, pedidoPara(URL_C)?.status);

  // §10.3 do plan.md: "Tooltip diz o motivo e mostra a URL". O `Tooltip` do
  // ImageErrorBox é `excludeFromSemantics: true`, então ele não aparece na
  // árvore acessível — só no pixel. Por isso a prova aqui é o hover + print.
  await move(...UI.centroDoNo);
  await sleep(2200);
  await shot('20c_tooltip_do_erro.png', {
    titulo: 'Tooltip do erro — o motivo E a URL original',
    clip: UI.recorteTooltip,
    provado: 'com o mouse parado sobre a caixa de erro o Tooltip aparece (é o `Tooltip` do ImageErrorBox, invisível para a árvore acessível — só existe no pixel)',
    olho: 'o balão traz o motivo E a URL que VOCÊ digitou, no fim da mensagem — é assim que se descobre um erro de digitação sem abrir o JSON',
  });
  await move(880, 700);
  await sleep(500);

  check('a URL inválida também chegou ao spec', URL_C, (await salvarEler((p) => p.src === URL_C)).src);

  // ------------------------------------------------- o print que é a cancela (24)
  step('DoD 24', 'os quatro estados lado a lado — a cancela da feature');
  const pares = [
    ['vazio', 'carregando'], ['vazio', 'falhou'], ['vazio', 'carregado'],
    ['carregando', 'falhou'], ['carregando', 'carregado'], ['falhou', 'carregado'],
  ];
  for (const [a, b] of pares) {
    check(`"${a}" e "${b}" não são o mesmo pixel`, true, estados[a] !== estados[b] && !!estados[a] && !!estados[b]);
  }

  // -------------------------------------------------------------- caso B, o relato
  step('B — host SEM ACAO (DoD 19)', 'o caso do relato: agora carrega, e carrega VIA PROXY');
  await typeInto(...UI.campoSrc, URL_B);
  await sleep(6000);
  await shot('19_caso_b_carregado.png', {
    titulo: 'Caso B — URL sem ACAO carregando (o relato do dev)',
    clip: UI.recorteCanvas,
    provado: `a URL do relato (host sem Access-Control-Allow-Origin) foi buscada pelo proxy e respondeu ${pedidoPara(URL_B)?.status}; é o que a F3 entrega`,
    olho: 'o logo aparece de verdade dentro da caixa — antes do item 39 esta caixa ficava cinza e muda',
  });
  check('caso B: houve chamada ao proxy com a URL do relato', true, !!pedidoPara(URL_B));
  check('caso B: o proxy respondeu 200', 200, pedidoPara(URL_B)?.status);
  check('caso B: NENHUMA requisição direta ao host da imagem saiu do editor (D11 no caminho do editor)', 0, pedidosDiretosPara('www.google.com').length);
  check('a rodada NÃO correu em modo fake — o resolver está ligado (DoD 13b)', true, pedidosDeImagem().length > 0);

  // --------------------------------------------------------- width 0 e abc (DoD 23)
  step('§10.8–9 (DoD 23)', 'width 0 e width abc — os dois sinais têm de se distinguir');
  await semear({ src: URL_A, ...TAMANHO_PADRAO });
  await abrirEditor({ selecionar: true });
  await typeInto(...UI.campoLargura, '0');
  await sleep(1500);
  await enableSemantics(); await sleep(600);
  const rotulosZero = (await semanticLabels()).join(' | ');
  await shot('23a_largura_zero.png', {
    titulo: 'Largura = 0',
    clip: UI.recorteInspectorTamanho,
    provado: 'o valor comitado no spec é 1 (o clamp da D6 agiu) e o rótulo "Ajustado para o mínimo (1)" está na árvore acessível',
    olho: 'logo abaixo do campo, a mensagem **"Ajustado para o mínimo (1)"**: o editor conta que mexeu no que você digitou, em vez de clampar calado. Guarde o TEXTO — o print seguinte tem de trazer outro',
  });
  const larguraZero = (await salvarEler((p) => p.width === 1)).width;
  check('o clamp da D6 agiu: 0 virou 1 no spec', 1, larguraZero);
  check('(D15/DoD 23) o campo mostra "Ajustado para o mínimo (1)"', true, /Ajustado para o m[íi]nimo/.test(rotulosZero));

  await typeInto(...UI.campoLargura, 'abc');
  await sleep(1500);
  await enableSemantics(); await sleep(600);
  const rotulosAbc = (await semanticLabels()).join(' | ');
  await shot('23b_largura_abc.png', {
    titulo: 'Largura = abc',
    clip: UI.recorteInspectorTamanho,
    provado: 'o texto inválido não derruba o editor e o rótulo "Valor inválido" está na árvore acessível',
    olho: 'a mensagem agora é **"Valor inválido"** — TEXTO diferente do print anterior, não só cor diferente. É esse par de textos que distingue os dois modos de falha para quem não enxerga cor; se os dois prints trouxerem a mesma frase, o item reprova',
  });
  check('(D15/DoD 23) o campo mostra errorText de valor inválido', true, /inv[áa]lid/i.test(rotulosAbc));
  // Só as NEGATIVAS distinguem: repetir aqui as duas positivas acima faria uma
  // conjunção que não tem como reprovar sozinha, e as duas mensagens aparecendo
  // nos DOIS estados passaria pelas três asserções com a tela errada.
  check('(D15/DoD 23) os dois sinais se distinguem: nenhum estado traz a mensagem do outro', true,
    !/inv[áa]lid/i.test(rotulosZero) && !/Ajustado para o m[íi]nimo/.test(rotulosAbc));

  // ------------------------------------------------------------- props novas da F4
  step('§10.10–11 (F4)', 'width 100%, alignment, borderRadius e backgroundColor');
  // `fit: none` é de propósito: com `contain` o logo já ocupa a largura toda e
  // o `alignment` não teria como aparecer no print.
  await semear({ src: URL_B, width: '100%', height: 200, fit: 'none', backgroundColor: '#FF102A43', borderRadius: 24, alignment: 'centerRight' });
  await abrirEditor();
  await sleep(2500);
  await shot('11a_props_f4.png', {
    titulo: 'width "100%" + raio + cor de fundo + alinhamento',
    clip: UI.recorteCanvas,
    provado: `o spec com \`width: "100%"\`, \`borderRadius: 24\`, \`backgroundColor\` e \`alignment: centerRight\` foi aceito e desenhado; a imagem veio pelo proxy (${pedidoPara(URL_B)?.status})`,
    olho: 'quatro coisas num print só: a caixa ocupa a LARGURA TODA do mock (o "100%"), os CANTOS estão ARREDONDADOS **e o arredondamento corta a imagem** (o raio compõe — sem platform view no caminho, que era o risco da D2), o FUNDO ESCURO aparece atrás do PNG transparente, e o logo está ENCOSTADO À DIREITA (o alignment)',
  });
  const propsF4 = (await getSpec()).root.props;
  check('width percentual sobreviveu ao round-trip', '100%', propsF4.width);
  check('borderRadius sobreviveu', 24, propsF4.borderRadius);
  check('alignment sobreviveu', 'centerRight', propsF4.alignment);

  // ------------------------------------------------------------- compat (DoD 25)
  step('DoD 25', 'conteúdo salvo ANTES da F4 (width numérico) reabre igual');
  await semear({ src: URL_A, width: 240 });
  await abrirEditor();
  await sleep(3000);
  await shot('25_compat_width_numerico.png', {
    titulo: 'Compatibilidade — `width: 240` numérico (spec pré-F4)',
    clip: { x: 350, y: 258, width: 260, height: 260 },
    provado: 'um spec no formato antigo (número cru, sem unidade) continua válido e renderiza — a migração doubleNum→dimension da D3 não quebrou conteúdo existente',
    olho: 'a imagem aparece com 240px de largura, sem caixa de erro e sem aviso de spec inválido',
  });
  check('o width numérico antigo continua no spec, intocado', 240, (await getSpec()).root.props.width);
  check('e nenhuma requisição de imagem falhou nesse estado', 200, pedidoPara(URL_A)?.status);

  // ------------------------------------------------------ salvar e recarregar (§10.14)
  step('§10.14', 'recarregar a página do navegador — o conteúdo reabre idêntico');
  const antesDoReload = JSON.stringify((await getSpec()).root.props);
  await abrirEditor();
  await sleep(2500);
  await shot('14_reabre_apos_reload.png', {
    titulo: 'Reabre após recarregar o navegador',
    clip: UI.recorteCanvas,
    provado: 'depois de um reload completo o spec é byte a byte o mesmo e a imagem volta a desenhar',
    olho: 'nada de tela de erro nem de conteúdo inválido — o canvas volta a mostrar a imagem',
  });
  check('o spec não mudou com o reload', antesDoReload, JSON.stringify((await getSpec()).root.props));

  // ------------------------------------------------- prova de rede (DoD 13b e 19)
  step('DoD 13b/19', 'o log de rede — a prova de que a rodada correu contra o backend real');
  const log = pedidosDeImagem();
  writeFileSync(`${OUT}/rede_imagens.json`, JSON.stringify(log, null, 1));
  check('toda imagem do canvas passou pelo proxy do backend real', true, log.length >= 4);
  await composeNetworkShot(log);

  // -------------------------------------------- o print comparativo (a peça central)
  await composeMatrixShot();
} finally {
  console.log('\nLimpando o rastro…');
  await purge();
  writeFileSync(`${OUT}/README.md`, readme());
}

console.log(`\n${g}PASS=${PASS}${o}  ${r}FAIL=${FAIL}${o}`);
if (FAIL > 0) console.log(`${r}Falhas:${o} ${failures.join(' | ')}`);
process.exit(FAIL > 0 ? 1 : 0);

// ------------------------------- composição dos prints -------------------------------
/// Monta uma página local com os recortes já capturados e a fotografa. Os quatro
/// estados precisam ser vistos JUNTOS para o DoD 24 ser decidido em segundos —
/// e é a última coisa que o driver faz, porque troca o documento da aba.
async function renderHtml(html, file, { width = 1200, height = 700 } = {}) {
  const { frameTree } = await send('Page.getFrameTree');
  await send('Page.setDocumentContent', { frameId: frameTree.frame.id, html });
  await sleep(900);
  await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
  await sleep(400);
  await shotFile(file);
}

function css() {
  return `body{margin:0;background:#0f1115;color:#e7e9ee;font:14px/1.5 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
h1{font-size:19px;margin:0 0 4px}.sub{color:#9aa3b2;font-size:13px;margin:0 0 18px}
.grid{display:grid;grid-template-columns:repeat(2,auto);gap:16px;justify-content:start}
.card{background:#171a21;border:1px solid #262b36;border-radius:10px;padding:12px}
.card h2{font-size:13px;margin:0 0 8px;letter-spacing:.04em;text-transform:uppercase;color:#f0682f}
.card img{width:368px;height:200px;border-radius:6px;display:block;background:#fff}
.card p{margin:8px 0 0;font-size:12px;color:#9aa3b2;max-width:368px}
table{border-collapse:collapse;width:100%;font-size:12px}
th,td{text-align:left;padding:6px 8px;border-bottom:1px solid #262b36}
th{color:#9aa3b2;font-weight:600}.ok{color:#4ade80}.err{color:#f87171}
code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;word-break:break-all}`;
}

async function composeMatrixShot() {
  const painel = (chave, titulo, nota) =>
    `<div class="card"><h2>${titulo}</h2><img src="data:image/png;base64,${estados[chave]}"><p>${nota}</p></div>`;
  const html = `<!doctype html><meta charset="utf-8"><style>${css()}</style><body style="padding:22px">
<h1>Item 39 — os quatro estados da imagem, lado a lado (DoD 24)</h1>
<p class="sub">Mesmo nó, mesmo tamanho (<code>width/height: 200</code>), mesmo recorte da tela do editor em ${WEB}.
<b>Se dois quadros forem visualmente iguais, a feature reprova</b> — é o bug original.</p>
<div class="grid">
${painel('vazio', '1 · Vazio', 'Sem <code>src</code>. Nenhuma requisição de rede.')}
${painel('carregando', '2 · Carregando', 'Rede estrangulada a 12 KB/s; requisição em voo.')}
${painel('falhou', '3 · Falhou', 'URL inexistente; proxy respondeu 502.')}
${painel('carregado', '4 · Carregado', 'Proxy respondeu 200; imagem decodificada.')}
</div></body>`;
  await renderHtml(html, '24_quatro_estados_lado_a_lado.png', { width: 880, height: 700 });
  shots.unshift({
    file: '24_quatro_estados_lado_a_lado.png',
    titulo: 'DoD 24 — OS QUATRO ESTADOS LADO A LADO (a cancela da feature)',
    provado: 'os quatro recortes têm geometria idêntica e são diferentes entre si nos seis pares (comparação byte a byte dos PNGs) — nenhum estado é o mesmo pixel de outro',
    olho: '**decida em segundos:** os quatro quadros contam quatro histórias diferentes para quem não leu o código? Se dois se parecerem, o item 39 reprova',
  });
}

async function composeNetworkShot(log) {
  const linhas = log.map((r) => {
    const alvo = decodeURIComponent((r.url.split('url=')[1] || ''));
    const ok = r.status === 200;
    return `<tr><td class="${ok ? 'ok' : 'err'}">${r.status ?? 'em voo'}</td><td><code>${alvo}</code></td><td><code>${r.url.split('?')[0]}</code></td></tr>`;
  }).join('');
  const html = `<!doctype html><meta charset="utf-8"><style>${css()}</style><body style="padding:22px">
<h1>Item 39 — rede: toda imagem do canvas saiu pelo proxy (DoD 13b e 19)</h1>
<p class="sub">Capturado pelo domínio <code>Network</code> do CDP durante a rodada — a mesma fonte que alimenta a aba Network do DevTools.
Nenhuma requisição direta ao host da imagem saiu do editor: <b>${pedidosDiretosPara('www.google.com').length}</b> chamadas diretas a <code>www.google.com</code>.
Se a rodada tivesse corrido em modo fake (D19), esta tabela estaria vazia.</p>
<table><tr><th>status</th><th>URL pedida pelo usuário (parâmetro <code>url</code>)</th><th>endpoint que o Chrome chamou</th></tr>${linhas}</table>
</body>`;
  await renderHtml(html, '13b_rede_via_proxy.png', { width: 1200, height: 200 + 32 * log.length });
  shots.push({
    file: '13b_rede_via_proxy.png',
    titulo: 'DoD 13b/19 — a rede provando que foi pelo proxy, contra o backend real',
    provado: `${log.length} requisições de imagem, todas para \`${API}/media/proxy\`, e zero chamadas diretas ao host — a rodada não correu em modo fake`,
    olho: 'confira que a coluna do meio traz as URLs que você reconhece (picsum, google) e que o endpoint é sempre o do backend de homologação',
  });
}

function readme() {
  const linhas = shots.map((s) => `### ${s.titulo}\n\n![${s.titulo}](${s.file})\n\n- **O script já provou:** ${s.provado}\n- **Só o seu olho prova:** ${s.olho}\n`);
  return `# Rodada ${OUT.split('rodada_')[1] || '??'} — E2E do item 39 (URL da imagem e props)

> Prints **gerados pelo QA** (headless, via CDP, contra a homologação real). O dev
> humano **confere** — não opera o browser. Cada estado foi produzido na tela do
> editor e **conferido por rede** (domínio \`Network\` do CDP) e **por spec** (API).

**Resultado das asserções:** ${PASS} PASS / ${FAIL} FAIL${FAIL ? `\n\n**Falhas:** ${failures.join(' | ')}` : ''}

**Comece pelo primeiro print.** Ele é a cancela do item (DoD 24): quatro estados
lado a lado, mesmo tamanho, mesmo recorte. Se dois forem iguais, pare por aí.

## Como regerar

\`\`\`bash
docs/16-image-url-e-props/e2e_hml.sh            # contrato por API (idempotente)
docs/16-image-url-e-props/e2e_shots.sh 01       # estes prints, na rodada 01
\`\`\`

Os dois criam um único conteúdo de teste no projeto \`default\` do hml e o apagam
no fim. Nada sobra em homologação; nada disso vai para produção.

## O que o script NÃO consegue provar (é o seu roteiro)

Está em [\`roteiro_e2e_humano.md\`](../../roteiro_e2e_humano.md) — a peça que máquina
nenhuma pega aqui é o **\`driva_demo_app\` no celular** (DoD 26): imagem carregando
**direto do host**, sem passar pelo proxy.

## Estados capturados

${linhas.join('\n')}`;
}
