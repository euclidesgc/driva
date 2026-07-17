import 'dart:js_interop';

import 'package:driva_editor/modules/projects_module/domain/entities/entities.dart';
import 'package:flutter/foundation.dart' show ValueChanged;
import 'package:web/web.dart' as web;

/// Ouve `dragover`/`drop` nativos do navegador para o formulário de projeto.
///
/// Flutter Web renderiza a UI num `<canvas>`/elementos que não recebem
/// eventos de drag-and-drop de arquivo do SO diretamente (isso exigiria um
/// platform view HTML sobreposto). Como o formulário de projeto tem **uma
/// única** área soltável visível por vez, ouvir os eventos no `document`
/// inteiro enquanto o formulário está montado é seguro e evita depender de
/// um plugin novo (`desktop_drop`/`super_drag_and_drop`) só para isto.
///
/// `onHover` reflete `dragover`/`dragleave` (o formulário usa isso para dar
/// o feedback visual de "solte aqui"); `onFile` dispara com o primeiro
/// arquivo solto. Implementação real, atrás do import condicional de
/// `image_drop_zone.dart`.
class ImageDropZoneImpl {
  ImageDropZoneImpl({required this.onHover, required this.onFile}) {
    web.document.addEventListener('dragover', _onDragOver);
    web.document.addEventListener('dragleave', _onDragLeave);
    web.document.addEventListener('drop', _onDrop);
  }

  final ValueChanged<bool> onHover;
  final ValueChanged<ProjectImageInput> onFile;

  late final JSExportedDartFunction _onDragOver = ((web.Event event) {
    event.preventDefault();
    onHover(true);
  }).toJS;

  late final JSExportedDartFunction _onDragLeave =
      ((web.Event event) => onHover(false)).toJS;

  late final JSExportedDartFunction _onDrop = ((web.Event event) {
    event.preventDefault();
    onHover(false);
    final dragEvent = event as web.DragEvent;
    final files = dragEvent.dataTransfer?.files;
    final file = (files != null && files.length > 0) ? files.item(0) : null;
    if (file == null) return;
    _readFile(file);
  }).toJS;

  void _readFile(web.File file) {
    final reader = web.FileReader();
    reader
      ..onload = (web.Event _) {
        final result = reader.result! as JSArrayBuffer;
        final bytes = result.toDart.asUint8List();
        onFile(
          ProjectImageInput(
            bytes: bytes,
            filename: file.name,
            contentType: file.type.isNotEmpty ? file.type : null,
          ),
        );
      }.toJS
      ..readAsArrayBuffer(file);
  }

  void dispose() {
    web.document.removeEventListener('dragover', _onDragOver);
    web.document.removeEventListener('dragleave', _onDragLeave);
    web.document.removeEventListener('drop', _onDrop);
  }
}
