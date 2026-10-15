import 'package:equatable/equatable.dart';

class CachedContent extends Equatable {
  const CachedContent({
    required this.specJson,
    required this.etag,
    required this.fetchedAt,
    this.themeJson,
  });

  factory CachedContent.fromJson(Map<String, dynamic> json) {
    final themeJson = json['themeJson'];
    return CachedContent(
      specJson: Map<String, dynamic>.from(json['specJson'] as Map),
      etag: json['etag'] as String?,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      themeJson: themeJson is Map ? Map<String, dynamic>.from(themeJson) : null,
    );
  }

  final Map<String, dynamic> specJson;
  final String? etag;
  final DateTime fetchedAt;
  final Map<String, dynamic>? themeJson;

  Map<String, dynamic> toJson() => {
    'specJson': specJson,
    'etag': etag,
    'fetchedAt': fetchedAt.toIso8601String(),
    'themeJson': themeJson,
  };

  @override
  List<Object?> get props => [specJson, etag, fetchedAt, themeJson];
}
