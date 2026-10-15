/// Lista fechada: um gatilho fora dela não é lido nem pelo parse tolerante,
/// porque nenhum renderer sabe ligá-lo.
enum EventTrigger {
  onPressed('Ao pressionar'),
  onTap('Ao tocar'),
  onDoubleTap('Ao tocar duas vezes'),
  onLongPress('Ao pressionar e segurar'),
  onChanged('Ao mudar'),
  onSubmit('Ao enviar');

  const EventTrigger(this.label);

  final String label;

  static EventTrigger? byName(String name) {
    for (final trigger in values) {
      if (trigger.name == name) return trigger;
    }
    return null;
  }
}
