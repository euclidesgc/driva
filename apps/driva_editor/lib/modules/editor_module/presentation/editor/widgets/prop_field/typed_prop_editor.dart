import 'package:driva_editor/core/theme/prop_icons.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/alignment_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/bool_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/color_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/edge_insets_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/enum_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/enum_icon_group_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/icon_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/number_editor.dart';
import 'package:driva_editor/modules/editor_module/presentation/editor/widgets/prop_field/string_editor.dart';
import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

/// O despacho `FieldKind` → editor. Novo tipo de propriedade = novo caso aqui
/// e mais nada: o Inspector não sabe de tipo.
class TypedPropEditor extends StatelessWidget {
  const TypedPropEditor({
    required this.field,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropField field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  /// Enum só vira grupo de ícones quando **toda** option resolve um ícone —
  /// meia paleta de ícones e meia de rótulos seria pior que o dropdown.
  bool get _rendersAsIconGroup =>
      field.kind == FieldKind.enumeration &&
      field.options.isNotEmpty &&
      field.options.every((option) => PropIcons.has(option.iconName));

  @override
  Widget build(BuildContext context) => switch (field.kind) {
    FieldKind.string => StringEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
    FieldKind.doubleNum => NumberEditor(
      field: field,
      value: value,
      onChanged: onChanged,
      isInt: false,
    ),
    FieldKind.intNum => NumberEditor(
      field: field,
      value: value,
      onChanged: onChanged,
      isInt: true,
    ),
    FieldKind.boolean => BoolEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
    FieldKind.color => ColorEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
    FieldKind.enumeration when _rendersAsIconGroup => EnumIconGroupEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
    FieldKind.enumeration => EnumEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
    FieldKind.edgeInsets => EdgeInsetsEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
    FieldKind.alignment => AlignmentEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
    FieldKind.iconName => IconEditor(
      field: field,
      value: value,
      onChanged: onChanged,
    ),
  };
}
