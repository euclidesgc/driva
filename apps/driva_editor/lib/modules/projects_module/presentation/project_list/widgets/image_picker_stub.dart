import 'dart:typed_data';

import '../../../domain/entities/entities.dart';

/// Fallback não-web (VM: `flutter analyze`/`flutter test` rodam aqui).
///
/// Nunca é chamado de verdade — o app é Flutter Web only — mas precisa
/// compilar/analisar fora do alvo web, senão `flutter test` (VM) quebra ao
/// carregar qualquer arquivo que importe este módulo transitivamente (é o
/// motivo deste import condicional existir; ver `image_picker.dart`).
class ImagePickerImpl {
  const ImagePickerImpl();

  Future<ProjectImageInput?> pick() async {
    throw UnsupportedError('Seleção de imagem só é suportada em Flutter Web.');
  }

  Uint8List bytesOf(ProjectImageInput image) => Uint8List.fromList(image.bytes);
}
