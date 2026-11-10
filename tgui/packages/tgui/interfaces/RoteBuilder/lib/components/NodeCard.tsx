// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Adapted from IntegratedCircuit/ObjectComponent.jsx
import {
  type CSSProperties,
  memo,
  type MouseEvent as ReactMouseEvent,
  type SyntheticEvent,
  useLayoutEffect,
  useRef,
} from 'react';
import { classes } from 'tgui-core/react';

import type { RoteNode } from '../graph';
import type { PortMouseHandler } from '../hooks/useWiring';
import {
  canLink,
  isPrimaryActivatePort,
  type PortHandle,
  portSlot,
  portsOf,
  samePort,
} from '../ports';
import type { PortData, PortDir, PortOffsets } from '../types';
import { offsetWithin } from '../util';
import { Port } from './Ports';

type Props = {
  node: RoteNode;
  selected?: boolean;
  pending?: PortHandle | null;
  linked?: ReadonlySet<string>;
  readOnly?: boolean;
  preview?: boolean;
  style?: CSSProperties;
  onNodeMouseDown?: (id: string, e: ReactMouseEvent) => void;
  onPortMouseDown?: PortMouseHandler;
  onPortMouseUp?: PortMouseHandler;
  onPortRightClick?: PortMouseHandler;
  onOpenSettings?: (id: string) => void;
  onDelete?: (id: string) => void;
  onSetValue?: (id: string, key: string, value: string | null) => void;
  onMeasure?: (id: string, offsets: PortOffsets | null) => void;
};

const NO_LINKS: ReadonlySet<string> = new Set();
const stopPropagation = (e: SyntheticEvent) => e.stopPropagation();

const nodeClass = (type: string) => `rote-effect--${String(type).split('/').pop()}`;

const defaultText = (port: PortData) =>
  port.default_value === null || port.default_value === undefined ? '' : String(port.default_value);

export const NodeCard = memo((props: Props) => {
  const {
    node,
    selected,
    pending = null,
    linked = NO_LINKS,
    readOnly,
    preview,
    style,
    onNodeMouseDown,
    onPortMouseDown,
    onPortMouseUp,
    onPortRightClick,
    onOpenSettings,
    onDelete,
    onSetValue,
    onMeasure,
  } = props;
  const { id, node: nodeData, settings, values } = node;
  const rootRef = useRef<HTMLDivElement | null>(null);

  // Report where each port's centre sits inside this node. This runs again only when
  // the node changes size (for example, a label is added); moving the node doesn't need it.
  useLayoutEffect(() => {
    const root = rootRef.current;
    if (preview || !root || !onMeasure) {
      return;
    }
    const measure = () => {
      const offsets: PortOffsets = {};
      root.querySelectorAll<HTMLElement>('[data-port]').forEach((socket) => {
        const pos = offsetWithin(socket, root);
        if (pos) {
          offsets[socket.dataset.port as string] = {
            x: pos.x + socket.offsetWidth / 2,
            y: pos.y + socket.offsetHeight / 2,
          };
        }
      });
      onMeasure(id, offsets);
    };
    measure();
    const observer = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(measure);
    observer?.observe(root);
    return () => {
      observer?.disconnect();
      onMeasure(id, null);
    };
  }, [id, nodeData, preview, onMeasure]);

  const renderPort = (dir: PortDir, port: PortData) => {
    const handle: PortHandle = { nodeId: id, dir, port };
    const slot = portSlot(dir, port.key);
    return (
      <Port
        key={slot}
        handle={handle}
        slot={slot}
        value={values[port.key] ?? defaultText(port)}
        linked={linked.has(slot)}
        invalid={!!pending && !samePort(pending, handle) && !canLink(pending, handle)}
        readOnly={!!readOnly || !!preview}
        onMouseDown={onPortMouseDown}
        onMouseUp={onPortMouseUp}
        onContextMenu={onPortRightClick}
        onSetValue={onSetValue}
      />
    );
  };

  const inputs = portsOf(nodeData, 'in');
  const outputs = portsOf(nodeData, 'out');
  const desc = String(nodeData.desc ?? '').trim();

  return (
    <div
      ref={rootRef}
      className={classes([
        'rote-node',
        'rote-effect',
        nodeClass(nodeData.type),
        selected && 'rote-node--selected',
        preview && 'rote-node--preview',
      ])}
      style={preview ? style : { left: node.x, top: node.y }}
      onMouseDown={preview ? undefined : (e) => onNodeMouseDown?.(id, e)}
    >
      {inputs.filter(isPrimaryActivatePort).map((port) => renderPort('in', port))}
      {outputs.filter(isPrimaryActivatePort).map((port) => renderPort('out', port))}

      <div className="rote-node__body">
        <div className="rote-node__header">
          <div className="rote-node__title-row">
            <span className="rote-node__title-text">{nodeData.name}</span>
            <span
              className="rote-node__settings-icon"
              title="Edit node settings"
              onMouseDown={stopPropagation}
              onClick={() => onOpenSettings?.(id)}
            >
              ⚙
            </span>
            {!readOnly && !preview && (
              <span
                className="rote-node__delete-icon"
                title="Remove node"
                onMouseDown={stopPropagation}
                onClick={() => onDelete?.(id)}
              >
                ✕
              </span>
            )}
          </div>
          <div className={classes(['rote-node__label', !settings.label && 'rote-node__label--hidden'])}>
            {settings.label}
          </div>
        </div>

        <div className="rote-node__ports">
          <div className="rote-node__port-col rote-node__port-col--in">
            {inputs.filter((port) => !isPrimaryActivatePort(port)).map((port) => renderPort('in', port))}
          </div>
          <div className="rote-node__port-col rote-node__port-col--out">
            {outputs.filter((port) => !isPrimaryActivatePort(port)).map((port) => renderPort('out', port))}
          </div>
        </div>

        {!!desc && <div className="rote-node__tooltip">{desc}</div>}
      </div>

    </div>
  );
});
