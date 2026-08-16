import 'package:flutter/material.dart';

class InvalidPreviewScreen extends StatelessWidget {
  const InvalidPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Link de preview inválido.')),
    );
  }
}
