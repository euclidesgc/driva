import 'package:driva_client/src/cached_content.dart';
import 'package:driva_client/src/driva_load_failure.dart';
import 'package:sdui_core/sdui_core.dart';

typedef FetchEntry = ({ContentSpec spec, CachedContent cached});

/// Resultado interno de uma tentativa de busca na rede — preserva a causa
/// de falha em vez de colapsar tudo em `null`. Interno ao package: não é
/// exportado pelo barrel.
sealed class FetchOutcome {
  const FetchOutcome();
}

class FetchOk extends FetchOutcome {
  const FetchOk(this.entry);
  final FetchEntry entry;
}

/// 304: o cache já servido continua válido. Não é sucesso (nada novo para
/// gravar) nem falha (o servidor respondeu normalmente).
class FetchNotModified extends FetchOutcome {
  const FetchNotModified();
}

class FetchFailed extends FetchOutcome {
  const FetchFailed(this.cause);
  final DrivaLoadCause cause;
}
