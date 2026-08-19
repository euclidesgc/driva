import 'package:equatable/equatable.dart';

class PublicationState extends Equatable {
  const PublicationState({
    required this.hasUnpublishedChanges,
    this.publishedVersion,
    this.publishedAt,
    this.latestVersion,
  });

  final int? publishedVersion;
  final DateTime? publishedAt;
  final bool hasUnpublishedChanges;

  /// Maior versão já criada, mesmo que nenhuma esteja no ar agora.
  /// `null` = nunca publicado nem uma vez.
  final int? latestVersion;

  bool get isPublished => publishedVersion != null;

  bool get everPublished => latestVersion != null;

  PublicationState copyWith({
    int? publishedVersion,
    DateTime? publishedAt,
    bool? hasUnpublishedChanges,
    int? latestVersion,
  }) {
    return PublicationState(
      publishedVersion: publishedVersion ?? this.publishedVersion,
      publishedAt: publishedAt ?? this.publishedAt,
      hasUnpublishedChanges:
          hasUnpublishedChanges ?? this.hasUnpublishedChanges,
      latestVersion: latestVersion ?? this.latestVersion,
    );
  }

  @override
  List<Object?> get props => [
    publishedVersion,
    publishedAt,
    hasUnpublishedChanges,
    latestVersion,
  ];
}
