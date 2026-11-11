import { useCallback, useEffect, useMemo, useReducer, useRef, useState } from 'react';

import { MAX_ROTENAME_CHARS } from '../constants';
import { EMPTY_GRAPH, getStats, graphReducer, type RoteGraph } from '../graph';
import { decodeRote, encodeRote, toRoteData } from '../serializer';
import type { NodeData, Position, RoteBuilderData } from '../types';
import { findUnreachableNodes, placementError, validateRote } from '../validator';

type Act = (action: string, payload?: Record<string, unknown>) => void;
type UiMessage = { text: string; isError: boolean } | null;

const UNREACHABLE_ERROR = 'Your rote contains unreachable nodes.';
const NO_HIGHLIGHTS: ReadonlySet<string> = new Set();

const initEditor = (data: RoteBuilderData) => {
  if (!data.rote_data) {
    return { graph: EMPTY_GRAPH, message: null as UiMessage };
  }
  const graph = decodeRote(data.rote_data, data.nodes);
  return graph
    ? { graph, message: null as UiMessage }
    : { graph: EMPTY_GRAPH, message: { text: 'This rote could not be loaded.', isError: true } };
};

export const useRoteEditor = (data: RoteBuilderData, act: Act) => {
  const [initial] = useState(() => initEditor(data));
  const [graph, dispatch] = useReducer(graphReducer, initial.graph);
  const [savedGraph, setSavedGraph] = useState<RoteGraph>(initial.graph);
  const [message, setMessage] = useState<UiMessage>(initial.message);
  const [highlightedNodes, setHighlightedNodes] =
    useState<ReadonlySet<string>>(NO_HIGHLIGHTS);
  const [roteName, setRoteName] = useState(data.rote_name ?? '');
  const [roteDesc, setRoteDesc] = useState(data.rote_desc ?? '');
  const [roteCode, setRoteCode] = useState<string | null>(data.rote_data ?? null);
  // For displaying on-compile node error warnings
  const [compileAttempted, setCompileAttempted] = useState(false);

  const viewOnly = !!data.view_only;
  const stats = useMemo(() => getStats(graph), [graph]);

  // Holds changes so they persist after window is closed
  const persistRef = useRef({ name: roteName, desc: roteDesc, graph });
  persistRef.current = { name: roteName, desc: roteDesc, graph };

  const showMessage = useCallback(
    (text: string, isError = false, highlight: ReadonlySet<string> = NO_HIGHLIGHTS) => {
      setMessage(text ? { text, isError } : null);
      setHighlightedNodes(highlight);
    },
    [],
  );

  const placeNode = (node: NodeData, at: Position) => {
    if (viewOnly) {
      return;
    }
    const error = placementError(node, stats, data.user_stats);
    if (error) {
      showMessage(error, true);
      return;
    }
    dispatch({ type: 'add', node, at });
    showMessage('');
  };

  const importRote = (code: string) => {
    if (viewOnly) {
      return;
    }
    const trimmed = code.trim();
    if (!trimmed) {
      return showMessage('Paste a rote code to import.', true);
    }
    const graph = decodeRote(trimmed, data.nodes);
    if (!graph) {
      return showMessage('That rote code could not be read.', true);
    }
    dispatch({ type: 'load', graph });
    setSavedGraph(graph);
    setRoteCode(trimmed);
    showMessage('Rote imported.');
  };

  const compile = () => {
    setCompileAttempted(true);
    const name = roteName.trim();
    if (!name) {
      return showMessage('Give your rote a name before saving.', true);
    }
    if (name.length > MAX_ROTENAME_CHARS) {
      return showMessage(`Rote names must be ${MAX_ROTENAME_CHARS} characters or fewer.`, true);
    }
    if (stats.node_count === 0) {
      return showMessage('Your rote needs at least one node before it can be saved.', true);
    }

    const validation = validateRote(graph, data.nodes, data.user_stats);
    if (!validation.ok) {
      const highlight =
        validation.error === UNREACHABLE_ERROR ? findUnreachableNodes(graph) : undefined;
      return showMessage(validation.error, true, highlight);
    }

    const code = encodeRote(graph, data.nodes);
    act('compile_rote', {
      name,
      desc: roteDesc.trim(),
      rote_data: JSON.stringify(toRoteData(graph, data.nodes)),
      rote_code: code,
    });
    setSavedGraph(graph);
    setRoteCode(code);
    showMessage(`"${name}" saved to rote slot 1.`);
  };

  const canReset = graph !== savedGraph;

  const resetToSaved = () => {
    if (viewOnly) {
      return;
    }
    dispatch({ type: 'load', graph: savedGraph });
    showMessage('Reset to last saved build.');
  };

  // Saves graph without compiling the rote
  const save = useCallback(() => {
    if (viewOnly) {
      return;
    }
    const { name, desc, graph: current } = persistRef.current;
    act('save_rote', {
      name: name.trim(),
      desc: desc.trim(),
      rote_code: encodeRote(current, data.nodes),
    });
  }, [act, data.nodes, viewOnly]);

  // Autosave so work survives hard window close
  useEffect(() => {
    if (viewOnly) {
      return;
    }
    const timer = setTimeout(save, 800);
    return () => clearTimeout(timer);
  }, [graph, roteName, roteDesc, save, viewOnly]);

  useEffect(() => save, [save]);

  return {
    graph,
    dispatch,
    stats,
    message,
    highlightedNodes,
    roteName,
    setRoteName,
    roteDesc,
    setRoteDesc,
    roteCode,
    viewOnly,
    placeNode,
    importRote,
    compile,
    save,
    canReset,
    resetToSaved,
    compileAttempted,
  };
};
