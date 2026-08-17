import 'package:equatable/equatable.dart';

class PublicationState extends Equatable {
  const PublicationState({
    required this.hasUnpublishedChanges,
    this.publishedVersion,
    this.publishedAt,
  });

  final int? publishedVersion;
  final DateTime? publishedAt;
  final bool hasUnpublishedChanges;

  bool get isPublished => publishedVersion != null;

  PublicationState copyWith({
    int? publishedVersion,
    DateTime? publishedAt,
    bool? hasUnpublishedChanges,
  }) {
    return PublicationState(
      publishedVersion: publishedVersion ?? this.publishedVersion,
      publishedAt: publishedAt ?? this.publishedAt,
      hasUnpublishedChanges:
          hasUnpublishedChanges ?? this.hasUnpublishedChanges,
    );
  }

  @override
  List<Object?> get props => [
    publishedVersion,
    publishedAt,
    hasUnpublishedChanges,
  ];
}
