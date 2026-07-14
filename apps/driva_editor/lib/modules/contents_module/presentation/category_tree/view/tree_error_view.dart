import 'package:flutter/material.dart';

class TreeErrorView extends StatelessWidget {
  const TreeErrorView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final Object failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar as categorias.'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
