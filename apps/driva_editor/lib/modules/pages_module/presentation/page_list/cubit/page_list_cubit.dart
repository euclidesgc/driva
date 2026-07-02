import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/error/error.dart';
import '../../../domain/entities/page_summary.dart';
import '../../../domain/use_cases/use_cases.dart';

part 'page_list_state.dart';

class PageListCubit extends Cubit<PageListState> {
  final GetPagesUseCase getPages;
  final CreatePageUseCase createPage;
  final DeletePageUseCase deletePage;

  PageListCubit({
    required this.getPages,
    required this.createPage,
    required this.deletePage,
  }) : super(const PageListLoading());

  Future<void> load() async {
    emit(const PageListLoading());
    final result = await getPages();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => PageListError(failure: failure),
        (pages) => pages.isEmpty
            ? const PageListEmpty()
            : PageListLoaded(pages: pages),
      ),
    );
  }

  /// Cria e recarrega. Devolve o resultado para a UI decidir a navegação
  /// (ir direto para o editor da página criada).
  Future<Either<Failure, PageSummary>> create({
    required String name,
    required String screenTarget,
  }) async {
    final result = await createPage(name: name, screenTarget: screenTarget);
    if (!isClosed && result.isRight()) await load();
    return result;
  }

  Future<void> delete(String id) async {
    final result = await deletePage(id);
    if (isClosed) return;
    // Erro ao excluir não derruba a lista: recarrega e a UI avisa via estado
    // atual (a página some ou permanece).
    result.fold((_) {}, (_) {});
    await load();
  }
}
