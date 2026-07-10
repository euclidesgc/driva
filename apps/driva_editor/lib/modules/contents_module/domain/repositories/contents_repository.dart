import 'package:fpdart/fpdart.dart';

import '../../../../core/error/error.dart';
import '../entities/content_sort.dart';
import '../entities/content_summary.dart';
import '../entities/contents_page.dart';

/// Contrato da listagem/CRUD de conteúdos. O erro previsto mora na assinatura.
abstract interface class ContentsRepository {
  /// Filtro de leitura por nó exato (sem herança de subcategorias), busca por
  /// `name` (`query`), ordenação (`sort`/`order`) e paginação por cursor
  /// opaco (`cursor`/`limit`). A ordenação é sempre do servidor — nada é
  /// reordenado no cliente.
  Future<Either<Failure, ContentsPage>> getContents({
    String? categoryId,
    String? query,
    ContentSort sort = ContentSort.updatedAt,
    ContentSortOrder order = ContentSortOrder.desc,
    String? cursor,
    int limit = 20,
  });

  Future<Either<Failure, ContentSummary>> createContent({
    required String name,
    required String slug,
    String? description,
    String? categoryId,
  });

  /// Atualiza só os campos enviados. `categoryId` presente **move** o
  /// conteúdo para outra categoria; ausente preserva a categoria atual
  /// (contrato do `PUT`, ver `prd.md`).
  Future<Either<Failure, ContentSummary>> updateContent(
    String id, {
    String? name,
    String? slug,
    String? description,
    String? categoryId,
  });

  Future<Either<Failure, Unit>> deleteContent(String id);
}
