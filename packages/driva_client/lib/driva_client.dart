/// Runtime do driva para apps de terceiro consumirem specs SDUI publicados:
/// `Driva.init(DrivaConfig(...))` uma vez, depois `DrivaContent(slug: ...)`
/// resolve memória → disco → rede, revalida em background e nunca derruba a
/// tela do app hospedeiro — falha total cai no fallback embarcado, depois no
/// `errorBuilder`, depois em um espaço vazio com log.
library;

export 'src/cache/driva_cache_store.dart';
export 'src/cache/memory_cache_store.dart';
export 'src/cache/prefs_cache_store.dart';
export 'src/cached_content.dart';
export 'src/content_repository.dart';
export 'src/driva.dart';
export 'src/driva_config.dart';
export 'src/driva_content.dart';
