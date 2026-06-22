"use client";

import { FieldLabel } from "@measured/puck";
import { ALIGNMENT, pruneBlank } from "@widgetmill/spec";
import Sketch from "@uiw/react-color-sketch";
import {
  useCallback,
  useEffect,
  useRef,
  useState,
  type CSSProperties,
  type ReactElement,
} from "react";
import { createPortal } from "react-dom";

/**
 * Campos customizados do Inspector. Existem para:
 *
 * 1. **Limpar opcionais numéricas.** O campo `number` nativo do Puck faz
 *    `onChange(Number(value))` e `Number("") === 0` — então limpar deixa `0`,
 *    nunca "ausente". [NumberInput] emite `undefined` quando vazio, e a poda
 *    (`pruneBlank`) remove a chave do spec.
 * 2. **Marcar obrigatórias** com um asterisco no slot de ícone do label
 *    ([RequiredMark]).
 * 3. **Tipos com múltiplas formas** (EdgeInsets, BorderRadius): um seletor de
 *    modo troca os inputs e garante que o valor emitido casa com **uma** das
 *    variantes do schema (`.strict()`), sem misturar chaves de modos diferentes.
 */

/**
 * Classe do `<input>` do Puck (versão 0.20.2) reusada para parity visual exata
 * — borda, raio, foco e variáveis de tema. **Acoplada à versão pinada**: ao
 * atualizar o Puck, reconferir este hash em `@measured/puck/dist/index.css`.
 */
const PUCK_INPUT_CLASS = "_Input-input_bsxfo_26";

type Maybe = number | undefined;

/** Converte entrada para número, tratando vazio/inválido como ausente. */
function num(x: unknown): Maybe {
  if (x == null || x === "") return undefined;
  const n = Number(x);
  return Number.isNaN(n) ? undefined : n;
}

/**
 * Asterisco "campo obrigatório". Ocupa o slot de ícone já existente do label
 * (não consome espaço extra) e se explica via tooltip no hover.
 */
export function RequiredMark(): ReactElement {
  return (
    <span
      title="Obrigatório"
      aria-label="Obrigatório"
      style={{ color: "#d32f2f", fontWeight: 700, fontSize: 15, lineHeight: 1 }}
    >
      ∗
    </span>
  );
}

// ── Primitivos ───────────────────────────────────────────────────────────────

/** Input numérico limpável: vazio → `undefined`; inválido é ignorado. */
function NumberInput({
  value,
  onChange,
  readOnly,
  ariaLabel,
}: {
  value: Maybe;
  onChange: (v: Maybe) => void;
  readOnly?: boolean;
  ariaLabel?: string;
}): ReactElement {
  // Rascunho local: digitar atualiza só este input (instantâneo). O commit no
  // estado global do Puck — que re-renderiza o editor inteiro — acontece só ao
  // sair do campo (blur) ou no Enter, NÃO a cada tecla. Sincroniza com o valor
  // externo (troca de nó, undo, troca de modo).
  const [draft, setDraft] = useState(value == null ? "" : String(value));
  useEffect(() => {
    setDraft(value == null ? "" : String(value));
  }, [value]);

  const commit = () => {
    const next = num(draft);
    if (next !== value) onChange(next);
  };

  return (
    <input
      className={PUCK_INPUT_CLASS}
      type="number"
      inputMode="decimal"
      autoComplete="off"
      aria-label={ariaLabel}
      title={ariaLabel}
      readOnly={readOnly}
      value={draft}
      onChange={(e) => setDraft(e.currentTarget.value)}
      onBlur={commit}
      onKeyDown={(e) => {
        if (e.key === "Enter") e.currentTarget.blur();
      }}
    />
  );
}

/** Input numérico com legenda curta acima (usado nas grades multi-campo). */
function LabeledNumber(props: {
  label: string;
  value: Maybe;
  onChange: (v: Maybe) => void;
  readOnly?: boolean;
}): ReactElement {
  return (
    <label style={{ display: "flex", flexDirection: "column", gap: 2 }}>
      <span style={{ fontSize: 11, color: "#6b7280" }}>{props.label}</span>
      <NumberInput
        value={props.value}
        onChange={props.onChange}
        readOnly={props.readOnly}
        ariaLabel={props.label}
      />
    </label>
  );
}

/** Controle segmentado para escolher o modo de um tipo com múltiplas formas. */
function ModeTabs(props: {
  value: string;
  options: ReadonlyArray<{ value: string; label: string }>;
  onChange: (value: string) => void;
  readOnly?: boolean;
}): ReactElement {
  return (
    <div role="tablist" style={{ display: "flex", gap: 4, marginBottom: 8 }}>
      {props.options.map((o) => {
        const active = o.value === props.value;
        return (
          <button
            key={o.value}
            type="button"
            role="tab"
            aria-selected={active}
            disabled={props.readOnly}
            onClick={() => props.onChange(o.value)}
            style={{
              flex: 1,
              padding: "5px 6px",
              fontSize: 12,
              cursor: props.readOnly ? "default" : "pointer",
              borderRadius: 6,
              border: "1px solid",
              borderColor: active ? "#3b82f6" : "#d1d5db",
              background: active ? "#eff6ff" : "#fff",
              color: active ? "#1d4ed8" : "#374151",
              fontWeight: active ? 600 : 400,
            }}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

const GRID2: CSSProperties = {
  display: "grid",
  gridTemplateColumns: "1fr 1fr",
  gap: 6,
};

/** Props que o Puck passa ao `render` de um campo `custom`. */
interface CustomFieldProps {
  field?: { label?: string; labelIcon?: ReactElement };
  name: string;
  value: unknown;
  onChange: (value: unknown) => void;
  readOnly?: boolean;
}

// ── Campo numérico simples ─────────────────────────────────────────────────────

function ClearableNumber({ field, name, value, onChange, readOnly }: CustomFieldProps): ReactElement {
  return (
    <FieldLabel label={field?.label ?? name} icon={field?.labelIcon} readOnly={readOnly}>
      <NumberInput
        value={value as Maybe}
        onChange={onChange}
        readOnly={readOnly}
        ariaLabel={field?.label ?? name}
      />
    </FieldLabel>
  );
}

/** Config de campo numérico limpável (a marca de obrigatório é anexada à parte). */
export function numberField(label?: string): Record<string, unknown> {
  return { type: "custom", label, render: ClearableNumber };
}

/**
 * Opção "limpar" (—) prefixada em selects de enums **opcionais**: o valor vira
 * `undefined` (some do spec na poda). Casa com o `value` quando nada está
 * selecionado, exibindo "—" em vez de fingir o primeiro item.
 */
export const CLEAR_OPTION = { label: "—", value: undefined };

// ── EdgeInsets (padding / margin): all | symmetric | per-side ───────────────────

type EdgeMode = "all" | "symmetric" | "perSide";

const EDGE_TABS = [
  { value: "all", label: "Todos" },
  { value: "symmetric", label: "Simétrico" },
  { value: "perSide", label: "Por lado" },
] as const;

/** Infere o modo pela forma do valor salvo (null = vazio/ambíguo → usa o local). */
function edgeMode(v: unknown): EdgeMode | null {
  if (v == null || typeof v !== "object") return null;
  const o = v as Record<string, unknown>;
  if ("all" in o) return "all";
  if ("horizontal" in o || "vertical" in o) return "symmetric";
  if ("left" in o || "top" in o || "right" in o || "bottom" in o) return "perSide";
  return null;
}

interface Sides {
  l: Maybe;
  t: Maybe;
  r: Maybe;
  b: Maybe;
}

/** Resolve qualquer modo para os 4 lados (base comum para converter). */
function edgeToSides(v: Record<string, unknown>, mode: EdgeMode): Sides {
  if (mode === "all") {
    const a = num(v.all);
    return { l: a, t: a, r: a, b: a };
  }
  if (mode === "symmetric") {
    const h = num(v.horizontal);
    const vv = num(v.vertical);
    return { l: h, t: vv, r: h, b: vv };
  }
  return { l: num(v.left), t: num(v.top), r: num(v.right), b: num(v.bottom) };
}

/** Projeta os 4 lados na forma do modo alvo (preserva valores onde dá). */
function edgeFromSides(s: Sides, target: EdgeMode): Record<string, Maybe> {
  if (target === "all") {
    const vals = [s.l, s.t, s.r, s.b].filter((x): x is number => x !== undefined);
    if (vals.length === 0) return {};
    const equal = vals.every((x) => x === vals[0]);
    return { all: equal ? vals[0] : (s.l ?? s.t ?? s.r ?? s.b) };
  }
  if (target === "symmetric") return { horizontal: s.l ?? s.r, vertical: s.t ?? s.b };
  return { left: s.l, top: s.t, right: s.r, bottom: s.b };
}

function EdgeInsetsField({ field, name, value, onChange, readOnly }: CustomFieldProps): ReactElement {
  // Modo EFETIVO: inferido do valor (verdade) quando determinável; o modo local
  // só governa o caso vazio/ambíguo (não dá p/ inferir all/symmetric/perSide de {}).
  const inferred = edgeMode(value);
  const [localMode, setLocalMode] = useState<EdgeMode>(inferred ?? "all");
  const mode = inferred ?? localMode;

  const v = (value ?? {}) as Record<string, unknown>;
  const emit = (next: Record<string, Maybe>) => onChange(pruneBlank(next));

  const switchMode = (next: string) => {
    const nm = next as EdgeMode;
    if (nm === mode) return;
    const converted = edgeFromSides(edgeToSides(v, mode), nm);
    setLocalMode(nm); // governa só o caso vazio; com valor, o modo vem do `value`
    onChange(pruneBlank(converted));
  };

  return (
    <FieldLabel el="div" label={field?.label ?? name} icon={field?.labelIcon} readOnly={readOnly}>
      <ModeTabs value={mode} options={EDGE_TABS} onChange={switchMode} readOnly={readOnly} />
      {mode === "all" && (
        <NumberInput value={num(v.all)} readOnly={readOnly} ariaLabel="all" onChange={(n) => emit({ all: n })} />
      )}
      {mode === "symmetric" && (
        <div style={GRID2}>
          <LabeledNumber
            label="horizontal"
            value={num(v.horizontal)}
            readOnly={readOnly}
            onChange={(n) => emit({ horizontal: n, vertical: num(v.vertical) })}
          />
          <LabeledNumber
            label="vertical"
            value={num(v.vertical)}
            readOnly={readOnly}
            onChange={(n) => emit({ horizontal: num(v.horizontal), vertical: n })}
          />
        </div>
      )}
      {mode === "perSide" && (
        <div style={GRID2}>
          <LabeledNumber
            label="left"
            value={num(v.left)}
            readOnly={readOnly}
            onChange={(n) => emit({ left: n, top: num(v.top), right: num(v.right), bottom: num(v.bottom) })}
          />
          <LabeledNumber
            label="top"
            value={num(v.top)}
            readOnly={readOnly}
            onChange={(n) => emit({ left: num(v.left), top: n, right: num(v.right), bottom: num(v.bottom) })}
          />
          <LabeledNumber
            label="right"
            value={num(v.right)}
            readOnly={readOnly}
            onChange={(n) => emit({ left: num(v.left), top: num(v.top), right: n, bottom: num(v.bottom) })}
          />
          <LabeledNumber
            label="bottom"
            value={num(v.bottom)}
            readOnly={readOnly}
            onChange={(n) => emit({ left: num(v.left), top: num(v.top), right: num(v.right), bottom: n })}
          />
        </div>
      )}
    </FieldLabel>
  );
}

/** Config de campo EdgeInsets com seletor de modo. */
export function edgeInsetsField(label?: string): Record<string, unknown> {
  return { type: "custom", label, render: EdgeInsetsField };
}

// ── BorderRadius: number uniforme | por canto ──────────────────────────────────

type RadiusMode = "uniform" | "perCorner";

const RADIUS_TABS = [
  { value: "uniform", label: "Uniforme" },
  { value: "perCorner", label: "Por canto" },
] as const;

function radiusMode(v: unknown): RadiusMode | null {
  if (typeof v === "number") return "uniform";
  if (v != null && typeof v === "object") return "perCorner";
  return null;
}

function BorderRadiusField({ field, name, value, onChange, readOnly }: CustomFieldProps): ReactElement {
  // Modo EFETIVO derivado do valor; o modo local só governa o caso vazio.
  const inferred = radiusMode(value);
  const [localMode, setLocalMode] = useState<RadiusMode>(inferred ?? "uniform");
  const mode = inferred ?? localMode;

  const c = (value ?? {}) as Record<string, unknown>;
  const emitCorner = (corner: string, n: Maybe) =>
    onChange(
      pruneBlank({
        topLeft: num(c.topLeft),
        topRight: num(c.topRight),
        bottomLeft: num(c.bottomLeft),
        bottomRight: num(c.bottomRight),
        [corner]: n,
      }),
    );

  const switchMode = (next: string) => {
    const nm = next as RadiusMode;
    if (nm === mode) return;
    if (nm === "uniform") {
      const vals = [c.topLeft, c.topRight, c.bottomLeft, c.bottomRight]
        .map(num)
        .filter((x): x is number => x !== undefined);
      setLocalMode(nm);
      onChange(vals[0]); // primeiro definido (ou undefined)
    } else {
      const r = typeof value === "number" ? value : undefined;
      setLocalMode(nm);
      onChange(pruneBlank({ topLeft: r, topRight: r, bottomLeft: r, bottomRight: r }));
    }
  };

  return (
    <FieldLabel el="div" label={field?.label ?? name} icon={field?.labelIcon} readOnly={readOnly}>
      <ModeTabs value={mode} options={RADIUS_TABS} onChange={switchMode} readOnly={readOnly} />
      {mode === "uniform" && (
        <NumberInput
          value={typeof value === "number" ? value : undefined}
          readOnly={readOnly}
          ariaLabel="borderRadius"
          onChange={(n) => onChange(n)}
        />
      )}
      {mode === "perCorner" && (
        <div style={GRID2}>
          <LabeledNumber label="topLeft" value={num(c.topLeft)} readOnly={readOnly} onChange={(n) => emitCorner("topLeft", n)} />
          <LabeledNumber label="topRight" value={num(c.topRight)} readOnly={readOnly} onChange={(n) => emitCorner("topRight", n)} />
          <LabeledNumber label="bottomLeft" value={num(c.bottomLeft)} readOnly={readOnly} onChange={(n) => emitCorner("bottomLeft", n)} />
          <LabeledNumber label="bottomRight" value={num(c.bottomRight)} readOnly={readOnly} onChange={(n) => emitCorner("bottomRight", n)} />
        </div>
      )}
    </FieldLabel>
  );
}

/** Config de campo BorderRadius com seletor de modo. */
export function borderRadiusField(label?: string): Record<string, unknown> {
  return { type: "custom", label, render: BorderRadiusField };
}

// ── Cor: campo #AARRGGBB + picker @uiw/react-color (Sketch) em popover ─────────
//
// O picker é controlado por ESTADO LOCAL (`text`), não pelo valor do Puck — o que
// mata o loop de render que tínhamos com um picker controlado pelo Puck ("Maximum
// update depth"): lá o valor voltava re-normalizado a cada tick e o picker
// reemitia onChange num ciclo. Aqui o picker só atualiza o rascunho local; o
// commit no Puck (que re-renderiza o editor) acontece só ao FECHAR o popover.

/** "#RRGGBB" ou "#AARRGGBB" → "AARRGGBB" (8, maiúsculas) ou null se inválido. */
function toArgbHex(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const m = v.trim().replace(/^#/, "");
  if (/^[0-9a-fA-F]{6}$/.test(m)) return ("FF" + m).toUpperCase(); // 6 → alpha FF
  if (/^[0-9a-fA-F]{8}$/.test(m)) return m.toUpperCase();
  return null;
}

/** Valor exibido/armazenado: "#AARRGGBB" (ou "" se vazio/inválido). */
function colorDisplay(v: unknown): string {
  const h = toArgbHex(v);
  return h ? "#" + h : "";
}

/** "AARRGGBB" (Flutter, alpha 1º) → "#rrggbbaa" (RGBA, alpha por último) p/ o picker. */
function argbToRgba(argb8: string): string {
  return ("#" + argb8.slice(2) + argb8.slice(0, 2)).toLowerCase();
}

/** "#rrggbb[aa]" (do picker) → "#AARRGGBB" (Flutter). Sem alpha assume FF. */
function rgbaToArgb(hexa: string): string {
  const m = hexa.replace(/^#/, "");
  const aa = m.length >= 8 ? m.slice(6, 8) : "ff";
  return ("#" + aa + m.slice(0, 6)).toUpperCase();
}

/** Amostras prontas (paleta Material) oferecidas no picker. */
const PRESET_SWATCHES = [
  "#f44336", "#e91e63", "#9c27b0", "#673ab7", "#3f51b5",
  "#2196f3", "#03a9f4", "#00bcd4", "#009688", "#4caf50",
  "#8bc34a", "#cddc39", "#ffeb3b", "#ffc107", "#ff9800",
  "#ff5722", "#795548", "#9e9e9e", "#607d8b", "#000000", "#ffffff",
];

/**
 * Popover ancorado. Renderiza num portal (`document.body`) com `position: fixed`
 * para não ser cortado pelo overflow do painel do Inspector. Posiciona abaixo da
 * âncora (vira pra cima se faltar espaço) e fecha ao clicar fora ou no Esc —
 * disparando `onClose` (onde fazemos o commit).
 */
function ColorPopover({
  anchor,
  onClose,
  children,
}: {
  anchor: HTMLElement | null;
  onClose: () => void;
  children: ReactElement;
}): ReactElement | null {
  const panelRef = useRef<HTMLDivElement>(null);
  const [pos, setPos] = useState<{ top: number; left: number } | null>(null);

  useEffect(() => {
    if (!anchor) return;
    const r = anchor.getBoundingClientRect();
    const PANEL_H = 340; // altura aprox. do Sketch (p/ decidir abrir pra cima)
    const below = r.bottom + 4;
    const flipUp = below + PANEL_H > window.innerHeight && r.top > PANEL_H;
    setPos({
      top: flipUp ? Math.max(8, r.top - PANEL_H - 4) : below,
      left: Math.max(8, Math.min(r.left, window.innerWidth - 234)),
    });
  }, [anchor]);

  useEffect(() => {
    const onDown = (e: PointerEvent) => {
      const t = e.target as Node;
      if (panelRef.current?.contains(t) || anchor?.contains(t)) return;
      onClose();
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("pointerdown", onDown, true);
    document.addEventListener("keydown", onKey, true);
    return () => {
      document.removeEventListener("pointerdown", onDown, true);
      document.removeEventListener("keydown", onKey, true);
    };
  }, [anchor, onClose]);

  if (typeof document === "undefined" || !pos) return null;
  return createPortal(
    <div
      ref={panelRef}
      style={{ position: "fixed", top: pos.top, left: pos.left, zIndex: 10000 }}
    >
      {children}
    </div>,
    document.body,
  );
}

function ColorField({ field, name, value, onChange, readOnly }: CustomFieldProps): ReactElement {
  // `text` (#AARRGGBB) é o rascunho local e a única fonte de verdade enquanto se
  // interage. O picker e a digitação só o atualizam (re-render local, barato); o
  // commit no Puck acontece ao fechar o popover ou sair do campo de texto.
  const [text, setText] = useState(() => colorDisplay(value));
  const [open, setOpen] = useState(false);
  const rowRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    setText(colorDisplay(value));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value]);

  const argb = toArgbHex(text); // "AARRGGBB" | null
  const swatchBg = argb ? "#" + argb.slice(2).toLowerCase() : "transparent";
  const pickerColor = argb ? argbToRgba(argb) : "#000000ff";

  // Refs p/ um commit estável: o arrasto no picker re-renderiza este campo ~60×/s,
  // e um `commit` recriado a cada render re-assinaria os listeners do popover.
  const textRef = useRef(text);
  textRef.current = text;
  const valueRef = useRef(value);
  valueRef.current = value;
  const onChangeRef = useRef(onChange);
  onChangeRef.current = onChange;

  const commit = useCallback(() => {
    const t = textRef.current.trim();
    const cur = colorDisplay(valueRef.current);
    if (t === "") {
      if (valueRef.current != null) onChangeRef.current(undefined);
      return;
    }
    const h = toArgbHex(t);
    if (h === null) {
      setText(cur); // descarta entrada inválida
      return;
    }
    const next = "#" + h;
    if (next !== cur) onChangeRef.current(next);
  }, []);

  const closePopover = useCallback(() => {
    setOpen(false);
    commit();
  }, [commit]);

  return (
    <FieldLabel el="div" label={field?.label ?? name} icon={field?.labelIcon} readOnly={readOnly}>
      <div ref={rowRef} style={{ display: "flex", gap: 6, alignItems: "center" }}>
        <button
          type="button"
          aria-label="Escolher cor"
          title="Escolher cor"
          disabled={readOnly}
          onClick={() => (open ? closePopover() : setOpen(true))}
          style={{
            width: 36,
            height: 32,
            flex: "0 0 auto",
            padding: 0,
            border: "1px solid #d1d5db",
            borderRadius: 6,
            background: swatchBg,
            cursor: readOnly ? "default" : "pointer",
          }}
        />
        <input
          className={PUCK_INPUT_CLASS}
          style={{ flex: 1 }}
          type="text"
          autoComplete="off"
          spellCheck={false}
          readOnly={readOnly}
          placeholder="#AARRGGBB"
          value={text}
          onChange={(e) => setText(e.currentTarget.value)}
          onBlur={commit}
          onKeyDown={(e) => {
            if (e.key === "Enter") e.currentTarget.blur();
          }}
        />
      </div>
      {open && !readOnly && (
        <ColorPopover anchor={rowRef.current} onClose={closePopover}>
          <Sketch
            color={pickerColor}
            presetColors={PRESET_SWATCHES}
            onChange={(color) => setText(rgbaToArgb(color.hexa))}
            style={{ boxShadow: "0 6px 24px rgba(0,0,0,0.22)" }}
          />
        </ColorPopover>
      )}
    </FieldLabel>
  );
}

/** Config de campo de cor: amostra + #AARRGGBB + picker Sketch (popover). */
export function colorField(label?: string): Record<string, unknown> {
  return { type: "custom", label, render: ColorField };
}

// ── Select nativo enxuto (reusado por gradiente/alinhamento) ───────────────────

function MiniSelect({
  value,
  options,
  onChange,
  readOnly,
  ariaLabel,
}: {
  value: string | undefined;
  options: ReadonlyArray<{ value: string | undefined; label: string }>;
  onChange: (v: string | undefined) => void;
  readOnly?: boolean;
  ariaLabel?: string;
}): ReactElement {
  return (
    <select
      aria-label={ariaLabel}
      title={ariaLabel}
      disabled={readOnly}
      value={value ?? ""}
      onChange={(e) => onChange(e.currentTarget.value === "" ? undefined : e.currentTarget.value)}
      style={{
        width: "100%",
        padding: "6px 8px",
        fontSize: 13,
        borderRadius: 6,
        border: "1px solid #d1d5db",
        background: "#fff",
        color: "#111827",
      }}
    >
      {options.map((o) => (
        <option key={String(o.value)} value={o.value ?? ""}>
          {o.label}
        </option>
      ))}
    </select>
  );
}

const ALIGN_OPTS = [
  { value: undefined, label: "—" },
  ...ALIGNMENT.map((a) => ({ value: a as string, label: a as string })),
];

const cardStyle: CSSProperties = {
  border: "1px solid #e5e7eb",
  borderRadius: 8,
  padding: 8,
  marginBottom: 8,
  background: "#fafafa",
};

const addBtnStyle: CSSProperties = {
  width: "100%",
  padding: "6px 8px",
  fontSize: 12,
  fontWeight: 600,
  cursor: "pointer",
  borderRadius: 6,
  border: "1px dashed #93c5fd",
  background: "#eff6ff",
  color: "#1d4ed8",
};

const removeBtnStyle: CSSProperties = {
  border: "none",
  background: "transparent",
  color: "#9ca3af",
  cursor: "pointer",
  fontSize: 16,
  lineHeight: 1,
  padding: "0 4px",
};

// ── Dimensão: Fixo (px) | Preencher (∞) | % largura/altura da tela ──────────────
//
// Resolve para um `double` no renderer (resolveDimension): número puro,
// `{unit:"infinity"}` ou `{unit:"screenWidth|screenHeight", factor}` (multiplicador).

type DimMode = "fixed" | "fill" | "screenWidth" | "screenHeight";

const DIM_TABS = [
  { value: "fixed", label: "Fixo" },
  { value: "fill", label: "Preencher" },
  { value: "screenWidth", label: "% Larg." },
  { value: "screenHeight", label: "% Alt." },
] as const;

function dimMode(v: unknown): DimMode | null {
  if (typeof v === "number") return "fixed";
  if (v && typeof v === "object") {
    const u = (v as { unit?: unknown }).unit;
    if (u === "infinity") return "fill";
    if (u === "screenWidth") return "screenWidth";
    if (u === "screenHeight") return "screenHeight";
  }
  return null;
}

function dimFactor(v: unknown): number | undefined {
  if (v && typeof v === "object" && typeof (v as { factor?: unknown }).factor === "number") {
    return (v as { factor: number }).factor;
  }
  return undefined;
}

function DimensionField({ field, name, value, onChange, readOnly }: CustomFieldProps): ReactElement {
  // Modo DERIVADO do valor (única fonte de verdade) — a aba nunca pode divergir do
  // que está salvo. `undefined`/número → "fixed" (estado vazio natural).
  const mode = dimMode(value) ?? "fixed";

  const factor = dimFactor(value);
  // Fator (multiplicador) ↔ porcentagem exibida: 0.5 ⇄ 50.
  const pct = factor == null ? undefined : Math.round(factor * 1000) / 10;

  // Troca de modo grava o valor COMPLETO do destino num único onChange (sem
  // depender de "limpar" o resíduo do modo anterior).
  const switchMode = (next: string) => {
    const nm = next as DimMode;
    if (nm === mode) return;
    if (nm === "fill") onChange({ unit: "infinity" });
    else if (nm === "fixed") onChange(typeof value === "number" ? value : undefined);
    // % entra com 100% (fator 1) p/ o valor já determinar o modo (sem snap-back).
    else onChange({ unit: nm, factor: factor ?? 1 });
  };

  return (
    <FieldLabel el="div" label={field?.label ?? name} icon={field?.labelIcon} readOnly={readOnly}>
      <ModeTabs value={mode} options={DIM_TABS} onChange={switchMode} readOnly={readOnly} />
      {mode === "fixed" && (
        <NumberInput
          value={typeof value === "number" ? value : undefined}
          readOnly={readOnly}
          ariaLabel="px"
          onChange={(n) => onChange(n)}
        />
      )}
      {mode === "fill" && (
        <div style={{ fontSize: 12, color: "#6b7280", padding: "4px 0" }}>
          Preenche o espaço disponível (<code>double.infinity</code>).
        </div>
      )}
      {(mode === "screenWidth" || mode === "screenHeight") && (
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <div style={{ flex: 1 }}>
            <NumberInput
              value={pct}
              readOnly={readOnly}
              ariaLabel="porcentagem"
              onChange={(n) =>
                onChange(
                  // Esvaziar mantém o modo (último fator, ou 100%); só a aba "Fixo" limpa.
                  n == null
                    ? { unit: mode, factor: factor ?? 1 }
                    : { unit: mode, factor: Math.round((n / 100) * 1000) / 1000 },
                )
              }
            />
          </div>
          <span style={{ fontSize: 12, color: "#6b7280", whiteSpace: "nowrap" }}>
            % {mode === "screenWidth" ? "largura" : "altura"} da tela
          </span>
        </div>
      )}
    </FieldLabel>
  );
}

/** Config de campo de dimensão (px fixo | preencher | % de tela). */
export function dimensionField(label?: string): Record<string, unknown> {
  return { type: "custom", label, render: DimensionField };
}

// ── Lista de sombras (boxShadow): cor + offset + blur + spread ─────────────────

interface ShadowItem {
  color?: string;
  offsetX?: number;
  offsetY?: number;
  blurRadius?: number;
  spreadRadius?: number;
}

function ShadowListField({ field, name, value, onChange, readOnly }: CustomFieldProps): ReactElement {
  const list: ShadowItem[] = Array.isArray(value) ? (value as ShadowItem[]) : [];
  // Emite o array cru; a poda de itens em branco acontece no boundary (puckToSpec).
  const setItem = (i: number, patch: Partial<ShadowItem>) =>
    onChange(list.map((s, idx) => (idx === i ? { ...s, ...patch } : s)));
  const add = () =>
    onChange([...list, { color: "#40000000", offsetX: 0, offsetY: 2, blurRadius: 4, spreadRadius: 0 }]);
  const remove = (i: number) => onChange(list.filter((_, idx) => idx !== i));

  return (
    <FieldLabel el="div" label={field?.label ?? name} icon={field?.labelIcon} readOnly={readOnly}>
      {list.map((s, i) => (
        <div key={i} style={cardStyle}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
            <span style={{ fontSize: 11, fontWeight: 600, color: "#6b7280" }}>Sombra {i + 1}</span>
            {!readOnly && (
              <button type="button" aria-label="Remover sombra" title="Remover" style={removeBtnStyle} onClick={() => remove(i)}>
                ✕
              </button>
            )}
          </div>
          <ColorField name="color" value={s.color} readOnly={readOnly} onChange={(c) => setItem(i, { color: c as string | undefined })} />
          <div style={{ ...GRID2, marginTop: 6 }}>
            <LabeledNumber label="offsetX" value={num(s.offsetX)} readOnly={readOnly} onChange={(n) => setItem(i, { offsetX: n })} />
            <LabeledNumber label="offsetY" value={num(s.offsetY)} readOnly={readOnly} onChange={(n) => setItem(i, { offsetY: n })} />
            <LabeledNumber label="blur" value={num(s.blurRadius)} readOnly={readOnly} onChange={(n) => setItem(i, { blurRadius: n })} />
            <LabeledNumber label="spread" value={num(s.spreadRadius)} readOnly={readOnly} onChange={(n) => setItem(i, { spreadRadius: n })} />
          </div>
        </div>
      ))}
      {!readOnly && (
        <button type="button" style={addBtnStyle} onClick={add}>
          + Adicionar sombra
        </button>
      )}
    </FieldLabel>
  );
}

/** Config de campo de lista de sombras (boxShadow). */
export function shadowListField(label?: string): Record<string, unknown> {
  return { type: "custom", label, render: ShadowListField };
}

// ── Gradiente (linear/radial): tipo + cores + begin/end ────────────────────────

function GradientField({ field, name, value, onChange, readOnly }: CustomFieldProps): ReactElement {
  const g = (value && typeof value === "object" ? value : {}) as Record<string, unknown>;
  const type = typeof g.type === "string" ? g.type : "linear";
  const colors: string[] = Array.isArray(g.colors) ? (g.colors as string[]) : [];
  const begin = typeof g.begin === "string" ? g.begin : undefined;
  const end = typeof g.end === "string" ? g.end : undefined;

  const emit = (patch: Record<string, unknown>) => {
    const next: Record<string, unknown> = { type, colors, begin, end, ...patch };
    const cleaned = (next.colors as string[]).filter((c) => typeof c === "string" && c !== "");
    if (cleaned.length === 0) {
      onChange(undefined); // sem cores → sem gradiente
      return;
    }
    next.colors = cleaned;
    onChange(pruneBlank(next));
  };

  const setColor = (i: number, c: string | undefined) => {
    const copy = [...colors];
    copy[i] = c ?? "";
    emit({ colors: copy });
  };

  return (
    <FieldLabel el="div" label={field?.label ?? name} icon={field?.labelIcon} readOnly={readOnly}>
      <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
        <MiniSelect
          ariaLabel="tipo de gradiente"
          value={type}
          readOnly={readOnly}
          options={[
            { value: "linear", label: "linear" },
            { value: "radial", label: "radial" },
          ]}
          onChange={(t) => emit({ type: t ?? "linear" })}
        />
        {colors.map((c, i) => (
          <div key={i} style={{ display: "flex", gap: 6, alignItems: "flex-end" }}>
            <div style={{ flex: 1 }}>
              <ColorField name={`cor ${i + 1}`} value={c} readOnly={readOnly} onChange={(v) => setColor(i, v as string | undefined)} />
            </div>
            {!readOnly && (
              <button
                type="button"
                aria-label="Remover cor"
                title="Remover cor"
                style={{ ...removeBtnStyle, paddingBottom: 8 }}
                onClick={() => emit({ colors: colors.filter((_, idx) => idx !== i) })}
              >
                ✕
              </button>
            )}
          </div>
        ))}
        {!readOnly && (
          <button type="button" style={addBtnStyle} onClick={() => emit({ colors: [...colors, "#1565C0"] })}>
            + Adicionar cor
          </button>
        )}
        {type === "linear" && (
          <div style={GRID2}>
            <label style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={{ fontSize: 11, color: "#6b7280" }}>begin</span>
              <MiniSelect ariaLabel="begin" value={begin} readOnly={readOnly} options={ALIGN_OPTS} onChange={(v) => emit({ begin: v })} />
            </label>
            <label style={{ display: "flex", flexDirection: "column", gap: 2 }}>
              <span style={{ fontSize: 11, color: "#6b7280" }}>end</span>
              <MiniSelect ariaLabel="end" value={end} readOnly={readOnly} options={ALIGN_OPTS} onChange={(v) => emit({ end: v })} />
            </label>
          </div>
        )}
      </div>
    </FieldLabel>
  );
}

/** Config de campo de gradiente (linear/radial). */
export function gradientField(label?: string): Record<string, unknown> {
  return { type: "custom", label, render: GradientField };
}

// ── Cabeçalho de seção (agrupa campos do Inspector) ────────────────────────────

function SectionHeader({ field }: CustomFieldProps): ReactElement {
  return (
    <div
      style={{
        margin: "16px 0 2px",
        paddingBottom: 4,
        borderBottom: "1px solid #eceff1",
        fontSize: 11,
        fontWeight: 700,
        letterSpacing: 0.6,
        textTransform: "uppercase",
        color: "#90a4ae",
      }}
    >
      {field?.label ?? ""}
    </div>
  );
}

/** Pseudo-campo: cabeçalho de seção (não emite valor). */
export function sectionHeaderField(label: string): Record<string, unknown> {
  return { type: "custom", label, render: SectionHeader };
}
