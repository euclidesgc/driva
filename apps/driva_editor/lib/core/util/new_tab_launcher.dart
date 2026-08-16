import 'package:driva_editor/core/util/new_tab_launcher_stub.dart'
    if (dart.library.js_interop) 'new_tab_launcher_web.dart';

/// Fachada pública: seleciona a implementação certa via import condicional
/// (`NewTabLauncherImpl`, web de verdade fora do VM/`flutter test`; stub caso
/// contrário). Chame como `const NewTabLauncher()`.
class NewTabLauncher extends NewTabLauncherImpl {
  const NewTabLauncher();
}
