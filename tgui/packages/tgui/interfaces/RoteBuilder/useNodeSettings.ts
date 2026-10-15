import { useCallback, useEffect, useRef, useState } from 'react';

import type { EffectData, NodeUserData } from './types';
import { getNodeEntry, updateUserData } from './nodes/nodes';
import { NODE_SETTINGS_EVENT } from './events';

type NodeData = {
  nodeId: string;
  effect: EffectData;
} | null;

export const useNodeSettings = (canvasRef: React.RefObject<HTMLDivElement | null>) => {
  const [nodeData, setNodeData] = useState<NodeData>(null);
  const savedCallbackRef = useRef<((data: NodeUserData) => void) | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) {
      return;
    }

    const handleSettings = (e: Event) => {
      const nodeId = (e as CustomEvent).detail as string;
      if (!nodeId) {
        return;
      }

      const entry = getNodeEntry(nodeId);
      if (!entry) {
        return;
      }

      setNodeData({ nodeId, effect: entry.effect });
    };

    canvas.addEventListener(NODE_SETTINGS_EVENT, handleSettings);
    return () => canvas.removeEventListener(NODE_SETTINGS_EVENT, handleSettings);
  }, [canvasRef]);

  const close = useCallback(() => {
    setNodeData(null);
  }, []);

  const save = useCallback((userdata: NodeUserData) => {
    if (!nodeData) {
      return;
    }

    updateUserData(nodeData.nodeId, userdata);

    // Update only the label text in the DOM without rebuilding the whole node
    const nodeEl = document.querySelector(`#${nodeData.nodeId}`);
    if (nodeEl) {
      const labelEl = nodeEl.querySelector('.rote-node__label');
      if (labelEl) {
        labelEl.textContent = userdata.label || '';
        labelEl.classList.toggle('rote-node__label--hidden', !userdata.label);
      }
    }

    if (savedCallbackRef.current) {
      savedCallbackRef.current(userdata);
    }

    setNodeData(null);
  }, [nodeData]);

  return {
    nodeData,
    save,
    close,
    onSave: (cb: (data: NodeUserData) => void) => {
      savedCallbackRef.current = cb;
    },
  };
};
