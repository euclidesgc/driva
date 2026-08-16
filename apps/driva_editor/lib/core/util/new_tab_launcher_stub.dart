/// Fallback não-web (VM: `flutter analyze`/`flutter test` rodam aqui).
///
/// Nunca é chamado de verdade — o app é Flutter Web only — mas precisa
/// compilar/analisar fora do alvo web, senão `flutter test` (VM) quebra ao
/// carregar qualquer arquivo que importe este módulo transitivamente (mesmo
/// motivo do `image_picker_stub.dart`).
class NewTabLauncherImpl {
  const NewTabLauncherImpl();

  void open(String url) {
    throw UnsupportedError('Abrir nova aba só é suportado em Flutter Web.');
  }
}
