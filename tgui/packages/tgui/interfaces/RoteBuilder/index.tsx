// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Based on tg's IntegratedCircuit UI
import { useMemo, useRef, useState } from 'react';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { EffectsMenu } from './lib/components/EffectsMenu';
import { NodeCard } from './lib/components/NodeCard';
import { NodeSettingsMenu } from './lib/components/NodeSettingsMenu';
import { RoteCanvas } from './lib/components/RoteCanvas';
import { SavePanel } from './lib/components/SavePanel';
import { makePreviewNode } from './lib/graph';
import { usePlacement } from './lib/hooks/usePlacement';
import { useRoteEditor } from './lib/hooks/useRoteEditor';
import { useViewport } from './lib/hooks/useViewport';
import type { RoteBuilderData } from './lib/types';

// @ts-ignore
import '../../styles/interfaces/RoteBuilder.scss';

export const RoteBuilder = () => {
  const { act, data } = useBackend<RoteBuilderData>();
  const editor = useRoteEditor(data, act);
  const viewport = useViewport();
  const canvasRef = useRef<HTMLDivElement | null>(null);
  const [settingsId, setSettingsId] = useState<string | null>(null);

  const placement = usePlacement({
    canvasRef,
    toPlane: viewport.toPlane,
    disabled: editor.viewOnly,
    onPlace: editor.placeEffect,
  });

  const ghostEffect = placement.ghost?.effect;
  const ghostNode = useMemo(() => ghostEffect && makePreviewNode(ghostEffect), [ghostEffect]);
  const settingsNode = settingsId ? editor.graph.nodes[settingsId] : undefined;

  return (
    <Window title="Rote Builder" width={1200} height={800}>
      <Window.Content className="rote-builder__content">
        <div className="rote-builder">
          <RoteCanvas
            canvasRef={canvasRef}
            graph={editor.graph}
            dispatch={editor.dispatch}
            viewport={viewport}
            readOnly={editor.viewOnly}
            shortcutsEnabled={!settingsNode}
            onOpenSettings={setSettingsId}
          />

          <EffectsMenu effects={data.effects} onPickUp={placement.pickUp} />

          <SavePanel
            roteName={editor.roteName}
            onNameChange={editor.setRoteName}
            stats={editor.stats}
            roteCode={editor.roteCode}
            viewOnly={editor.viewOnly}
            onSave={editor.save}
          />

          {editor.message && (
            <div
              className={`rote-builder__message ${
                editor.message.isError ? 'rote-builder__message--error' : 'rote-builder__message--ok'
              }`}
            >
              {editor.message.text}
            </div>
          )}

          {placement.ghost && ghostNode && (
            <NodeCard
              preview
              node={ghostNode}
              style={{
                left: placement.ghost.x,
                top: placement.ghost.y,
                transform: `scale(${viewport.zoom})`,
              }}
            />
          )}

          {settingsNode && (
            <NodeSettingsMenu
              key={settingsNode.id}
              effect={settingsNode.effect}
              settings={settingsNode.settings}
              readOnly={editor.viewOnly}
              onSave={(settings) => {
                editor.dispatch({ type: 'settings', id: settingsNode.id, settings });
                setSettingsId(null);
              }}
              onClose={() => setSettingsId(null)}
            />
          )}
        </div>
      </Window.Content>
    </Window>
  );
}
