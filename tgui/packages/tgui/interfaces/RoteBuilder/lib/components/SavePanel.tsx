// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { useState } from 'react';
import { Button, Input, Modal, Section, TextArea } from 'tgui-core/components';

import { MAX_NODES, MAX_ROTENAME_CHARS } from '../constants';
import type { RoteStats } from '../graph';

type Props = {
  roteName: string;
  onNameChange: (value: string) => void;
  onOpenDescModal: () => void;
  stats: RoteStats;
  roteCode: string | null;
  viewOnly: boolean;
  onCompile: () => void;
  onImport: (code: string) => void;
  canReset: boolean;
  onReset: () => void;
};

export const SavePanel = (props: Props) => {
  const {
    roteName,
    onNameChange,
    onOpenDescModal,
    stats,
    roteCode,
    viewOnly,
    onCompile,
    onImport,
    canReset,
    onReset,
  } = props;
  const [importOpen, setImportOpen] = useState(false);
  const [importCode, setImportCode] = useState('');

  const closeImport = () => {
    setImportOpen(false);
    setImportCode('');
  };

  const doImport = () => {
    onImport(importCode);
    closeImport();
  };

  return (
    <div className="rote-builder__save-panel">
      <div className="rote-builder__save-row">
        {!viewOnly && (
          <>
            <Input
              fluid
              className="rote-builder__save-name"
              placeholder="Rote name"
              value={roteName}
              maxLength={MAX_ROTENAME_CHARS}
              onChange={onNameChange}
            />
            <Button icon="align-left" tooltip="Set rote description" onClick={onOpenDescModal} />
          </>
        )}
        <div className="rote-builder__save-stats">
          <div className="rote-builder__complexity">
            Complexity: {stats.complexity}/{stats.max_complexity}
          </div>
          <div className="rote-builder__node-count">
            Nodes: {stats.node_count}/{MAX_NODES}
          </div>
        </div>
        {!viewOnly && (
          <>
            <Button icon="save" color="good" onClick={onCompile}>
              Save
            </Button>
            <Button icon="file-import" color="average" onClick={() => setImportOpen(true)}>
              Import
            </Button>
            <Button
              icon="arrow-rotate-left"
              color="average"
              disabled={!canReset}
              onClick={onReset}
            >
              Reset
            </Button>
          </>
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
      {importOpen && (
        <Modal>
          <Section
            title="Import Rote"
            buttons={
              <>
                <Button color="red" icon="window-close" onClick={closeImport}>
                  Cancel
                </Button>
                <Button
                  color="average"
                  icon="file-import"
                  disabled={!importCode.trim()}
                  onClick={doImport}
                >
                  Import
                </Button>
              </>
            }
          >
            <TextArea
              fluid
              height="4rem"
              placeholder="Paste a rote code here to import it..."
              value={importCode}
              onChange={setImportCode}
            />
          </Section>
        </Modal>
      )}
    </div>
  );
};
