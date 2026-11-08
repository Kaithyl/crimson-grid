// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { Button, Input } from 'tgui-core/components';

import { MAX_NODES, MAX_ROTENAME_CHARS } from '../constants';
import type { RoteStats } from '../graph';

type Props = {
  roteName: string;
  onNameChange: (value: string) => void;
  stats: RoteStats;
  roteCode: string | null;
  viewOnly: boolean;
  onSave: () => void;
};

export const SavePanel = (props: Props) => {
  const { roteName, onNameChange, stats, roteCode, viewOnly, onSave } = props;
  return (
    <div className="rote-builder__save-panel">
      <div className="rote-builder__save-row">
        {!viewOnly && (
          <Input
            fluid
            className="rote-builder__save-name"
            placeholder="Rote name"
            value={roteName}
            maxLength={MAX_ROTENAME_CHARS}
            onChange={onNameChange}
          />
        )}
        <div className="rote-builder__save-stats">
          <div className="rote-builder__complexity">Complexity: {stats.complexity}</div>
          <div className="rote-builder__node-count">
            Nodes: {stats.node_count}/{MAX_NODES}
          </div>
        </div>
        {!viewOnly && (
          <Button icon="save" color="good" onClick={onSave}>
            Save
          </Button>
        )}
      </div>
      {roteCode && (
        <div className="rote-builder__rote-code">
          <div className="rote-builder__rote-code-label">Code: </div>
          <div className="rote-builder__rote-code-value" title={roteCode}>
            {roteCode}
          </div>
        </div>
      )}
    </div>
  );
};
