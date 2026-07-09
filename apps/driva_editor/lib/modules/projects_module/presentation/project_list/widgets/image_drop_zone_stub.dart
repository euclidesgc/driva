import 'package:flutter/foundation.dart' show ValueChanged;

import '../../../domain/entities/entities.dart';

/// Fallback não-web (VM: `flutter analyze`/`flutter test` rodam aqui).
///
/// Nunca ouve nada de verdade — o app é Flutter Web only — mas precisa
/// existir fora do alvo web para o VM test runner conseguir carregar
/// qualquer arquivo que importe este módulo transitivamente (ver
/// `image_drop_zone.dart`).
class ImageDropZoneImpl {
  ImageDropZoneImpl({required this.onHover, required this.onFile});

  final ValueChanged<bool> onHover;
  final ValueChanged<ProjectImageInput> onFile;

  void dispose() {}
}
