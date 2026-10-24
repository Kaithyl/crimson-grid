import type { RefObject } from 'react';
import { useRef, type DragEvent } from 'react';
import type Drawflow from 'drawflow';

import { MAX_NODES } from './constants';
import { createEffectNode } from './rote/node';
import { getRoteStats } from './rote/rote';
import type { EffectData, UserStats } from './types';

type NodeHandlerArgs = {
  drawflowRef: RefObject<Drawflow | null>;
  effects: EffectData[];
  userStats: UserStats;
  viewOnly: boolean;
  onMessage: (text: string, isError: boolean) => void;
  onGraphChanged: () => void;
};

const getErrorMessage = (
  effect: EffectData,
  userStats: UserStats,
): string | null => {
  if (!effect.spheres || effect.spheres.length === 0) {
    return null;
  }

  for (const option of effect.spheres) {
    let meets = true;
    for (const [sphere, required] of Object.entries(option)) {
      if ((Number(userStats[sphere]) || 0) < required) {
        meets = false;
        break;
      }
    }
    if (meets) {
      return null;
    }
  }

  return `You don't have the required spheres for "${effect.name}".`;
};

export const useNodeHandler = (args: NodeHandlerArgs) => {
  const { drawflowRef, effects, userStats, viewOnly, onMessage, onGraphChanged } = args;
  const draggedItemRef = useRef<string | null>(null);

  const onDragStart = (event: DragEvent, id: string) => {
    draggedItemRef.current = id;
    event.dataTransfer.setData('text/plain', id);
    event.dataTransfer.effectAllowed = 'copy';
  };

  const onDragOver = (event: DragEvent) => {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
  };

  const onDragEnd = () => {
    draggedItemRef.current = null;
  };

  const onDrop = (event: DragEvent) => {
    event.preventDefault();

    const df = drawflowRef.current;
    const id = event.dataTransfer.getData('text/plain') || draggedItemRef.current;
    draggedItemRef.current = null;

    if (!df || !id) {
      return;
    }

    const effect = effects.find((candidate) => candidate.name === id);
    if (!effect) {
      return;
    }

    if (viewOnly) {
      //onMessage('You are only viewing this rote.', true);
      return;
    }

    const stats = getRoteStats();
    const typeKey = effect.type ?? effect.name;
    const typeCount = stats.nodes[typeKey] ?? 0;

    if (stats.node_count >= MAX_NODES) {
      onMessage(`You can't have more than ${MAX_NODES}.`, true);
      return;
    }

    if (effect.max_nodes && typeCount >= effect.max_nodes) {
      onMessage(
        `You can't add more than ${effect.max_nodes} of "${effect.name}" to a rote.`,
        true,
      );
      return;
    }

    const error = getErrorMessage(effect, userStats);
    if (error) {
      onMessage(error, true);
      return;
    }

    createEffectNode(df, effect, event.clientX, event.clientY);
    onMessage('', false);
    onGraphChanged();
  };

  return { onDragStart, onDragOver, onDrop, onDragEnd };
};
