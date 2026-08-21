import 'package:driva_editor/modules/editor_module/presentation/editor/cubit/version_compare_mode_cubit.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/page/version_compare_mode_scope.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/version_compare_node_lookup.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sdui_core/sdui_core.dart';

/// Decide, campo a campo, se o Inspector oferece "trazer o valor desta
/// versão" — de propósito fora do `InspectorVm` (mesma razão do
/// `InspectorCompareSection`): o dado de comparação não tem `==`
/// escrito à mão, então mora num `BlocSelector` escopado ao par
/// (nodeId, field.key), reconstruindo só este campo quando a candidata muda.
class PropFieldCompareBinding extends StatelessWidget {
  const PropFieldCompareBinding({
    required this.ownerKey,
    required this.nodeId,
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String ownerKey;

  /// `null` fora do modo nó (safe area/página): não há nó correspondente na
  /// candidata para comparar.
  final String? nodeId;

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final nodeId = this.nodeId;
    final compareCubit = nodeId == null
        ? null
        : VersionCompareModeScope.of(context);

    if (compareCubit == null || nodeId == null) {
      return PropFieldEditor(
        key: ValueKey('${ownerKey}_${field.key}'),
        field: field,
        value: value,
        onChanged: onChanged,
      );
    }

    return BlocSelector<
      VersionCompareModeCubit,
      VersionCompareModeState,
      _Copyable
    >(
      bloc: compareCubit,
      selector: (state) =>
          _copyableFrom(state, nodeId: nodeId, propertyKey: field.key),
      builder: (context, copyable) => PropFieldEditor(
        key: ValueKey('${ownerKey}_${field.key}'),
        field: field,
        value: value,
        onChanged: onChanged,
        onCopyFromVersion: copyable.canCopy
            ? () => compareCubit.editorCubit.copyPropertyFromVersion(
                nodeId,
                field.key,
                copyable.candidateValue,
              )
            : null,
      ),
    );
  }
}

typedef _Copyable = ({bool canCopy, Object? candidateValue});

const _Copyable _notCopyable = (canCopy: false, candidateValue: null);

_Copyable _copyableFrom(
  VersionCompareModeState state, {
  required String nodeId,
  required String propertyKey,
}) {
  if (state is! VersionCompareModeActive) return _notCopyable;

  final baseNode = nodeById(state.baseSpec.root, nodeId);
  final candidateNode = nodeById(state.candidate.spec.root, nodeId);
  if (baseNode == null || candidateNode == null) return _notCopyable;
  if (baseNode.type != candidateNode.type) return _notCopyable;
  if (!changedPropertyKeys(baseNode, candidateNode).contains(propertyKey)) {
    return _notCopyable;
  }

  return (canCopy: true, candidateValue: candidateNode.properties[propertyKey]);
}
