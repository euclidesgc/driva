part of 'catalog_cubit.dart';

sealed class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => [];
}

final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

final class CatalogEmpty extends CatalogState {
  const CatalogEmpty();
}

final class CatalogLoaded extends CatalogState {
  const CatalogLoaded({required this.items});

  final List<PublishedSummary> items;

  @override
  List<Object?> get props => [items];
}

final class CatalogError extends CatalogState {
  const CatalogError({required this.failure});

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
