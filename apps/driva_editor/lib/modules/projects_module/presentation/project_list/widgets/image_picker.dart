import 'package:driva_editor/modules/projects_module/presentation/project_list/widgets/image_picker_stub.dart'
    if (dart.library.js_interop) 'image_picker_web.dart';

/// Fachada pública: seleciona a implementação certa via import condicional
/// (`ImagePickerImpl`, web de verdade fora do VM/`flutter test`; stub caso
/// contrário). Chame como `const WebImagePicker()`.
class WebImagePicker extends ImagePickerImpl {
  const WebImagePicker();
}
