import 'package:driva_editor/core/error/error.dart';
import 'package:driva_editor/modules/editor_module/domain/entities/entities.dart';
import 'package:driva_editor/modules/editor_module/domain/repositories/editor_repository.dart';
import 'package:fpdart/fpdart.dart';

class PublishContentUseCase {
  const PublishContentUseCase({required this.repository});
  final EditorRepository repository;

  Future<Either<Failure, PublicationState>> call(String id, {String? note}) =>
      repository.publish(id, note: note);
}
