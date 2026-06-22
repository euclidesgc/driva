# flutter/

Lado Flutter, isolado do workspace pnpm (toolchain própria, workspace pub).

- **sdui_flutter/** — renderer real: models `freezed` espelhando o Zod, registry `type → builder`, dispatcher de ações. Renderer puro (sem deps internas). *(M1)*
- **sdui_preview/** — app Flutter Web mínimo: embarca `sdui_flutter` e a bridge `postMessage` para o editor. *(M1)*

A paridade com o kernel Zod é garantida por **testes golden** que consomem `packages/spec/fixtures`.
