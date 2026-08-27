# driva_client

Runtime do driva para apps Flutter. Busca no servidor a tela que alguém publicou
no editor, guarda em cache, revalida sozinho e desenha com o renderer
(`sdui_flutter`).

Do lado do seu app são duas linhas: `Driva.init` uma vez, no `main`, e um
`DrivaContent(slug: ...)` onde a tela deve aparecer.

## Exemplo mínimo

```dart
import 'package:driva_client/driva_client.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Driva.init(
    DrivaConfig(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      publishableKey: const String.fromEnvironment('PUBLISHABLE_KEY'),
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Minha home')),
        body: DrivaContent(
          slug: 'home',
          loadingBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error) =>
              const Center(child: Text('Não foi possível carregar esta tela.')),
        ),
      ),
    );
  }
}
```

Rodando, com a configuração vindo de um arquivo de ambiente:

```bash
flutter run --dart-define-from-file=config/dev.json
```

```json
{
  "API_BASE_URL": "https://<sua-api>",
  "PUBLISHABLE_KEY": "cole-aqui-a-chave-do-projeto"
}
```

A `PUBLISHABLE_KEY` é a chave publicável do projeto: ela só lê conteúdo
**publicado**, nunca escreve e nunca vê rascunho — por isso pode viajar no
binário. Ainda assim ela é **por ambiente** e não entra no repositório; o
arquivo versionado leva um placeholder.

## O que o package garante

- **Resolve em três degraus — memória → disco → rede.** Da segunda abertura em
  diante a tela aparece na hora, e a revalidação acontece em background
  (*stale-while-revalidate*, com `ETag`/`304`).
- **Nunca derruba a tela do seu app.** Se tudo falhar, a ordem é fallback
  embarcado → `errorBuilder` → nada, com log. Quem usa `DrivaContent` não vê
  exceção nenhuma subir.
- **Quando falha, diz por quê.** O objeto entregue ao `errorBuilder` é um
  `DrivaLoadFailure` com `slug` e `cause` (`network`, `notFound`, `invalidSpec`,
  `serverError`) — dá para dizer "esta tela não existe" em vez de "sem conexão".
  ⚠️ **Se você consome `Driva.instance.repository.load(slug)` direto**, em vez do
  widget, saiba que desde a `0.2.0` esse `Stream` **fecha pelo canal de erro**
  com `DrivaLoadFailure` quando nada pôde ser servido (antes ele completava em
  silêncio): trate o `onError`, senão vira erro assíncrono não capturado.
- **Só desenha spec validado pelo kernel.** JSON corrompido ou `specVersion`
  mais nova que a do app é tratado como falha de parse, não como conteúdo.

## O que ainda não funciona

- **Ações são inertes.** O editor ainda não deixa autorar eventos, então o
  `onAction` nunca é chamado — um botão publicado hoje não faz nada.
- **Binding não resolve.** `{{user.name}}` chega ao usuário final como texto
  literal.
- **Flutter Web de terceiro não é suportado** nesta fatia. O alvo é app Flutter
  nativo, mobile e desktop.

## Guia completo

O passo a passo, os campos do `DrivaConfig`, o comportamento offline caso a
caso, como embarcar um fallback e o que fazer quando o servidor publica um
`specVersion` mais novo que o app da loja:

**[`docs/25-entrega-app-cliente/integracao.md`](../../docs/25-entrega-app-cliente/integracao.md)**
