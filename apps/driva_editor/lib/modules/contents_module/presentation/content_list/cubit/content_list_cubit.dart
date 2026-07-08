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

  /// Cria e devolve o resultado. No sucesso, não emite estado nem recarrega a
  /// lista: a UI navega direto para o editor do conteúdo criado (sem flash de
  /// loading). No conflito de slug e demais falhas, a UI trata pelo `Left`.
  Future<Either<Failure, ContentSummary>> create({
    required String name,
    required String slug,
    String? description,
  }) async {
    return createContent(name: name, slug: slug, description: description);
  }

  /// Exclusão otimista: remove o card na hora sobre o `Loaded` atual (vira
  /// `Empty` ao esvaziar) e devolve o resultado. Em falha, reconcilia com
  /// `load()` (restaura a verdade do servidor) e devolve o `Left` para a UI
  /// avisar via snackbar. Sem spinner full-screen no caminho de sucesso.
  Future<Either<Failure, Unit>> delete(String id) async {
    final current = state;
    if (current is ContentListLoaded) {
      final remaining = current.contents.where((c) => c.id != id).toList();
      emit(
        remaining.isEmpty
            ? const ContentListEmpty()
            : ContentListLoaded(contents: remaining),
      );
    }
    final result = await deleteContent(id);
    if (isClosed) return result;
    if (result.isLeft()) await load();
    return result;
  }
}
