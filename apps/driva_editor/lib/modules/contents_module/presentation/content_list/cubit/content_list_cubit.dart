import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/error/error.dart';
import '../../../domain/entities/content_summary.dart';
import '../../../domain/use_cases/use_cases.dart';

part 'content_list_state.dart';

class ContentListCubit extends Cubit<ContentListState> {
  final GetContentsUseCase getContents;
  final CreateContentUseCase createContent;
  final DeleteContentUseCase deleteContent;

  ContentListCubit({
    required this.getContents,
    required this.createContent,
    required this.deleteContent,
  }) : super(const ContentListLoading());

  Future<void> load() async {
    emit(const ContentListLoading());
    final result = await getContents();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => ContentListError(failure: failure),
        (contents) => contents.isEmpty
            ? const ContentListEmpty()
            : ContentListLoaded(contents: contents),
      ),
    );
  }

  /// Cria e recarrega. Devolve o resultado para a UI decidir a navegação
  /// (ir direto para o editor do conteúdo criado) e tratar `ConflictFailure`.
  Future<Either<Failure, ContentSummary>> create({
    required String name,
    required String slug,
    String? description,
  }) async {
    final result = await createContent(
      name: name,
      slug: slug,
      description: description,
    );
    if (!isClosed && result.isRight()) await load();
    return result;
  }

  Future<void> delete(String id) async {
    final result = await deleteContent(id);
    if (isClosed) return;
    // Erro ao excluir não derruba a lista: recarrega e a UI avisa via estado
    // atual (o conteúdo some ou permanece).
    result.fold((_) {}, (_) {});
    await load();
  }
}
