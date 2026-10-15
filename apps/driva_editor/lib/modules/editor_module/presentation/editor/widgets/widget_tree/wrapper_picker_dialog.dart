import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

class WrapperPickerDialog extends StatefulWidget {
  const WrapperPickerDialog({
    required this.title,
    required this.types,
    required this.confirmLabel,
    super.key,
  });

  final String title;
  final List<String> types;
  final String confirmLabel;

  static List<String> get wrapperTypes => [
    for (final entry in widgetCatalog.entries)
      if (entry.value.slot == SlotKind.multi) entry.key,
  ];

  static List<String> get allTypes => widgetCatalog.keys.toList();

  @override
  State<WrapperPickerDialog> createState() => _WrapperPickerDialogState();
}

class _WrapperPickerDialogState extends State<WrapperPickerDialog> {
  late String _selected = widget.types.first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final type in widget.types)
              ListTile(
                key: ValueKey('picker-$type'),
                dense: true,
                selected: type == _selected,
                title: Text(descriptorFor(type)?.label ?? type),
                trailing: type == _selected ? const Icon(Icons.check) : null,
                onTap: () => setState(() => _selected = type),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
