import 'package:sdui_core/src/catalog/widget_catalog.dart';
import 'package:sdui_core/src/diagnostics/spec_diagnostic.dart';
import 'package:sdui_core/src/model/sdui_node.dart';

/// Únicos tipos cujo builder distribui os filhos num `Flex` — logo, os únicos
/// lugares onde `expanded`/`spacer` têm efeito.
const Set<String> _flexParentTypes = {'row', 'column'};

const Set<String> _flexOnlyTypes = {'expanded', 'spacer'};

/// Slot único cujo widget é puro embrulho: sem filho, não sobra nada na tela.
const Set<String> _wrapperTypes = {'expanded', 'padding', 'center'};

List<SpecDiagnostic> diagnoseTree(SduiNode? root) {
  if (root == null) return const [];
  final found = <SpecDiagnostic>[];
  _visit(root, parentType: null, into: found);
  return List.unmodifiable(found);
}

void _visit(
  SduiNode node, {
  required String? parentType,
  required List<SpecDiagnostic> into,
}) {
  final label = descriptorFor(node.type)?.label ?? node.type;

  if (_flexOnlyTypes.contains(node.type) &&
      !_flexParentTypes.contains(parentType)) {
    into.add(
      SpecDiagnostic(
        nodeId: node.id,
        nodeType: node.type,
        code: DiagnosticCode.flexOnlyOutsideFlex,
        severity: DiagnosticSeverity.error,
        message:
            '$label só funciona dentro de uma Row ou Column. '
            'Fora delas o renderer o ignora.',
      ),
    );
  }

  if (_wrapperTypes.contains(node.type) && node.child == null) {
    into.add(
      SpecDiagnostic(
        nodeId: node.id,
        nodeType: node.type,
        code: DiagnosticCode.emptySingleSlot,
        severity: DiagnosticSeverity.warning,
        message: '$label está sem filho e não desenha nada.',
      ),
    );
  }

  final child = node.child;
  if (child != null) _visit(child, parentType: node.type, into: into);
  for (final each in node.children) {
    _visit(each, parentType: node.type, into: into);
  }
}
