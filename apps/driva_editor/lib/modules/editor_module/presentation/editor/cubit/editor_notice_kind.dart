/// Recado da última operação que não terminou onde o usuário apontou — ou que
/// precisa de confirmação visível, como copiar. O texto em pt-BR mora na barra
/// de status; o estado carrega só o motivo.
enum EditorNoticeKind {
  dropRedirected,
  dropCycle,
  dropNoSlot,
  dropUnknownTarget,
  rootNotMovable,
  rootNotDuplicable,
  nodeCopied,
  clipboardEmpty,
  nodeWrapped,
}
