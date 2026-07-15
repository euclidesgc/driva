import 'package:flutter/material.dart';

/// Banner de mensagem (aviso/erro): ícone + texto, para a cor não ser o único
/// sinal. O [semanticsPrefix] rotula a natureza da mensagem para leitores de
/// tela ("Aviso: ..." / "Erro: ...").
class MessageBanner extends StatelessWidget {
  const MessageBanner({
    super.key,
    required this.message,
    this.semanticsPrefix = 'Aviso',
  });

  final String message;
  final String semanticsPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: '$semanticsPrefix: $message',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
