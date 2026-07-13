# Driva Design System

The design system for **Driva**, a product by **BMJTech**. Driva is a **Server-Driven UI (SDUI)** platform: a web application where teams assemble **pages** and **widgets** that are rendered as **native components inside a customer's Flutter app** — no app-store release required. The product of the platform is **data** (a JSON *spec*), not Dart code; the app downloads the spec and renders it with a proprietary renderer. Its construction model is inspired by **FlutterFlow**: a drag-and-drop builder for dynamic widgets and pages.

> **Why this design system exists.** The #1 problem of the predecessor POC (WidgetMill) was **bad design/UX**. The board made visual quality a *first-class acceptance criterion* for Driva: the editor must be clean, modern, intuitive, and pleasant, with a consistent design system and fluid interactions. This repository is that design system.

## Sources used to build this
- **Codebase:** `driva/` (local) — at the time of writing it contains only `docs/` (specs + runbooks); the product is greenfield.
  - `driva/docs/specs/visao-geral.html` — product overview & increment slicing (modules A/B/C).
  - `driva/docs/specs/modulo-pagina.html` — the **Module A / I1 Page Builder** spec this system primarily serves.
  - `driva/docs/padrao-de-projeto-flutter.md` — the Flutter (Clean Architecture, go_router, bloc) pattern for the client app.
- **GitHub:** https://github.com/euclidesgc/driva — explore for the latest source. *(At build time the repo held only a placeholder readme; revisit it as the product grows — it is the source of truth for real widget types, the page spec schema, and the editor implementation.)*

Because the product is at its very beginning, the **brand identity here is provisional** (see Caveats). It is grounded in the product's nature (a precise, modern builder tool) and the blue accent already present in the spec docs.

---

## The product surfaces
Driva is built in **modules**, sliced into short increments:
- **Module A — Page Builder (I1, current):** assemble a page from a widget catalog (palette), order the blocks, edit properties, and see a faithful device preview. → see `ui_kits/editor/`.
- **Module B — Widget Builder (I3):** compose complex widgets with component **states** (idle/loading/success/error/empty) and a **data source** with parameters.
- **Module C — Workflow (I4):** draft → homologation → production publishing, with roles, **versioning**, and **scheduling**.

Platform stack (for context): **Next.js** (web editor), **NestJS** (domain backend: RBAC, workflow, versioning), **Flutter Web** (the faithful preview), Postgres/JSONB. The final client app is **native Flutter** consuming the spec.

---

## Content fundamentals
The product UI and all human-facing copy are in **Brazilian Portuguese (pt-BR)**; code identifiers and these guideline files are in English.

- **Voice:** clear, direct, professional-but-warm — a confident tool, not chatty. Lead with the noun/action.
- **Person:** address the user implicitly via imperatives ("Salvar rascunho", "Arraste um widget aqui"), not "você". State facts plainly ("Página · 4 blocos", "Nenhum bloco selecionado").
- **Casing:** **Sentence case** for everything — buttons, labels, titles ("Pré-visualizar", "Fonte de dados"). Reserve UPPERCASE (with wide tracking) for tiny section eyebrows only ("MÍDIA", "DADOS"). Never Title Case.
- **Domain vocabulary (use consistently):** *Página, Bloco, Widget, Paleta, Inspector, Preview fiel, Rascunho, Homologação, Produção, Spec*. Stages are **Rascunho → Homologação → Produção**. Widget states are **idle / loading / success / error / empty** (kept in English, matching the spec).
- **Technical tokens** (slugs, versions, bindings) are shown in **monospace**: `/home`, `product_list@v1`, `{{ user.tier }}`.
- **Numbers/units:** Portuguese formatting where user-facing (`R$ 199`, `R$ 49,90`); px/dp/pt for sizes.
- **Tone of empty/system states:** helpful and brief — say what to do ("Selecione um bloco na página para editar suas propriedades."), never cute.
- **Emoji:** none in product UI. Iconography carries meaning instead.

---

## Visual foundations
A **light, precise, builder-tool** aesthetic: a calm neutral chrome that recedes so the user's *content* (the page being built) is the brightest thing on screen.

- **Color.** Brand is **Driva Blue** (`--blue-500 #2f6bff`) — used for the primary action, selection, focus, and the active state of a block. A secondary **violet** (`--violet-500`) marks the *widget/data* world (data bindings, the widget builder). Neutrals are a **cool slate** ramp doing 80% of the work. Semantic colors are reserved and meaningful; the **workflow** owns three: slate (draft), amber (homologation), green (production). Backgrounds are flat fills, **not** gradients — the only gradient in the system is *inside the rendered preview content* (e.g. a banner), never in the editor chrome.
- **Surfaces.** A clear ladder: `--surface-app` (chrome) → `--surface-panel` (white panels) → `--surface-sunken` (wells/tracks) → `--surface-canvas` (the gray preview backdrop). Columns are separated by 1px hairlines, not heavy shadows.
- **Type.** **Geist** for all UI (clean, neutral, technical); **Geist Mono** for specs, slugs, versions, and bindings. A compact scale tuned for density — body is **14px**; nothing functional below 11px. Headings use slight negative tracking.
- **Spacing.** A **4px grid**. The editor uses fixed rails (`--rail-palette 280`, `--rail-inspector 320`, `--topbar-h 52`). Dense but breathable: 8–14px paddings inside panels.
- **Radius.** Moderate and consistent: **8px** default for controls and cards, 6px for small chips, 10–14px for larger surfaces, pill for badges. Nothing fully sharp, nothing bubbly.
- **Borders & shadows.** Borders define structure (1px hairlines everywhere); shadows are **crisp and low-blur**, used sparingly to lift only truly floating things (menus, popovers, the device, a dragged block). A dedicated `--shadow-drag` (blue-tinted) communicates "picked up". Selected elements use a **2px brand ring**, not a heavy shadow.
- **Motion.** Quick and functional: 120–180ms, `--ease-out` for most, a gentle `--ease-spring` for toggles/toasts. Things fade and slide a few px; nothing bounces decoratively. Save status pulses; the "live" preview dot has a soft halo.
- **States.** Hover = subtle neutral tint (`--surface-hover`) or a stronger border; press = 0.5px nudge down; selected = brand ring + brand-subtle fill; disabled = 40–50% opacity. Focus is always a visible 3px brand ring (`--ring`).
- **Imagery.** The editor itself is image-light (it's a tool); imagery lives *in the preview*, where placeholder content uses soft pastel swatches. Logos/marks are flat and geometric.
- **Transparency/blur:** avoided in chrome (kept crisp for precision); reserved, if used at all, for overlays.

See the **Design System tab** for live specimen cards of every foundation above, and the token sources in `tokens/`.

---

## Iconography
- **System:** [**Lucide**](https://lucide.dev) (ISC license) — outline, 24×24, **2px stroke**, `currentColor`. It is the right match for a modern builder tool: even weight, geometric, comprehensive. Driva's codebase ships no icons of its own, so Lucide is the documented standard.
- **How it's delivered:** a curated subset is copied into **`assets/icons.js`** (exact Lucide path data), exposing `window.Icon` (a React component) and `window.drivaIconSvg(name,size,stroke)` / `window.DRIVA_ICONS` (raw strings). Cards and the UI kit use this — no CDN dependency. Add icons by copying more Lucide paths into that file. *(For production, the Flutter app should pair these with a matching native icon set.)*
- **Usage:** icons are functional, not decorative — palette widget types, block controls (show/hide, remove, reorder), toolbar actions, the data-binding link glyph. Pair an icon with a text label wherever space allows; icon-only controls always carry a tooltip/`aria-label`.
- **Emoji / unicode as icons:** never. Chevrons, grips, and marks are all SVG.
- **Brand mark:** `assets/driva-mark.svg` (stacked SDUI blocks) + `assets/driva-wordmark.svg` (and `-inverse`). Provisional.

---

## Index / manifest
**Foundations**
- `styles.css` — the entry point consumers link (import manifest only).
- `tokens/colors.css` · `typography.css` · `spacing.css` · `elevation.css` · `fonts.css` — all design tokens.
- `assets/` — `driva-mark.svg`, `driva-wordmark.svg`, `driva-wordmark-inverse.svg`, `icons.js`.
- `guidelines/*.card.html` — foundation specimen cards (Colors, Type, Spacing, Brand) shown in the Design System tab.

**Components** (`window.DrivaDesignSystem_5934aa`) — see each `*.prompt.md`:
- `components/core/` — Button, IconButton, Badge, Avatar, Tooltip.
- `components/forms/` — Input, Textarea, Select, Switch, SegmentedControl, Checkbox.
- `components/layout/` — Panel, Tabs.
- `components/builder/` — **WidgetTile, BlockRow, PropertyRow, StageBadge, StateChip** (the SDUI-specific primitives).

**UI kits**
- `ui_kits/editor/` — the full interactive **Page Builder** editor (Module A / I1). Start at `index.html`.

**Other**
- `SKILL.md` — makes this system usable as a downloadable Agent Skill.
- `readme.md` — this file.

---

## Caveats & how to make this perfect
- **Brand identity is provisional.** Driva is greenfield with no existing logo, palette, or font choice in the codebase. I chose Driva Blue + slate, Geist/Geist Mono, and a stacked-blocks mark to fit a precise modern builder. **If BMJTech has — or wants — specific brand colors, a real logo, or a chosen typeface, share them and I'll re-skin everything from the tokens up.**
- **Fonts load from Google Fonts** (`tokens/fonts.css`) for portability. For production, **self-host Geist & Geist Mono** and swap the `@import` for local `@font-face` rules. *If you'd prefer different typefaces, tell me.*
- **Light theme only** so far. If the team wants a dark editor (the spec docs were dark), I can add a dark token scope.
- **The preview is an HTML approximation.** The real "preview fiel" is the embedded Flutter Web app — this kit fakes it for visual/interaction fidelity only.

**My ask:** confirm (1) brand colors + logo, (2) typeface, (3) light vs. dark editor. With those three, this becomes production-grade. Explore the GitHub repo (https://github.com/euclidesgc/driva) as it fills in so future designs track the real widget catalog and page spec.
