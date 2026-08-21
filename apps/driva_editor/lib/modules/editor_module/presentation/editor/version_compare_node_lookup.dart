import 'package:sdui_core/sdui_core.dart';

SduiNode? nodeById(SduiNode? root, String id) =>
    root == null ? null : findNode(root, id);
