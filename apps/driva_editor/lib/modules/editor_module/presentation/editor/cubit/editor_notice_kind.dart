/// Recado da última operação que não terminou onde o usuário apontou, que
/// precisa de confirmação visível (como copiar), ou que falhou de um jeito
/// que o usuário precisa ver (publicar, restaurar). O texto em pt-BR mora na
/// barra de status; o estado carrega só o motivo.
enum EditorNoticeKind {
  dropRedirected,
  dropCycle,
  dropWrapped,
  dropUnknownTarget,
  rootNotMovable,
  rootNotDuplicable,
  nodeCopied,
  clipboardEmpty,
  nodeWrapped,
  publishFailed,
  unpublishFailed,
  restoreFailed,
}
