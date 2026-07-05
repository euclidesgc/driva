// Bootstrap customizado do Flutter Web.
//
// Motivo: no Chrome/Chromium com GPU, o Flutter auto-seleciona a variante
// `chromium` do CanvasKit (APIs experimentais), que em alguns drivers falha ao
// registrar a fonte de ícones OTF (MaterialIcons) — os ícones viram "tofu" (□) e
// o console loga "Could not find a set of Noto fonts...". A variante `full`
// (portável) renderiza os ícones em qualquer ambiente. Forçamos `full` aqui.
//
// Tokens `{{...}}` são preenchidos pelo flutter build/run (flutter.js e build
// config). NÃO remova — sem eles o app não sobe.
{{flutter_js}}
{{flutter_build_config}}

const serviceWorkerCleanup = (() => {
  if (!("serviceWorker" in navigator)) {
    return Promise.resolve();
  }
  return navigator.serviceWorker.getRegistrations()
    .then((registrations) => Promise.all(
      registrations.map((registration) => registration.unregister()),
    ))
    .catch((error) => {
      console.warn("Nao foi possivel limpar service workers antigos:", error);
    });
})();

serviceWorkerCleanup.finally(() => {
  _flutter.loader.load({
    config: {
      canvasKitVariant: "full",
    },
  });
});
