"use client";

import { createUsePuck } from "@measured/puck";
import { useEffect, useRef } from "react";

const usePuckSel = createUsePuck();

/**
 * Sincroniza a seleção/painel de propriedades para que o título cravado "Page"
 * (que o Puck mostra para a raiz quando nada está selecionado — sem API para
 * trocar) NUNCA apareça:
 *
 *  1. **Auto-seleciona o 1º componente** ao carregar (e ao trocar de dados) →
 *     o painel mostra as props dele em vez de "Page". Respeita deseleção manual
 *     (não re-seleciona quando o usuário clica fora de propósito).
 *  2. **Esconde a barra de propriedades** quando nada está selecionado — em vez
 *     de exibir o "Page" vazio.
 *
 * Renderiza `null`; só roda efeitos. Deve viver DENTRO do `<Puck>` (usa `usePuck`).
 * Seletores primitivos (length/index) → os efeitos só rodam quando muda o que
 * importa, evitando re-render/loop. `recordHistory: false` não polui o desfazer.
 */
export function EditorSelectionSync(): null {
  const contentLength = usePuckSel((s) => s.appState.data.content.length);
  const selectedIndex = usePuckSel((s) => s.appState.ui.itemSelector?.index ?? null);
  const dispatch = usePuckSel((s) => s.dispatch);

  const prevLen = useRef<number>(-1);
  const autoSelected = useRef(false);

  // (1) Auto-seleção do 1º componente — no carregamento inicial e ao trocar de
  // dados (load de versão/undo mudam `contentLength` → rearma). Só age quando
  // nada está selecionado; após uma deseleção manual NÃO re-seleciona.
  useEffect(() => {
    if (contentLength !== prevLen.current) {
      prevLen.current = contentLength;
      autoSelected.current = false; // dados novos → permite auto-selecionar
    }
    if (contentLength === 0) return; // nada a selecionar
    if (!autoSelected.current && selectedIndex === null) {
      dispatch({
        type: "setUi",
        ui: { itemSelector: { index: 0 } },
        recordHistory: false,
      });
      autoSelected.current = true;
    } else if (selectedIndex !== null) {
      // já havia seleção (ex.: pré-seleção via prop `ui`) → nada a fazer
      autoSelected.current = true;
    }
  }, [contentLength, selectedIndex, dispatch]);

  // (2) Esconde a barra direita quando nada está selecionado.
  useEffect(() => {
    dispatch({
      type: "setUi",
      ui: { rightSideBarVisible: selectedIndex !== null },
      recordHistory: false,
    });
  }, [selectedIndex, dispatch]);

  return null;
}
