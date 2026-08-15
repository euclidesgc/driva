import 'package:sdui_core/sdui_core.dart';

class NodeDiagnosticsSummary {
  const NodeDiagnosticsSummary({required this.severity, required this.message});

  final DiagnosticSeverity severity;
  final String message;
}

/// Assume [diagnostics] não vazio — quem chama já filtrou pelo `nodeId`.
NodeDiagnosticsSummary summarizeDiagnostics(List<SpecDiagnostic> diagnostics) {
  final severity =
      diagnostics.any(
        (each) => each.severity == DiagnosticSeverity.error,
      )
      ? DiagnosticSeverity.error
      : DiagnosticSeverity.warning;
  return NodeDiagnosticsSummary(
    severity: severity,
    message: diagnostics.map((each) => each.message).join('\n'),
  );
}

/// Agrupa uma vez por leitura do estado — nunca por linha da árvore nem por
/// nó do canvas, que multiplicaria `diagnoseTree` por N.
Map<String, List<SpecDiagnostic>> diagnosticsByNode(
  List<SpecDiagnostic> diagnostics,
) {
  final grouped = <String, List<SpecDiagnostic>>{};
  for (final diagnostic in diagnostics) {
    grouped.putIfAbsent(diagnostic.nodeId, () => []).add(diagnostic);
  }
  return grouped;
}
