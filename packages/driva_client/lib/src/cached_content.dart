import 'package:equatable/equatable.dart';

class CachedContent extends Equatable {
  const CachedContent({
    required this.specJson,
    required this.etag,
    required this.fetchedAt,
  });

  factory CachedContent.fromJson(Map<String, dynamic> json) {
    return CachedContent(
      specJson: Map<String, dynamic>.from(json['specJson'] as Map),
      etag: json['etag'] as String?,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  final Map<String, dynamic> specJson;
  final String? etag;
  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
    'specJson': specJson,
    'etag': etag,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [specJson, etag, fetchedAt];
}
