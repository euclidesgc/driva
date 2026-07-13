import 'image_drop_zone_stub.dart'
    if (dart.library.js_interop) 'image_drop_zone_web.dart';

/// Fachada pública: seleciona a implementação certa via import condicional
/// (`ImageDropZoneImpl`, web de verdade fora do VM/`flutter test`; stub caso
/// contrário).
class WebImageDropZone extends ImageDropZoneImpl {
  WebImageDropZone({required super.onHover, required super.onFile});
}
