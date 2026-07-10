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

  /// Filtro/busca correntes — usados por [load] e reaplicados por
  /// [reloadWithFilter], que a tela do projeto chama ao trocar de categoria
  /// selecionada ou digitar na busca.
  String? _categoryId;
  String? _query;

  ContentListCubit({
    required this.getContents,
    required this.createContent,
    required this.deleteContent,
    String? categoryId,
    String? query,
  }) : _categoryId = categoryId,
       _query = query,
       super(const ContentListLoading());

  // TODO(P16): paginação infinita (usar `page.nextCursor`); por ora carrega
  // só a primeira página do filtro/busca correntes.
  Future<void> load() async {
    emit(const ContentListLoading());
    final result = await getContents(categoryId: _categoryId, query: _query);
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => ContentListError(failure: failure),
        (page) => page.items.isEmpty
            ? const ContentListEmpty()
            : ContentListLoaded(contents: page.items),
      ),
    );
  }

  /// Troca o filtro por categoria e/ou a busca e recarrega. `categoryId:
  /// () => null` limpa o filtro (mostra todas as categorias); ausente
  /// preserva o filtro atual. Usada pela tela do projeto ao selecionar um nó
  /// da árvore ou digitar na busca (com debounce).
  Future<void> reloadWithFilter({
    String? Function()? categoryId,
    String? query,
  }) {
    if (categoryId != null) _categoryId = categoryId();
    _query = query;
    return load();
  }

  /// Cria e devolve o resultado. No sucesso, não emite estado nem recarrega a
  /// lista: a UI navega direto para o editor do conteúdo criado (sem flash de
  /// loading). No conflito de slug e demais falhas, a UI trata pelo `Left`.
  Future<Either<Failure, ContentSummary>> create({
    required String name,
    required String slug,
    String? description,
    String? categoryId,
  }) async {
    return createContent(
      name: name,
      slug: slug,
      description: description,
      categoryId: categoryId,
    );
  }

  /// Categoria atualmente filtrada (nó selecionado na árvore) — usada pela
  /// tela do projeto como default do formulário de "novo conteúdo".
  String? get currentCategoryId => _categoryId;

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
