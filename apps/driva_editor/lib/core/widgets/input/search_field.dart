import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    required this.hintText,
    required this.onChanged,
    this.semanticsLabel,
    super.key,
  });

  static const _iconSize = 18.0;

  final String hintText;
  final ValueChanged<String> onChanged;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticsLabel ?? hintText,
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, size: _iconSize),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
