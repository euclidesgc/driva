import 'package:driva_editor/core/error/error.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

abstract interface class EditorRepository {
  Future<Either<Failure, ContentSpec>> loadContent(String id);

  Future<Either<Failure, Unit>> saveDraft(ContentSpec content);
}
