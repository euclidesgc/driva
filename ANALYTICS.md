# Analytics

> O que cada módulo envia para analytics: evento, quando dispara, o que carrega.

## Conteúdos (contents_module, editor_module)

**Nenhum evento de analytics é enviado.** Decisão registrada no PRD: instrumentação de produto fica para quando houver usuários além do time (junto do workflow de publicação/serving). O rename página → conteúdo **não** adicionou eventos.

Quando entrar, os candidatos naturais são: conteúdo criado, colisão de slug resolvida (`suggestedSlug`), bloco adicionado (por tipo), conteúdo salvo, publicação.
