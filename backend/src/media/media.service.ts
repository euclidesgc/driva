import {
  BadGatewayException,
  BadRequestException,
  GatewayTimeoutException,
  Inject,
  Injectable,
  Logger,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import * as http from 'node:http';
import * as https from 'node:https';
import {
  IpBlocklist,
  MEDIA_IP_BLOCKLIST,
  MediaTargetRejectedError,
  assertAllowedTarget,
  createSafeLookup,
} from './url-guard';
import {
  MEDIA_PROXY_ALLOWED_CONTENT_TYPES,
  MEDIA_PROXY_MAX_BYTES,
  MEDIA_PROXY_MAX_REDIRECTS,
  MEDIA_PROXY_TIMEOUT_MS,
} from './media.constants';

export class MediaTimeoutError extends Error {}

export interface ProxiedMedia {
  body: Buffer;
  contentType: string;
  etag: string;
}

const REDIRECT_STATUSES = new Set([301, 302, 303, 307, 308]);

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);

  constructor(
    @Inject(MEDIA_IP_BLOCKLIST) private readonly isBlocked: IpBlocklist,
  ) {}

  async fetch(rawUrl: string): Promise<ProxiedMedia> {
    let target: URL;
    try {
      target = assertAllowedTarget(rawUrl, this.isBlocked);
    } catch (error) {
      this.logger.warn(
        `recusado antes de conectar: ${(error as Error).message}`,
      );
      throw new BadRequestException('URL de mídia recusada.');
    }

    const deadline = Date.now() + MEDIA_PROXY_TIMEOUT_MS;
    try {
      const { body, contentType } = await this.fetchFollowingRedirects(
        target,
        MEDIA_PROXY_MAX_REDIRECTS,
        deadline,
      );
      return {
        body,
        contentType,
        etag: `"${createHash('sha256').update(body).digest('hex')}"`,
      };
    } catch (error) {
      if (error instanceof MediaTargetRejectedError) {
        this.logger.warn(`recusado durante a busca: ${error.message}`);
        throw new BadRequestException('URL de mídia recusada.');
      }
      if (error instanceof MediaTimeoutError) {
        this.logger.warn('timeout buscando mídia proxyada');
        throw new GatewayTimeoutException(
          'Tempo esgotado ao buscar a mídia.',
        );
      }
      this.logger.warn(`falha ao buscar mídia: ${(error as Error).message}`);
      throw new BadGatewayException(
        'Não foi possível obter a mídia solicitada.',
      );
    }
  }

  private fetchFollowingRedirects(
    url: URL,
    redirectsLeft: number,
    deadline: number,
  ): Promise<{ body: Buffer; contentType: string }> {
    return new Promise((resolve, reject) => {
      const remaining = deadline - Date.now();
      if (remaining <= 0) {
        reject(new MediaTimeoutError());
        return;
      }

      const client = url.protocol === 'https:' ? https : http;

      let settled = false;
      const settle = (fn: () => void) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        fn();
      };

      // Requisição de saída montada do zero: só os dois headers abaixo.
      // Nenhum header do chamador (Authorization, Cookie, x-driva-key,
      // x-project-id...) é lido nem repassado — não tem como vazar o que
      // nunca foi consultado (controle 8, "confused deputy").
      const req = client.request(url, {
        method: 'GET',
        agent: false,
        lookup: createSafeLookup(this.isBlocked),
        headers: {
          'user-agent': 'driva-media-proxy/1.0',
          accept: 'image/*',
        },
      });

      const timer = setTimeout(() => {
        req.destroy();
        settle(() => reject(new MediaTimeoutError()));
      }, remaining);

      req.on('error', (err) => {
        settle(() => reject(err));
      });

      req.on('response', (res) => {
        const status = res.statusCode ?? 0;

        if (REDIRECT_STATUSES.has(status)) {
          res.resume();
          if (redirectsLeft <= 0) {
            settle(() =>
              reject(
                new MediaTargetRejectedError(
                  'cadeia de redirects acima do teto',
                ),
              ),
            );
            return;
          }
          const location = res.headers.location;
          if (!location) {
            settle(() =>
              reject(new MediaTargetRejectedError('redirect sem Location')),
            );
            return;
          }
          let next: URL;
          try {
            next = assertAllowedTarget(
              new URL(location, url).toString(),
              this.isBlocked,
            );
          } catch (error) {
            settle(() => reject(error));
            return;
          }
          settle(() => {
            resolve(
              this.fetchFollowingRedirects(next, redirectsLeft - 1, deadline),
            );
          });
          return;
        }

        if (status < 200 || status >= 300) {
          res.resume();
          settle(() => reject(new Error(`upstream respondeu ${status}`)));
          return;
        }

        const contentType = (res.headers['content-type'] ?? '')
          .split(';')[0]
          .trim()
          .toLowerCase();
        if (!MEDIA_PROXY_ALLOWED_CONTENT_TYPES.has(contentType)) {
          res.resume();
          settle(() =>
            reject(
              new MediaTargetRejectedError(
                `content-type não permitido: ${contentType || '(vazio)'}`,
              ),
            ),
          );
          return;
        }

        const declared = Number(res.headers['content-length'] ?? NaN);
        if (Number.isFinite(declared) && declared > MEDIA_PROXY_MAX_BYTES) {
          res.destroy();
          req.destroy();
          settle(() =>
            reject(new Error('conteúdo maior que o teto (content-length)')),
          );
          return;
        }

        const chunks: Buffer[] = [];
        let total = 0;
        res.on('data', (chunk: Buffer) => {
          total += chunk.length;
          if (total > MEDIA_PROXY_MAX_BYTES) {
            res.destroy();
            req.destroy();
            settle(() =>
              reject(new Error('conteúdo maior que o teto (streaming)')),
            );
            return;
          }
          chunks.push(chunk);
        });
        res.on('end', () => {
          settle(() => resolve({ body: Buffer.concat(chunks), contentType }));
        });
        res.on('error', (err) => {
          settle(() => reject(err));
        });
      });

      req.end();
    });
  }
}
