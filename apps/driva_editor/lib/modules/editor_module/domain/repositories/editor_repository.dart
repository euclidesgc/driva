import 'package:fpdart/fpdart.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../../../core/error/error.dart';

abstract interface class EditorRepository {
  Future<Either<Failure, ContentSpec>> loadContent(String id);

  Future<Either<Failure, Unit>> saveDraft(ContentSpec content);
}
