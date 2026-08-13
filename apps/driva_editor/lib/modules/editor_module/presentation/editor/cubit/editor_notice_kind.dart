/// Por que o último arraste não terminou onde o usuário apontou. O texto em
/// pt-BR mora na barra de status; o estado carrega só o motivo.
enum EditorNoticeKind {
  dropRedirected,
  dropCycle,
  dropNoSlot,
  dropUnknownTarget,
  rootNotMovable,
}
