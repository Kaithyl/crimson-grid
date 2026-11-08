// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Adapted from IntegratedCircuit/Port.jsx
import { classes } from 'tgui-core/react';

import type { PortMouseHandler } from '../hooks/useWiring';
import { isTriggerPort, type PortHandle } from '../ports';
import { hasValueEditor, PortValueInput } from './PortValueInput';

type Props = {
  handle: PortHandle;
  slot: string;
  value: string;
  linked: boolean;
  invalid: boolean;
  readOnly: boolean;
  onMouseDown?: PortMouseHandler;
  onMouseUp?: PortMouseHandler;
  onContextMenu?: PortMouseHandler;
  onSetValue?: (nodeId: string, key: string, value: string | null) => void;
};

export const Port = (props: Props) => {
  const { handle, slot, value, linked, invalid, readOnly } = props;
  const { onMouseDown, onMouseUp, onContextMenu, onSetValue } = props;
  const { dir, port } = handle;
  const trigger = isTriggerPort(port);

  // `data-port` is how NodeCard finds this socket when measuring wire endpoints
  const socket = (
    <span
      data-port={slot}
      className={classes([
        'rote-port__socket',
        `rote-port__socket--${dir}`,
        trigger && 'rote-port--activate',
        invalid && 'rote-port--invalid',
      ])}
      title={trigger ? port.name : undefined}
      onMouseDown={(e) => onMouseDown?.(handle, e)}
      onMouseUp={trigger ? (e) => onMouseUp?.(handle, e) : undefined}
      onContextMenu={(e) => onContextMenu?.(handle, e)}
    />
  );

  if (trigger) {
    return socket;
  }

  // For data ports, the whole row accepts a dropped wire, which is easier to hit than the socket alone
  return (
    <div
      className={classes(['rote-node__port-label', invalid && 'rote-port--invalid'])}
      title={`${port.name} (type ${port.type})`}
      onMouseUp={(e) => onMouseUp?.(handle, e)}
    >
      {socket}
      <span>{port.name}</span>
      {dir === 'in' && hasValueEditor(port) && (
        <PortValueInput
          port={port}
          value={value}
          disabled={readOnly || linked}
          onCommit={(next) => onSetValue?.(handle.nodeId, port.key, next)}
        />
      )}
      {!!port.desc && <div className="rote-port__tooltip">{port.desc}</div>}
    </div>
  );
};
