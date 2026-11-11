// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Adapted from IntegratedCircuit/Port.jsx
import type { ReactNode } from 'react';
import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import type { PortMouseHandler } from '../hooks/useWiring';
import {
  hasPromise,
  isOptionalTriggerPort,
  isPrimaryActivatePort,
  isTriggerPort,
  type PortHandle,
  portTypeLabel,
  promiseLabel,
} from '../ports';
import { hasValueEditor, PortValueInput } from './PortValueInput';

type Props = {
  handle: PortHandle;
  slot: string;
  value: string;
  linked: boolean;
  invalid: boolean;
  readOnly: boolean;
  // Extra inline content
  extra?: ReactNode;
  onMouseDown?: PortMouseHandler;
  onMouseUp?: PortMouseHandler;
  onContextMenu?: PortMouseHandler;
  onSetValue?: (nodeId: string, key: string, value: string | null) => void;
};

export const Port = (props: Props) => {
  const { handle, slot, value, linked, invalid, readOnly, extra } = props;
  const { onMouseDown, onMouseUp, onContextMenu, onSetValue } = props;
  const { dir, port } = handle;
  const trigger = isTriggerPort(port);
  const primaryActivate = isPrimaryActivatePort(port);
  const optionalTrigger = isOptionalTriggerPort(port);
  const promise = hasPromise(port);

  const socket = (
    <span
      data-port={slot}
      className={classes([
        'rote-port__socket',
        `rote-port__socket--${dir}`,
        trigger && 'rote-port--activate',
        trigger && !primaryActivate && 'rote-port--activate-inline',
        invalid && 'rote-port--invalid',
      ])}
      title={trigger ? port.name : undefined}
      onMouseDown={(e) => onMouseDown?.(handle, e)}
      onMouseUp={trigger ? (e) => onMouseUp?.(handle, e) : undefined}
      onContextMenu={(e) => onContextMenu?.(handle, e)}
    />
  );

  if (primaryActivate) {
    return socket;
  }

  return (
    <div
      className={classes(['rote-node__port-label', invalid && 'rote-port--invalid'])}
      title={`${port.name} (type ${port.type})`}
      onMouseUp={(e) => onMouseUp?.(handle, e)}
    >
      {socket}
      <div className="rote-node__port-text">
        <div className="rote-node__port-name-row">
          <span className="rote-node__port-name">
            {optionalTrigger ? 'Trigger' : port.name}
          </span>
          {dir === 'in' && !trigger && promise && (
            <span
              className="rote-port__promise"
              title={`Left empty, this port is guaranteed to be the ${promiseLabel(port).toLowerCase()}.`}
            >
              <Icon name="upload" className="rote-port__promise-icon" />
              <span className="rote-port__promise-label">{promiseLabel(port)}</span>
            </span>
          )}
          {dir === 'in' && !trigger && !promise && hasValueEditor(port) && (
            <PortValueInput
              port={port}
              value={linked ? '' : value}
              disabled={readOnly || linked}
              onCommit={(next) => onSetValue?.(handle.nodeId, port.id, next)}
            />
          )}
          {extra}
        </div>
        <div className="rote-node__port-type">{portTypeLabel(port)}</div>
      </div>
      {!!port.desc && <div className="rote-port__tooltip">{port.desc}</div>}
    </div>
  );
};
