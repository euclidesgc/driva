import 'package:bloc/bloc.dart';
import 'package:driva_demo_app/core/error/error.dart';
import 'package:driva_demo_app/modules/published_module/domain/entities/entities.dart';
import 'package:driva_demo_app/modules/published_module/domain/use_cases/use_cases.dart';
import 'package:equatable/equatable.dart';

part 'catalog_state.dart';

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit({required this.getPublishedContents})
    : super(const CatalogLoading());

  final GetPublishedContentsUseCase getPublishedContents;

  Future<void> load() async {
    emit(const CatalogLoading());
    final result = await getPublishedContents();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => CatalogError(failure: failure),
        (items) =>
            items.isEmpty ? const CatalogEmpty() : CatalogLoaded(items: items),
      ),
    );
  }
}
