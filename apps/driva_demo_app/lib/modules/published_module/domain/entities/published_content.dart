import 'package:equatable/equatable.dart';
import 'package:sdui_core/sdui_core.dart';

class PublishedContent extends Equatable {
  const PublishedContent({
    required this.spec,
    required this.updatedAt,
    required this.etag,
  });

  final ContentSpec spec;
  final DateTime updatedAt;

  /// Validador de cache devolvido pela API. É o que o SDK usará para
  /// revalidar sem baixar o spec de novo.
  final String? etag;

  @override
  List<Object?> get props => [spec, updatedAt, etag];
}
