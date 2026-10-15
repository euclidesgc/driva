import 'package:sdui_core/sdui_core.dart';
import 'package:test/test.dart';

void main() {
  group('EventTrigger', () {
    test('é a lista fechada de seis gatilhos, na ordem, com rótulo', () {
      expect(
        {
          for (final trigger in EventTrigger.values)
            trigger.name: trigger.label,
        },
        {
          'onPressed': 'Ao pressionar',
          'onTap': 'Ao tocar',
          'onDoubleTap': 'Ao tocar duas vezes',
          'onLongPress': 'Ao pressionar e segurar',
          'onChanged': 'Ao mudar',
          'onSubmit': 'Ao enviar',
        },
      );
      expect(EventTrigger.values.map((t) => t.name), [
        'onPressed',
        'onTap',
        'onDoubleTap',
        'onLongPress',
        'onChanged',
        'onSubmit',
      ]);
    });

    test('byName encontra o gatilho pelo nome gravado no spec', () {
      expect(EventTrigger.byName('onTap'), EventTrigger.onTap);
      expect(EventTrigger.byName('onSubmit'), EventTrigger.onSubmit);
    });

    test('byName devolve null para nome fora da lista', () {
      expect(EventTrigger.byName('onForcePress'), isNull);
      expect(EventTrigger.byName(''), isNull);
    });
  });
}
