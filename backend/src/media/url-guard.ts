// Superfície de SSRF: recusa é sempre por allowlist de esquema/IP, nunca por
// blocklist — CLAUDE.md e docs/16-image-url-e-props/plan.md §5-F2.
import { isIP } from 'node:net';
import { lookup as nodeDnsLookup } from 'node:dns';
import type { LookupAddress, LookupOptions } from 'node:dns';
import ipaddr from 'ipaddr.js';

const ALLOWED_SCHEMES = new Set(['http:', 'https:']);

export class MediaTargetRejectedError extends Error {}

export type IpBlocklist = (ip: string) => boolean;

export const MEDIA_IP_BLOCKLIST = Symbol('MEDIA_IP_BLOCKLIST');

// `ipaddr.process` colapsa IPv4-mapeado-em-IPv6 (`::ffff:169.254.169.254`)
// para o IPv4 equivalente antes de classificar — fecha esse bypass sem
// checagem manual de bits. `range() !== 'unicast'` cobre, numa condição só,
// loopback, privados (RFC1918), link-local (169.254.169.254 incluso),
// CGNAT, 0.0.0.0/8, multicast, broadcast, reservados (TEST-NET etc.) e o
// ULA IPv6 (fc00::/7) — a lista inteira do controle 2 do plano.
export const isBlockedIp: IpBlocklist = (ip) => {
  try {
    return ipaddr.process(ip).range() !== 'unicast';
  } catch {
    return true;
  }
};

function literalHostOf(hostname: string): string {
  return hostname.startsWith('[') && hostname.endsWith(']')
    ? hostname.slice(1, -1)
    : hostname;
}

// Valida esquema + host, e recusa IP literal bloqueado já aqui — o Node
// pula a `lookup` customizada quando o host da URL já é um IP (não há o
// que resolver), então esse é o único ponto que intercepta
// `?url=http://169.254.169.254/...` direto. Chamada a cada hop de redirect,
// não só na URL de entrada (controle 4).
export function assertAllowedTarget(
  raw: string,
  isBlocked: IpBlocklist = isBlockedIp,
): URL {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new MediaTargetRejectedError('URL malformada');
  }

  if (!ALLOWED_SCHEMES.has(url.protocol)) {
    throw new MediaTargetRejectedError(
      `esquema não permitido: ${url.protocol}`,
    );
  }
  if (!url.hostname) {
    throw new MediaTargetRejectedError('URL sem host');
  }

  const literal = literalHostOf(url.hostname);
  if (isIP(literal) && isBlocked(literal)) {
    throw new MediaTargetRejectedError(
      `endereço de destino bloqueado: ${literal}`,
    );
  }

  return url;
}

export type NodeLookupFn = typeof nodeDnsLookup;

export type SafeLookupFn = (
  hostname: string,
  options: LookupOptions,
  callback: (
    err: NodeJS.ErrnoException | null,
    address: string | LookupAddress[],
    family?: number,
  ) => void,
) => void;

// O controle do TOCTOU/DNS rebinding: esta é a função que `http.request`/
// `https.request` chamam no instante de abrir o socket, não antes — o(s)
// endereço(s) validado(s) aqui são exatamente os que o Node usa em seguida
// para conectar. Não existe uma segunda resolução independente (a de um
// `fetch(url)` cru, por exemplo) que possa devolver um endereço diferente
// do que foi checado.
//
// Desde o Node 20, `autoSelectFamily` (Happy Eyeballs) vem ligado por
// padrão: para host por nome (não IP literal), o Node sempre chama esta
// função com `{ all: true }`, pedindo IPv4 **e** IPv6 para tentar as duas
// em paralelo — nunca um endereço só. Ignorar esse caso (como uma versão
// anterior deste guard fazia) recusaria toda URL por hostname, ou seja,
// praticamente toda imagem do mundo real. A resposta correta não é
// desligar o Happy Eyeballs: é filtrar a lista, mantendo só os endereços
// que passam no controle 2 — o Node só tenta conectar ao que sobra.
export function createSafeLookup(
  isBlocked: IpBlocklist = isBlockedIp,
  baseLookup: NodeLookupFn = nodeDnsLookup,
): SafeLookupFn {
  return (hostname, options, callback) => {
    if (options.all) {
      baseLookup(hostname, { ...options, all: true }, (err, addresses) => {
        if (err) {
          callback(err, addresses);
          return;
        }
        const allowed = addresses.filter((entry) => !isBlocked(entry.address));
        if (allowed.length === 0) {
          const resolved = addresses.map((entry) => entry.address).join(', ');
          callback(
            new MediaTargetRejectedError(
              `nenhum endereço de destino permitido (${resolved || 'nenhum resolvido'})`,
            ) as NodeJS.ErrnoException,
            [],
          );
          return;
        }
        callback(null, allowed);
      });
      return;
    }

    baseLookup(hostname, { ...options, all: false }, (err, address, family) => {
      if (err) {
        callback(err, address, family);
        return;
      }
      if (isBlocked(address)) {
        callback(
          new MediaTargetRejectedError(
            `endereço de destino bloqueado: ${address}`,
          ) as NodeJS.ErrnoException,
          address,
          family,
        );
        return;
      }
      callback(null, address, family);
    });
  };
}
