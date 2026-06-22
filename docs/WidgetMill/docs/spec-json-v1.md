# WidgetMill — Spec JSON v1 (Referência de Primitivos)

> Contrato central do produto. Define, primitivo a primitivo, as props expostas e seus tipos/enums, espelhando a API oficial do Flutter. Deste documento derivam: os forms do Inspector (web), a validação (Zod no backend), os models (`freezed` no Flutter) e o registry do renderer.
>
> Base: Flutter estável (inclui `spacing` em Row/Column, GA no Flutter 3.27).

---

## 1. Convenções gerais

### 1.1 Estrutura de um nó

```jsonc
{
  "type": "container",     // identificador do primitivo
  "props": { },            // props do primitivo (ver tabelas)
  "events": { },           // opcional: eventos → lista de ações
  "child":  { },           // primitivos de 1 filho
  "children": [ ]          // primitivos de N filhos
}
```

### 1.2 Tipos de prop

| Tipo | Representação JSON | Exemplo |
|---|---|---|
| `string` | string | `"Olá"` |
| `int` | número inteiro | `3` |
| `double` | número | `16.0` |
| `bool` | booleano | `true` |
| `color` | hex `#RRGGBB` ou `#AARRGGBB` | `"#FF1565C0"` |
| `enum` | string (valor do enum) | `"center"` |
| `edgeInsets` | objeto (ver §3.1) | `{ "all": 16 }` |
| `borderRadius` | número (uniforme) ou objeto | `8` ou `{ "topLeft": 8 }` |
| `textStyle` | objeto (ver §3.2) | `{ "fontSize": 16 }` |
| `boxDecoration` | objeto (ver §3.3) | `{ "color": "#FFF" }` |
| `action` / `actionList` | objeto / array (ver §4) | `[ { "type": "navigate" } ]` |
| `child` / `children` | nó / array de nós | — |

### 1.3 Binding

Qualquer valor de prop pode ser uma referência a uma prop pública via `"{{chave}}"`. Resolvido em runtime contra o `propsSchema` do widget.

---

## 2. Primitivos

Defaults seguem o Flutter quando aplicável. `—` = sem default (opcional/nulo).

### 2.1 Container

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `width` | double | — | — |
| `height` | double | — | — |
| `padding` | edgeInsets | — | — |
| `margin` | edgeInsets | — | — |
| `color` | color | — | — (não usar junto com `decoration`) |
| `alignment` | enum (Alignment) | ver §3.4 | — |
| `decoration` | boxDecoration | ver §3.3 | — |
| `constraints.minWidth/maxWidth/minHeight/maxHeight` | double | — | — |
| `child` | child | — | — |

> Regra do Flutter: `color` e `decoration` são mutuamente exclusivos. No Inspector, se o usuário define `decoration.color`, esconder `color`.

### 2.2 Column / 2.3 Row

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `mainAxisAlignment` | enum (MainAxisAlignment) | `start, end, center, spaceBetween, spaceAround, spaceEvenly` | `start` |
| `crossAxisAlignment` | enum (CrossAxisAlignment) | `start, end, center, stretch, baseline` | `center` |
| `mainAxisSize` | enum (MainAxisSize) | `min, max` | `max` |
| `spacing` | double | — | `0.0` |
| `textBaseline` | enum (TextBaseline) | `alphabetic, ideographic` | — (req. se crossAxis=baseline) |
| `children` | children | — | `[]` |

### 2.4 Stack

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `alignment` | enum (AlignmentDirectional) | ver §3.4 | `topStart` |
| `fit` | enum (StackFit) | `loose, expand, passthrough` | `loose` |
| `clipBehavior` | enum (Clip) | `none, hardEdge, antiAlias, antiAliasWithSaveLayer` | `hardEdge` |
| `children` | children | — | `[]` |

> Filhos podem ser **Positioned** (sub-tipo): props `left, top, right, bottom, width, height`.

### 2.5 Text

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `data` | string | — | `""` |
| `style` | textStyle | ver §3.2 | — |
| `textAlign` | enum (TextAlign) | `left, right, center, justify, start, end` | `start` |
| `maxLines` | int | — | — |
| `overflow` | enum (TextOverflow) | `clip, fade, ellipsis, visible` | `clip` |
| `softWrap` | bool | — | `true` |

### 2.6 Image

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `source` | enum | `network, asset` | `network` |
| `src` | string | URL ou caminho do asset | — |
| `width` | double | — | — |
| `height` | double | — | — |
| `fit` | enum (BoxFit) | `fill, contain, cover, fitWidth, fitHeight, none, scaleDown` | `contain` |

### 2.7 Icon

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `icon` | string | nome do ícone (catálogo Material) | — |
| `size` | double | — | `24.0` |
| `color` | color | — | — |

### 2.8 Button

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `variant` | enum | `elevated, text, outlined, filled` | `elevated` |
| `label` | string | — | — |
| `onPressed` | actionList | ver §4 | — |
| `enabled` | bool | — | `true` |
| `style.backgroundColor` | color | — | — |
| `style.foregroundColor` | color | — | — |
| `style.padding` | edgeInsets | — | — |
| `child` | child | (alternativa ao `label`) | — |

### 2.9 SizedBox / 2.10 Padding / 2.11 Center

| Primitivo | Props |
|---|---|
| **SizedBox** | `width` (double), `height` (double), `child` |
| **Padding** | `padding` (edgeInsets, obrigatório), `child` |
| **Center** | `widthFactor` (double), `heightFactor` (double), `child` |

### 2.12 Expanded / Flexible

| Prop | Tipo | Enum/Valores | Default |
|---|---|---|---|
| `flex` | int | — | `1` |
| `fit` | enum (FlexFit) | `tight` (Expanded), `loose` (Flexible) | — |
| `child` | child | — | — |

> Só válidos como filhos diretos de Row/Column.

### 2.13 Spacer

| Prop | Tipo | Default |
|---|---|---|
| `flex` | int | `1` |

### 2.14 GestureDetector

| Prop | Tipo | Default |
|---|---|---|
| `events.onTap` | actionList | — |
| `events.onLongPress` | actionList | — |
| `events.onDoubleTap` | actionList | — |
| `child` | child | — |

---

## 3. Tipos complexos

### 3.1 EdgeInsets (padding / margin)

Aceita uma das formas:
```jsonc
{ "all": 16 }
{ "horizontal": 12, "vertical": 8 }              // EdgeInsets.symmetric
{ "left": 8, "top": 4, "right": 8, "bottom": 4 } // EdgeInsets.only / fromLTRB
```

### 3.2 TextStyle

| Campo | Tipo | Enum/Valores |
|---|---|---|
| `fontSize` | double | — |
| `fontWeight` | enum | `w100, w200, w300, w400 (normal), w500, w600, w700 (bold), w800, w900` |
| `fontStyle` | enum | `normal, italic` |
| `color` | color | — |
| `fontFamily` | string | — |
| `letterSpacing` | double | — |
| `wordSpacing` | double | — |
| `height` | double | (altura de linha, multiplicador) |
| `decoration` | enum | `none, underline, overline, lineThrough` |

### 3.3 BoxDecoration

| Campo | Tipo | Detalhe |
|---|---|---|
| `color` | color | — |
| `borderRadius` | borderRadius | número uniforme ou `{ topLeft, topRight, bottomLeft, bottomRight }` |
| `border` | object | `{ "color": color, "width": double, "style": "solid\|none" }` (uniforme) ou por lado |
| `boxShadow` | array | itens: `{ "color": color, "offsetX": double, "offsetY": double, "blurRadius": double, "spreadRadius": double }` |
| `gradient` | object | `{ "type": "linear\|radial", "colors": [color], "stops": [double], "begin": Alignment, "end": Alignment }` |
| `shape` | enum | `rectangle, circle` |

### 3.4 Alignment (enum)

`topLeft, topCenter, topRight, centerLeft, center, centerRight, bottomLeft, bottomCenter, bottomRight`

Variante direcional (Stack): `topStart, topCenter, topEnd, centerStart, center, centerEnd, bottomStart, bottomCenter, bottomEnd`

---

## 4. Eventos e Ações

Evento → **lista ordenada** de ações, executada em sequência.

```jsonc
"events": {
  "onTap": [
    { "type": "navigate", "params": { "routeId": "route_product", "args": { "id": "{{productId}}" } } },
    { "type": "track",    "params": { "event": "cta_click" } }
  ]
}
```

| type | params | observação |
|---|---|---|
| `navigate` | `routeId`, `args` | `routeId` = rota cadastrada no projeto; `args` preenche os params declarados |
| `openUrl` | `url` | abre web |
| `goBack` | — | volta |
| `showDialog` | `dialogId`, `params` | diálogo registrado pelo cliente |
| `track` | `event`, `props` | telemetria |
| `custom` | `name`, `params` | handler arbitrário do cliente |

---

## 5. Esqueleto do Design System (mínimo, evolutivo)

> Não é foco agora, mas a estrutura fica pronta para tokens. No MVP, valores podem ser livres; quando os tokens entrarem, props de cor/tipografia poderão referenciar `$token`.

### 5.1 Tokens de cor (referenciáveis como `$nome`)
```jsonc
{
  "primary":    "#1565C0",
  "onPrimary":  "#FFFFFF",
  "secondary":  "#00897B",
  "surface":    "#FFFFFF",
  "onSurface":  "#1A1A1A",
  "background": "#F5F5F5",
  "error":      "#D32F2F",
  "muted":      "#9E9E9E"
}
```

### 5.2 Escala tipográfica
```jsonc
{
  "displayLarge": { "fontSize": 32, "fontWeight": "w700" },
  "titleLarge":   { "fontSize": 22, "fontWeight": "w600" },
  "bodyLarge":    { "fontSize": 16, "fontWeight": "w400" },
  "bodyMedium":   { "fontSize": 14, "fontWeight": "w400" },
  "labelSmall":   { "fontSize": 12, "fontWeight": "w500" }
}
```

### 5.3 Escala de espaçamento
```jsonc
{ "xs": 4, "sm": 8, "md": 16, "lg": 24, "xl": 32 }
```

Resolução de token: um valor `"$primary"` em prop de cor, ou `"$bodyLarge"` em `style`, é resolvido pelo renderer contra os tokens do projeto. Enquanto o design system não entra, props aceitam valores literais.

---

## 6. Exemplo completo (widget `primary_button`)

```jsonc
{
  "slug": "primary_button",
  "name": "Botão Primário",
  "kind": "primitive",
  "version": 1,
  "propsSchema": [
    { "key": "label",     "type": "string", "required": true,  "default": "Comprar" },
    { "key": "bgColor",   "type": "color",  "required": false, "default": "#1565C0" },
    { "key": "productId", "type": "string", "required": true }
  ],
  "tree": {
    "type": "gestureDetector",
    "events": {
      "onTap": [
        { "type": "navigate", "params": { "routeId": "route_product", "args": { "id": "{{productId}}" } } }
      ]
    },
    "child": {
      "type": "container",
      "props": {
        "padding": { "horizontal": 24, "vertical": 12 },
        "decoration": { "color": "{{bgColor}}", "borderRadius": 8 }
      },
      "child": {
        "type": "text",
        "props": {
          "data": "{{label}}",
          "style": { "fontSize": 16, "fontWeight": "w600", "color": "#FFFFFF" },
          "textAlign": "center"
        }
      }
    }
  }
}
```

---

## 7. Notas de implementação

- **Validação compartilhada**: gerar o schema Zod a partir deste documento; o mesmo schema valida no Inspector (web) e no backend.
- **Models Flutter**: `freezed` + `json_serializable` por primitivo; o registry mapeia `type → builder`.
- **Versão do spec**: incluir um campo `specVersion` no payload de topo para permitir migração futura sem quebrar widgets salvos.
- **Enums como string**: sempre serializar enums pelo nome do valor Flutter (ex.: `"spaceBetween"`), nunca por índice.
- **Cobertura incremental**: começar pelos primitivos de layout (Container, Column, Row, Text) e expandir; cada novo primitivo é uma entrada na tabela + um builder no renderer.
