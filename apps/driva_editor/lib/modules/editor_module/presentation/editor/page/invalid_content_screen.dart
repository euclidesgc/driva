import 'package:flutter/material.dart';

/// id malformado na URL: fallback tratado, nunca crash.
class InvalidContentScreen extends StatelessWidget {
  const InvalidContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Conteúdo inválido.')));
  }
}
