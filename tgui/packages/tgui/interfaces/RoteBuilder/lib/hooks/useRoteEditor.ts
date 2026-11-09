import { useCallback, useMemo, useReducer, useState } from 'react';

import { MAX_ROTENAME_CHARS } from '../constants';
import { EMPTY_GRAPH, getStats, graphReducer } from '../graph';
import { decodeRote, encodeRote, toRoteData } from '../serializer';
import type { NodeData, Position, RoteBuilderData } from '../types';
import { placementError, validateRote } from '../validator';

type Act = (action: string, payload?: Record<string, unknown>) => void;
type UiMessage = { text: string; isError: boolean } | null;

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
  const [message, setMessage] = useState<UiMessage>(initial.message);
  const [roteName, setRoteName] = useState(data.rote_name ?? '');
  const [roteCode, setRoteCode] = useState<string | null>(data.rote_data ?? null);

  const viewOnly = !!data.view_only;
  const stats = useMemo(() => getStats(graph), [graph]);

  const showMessage = useCallback((text: string, isError = false) => {
    setMessage(text ? { text, isError } : null);
  }, []);

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

  const save = () => {
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
      return showMessage(validation.error, true);
    }

    const code = encodeRote(graph, data.nodes);
    act('save_rote', {
      name,
      rote_data: JSON.stringify(toRoteData(graph, data.nodes)),
      rote_code: code,
    });
    setRoteCode(code);
    showMessage(`"${name}" saved to rote slot 1.`);
  };

  return {
    graph,
    dispatch,
    stats,
    message,
    roteName,
    setRoteName,
    roteCode,
    viewOnly,
    placeNode,
    save,
  };
};
