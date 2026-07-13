/// Campo de ordenação da listagem de conteúdos — espelha o enum aceito por
/// `GET /v1/contents` (`sort`).
enum ContentSort { updatedAt, createdAt, name }

/// Direção da ordenação — espelha o enum aceito por `GET /v1/contents`
/// (`order`).
enum ContentSortOrder { asc, desc }
