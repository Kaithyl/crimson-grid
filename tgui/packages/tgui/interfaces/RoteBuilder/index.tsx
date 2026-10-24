// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { Button, Input } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { Window } from '../../layouts';

import { MAX_ROTENAME_CHARS, MAX_NODES } from './constants';
import { EffectsMenu } from './EffectsMenu';
import { NodeSettingsMenu } from './NodeSettingsMenu';
import { getUserData } from './rote/rote';
import type { RoteBuilderData } from './types';
import { useCanvas } from './useCanvas';
import { useNodeSettings } from './useNodeSettings';
import { useNodeHandler } from './useNodeHandler';
import { useRoteHandler } from './useRoteHandler';

// @ts-ignore
import 'drawflow/dist/drawflow.min.css';
// @ts-ignore
import '../../styles/interfaces/RoteBuilder.scss'; // Load this last to override default drawflow styles

const DEFAULT_USERDATA = {
  label: '',
  success_percentage: 0,
  min_success: 0,
  max_success: 0,
  sphere_index: 0,
};

export const RoteBuilder = () => {
  const { act, data } = useBackend<RoteBuilderData>();
  const { canvasRef, drawflowRef } = useCanvas();

  const {
    nodeData: nodesettings,
    save: handlePopupSave,
    close: handlePopupClose,
  } = useNodeSettings(canvasRef);

  const {
    roteName,
    setRoteName,
    message,
    roteStats,
    roteCode,
    viewOnly,
    handleMessage,
    refreshStats,
    handleSave,
  } = useRoteHandler({ drawflowRef, data, act });

  const nodeHandlers = useNodeHandler({
    drawflowRef,
    effects: data.effects,
    userStats: data.user_stats,
    viewOnly,
    onMessage: handleMessage,
    onGraphChanged: refreshStats,
  });

  return (
    <Window title="Rote Builder" width={1200} height={800}>
      <Window.Content className="rote-builder__content">
        <div className="rote-builder">
          <div
            ref={canvasRef}
            className="rote-builder__canvas"
            onDragOver={nodeHandlers.onDragOver}
            onDrop={nodeHandlers.onDrop}
          />

          <EffectsMenu
            effects={data.effects}
            onDragStart={nodeHandlers.onDragStart}
            onDragEnd={nodeHandlers.onDragEnd}
          />

          <div className="rote-builder__save-panel">
            <div className="rote-builder__save-row">
              {!viewOnly && (
                <Input
                  fluid
                  className="rote-builder__save-name"
                  placeholder="Rote name"
                  value={roteName}
                  maxLength={MAX_ROTENAME_CHARS}
                  onChange={setRoteName}
                />
              )}
              <div className="rote-builder__save-stats">
                <div className="rote-builder__complexity">
                  Complexity: {roteStats.complexity}
                </div>
                <div className="rote-builder__node-count">
                  Nodes: {roteStats.node_count}/{MAX_NODES}
                </div>
              </div>
              {!viewOnly && (
                <Button icon="save" color="good" onClick={handleSave}>
                  Save
                </Button>
              )}
            </div>
            {roteCode && (
              <div className="rote-builder__rote-code">
                <div className="rote-builder__rote-code-label">Code: </div>
                <div className="rote-builder__rote-code-value" title={roteCode}>{roteCode}</div>
              </div>
            )}
          </div>

          {message && (
            <div
              className={`rote-builder__message ${message.isError ? 'rote-builder__message--error' : 'rote-builder__message--ok'}`}
            >
              {message.text}
            </div>
          )}

          {nodesettings && (
            <NodeSettingsMenu
              effect={nodesettings.effect}
              data={getUserData(nodesettings.nodeId) ?? DEFAULT_USERDATA}
              onSave={handlePopupSave}
              onClose={handlePopupClose}
            />
          )}
        </div>
      </Window.Content>
    </Window>
  );
}
