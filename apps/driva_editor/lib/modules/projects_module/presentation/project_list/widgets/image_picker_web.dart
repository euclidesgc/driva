import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../../domain/entities/entities.dart';

/// Abre o seletor de arquivo nativo do navegador (`<input type="file">`) e
/// devolve os bytes escolhidos como [ProjectImageInput].
///
/// O app é Flutter Web only (sem alvo mobile/desktop nesta fase), então usar
/// a API do DOM direto via `package:web` (sem `dart:html`, deprecated) é a
/// via web-friendly recomendada — evita puxar um plugin novo (`file_picker`/
/// `image_picker`) só para isso. Implementação real, atrás do import
/// condicional de `image_picker.dart` (o `dart:js_interop` que ela usa não
/// existe fora do alvo web — ver `image_picker_stub.dart`).
class ImagePickerImpl {
  const ImagePickerImpl();

  /// Allowlist espelhando o pipeline do CISO no backend (png/jpg/webp).
  static const accept = '.png,.jpg,.jpeg,.webp,image/png,image/jpeg,image/webp';

  /// Abre o seletor; `null` se o usuário cancelar.
  Future<ProjectImageInput?> pick() {
    final completer = Completer<ProjectImageInput?>();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = accept
      ..style.display = 'none';

    web.document.body?.appendChild(input);

    void cleanup() => input.remove();

    input.onchange = (web.Event _) {
      final files = input.files;
      final file = (files != null && files.length > 0) ? files.item(0) : null;
      if (file == null) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final reader = web.FileReader();
      reader.onload = (web.Event _) {
        final result = reader.result as JSArrayBuffer;
        final bytes = result.toDart.asUint8List();
        cleanup();
        if (!completer.isCompleted) {
          completer.complete(
            ProjectImageInput(
              bytes: bytes,
              filename: file.name,
              contentType: file.type.isNotEmpty ? file.type : null,
            ),
          );
        }
      }.toJS;
      reader.onerror = (web.Event _) {
        cleanup();
        if (!completer.isCompleted) completer.complete(null);
      }.toJS;
      reader.readAsArrayBuffer(file);
    }.toJS;

    // Sem re-emissão de `change` em cancelar: se o usuário fechar o diálogo
    // sem escolher nada, o completer simplesmente não resolve — aceitável
    // aqui pois a UI não trava esperando (o botão continua clicável).
    input.click();
    return completer.future;
  }

  Uint8List bytesOf(ProjectImageInput image) => Uint8List.fromList(image.bytes);
}
