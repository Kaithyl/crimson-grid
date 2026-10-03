// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { type DragEvent, useRef } from 'react';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';

import type { RoteBuilderData } from './types'
import { useCanvas } from './useCanvas';
import { createEffectNode } from './nodes/node'
import { EffectsMenu } from './EffectsMenu'

// @ts-ignore
import 'drawflow/dist/drawflow.min.css';
// @ts-ignore
import '../../styles/interfaces/RoteBuilder.scss'; // Load this last to override default drawflow styles

export const RoteBuilder = () => {
  const { data } = useBackend<RoteBuilderData>();
  const { canvasRef, drawflowRef } = useCanvas();

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

  const onDrop = (event: DragEvent) => {
    event.preventDefault();

    const df = drawflowRef.current;
    const id = event.dataTransfer.getData('text/plain') || draggedItemRef.current;
    draggedItemRef.current = null;

    if (!df || !id) {
      return;
    }

    const effect = data.effects.find((e) => e.name === id);
    if (!effect) {
      return;
    }

    createEffectNode(df, effect, event.clientX, event.clientY);
  };

  const onDragEnd = () => {
    draggedItemRef.current = null;
  };

  return (
    <Window title="Rote Builder" width={1200} height={800}>
      <Window.Content className="rote-builder__content">
        <div className="rote-builder">
            <div
                ref={canvasRef}
                className="rote-builder__canvas"
                onDragOver={onDragOver}
                onDrop={onDrop}
            />

            <EffectsMenu
                effects={data.effects}
                onDragStart={onDragStart}
                onDragEnd={onDragEnd}
            />
        </div>
      </Window.Content>
    </Window>
  );
}
