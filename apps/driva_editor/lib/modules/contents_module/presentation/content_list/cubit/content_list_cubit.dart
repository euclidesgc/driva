import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../../core/error/error.dart';
import '../../../domain/entities/content_sort.dart';
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

  /// Ordenação corrente — sempre do servidor (`GET /v1/contents` `sort`/`order`).
  /// Default: mais recentes primeiro (`updatedAt` desc), como a home.
  ContentSort _sort;
  ContentSortOrder _order;

  ContentListCubit({
    required this.getContents,
    required this.createContent,
    required this.deleteContent,
    String? categoryId,
    String? query,
    ContentSort sort = ContentSort.updatedAt,
    ContentSortOrder order = ContentSortOrder.desc,
  }) : _categoryId = categoryId,
       _query = query,
       _sort = sort,
       _order = order,
       super(const ContentListLoading());

  /// Ordenação corrente — a UI reflete estes valores no controle de ordenação.
  ContentSort get currentSort => _sort;
  ContentSortOrder get currentOrder => _order;

  // TODO(P16): paginação infinita (usar `page.nextCursor`); por ora carrega
  // só a primeira página do filtro/busca correntes.
  Future<void> load() async {
    emit(const ContentListLoading());
    final result = await getContents(
      categoryId: _categoryId,
      query: _query,
      sort: _sort,
      order: _order,
    );
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

  /// Troca a ordenação (campo e/ou direção) e recarrega da primeira página.
  /// Preserva o filtro por categoria e a busca correntes.
  Future<void> changeSort({ContentSort? sort, ContentSortOrder? order}) {
    if (sort != null) _sort = sort;
    if (order != null) _order = order;
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
