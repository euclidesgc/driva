// `jest.mock` PRECISA rodar antes de qualquer módulo do proxy ser
// carregado (`MediaModule` → `media.service.ts` → `url-guard.ts`, que
// importa `node:dns` no próprio topo do arquivo) — senão `url-guard.ts`
// resolve contra o `dns.lookup` real, cacheado antes da troca, e este
// arquivo de teste passa a inspecionar um mock que ninguém chama. Por
// isso o `jest.mock` vem antes de qualquer `import`, nesta ordem exata —
// não é estilo, é o que garante que a substituição vale para todo mundo
// que ainda vai `require('node:dns')`.
//
// `dns.lookup` também é um módulo nativo com propriedades não
// reconfiguráveis — `jest.spyOn` não consegue redefini-lo diretamente
// (`TypeError: Cannot redefine property`). `jest.mock` troca o módulo
// inteiro por um objeto novo, onde `lookup` já nasce um `jest.fn` — e
// nasce delegando para a implementação real, então todo teste que NÃO
// mexe no mock continua resolvendo DNS de verdade.
jest.mock('node:dns', () => {
  const actual = jest.requireActual<typeof import('node:dns')>('node:dns');
  return { __esModule: true, ...actual, lookup: jest.fn(actual.lookup) };
});

import { Test } from '@nestjs/testing';
import type { NestExpressApplication } from '@nestjs/platform-express';
import * as http from 'node:http';
import * as dns from 'node:dns';
import type { AddressInfo } from 'node:net';
import request from 'supertest';
import { configureApp } from '../src/configure-app';
import { MediaModule } from '../src/media/media.module';
import {
  MEDIA_IP_BLOCKLIST,
  assertAllowedTarget,
  isBlockedIp,
  type IpBlocklist,
} from '../src/media/url-guard';
import { MEDIA_PROXY_THROTTLE } from '../src/media/media.constants';

const realDnsLookup =
  jest.requireActual<typeof import('node:dns')>('node:dns').lookup;
const mockedDnsLookup = dns.lookup as jest.MockedFunction<typeof dns.lookup>;

// O Node (autoSelectFamily/Happy Eyeballs, ligado por padrão desde a v20)
// sempre pede `{ all: true }` para host por nome — então o fake precisa
// responder nos dois formatos: lista de endereços quando `all: true`,
// endereço único caso contrário. Sem isso o teste mockaria uma forma que
// `createSafeLookup` nunca recebe de verdade.
function fakeResolutionOf(address: string, family = 4) {
  return (
    _hostname: string,
    optionsOrCallback: unknown,
    maybeCallback?: unknown,
  ) => {
    const options = (
      typeof optionsOrCallback === 'function' ? {} : optionsOrCallback
    ) as { all?: boolean };
    const callback = (
      typeof optionsOrCallback === 'function' ? optionsOrCallback : maybeCallback
    ) as (...args: unknown[]) => void;

    if (options.all) {
      callback(null, [{ address, family }]);
      return;
    }
    callback(null, address, family);
  };
}

// PNG 1x1 transparente — fixture pública e bem conhecida, sem nada sensível.
const PNG_1X1 = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  'base64',
);

const LOCALHOST_ORIGIN = 'http://localhost:5173';

type Handler = (
  req: http.IncomingMessage,
  res: http.ServerResponse,
) => void;

/**
 * Servidor local efêmero para os testes que precisam de um alvo de verdade.
 * Sobe em `127.0.0.1` numa porta aleatória e fecha ao final — nunca há URL
 * fixa de infraestrutura no teste (CLAUDE.md).
 */
async function withServer<T>(
  handler: Handler,
  run: (origin: string) => Promise<T>,
): Promise<T> {
  const server = http.createServer(handler);
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address() as AddressInfo;
  const origin = `http://127.0.0.1:${address.port}`;
  try {
    return await run(origin);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
}

/**
 * App com a política de IP real e não modificada (`isBlockedIp`, sem
 * override) — é o que roda em produção. Todo teste que prova bloqueio de
 * SSRF usa este app, para provar o código de verdade, não um substituto.
 */
async function buildDefaultApp(): Promise<NestExpressApplication> {
  const moduleRef = await Test.createTestingModule({
    imports: [MediaModule],
  }).compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}

/**
 * Toda máquina de teste só tem loopback como IP alcançável — e loopback é
 * sempre bloqueado pela política real, por construção (é a categoria mais
 * óbvia de SSRF). Sem um jeito de apontar para um alvo de verdade, os
 * testes de corpo/streaming/headers/cache não teriam como existir de forma
 * hermética (sem depender de host externo, que seria flakiness em CI).
 *
 * A saída: um `overrideProvider` do Nest, só neste app de teste, que abre
 * uma exceção estreita para `127.0.0.1` e delega todo o resto para a
 * mesma `isBlockedIp` real — inclusive o endereço de metadata, que
 * continua bloqueado mesmo aqui (prova o teste #35 abaixo). O
 * `MediaModule` de produção nunca importa este override; ele só existe
 * dentro deste arquivo de teste.
 */
function loopbackAllowed(ip: string): boolean {
  return ip !== '127.0.0.1' && isBlockedIp(ip);
}

async function buildLoopbackAllowedApp(): Promise<NestExpressApplication> {
  const moduleRef = await Test.createTestingModule({
    imports: [MediaModule],
  })
    .overrideProvider(MEDIA_IP_BLOCKLIST)
    .useValue(loopbackAllowed as IpBlocklist)
    .compile();
  const app = moduleRef.createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}

function proxyUrl(target: string): string {
  return `/v1/media/proxy?url=${encodeURIComponent(target)}`;
}

describe('Media proxy — matriz de segurança (docs/16-image-url-e-props/plan.md §11.4)', () => {
  describe('bloqueios validados contra a política real, sem override (##27-34)', () => {
    let app: NestExpressApplication;

    beforeEach(async () => {
      app = await buildDefaultApp();
    });

    afterEach(async () => {
      await app.close();
      mockedDnsLookup.mockReset();
      mockedDnsLookup.mockImplementation(realDnsLookup);
    });

    it('#27 — allowlist de esquema recusa file://, e é a allowlist quem recusa', async () => {
      // A resposta HTTP é genérica de propósito (controle 10, sem oráculo)
      // — sozinha ela não prova QUAL checagem disparou. `file:///etc/passwd`
      // tem host vazio, então caindo o ramo do controle 1 (`if (false)` na
      // allowlist) o código passaria para a checagem de host e rejeitaria
      // do mesmo jeito, por um motivo errado — o teste continuaria verde
      // sem a allowlist existir. `assertAllowedTarget` chamado direto prova
      // a razão exata.
      expect(() => assertAllowedTarget('file:///etc/passwd')).toThrow(
        /esquema não permitido/,
      );

      const res = await request(app.getHttpServer()).get(
        proxyUrl('file:///etc/passwd'),
      );
      expect(res.status).toBe(400);
      // §11.4 linha 27: "nenhum acesso a disco". Se alguma dependência HTTP
      // no meio do caminho entendesse `file://` e o proxy não tivesse
      // barrado antes, o conteúdo real do arquivo apareceria aqui.
      expect(res.text).not.toMatch(/root:.*:0:0:/);
    });

    it.each([
      ['gopher://x/', 'gopher'],
      ['data:text/html,<script>alert(1)</script>', 'data'],
      ['ftp://x/arquivo', 'ftp'],
      ['blob:https://x/algo', 'blob'],
    ])('#28 — allowlist de esquema recusa %s, pela allowlist', async (target) => {
      // `data:` e `blob:` também têm host vazio (mesmo risco do #27) —
      // `gopher:`/`ftp:` têm host, então já matavam a mutação da allowlist
      // pelo status sozinho, mas a razão explícita vale para os quatro.
      expect(() => assertAllowedTarget(target)).toThrow(
        /esquema não permitido/,
      );

      const res = await request(app.getHttpServer()).get(proxyUrl(target));
      expect(res.status).toBe(400);
    });

    it('#29 — recusa loopback (o próprio backend)', async () => {
      const res = await request(app.getHttpServer()).get(
        proxyUrl('http://127.0.0.1:3000/v1/contents'),
      );
      expect(res.status).toBe(400);
    });

    it('#30 — recusa o endereço de metadata de nuvem', async () => {
      const res = await request(app.getHttpServer()).get(
        proxyUrl('http://169.254.169.254/latest/meta-data/'),
      );
      expect(res.status).toBe(400);
    });

    it.each([['10.0.0.1'], ['172.16.0.1'], ['192.168.0.1']])(
      '#31 — recusa IP privado %s',
      async (ip) => {
        const res = await request(app.getHttpServer()).get(
          proxyUrl(`http://${ip}/`),
        );
        expect(res.status).toBe(400);
      },
    );

    it('#32 — recusa loopback IPv6 (::1)', async () => {
      const res = await request(app.getHttpServer()).get(
        proxyUrl('http://[::1]/'),
      );
      expect(res.status).toBe(400);
    });

    it('#32 — recusa o bypass IPv4-mapeado (::ffff:169.254.169.254)', async () => {
      const res = await request(app.getHttpServer()).get(
        proxyUrl('http://[::ffff:169.254.169.254]/'),
      );
      expect(res.status).toBe(400);
    });

    it('#33 — recusa host público que resolve para IP privado', async () => {
      // Sem depender de um serviço de DNS externo real (ex.: nip.io): o
      // mock simula "hostname qualquer, resolução aponta para dentro" —
      // exatamente o que o controle 2 tem de pegar, porque ele valida o
      // IP resolvido, nunca a string do host.
      mockedDnsLookup.mockImplementation(fakeResolutionOf('10.1.2.3'));

      const res = await request(app.getHttpServer()).get(
        proxyUrl('http://parece-publico.invalid/imagem.png'),
      );
      expect(res.status).toBe(400);
    });

    it('#34 — DNS rebinding: valida no instante da conexão, não antes', async () => {
      // A vulnerabilidade clássica é DUAS resoluções — uma que valida
      // (pública, passa) e outra, separada, que conecta (privada, TOCTOU).
      // Este mecanismo faz UMA única resolução, que ao mesmo tempo valida
      // E é a que conecta — por isso a prova é dupla: (a) o resultado
      // privado é recusado, e (b) só existe UMA chamada de `dns.lookup`
      // para o request inteiro. Se existisse uma pré-checagem separada
      // (o padrão vulnerável), haveria uma segunda chamada — e ela é
      // que abriria a janela do TOCTOU.
      mockedDnsLookup.mockImplementation(fakeResolutionOf('192.168.50.50'));

      const res = await request(app.getHttpServer()).get(
        proxyUrl('http://rebinding.invalid/imagem.png'),
      );

      expect(res.status).toBe(400);
      expect(mockedDnsLookup).toHaveBeenCalledTimes(1);
    });
  });

  describe('redirect, conteúdo, streaming, headers e cache — precisam de alvo real (##35-44)', () => {
    let app: NestExpressApplication;

    beforeEach(async () => {
      app = await buildLoopbackAllowedApp();
    });

    afterEach(async () => {
      await app.close();
    });

    it('#35 — não segue redirect para IP interno (metadata)', async () => {
      await withServer(
        (_req, res) => {
          res.writeHead(302, {
            Location: 'http://169.254.169.254/latest/meta-data/',
          });
          res.end();
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/redirect`),
          );
          expect(res.status).toBe(400);
        },
      );
    });

    it('#36 — teto de redirects: cadeia acima do limite é recusada', async () => {
      await withServer(
        (req, res) => {
          const match = /\/chain\/(\d+)/.exec(req.url ?? '');
          const n = match ? Number(match[1]) : 0;
          if (n < 6) {
            res.writeHead(302, { Location: `/chain/${n + 1}` });
            res.end();
            return;
          }
          res.writeHead(200, { 'Content-Type': 'image/png' });
          res.end(PNG_1X1);
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/chain/0`),
          );
          expect(res.status).toBe(400);
        },
      );
    });

    it('#36b — dentro do teto de redirects, chega ao destino', async () => {
      await withServer(
        (req, res) => {
          const match = /\/chain\/(\d+)/.exec(req.url ?? '');
          const n = match ? Number(match[1]) : 0;
          if (n < 2) {
            res.writeHead(302, { Location: `/chain/${n + 1}` });
            res.end();
            return;
          }
          res.writeHead(200, { 'Content-Type': 'image/png' });
          res.end(PNG_1X1);
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/chain/0`),
          );
          expect(res.status).toBe(200);
          expect(res.headers['content-type']).toBe('image/png');
        },
      );
    });

    it('#37 — teto de tamanho: aborta em streaming sem bufferizar tudo', async () => {
      // Em loopback, `res.write` sozinho não prova nada: o kernel aceita
      // megabytes no buffer de socket quase instantaneamente, e o servidor
      // terminaria de escrever tudo antes de o proxy sequer processar o
      // primeiro chunk — testando só "status ≠ 200" no fim. Espaçar os
      // chunks no tempo (`setInterval`) força um streaming de verdade:
      // se o proxy aborta ao ultrapassar o teto, o servidor nunca chega
      // ao chunk 15 (15MB), porque a conexão morre no meio.
      const TOTAL_CHUNKS = 15;
      const CHUNK_INTERVAL_MS = 25;

      let sent = 0;
      let timer: ReturnType<typeof setInterval>;
      let closedEarly = false;
      let resolveClosed: () => void;
      // O `close` do socket do lado do servidor chega alguns ticks depois
      // de o proxy destruir a conexão — sem esperar por ele, a asserção
      // corre contra o servidor antes de ele perceber o abort.
      const closed = new Promise<void>((resolve) => {
        resolveClosed = resolve;
      });

      const handler: Handler = (_req, res) => {
        res.writeHead(200, { 'Content-Type': 'image/png' });
        const chunk = Buffer.alloc(1024 * 1024, 7);
        res.on('close', () => {
          clearInterval(timer);
          if (sent < TOTAL_CHUNKS) closedEarly = true;
          resolveClosed();
        });
        timer = setInterval(() => {
          if (res.destroyed || res.writableEnded) {
            clearInterval(timer);
            return;
          }
          if (sent >= TOTAL_CHUNKS) {
            clearInterval(timer);
            res.end();
            return;
          }
          sent += 1;
          res.write(chunk);
        }, CHUNK_INTERVAL_MS);
      };

      await withServer(handler, async (origin) => {
        const res = await request(app.getHttpServer()).get(
          proxyUrl(`${origin}/oversized`),
        );
        expect(res.status).not.toBe(200);
        await Promise.race([
          closed,
          new Promise<void>((_, reject) =>
            setTimeout(
              () => reject(new Error('servidor não observou o close')),
              2_000,
            ),
          ),
        ]);
      });

      expect(sent).toBeLessThan(TOTAL_CHUNKS);
      expect(closedEarly).toBe(true);
    });

    // O `testTimeout` global (`test/jest-e2e.json`) fica acima do
    // `MEDIA_PROXY_TIMEOUT_MS` (10s) — esse é o teste que precisa da folga;
    // sem ela o jest estoura em 5s **antes** da asserção rodar, e o
    // `afterEach` corre contra uma requisição ainda pendente.
    it('#38 — timeout: alvo que segura a conexão aberta devolve 504', async () => {
      await withServer(
        () => {
          // Nunca responde — a conexão fica aberta até o proxy desistir.
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/pendurado`),
          );
          expect(res.status).toBe(504);
        },
      );
    });

    it('#39 — content-type fora da allowlist é recusado, corpo não repassado', async () => {
      await withServer(
        (_req, res) => {
          res.writeHead(200, { 'Content-Type': 'text/html' });
          res.end('<html>não é imagem</html>');
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/pagina.html`),
          );
          expect(res.status).toBe(400);
          expect(res.text).not.toContain('não é imagem');
        },
      );
    });

    it('#39b — content-type image/svg+xml também é recusado (D9: SVG carrega script)', async () => {
      await withServer(
        (_req, res) => {
          res.writeHead(200, { 'Content-Type': 'image/svg+xml' });
          res.end('<svg onload="alert(1)"></svg>');
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/imagem.svg`),
          );
          expect(res.status).toBe(400);
          expect(res.text).not.toContain('onload');
        },
      );
    });

    it('#40 — rate limit: N+1 requisições na janela devolvem 429', async () => {
      await withServer(
        (_req, res) => {
          res.writeHead(200, { 'Content-Type': 'image/png' });
          res.end(PNG_1X1);
        },
        async (origin) => {
          const target = proxyUrl(`${origin}/ok.png`);
          const limit = MEDIA_PROXY_THROTTLE.default.limit;

          let last: { status: number } = { status: 0 };
          for (let i = 0; i < limit + 1; i += 1) {
            last = await request(app.getHttpServer()).get(target);
          }
          expect(last.status).toBe(429);
        },
      );
    });

    it('#41 — nada de confused deputy: headers do chamador não chegam ao alvo', async () => {
      let capturedHeaders: http.IncomingHttpHeaders = {};

      await withServer(
        (req, res) => {
          capturedHeaders = req.headers;
          res.writeHead(200, { 'Content-Type': 'image/png' });
          res.end(PNG_1X1);
        },
        async (origin) => {
          const res = await request(app.getHttpServer())
            .get(proxyUrl(`${origin}/eco.png`))
            .set('Authorization', 'Bearer segredo-do-chamador')
            .set('Cookie', 'session=chamador')
            .set('x-driva-key', 'pk_nao_deveria_vazar')
            .set('x-project-id', 'proj_nao_deveria_vazar');

          expect(res.status).toBe(200);
        },
      );

      expect(capturedHeaders.authorization).toBeUndefined();
      expect(capturedHeaders.cookie).toBeUndefined();
      expect(capturedHeaders['x-driva-key']).toBeUndefined();
      expect(capturedHeaders['x-project-id']).toBeUndefined();
    });

    it('#42 — resposta limpa: Set-Cookie do alvo não é repassado', async () => {
      await withServer(
        (_req, res) => {
          res.writeHead(200, {
            'Content-Type': 'image/png',
            'Set-Cookie': 'sessao-do-alvo=xyz; HttpOnly',
          });
          res.end(PNG_1X1);
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/com-cookie.png`),
          );
          expect(res.status).toBe(200);
          expect(res.headers['set-cookie']).toBeUndefined();
        },
      );
    });

    it('#43 — erro sem oráculo: status/corpo do alvo não vazam', async () => {
      await withServer(
        (_req, res) => {
          res.writeHead(500, {
            'Content-Type': 'text/plain',
            'X-Debug-Interno': 'stack-trace-do-alvo',
          });
          res.end('erro interno: senha_db=segredo123 em /var/app/config');
        },
        async (origin) => {
          const res = await request(app.getHttpServer()).get(
            proxyUrl(`${origin}/quebrado`),
          );
          expect(res.status).toBe(502);
          expect(res.text).not.toContain('segredo123');
          expect(res.text).not.toContain('stack-trace');
          expect(res.headers['x-debug-interno']).toBeUndefined();
        },
      );
    });

    it.each([
      ['image/png', PNG_1X1],
      ['image/webp', PNG_1X1],
    ])(
      '#44 — caminho feliz com %s: 200, content-type de imagem, ACAO e ETag',
      async (contentType, body) => {
        await withServer(
          (_req, res) => {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(body);
          },
          async (origin) => {
            const res = await request(app.getHttpServer())
              .get(proxyUrl(`${origin}/imagem`))
              .set('Origin', LOCALHOST_ORIGIN);

            expect(res.status).toBe(200);
            expect(res.headers['content-type']).toBe(contentType);
            expect(res.headers['access-control-allow-origin']).toBe(
              LOCALHOST_ORIGIN,
            );
            expect(res.headers.etag).toBeTruthy();
            expect(res.headers['cache-control']).toContain('max-age');
          },
        );
      },
    );
  });
});
