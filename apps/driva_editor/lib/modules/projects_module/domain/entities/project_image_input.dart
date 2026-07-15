import 'package:equatable/equatable.dart';

class ProjectImageInput extends Equatable {
  const ProjectImageInput({
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  final List<int> bytes;
  final String filename;

  final String? contentType;

  @override
  List<Object?> get props => [bytes, filename, contentType];
}
