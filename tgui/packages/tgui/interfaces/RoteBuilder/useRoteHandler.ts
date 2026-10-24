import { useEffect, useRef, useState } from 'react';
import type { RefObject } from 'react';
import type Drawflow from 'drawflow';

import { MAX_ROTENAME_CHARS, MAX_NODES } from './constants';
import { getRoteStats, resetRote, type RoteStats } from './rote/rote';
import {
  buildRoteData,
  loadRoteIntoEditor,
  parseRoteData,
  serializeRoteData,
  validateRote,
} from './rote/serializer';
import type { RoteBuilderData } from './types';

type UiMessage = { text: string; isError: boolean } | null;

const EMPTY_STATS: RoteStats = { node_count: 0, complexity: 0, nodes: {} };

type RoteHandlerArgs = {
  drawflowRef: RefObject<Drawflow | null>;
  data: RoteBuilderData;
  act: (action: string, payload?: Record<string, unknown>) => void;
};

export const useRoteHandler = (args: RoteHandlerArgs) => {
  const { drawflowRef, data, act } = args;
  const loadedRef = useRef(false);

  const [roteName, setRoteName] = useState(data.rote_name ?? '');
  const [message, setMessage] = useState<UiMessage>(null);
  const [roteStats, setRoteStats] = useState<RoteStats>(EMPTY_STATS);
  const [roteCode, setRoteCode] = useState<string | null>(data.rote_data ?? null);

  const viewOnly = !!data.view_only;

  const handleMessage = (text: string, isError: boolean) => {
    setMessage(text ? { text, isError } : null);
  };

  const refreshStats = () => {
    setRoteStats(getRoteStats());
  };

  useEffect(() => {
    const df = drawflowRef.current;
    if (!df) {
      return;
    }

    resetRote();
    refreshStats();

    df.on('nodeCreated', refreshStats);
    df.on('nodeRemoved', refreshStats);

    if (!loadedRef.current && data.rote_data) {
      loadedRef.current = true;
      const graph = parseRoteData(data.rote_data, data.effects);
      if (graph) {
        loadRoteIntoEditor(df, graph);
      }
      refreshStats();
    }

    return () => {
      const removeListener = (name: string) => {
        const entry = df.events[name];
        if (entry) {
          entry.listeners = entry.listeners.filter((listener) => listener !== refreshStats);
        }
      };
      removeListener('nodeCreated');
      removeListener('nodeRemoved');
    };
  }, [drawflowRef]);

  const handleSave = () => {
    const df = drawflowRef.current;
    if (!df) {
      return;
    }

    const name = roteName.trim();
    if (!name) {
      setMessage({ text: 'Give your rote a name before saving.', isError: true });
      return;
    }
    if (name.length > MAX_ROTENAME_CHARS) {
      setMessage({ text: `Rote names must be ${MAX_ROTENAME_CHARS} characters or fewer.`, isError: true });
      return;
    }

    const stats = getRoteStats();
    if (stats.node_count === 0) {
      setMessage({
        text: 'Your rote needs at least one node before it can be saved.',
        isError: true,
      });
      return;
    }

    const rote = buildRoteData(df, data.effects);
    const validation = validateRote(rote, data.effects, data.user_stats);
    if (!validation.ok) {
      setMessage({ text: validation.error, isError: true });
      return;
    }

    const compressedCode = serializeRoteData(df, data.effects);
    act('save_rote', {
      name,
      rote_data: JSON.stringify(rote),
      rote_code: compressedCode,
    });
    setRoteCode(compressedCode);
    setMessage({ text: `"${name}" saved to rote slot 1.`, isError: false });
  };

  return {
    roteName,
    setRoteName,
    message,
    roteStats,
    roteCode,
    viewOnly,
    handleMessage,
    refreshStats,
    handleSave,
  };
};
