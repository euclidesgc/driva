"use client";

import "@measured/puck/puck.css";
import "./editor.css";
import dynamic from "next/dynamic";
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactElement,
  type ReactNode,
} from "react";
import type { Data, UiState } from "@measured/puck";
import {
  diagnose,
  getVersion,
  puckDataToSpec,
  specToPuckData,
  type Diagnostic,
  type DiagnosticSeverity,
  type PuckComponent,
  type PuckData,
  type SpecNode,
  type VersionStatus,
} from "@widgetmill/spec";
import { config, INITIAL_DATA } from "../lib/puck-config";
import {
  WidgetSessionProvider,
  useWidgetSession,
} from "../lib/widget-session";
import { PreviewFrame } from "../components/preview/PreviewFrame";
import { HeaderActions } from "../components/save/HeaderActions";
import { HistoryPanel } from "../components/save/HistoryPanel";
import { CompareView } from "../components/save/CompareView";
import { ConfirmDialog } from "../components/save/ConfirmDialog";
import { IdentityDialog, type IdentityValues } from "../components/save/IdentityDialog";
import { PreviewBanner } from "../components/save/PreviewBanner";
import { Toast } from "../components/save/Toast";
import { DiagnosticsContext } from "../components/diagnostics/context";
import { StatusBar } from "../components/diagnostics/StatusBar";
import { Tabs } from "../components/ui/Tabs";
import { JsonView } from "../components/ui/JsonView";

// Puck usa APIs de navegador (drag-and-drop) — carrega só no cliente.
const Puck = dynamic(() => import("@measured/puck").then((m) => m.Puck), {
  ssr: false,
});

// Auto-seleciona o 1º componente + esconde a barra direita quando nada está
// selecionado (assim o título cravado "Page" do Puck nunca aparece). Só no
// cliente — depende de @measured/puck (APIs de navegador).
const EditorSelectionSync = dynamic(
  () =>
    import("../components/editor/EditorSelectionSync").then(
      (m) => m.EditorSelectionSync,
    ),
  { ssr: false },
);

type SetData = (action: { type: "setData"; data: unknown }) => void;

const treeOf = (data: Data): SpecNode | null =>
  puckDataToSpec(data as unknown as PuckData) ?? null;

const diagnoseData = (data: Data): Diagnostic[] =>
  diagnose((data as unknown as PuckData).content as unknown as PuckComponent[]);

/** Mapa nodeId → severidade (erro tem precedência) para marcar o canvas. */
function diagMapOf(diags: Diagnostic[]): Map<string, DiagnosticSeverity> {
  const map = new Map<string, DiagnosticSeverity>();
  for (const d of diags) {
    if (!d.nodeId) continue;
    if (d.severity === "error" || !map.has(d.nodeId)) map.set(d.nodeId, d.severity);
  }
  return map;
}

/** Assinatura estável dos diagnósticos — detecta mudança real de conteúdo (não
 *  só de referência), para evitar re-render/propagação de contexto desnecessária. */
const sigOf = (diags: Diagnostic[]): string =>
  diags.map((d) => `${d.code}:${d.nodeId ?? ""}:${d.severity}`).join("|");

/** UI do Puck (estática): tablet como viewport padrão, sem controles de
 *  viewport/zoom. Constante de módulo p/ não recriar a prop a cada render. */
const PUCK_UI = {
  viewports: {
    controlsVisible: false,
    current: { width: 768, height: "auto" },
    options: [{ width: 768, height: "auto", label: "Tablet" }],
  },
  // Pré-seleciona o 1º componente já na 1ª render → o painel mostra as props dele
  // (não o título "Page") sem flash. EditorSelectionSync garante o mesmo caso o
  // Puck ignore esta seleção inicial.
  itemSelector: { index: 0 },
} satisfies Partial<UiState>;

type EditorView = "montagem" | "resultado";

/** Aba ativa da área central (Montagem ⇄ Spec), exposta por contexto para que os
 *  overrides do Puck fiquem ESTÁVEIS — trocar de aba não re-sincroniza o store nem
 *  reconstrói o canvas. */
const ViewContext = createContext<{ view: EditorView; setView: (v: EditorView) => void }>({
  view: "montagem",
  setView: () => {},
});

/** JSON do spec atual, exposto à aba "Spec". Via contexto, atualizá-lo re-renderiza
 *  só o painel da aba Spec — não o Puck nem o canvas. */
const SpecJsonContext = createContext<string>("");

/** Painel da aba "Spec": o JSON resultante da montagem (só leitura). O `JsonView`
 *  já preenche o pai (flex:1) — o padding fica no contêiner da aba em PreviewArea. */
function SpecPanel(): ReactElement {
  const json = useContext(SpecJsonContext);
  return <JsonView json={json} />;
}

/** Área central do editor (override `preview` do Puck): abas no topo + o conteúdo
 *  abaixo. O canvas (`children`, a "Montagem") fica SEMPRE montado, alternando por
 *  `display` — trocar de aba NÃO o reconstrói. O painel "Spec" só monta quando ativo. */
function PreviewArea({ children }: { children: ReactNode }): ReactElement {
  const { view, setView } = useContext(ViewContext);
  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", minHeight: 0 }}>
      <EditorSelectionSync />
      <div style={{ padding: "8px 12px", borderBottom: "1px solid #eee", background: "#fff" }}>
        <Tabs
          value={view}
          onChange={setView}
          options={[
            { value: "montagem", label: "Montagem" },
            { value: "resultado", label: "Spec" },
          ]}
        />
      </div>
      <div style={{ flex: 1, minHeight: 0, display: view === "montagem" ? "block" : "none" }}>
        {children}
      </div>
      <div
        style={{
          flex: 1,
          minHeight: 0,
          display: view === "resultado" ? "flex" : "none",
          flexDirection: "column",
          padding: 12,
          boxSizing: "border-box",
        }}
      >
        {view === "resultado" && <SpecPanel />}
      </div>
    </div>
  );
}

export default function EditorPage() {
  return (
    <WidgetSessionProvider>
      <EditorShell />
    </WidgetSessionProvider>
  );
}

function EditorShell() {
  const session = useWidgetSession();
  const dispatchRef = useRef<SetData | null>(null);
  const lastData = useRef<Data>(INITIAL_DATA);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const [previewSpec, setPreviewSpec] = useState<SpecNode | null>(() =>
    treeOf(INITIAL_DATA),
  );
  const [diagnostics, setDiagnostics] = useState<Diagnostic[]>(() =>
    diagnoseData(INITIAL_DATA),
  );
  const [events, setEvents] = useState<string[]>([]);
  const [view, setView] = useState<EditorView>("montagem");
  const [historyOpen, setHistoryOpen] = useState(false);
  const [identityOpen, setIdentityOpen] = useState(false);
  const [compareTo, setCompareTo] = useState<number | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<number | null>(null);
  const pendingSave = useRef<VersionStatus | null>(null);

  // Assinatura dos diagnósticos atuais — evita re-render quando uma edição não
  // muda diagnóstico nenhum (cor, tamanho, etc.). Init preguiçoso a partir do
  // estado inicial (useRef não tem init lazy nativo).
  const diagSig = useRef<string | null>(null);
  if (diagSig.current === null) diagSig.current = sigOf(diagnostics);

  const onChange = useCallback((data: Data) => {
    lastData.current = data;
    // Tudo num só timer debounced: diagnosticar + traduzir o spec a CADA tecla/
    // tick de slider deixava o editor pesado (percorre a árvore + re-renderiza o
    // canvas inteiro via DiagnosticsContext). Roda uma vez após a pausa, e só
    // atualiza os diagnósticos se a severidade de algum nó realmente mudou.
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => {
      setPreviewSpec(treeOf(data));
      const next = diagnoseData(data);
      const sig = sigOf(next);
      if (sig !== diagSig.current) {
        diagSig.current = sig;
        setDiagnostics(next);
      }
    }, 200);
  }, []);

  const doSave = useCallback(
    (status: VersionStatus) => {
      const tree = treeOf(lastData.current);
      if (tree) void session.save(status, tree);
    },
    [session],
  );

  const requestSave = useCallback(
    (status: VersionStatus) => {
      if (session.hasIdentity) doSave(status);
      else {
        pendingSave.current = status;
        setIdentityOpen(true);
      }
    },
    [session.hasIdentity, doSave],
  );

  const onIdentitySubmit = useCallback(
    async (values: IdentityValues) => {
      await session.saveIdentity(values);
      setIdentityOpen(false);
      if (pendingSave.current) {
        doSave(pendingSave.current);
        pendingSave.current = null;
      }
    },
    [session, doSave],
  );

  const onLoad = useCallback(
    async (version: number) => {
      const v = await session.loadVersion(version);
      if (v) {
        dispatchRef.current?.({
          type: "setData",
          data: specToPuckData(v.spec.tree),
        });
      }
      setHistoryOpen(false);
    },
    [session],
  );

  const compareOldSpec = useMemo<SpecNode | null>(() => {
    if (compareTo == null || !session.record) return null;
    return getVersion(session.record, compareTo)?.spec.tree ?? null;
  }, [compareTo, session.record]);

  const diagMap = useMemo(() => diagMapOf(diagnostics), [diagnostics]);
  const hasErrors = diagnostics.some((d) => d.severity === "error");

  // JSON do spec para a aba "JSON" (só leitura). Deriva do `previewSpec`, que já é
  // debounced → não recomputa a cada tecla; só re-stringifica quando o spec muda.
  const json = useMemo(
    () => (previewSpec ? JSON.stringify(previewSpec, null, 2) : ""),
    [previewSpec],
  );

  // Overrides ESTÁVEIS (deps []) — a aba ativa chega via ViewContext, então trocar
  // de aba NÃO recria overrides/plugins (sem re-sync do store, sem reconstruir o
  // canvas). As abas + conteúdo vivem na área central (override `preview`).
  const overrides = useMemo(
    () => ({
      preview: ({ children }: { children: ReactNode }) => (
        <PreviewArea>{children}</PreviewArea>
      ),
    }),
    [],
  );
  const plugins = useMemo(() => [{ overrides }], [overrides]);
  const viewCtx = useMemo(() => ({ view, setView }), [view]);

  // Estável entre renders (só muda com requestSave/hasErrors) — evita que o
  // Puck re-renderize o header a cada render do EditorShell.
  const renderHeaderActions = useCallback(
    ({ dispatch }: { dispatch: unknown }) => {
      dispatchRef.current = dispatch as SetData;
      return (
        <HeaderActions
          onSave={requestSave}
          onOpenHistory={() => setHistoryOpen(true)}
          onEditMetadata={() => setIdentityOpen(true)}
          canPublish={!hasErrors}
        />
      );
    },
    [requestSave, hasErrors],
  );

  const identityInitial: IdentityValues | undefined = session.identity
    ? {
        name: session.identity.name,
        slug: session.identity.slug,
        description: session.identity.description,
      }
    : undefined;

  return (
    <div style={{ display: "flex", height: "100vh" }}>
      <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column" }}>
        <DiagnosticsContext.Provider value={diagMap}>
          {/* `view` (aba) e `json` chegam por contexto → trocar de aba ou atualizar
              o JSON re-renderiza só o necessário, sem reconstruir o canvas do Puck. */}
          <ViewContext.Provider value={viewCtx}>
            <SpecJsonContext.Provider value={json}>
              <div className="wm-editor-host" style={{ flex: 1, minHeight: 0 }}>
                <Puck
                  config={config}
                  data={INITIAL_DATA}
                  onChange={onChange}
                  // Título do header = nome do componente (ou "— sem nome —" sem identidade).
                  headerTitle={session.identity?.name ?? "— sem nome —"}
                  // Canvas focado em EDIÇÃO: largura de tablet e sem controles de viewport
                  // — a simulação de dispositivo é papel do painel de Preview à direita.
                  ui={PUCK_UI}
                  renderHeaderActions={renderHeaderActions}
                  // Abas "Montagem | Spec" + troca canvas/JSON na área central
                  // (override `preview` via plugin), implementado em PreviewArea.
                  plugins={plugins}
                />
              </div>
            </SpecJsonContext.Provider>
          </ViewContext.Provider>
        </DiagnosticsContext.Provider>
        <StatusBar diagnostics={diagnostics} />
      </div>

      <aside
        style={{
          width: 430,
          display: "flex",
          flexDirection: "column",
          padding: 12,
          gap: 8,
          borderLeft: "1px solid #eee",
        }}
      >
        <PreviewBanner />
        <strong style={{ fontSize: 14 }}>Preview (Flutter)</strong>
        <div
          style={{
            flex: 1,
            minHeight: 0,
            border: "1px solid #eee",
            borderRadius: 8,
            overflow: "hidden",
          }}
        >
          <PreviewFrame
            spec={previewSpec}
            onAction={(a) =>
              setEvents((prev) => [JSON.stringify(a), ...prev].slice(0, 6))
            }
          />
        </div>
        {events.length > 0 && (
          <div style={{ fontSize: 12, color: "#555" }}>
            <strong>Eventos:</strong>
            <ul style={{ margin: "4px 0", paddingLeft: 18 }}>
              {events.map((ev, i) => (
                <li key={i}>{ev}</li>
              ))}
            </ul>
          </div>
        )}
      </aside>

      <HistoryPanel
        open={historyOpen}
        record={session.record}
        onClose={() => setHistoryOpen(false)}
        onLoad={onLoad}
        onCompare={(v) => setCompareTo(v)}
        onDelete={(v) => setDeleteTarget(v)}
        onRestore={(v) => void session.restoreVersion(v)}
      />
      <CompareView
        open={compareTo != null}
        versionLabel={compareTo != null ? `v${compareTo}` : ""}
        oldSpec={compareOldSpec}
        currentSpec={treeOf(lastData.current)}
        onClose={() => setCompareTo(null)}
      />
      <IdentityDialog
        open={identityOpen}
        initial={identityInitial}
        onSubmit={onIdentitySubmit}
        onCancel={() => setIdentityOpen(false)}
      />
      <ConfirmDialog
        open={deleteTarget != null}
        title={`Excluir a versão v${deleteTarget ?? ""}?`}
        danger
        confirmLabel="Excluir"
        message={
          <>
            A versão deixará de poder ser carregada, comparada ou usada. <strong>Esta
            exclusão ficará registrada no histórico</strong> (quem excluiu e quando) e não
            pode ser desfeita.
          </>
        }
        onConfirm={async () => {
          if (deleteTarget != null) await session.deleteVersion(deleteTarget);
          setDeleteTarget(null);
        }}
        onCancel={() => setDeleteTarget(null)}
      />
      <Toast message={session.toast} onDismiss={session.clearToast} />
    </div>
  );
}
