// Bootstrap customizado do Flutter Web.
//
// Motivo: no Chrome/Chromium com GPU, o Flutter auto-seleciona a variante
// `chromium` do CanvasKit (APIs experimentais), que em alguns drivers falha ao
// registrar a fonte de ícones OTF (MaterialIcons) — os ícones viram "tofu" (□) e
// o console loga "Could not find a set of Noto fonts...". A variante `full`
// (portável) renderiza os ícones em qualquer ambiente. Forçamos `full` aqui.
//
// Tokens `{{...}}` são preenchidos pelo flutter build/run (flutter.js, build
// config e versão do service worker). NÃO remova — sem eles o app não sobe.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitVariant: "full",
  },
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
