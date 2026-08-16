import {
  MediaTargetRejectedError,
  createSafeLookup,
  isBlockedIp,
  type NodeLookupFn,
} from './url-guard';

// O e2e (`test/media-proxy.e2e-spec.ts`) só exercita o ramo `all: true` de
// `createSafeLookup` — é o que o Node pede por padrão desde a v20
// (`autoSelectFamily`/Happy Eyeballs). Mas a função também atende
// `all: false`/ausente (Node sem Happy Eyeballs, ou qualquer chamador
// direto), e esse ramo não passava por rede alguma para ser provado — daí
// o teste unitário, com um `baseLookup` falso, sem HTTP.

function singleAddressLookupOf(address: string, family = 4): NodeLookupFn {
  return ((_hostname, _options, callback: (...args: unknown[]) => void) => {
    callback(null, address, family);
  }) as NodeLookupFn;
}

function multiAddressLookupOf(
  addresses: Array<{ address: string; family: number }>,
): NodeLookupFn {
  return ((_hostname, _options, callback: (...args: unknown[]) => void) => {
    callback(null, addresses);
  }) as NodeLookupFn;
}

describe('createSafeLookup — ramo de endereço único (all: false)', () => {
  it('recusa endereço bloqueado', (done) => {
    const safeLookup = createSafeLookup(
      isBlockedIp,
      singleAddressLookupOf('127.0.0.1'),
    );

    safeLookup('qualquer.host', { all: false }, (err) => {
      expect(err).toBeInstanceOf(MediaTargetRejectedError);
      done();
    });
  });

  it('libera endereço não bloqueado', (done) => {
    const safeLookup = createSafeLookup(
      isBlockedIp,
      singleAddressLookupOf('8.8.8.8', 4),
    );

    safeLookup('qualquer.host', { all: false }, (err, address, family) => {
      expect(err).toBeNull();
      expect(address).toBe('8.8.8.8');
      expect(family).toBe(4);
      done();
    });
  });

  it('propaga erro de resolução sem chamar o blocklist', (done) => {
    const resolutionError = new Error('ENOTFOUND');
    const failingLookup: NodeLookupFn = ((
      _hostname: string,
      _options: unknown,
      callback: (...args: unknown[]) => void,
    ) => {
      callback(resolutionError);
    }) as NodeLookupFn;

    const safeLookup = createSafeLookup(isBlockedIp, failingLookup);

    safeLookup('qualquer.host', { all: false }, (err) => {
      expect(err).toBe(resolutionError);
      done();
    });
  });
});

describe('createSafeLookup — ramo de múltiplos endereços (all: true, Happy Eyeballs)', () => {
  it('recusa quando todos os endereços resolvidos são bloqueados', (done) => {
    const safeLookup = createSafeLookup(
      isBlockedIp,
      multiAddressLookupOf([
        { address: '127.0.0.1', family: 4 },
        { address: '169.254.169.254', family: 4 },
      ]),
    );

    safeLookup('qualquer.host', { all: true }, (err) => {
      expect(err).toBeInstanceOf(MediaTargetRejectedError);
      done();
    });
  });

  it('filtra os bloqueados e libera só os endereços permitidos', (done) => {
    const safeLookup = createSafeLookup(
      isBlockedIp,
      multiAddressLookupOf([
        { address: '127.0.0.1', family: 4 },
        { address: '8.8.8.8', family: 4 },
      ]),
    );

    safeLookup('qualquer.host', { all: true }, (err, addresses) => {
      expect(err).toBeNull();
      expect(addresses).toEqual([{ address: '8.8.8.8', family: 4 }]);
      done();
    });
  });
});
