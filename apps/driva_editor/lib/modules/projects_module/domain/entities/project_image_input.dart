import 'package:equatable/equatable.dart';

/// Entrada de imagem para criar/atualizar um projeto, modelada de forma
/// **agnóstica de Flutter/dart:io**: domain é Dart puro, então a imagem
/// trafega como bytes crus + metadados — nunca como `File`/`XFile`/
/// `MultipartFile`. A camada `data` é quem monta o multipart a partir daqui.
class ProjectImageInput extends Equatable {
  const ProjectImageInput({
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  final List<int> bytes;
  final String filename;

  /// MIME type opcional (ex.: `image/png`); quando ausente, a camada data
  /// pode inferir a partir da extensão do `filename` ou deixar o backend
  /// detectar por magic bytes (pipeline do CISO).
  final String? contentType;

  @override
  List<Object?> get props => [bytes, filename, contentType];
}
