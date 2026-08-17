import 'package:equatable/equatable.dart';

class ContentVersion extends Equatable {
  const ContentVersion({
    required this.version,
    required this.createdAt,
    this.note,
    this.createdBy,
  });

  final int version;
  final DateTime createdAt;
  final String? note;
  final String? createdBy;

  @override
  List<Object?> get props => [version, createdAt, note, createdBy];
}
