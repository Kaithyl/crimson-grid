// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Based on tg's IntegratedCircuit UI
import { useMemo, useRef, useState } from 'react';

import { Button, Modal, Section, TextArea } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { NodeCard } from './lib/components/NodeCard';
import { NodeSettingsMenu } from './lib/components/NodeSettingsMenu';
import { NodesMenu } from './lib/components/NodesMenu';
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
  const [descModalOpen, setDescModalOpen] = useState(false);
  const [descDraft, setDescDraft] = useState('');

  const placement = usePlacement({
    canvasRef,
    toPlane: viewport.toPlane,
    disabled: editor.viewOnly,
    onPlace: editor.placeNode,
  });

  const ghostNodeData = placement.ghost?.node;
  const ghostNode = useMemo(
    () => ghostNodeData && makePreviewNode(ghostNodeData),
    [ghostNodeData],
  );
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
            userStats={data.user_stats}
            includeStranded={editor.compileAttempted}
            highlightedNodes={editor.highlightedNodes}
            shortcutsEnabled={!settingsNode}
            onOpenSettings={setSettingsId}
          />

          <NodesMenu nodes={data.nodes} onPickUp={placement.pickUp} />

          <SavePanel
            roteName={editor.roteName}
            onNameChange={editor.setRoteName}
            onOpenDescModal={() => {
              setDescDraft(editor.roteDesc);
              setDescModalOpen(true);
            }}
            stats={editor.stats}
            roteCode={editor.roteCode}
            viewOnly={editor.viewOnly}
            onCompile={editor.compile}
            onImport={editor.importRote}
            canReset={editor.canReset}
            onReset={editor.resetToSaved}
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
              node={settingsNode.node}
              settings={settingsNode.settings}
              readOnly={editor.viewOnly}
              onSave={(settings) => {
                editor.dispatch({ type: 'settings', id: settingsNode.id, settings });
                setSettingsId(null);
              }}
              onClose={() => setSettingsId(null)}
            />
          )}

          {descModalOpen && (
            <Modal>
              <Section
                title="Rote Description"
                buttons={
                  <>
                    <Button color="red" icon="window-close" onClick={() => setDescModalOpen(false)}>
                      Cancel
                    </Button>
                    <Button
                      color="good"
                      icon="save"
                      onClick={() => {
                        editor.setRoteDesc(descDraft);
                        setDescModalOpen(false);
                      }}
                    >
                      Save
                    </Button>
                  </>
                }
              >
                <TextArea
                  fluid
                  height="6rem"
                  placeholder="Describe this rote..."
                  value={descDraft}
                  onChange={setDescDraft}
                />
              </Section>
            </Modal>
          )}
        </div>
      </Window.Content>
    </Window>
  );
}
