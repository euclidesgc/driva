// Desativa service workers Flutter antigos que ainda controlam o navegador.
//
// Contexto: builds anteriores usavam PWA offline-first. Se o SW antigo estiver
// ativo, ele pode servir index/bootstrap antigos do cache e impedir que a app
// nova rode o unregister no bootstrap. Por isso este arquivo precisa ser um SW
// real: o browser atualiza /flutter_service_worker.js, ativa este script,
// limpa caches da origem e se remove.

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      await self.clients.claim();

      const cacheNames = await caches.keys();
      await Promise.all(cacheNames.map((name) => caches.delete(name)));

      await self.registration.unregister();

      const clients = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      await Promise.all(
        clients.map((client) => {
          if ('navigate' in client) {
            return client.navigate(client.url);
          }
          return undefined;
        }),
      );
    })(),
  );
});
