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
import { Icon } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import { TAG_FOCI } from '../constants';
import type { RoteNode } from '../graph';
import type { PortMouseHandler } from '../hooks/useWiring';
import {
  canLink,
  extendablePortGroups,
  isPrimaryActivatePort,
  type PortHandle,
  portGroupOf,
  portSlot,
  portsOf,
  samePort,
} from '../ports';
import type { PortData, PortDir, PortOffsets } from '../types';
import { offsetWithin } from '../util';
import type { NodeIssue } from '../validator';
import { Port } from './Ports';

type Props = {
  node: RoteNode;
  selected?: boolean;
  pending?: PortHandle | null;
  linked?: ReadonlySet<string>;
  highlighted?: boolean;
  issues?: NodeIssue[];
  readOnly?: boolean;
  preview?: boolean;
  style?: CSSProperties;
  onNodeMouseDown?: (id: string, e: ReactMouseEvent) => void;
  onPortMouseDown?: PortMouseHandler;
  onPortMouseUp?: PortMouseHandler;
  onPortRightClick?: PortMouseHandler;
  onOpenSettings?: (id: string) => void;
  onExamine?: (id: string, e: ReactMouseEvent) => void;
  onDelete?: (id: string) => void;
  onSetValue?: (id: string, key: string, value: string | null) => void;
  onPortCount?: (id: string, group: string, count: number) => void;
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
    highlighted,
    issues,
    readOnly,
    preview,
    style,
    onNodeMouseDown,
    onPortMouseDown,
    onPortMouseUp,
    onPortRightClick,
    onOpenSettings,
    onExamine,
    onDelete,
    onSetValue,
    onPortCount,
    onMeasure,
  } = props;
  const { id, node: nodeData, settings, values } = node;
  const rootRef = useRef<HTMLDivElement | null>(null);

  // Get port locations, only recheck if node html element changes size
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

  const groups = extendablePortGroups(nodeData);
  const portCounts = settings.port_counts ?? {};
  // Unset groups fall back to their default visible count
  const countFor = (group: string) => portCounts[group] ?? groups[group]?.default;
  const visible = (port: PortData) => {
    const group = portGroupOf(nodeData, port.id);
    if (group === null) {
      return true;
    }
    const count = countFor(group);
    return count === undefined || Number(port.id.slice(group.length)) < count;
  };

  const renderPort = (dir: PortDir, port: PortData, extra?: React.ReactNode) => {
    const handle: PortHandle = { nodeId: id, dir, port };
    const slot = portSlot(dir, port.id);
    return (
      <Port
        key={slot}
        handle={handle}
        slot={slot}
        value={values[port.id] ?? defaultText(port)}
        linked={linked.has(slot)}
        invalid={!!pending && !samePort(pending, handle) && !canLink(pending, handle)}
        readOnly={!!readOnly || !!preview}
        onMouseDown={onPortMouseDown}
        onMouseUp={onPortMouseUp}
        onContextMenu={onPortRightClick}
        onSetValue={onSetValue}
        extra={extra}
      />
    );
  };

  const renderGroupControls = (group: string) => {
    const def = groups[group];
    if (!def || readOnly || preview) {
      return null;
    }
    const count = countFor(group) ?? def.default;
    return (
      <div className="rote-node__port-group-controls">
        <span
          className={classes([
            'rote-node__port-group-btn',
            count <= def.min && 'rote-node__port-group-btn--disabled',
          ])}
          title="Remove port"
          onMouseDown={stopPropagation}
          onClick={() => count > def.min && onPortCount?.(id, group, count - 1)}
        >
          −
        </span>
        <span
          className={classes([
            'rote-node__port-group-btn',
            count >= def.max && 'rote-node__port-group-btn--disabled',
          ])}
          title="Add port"
          onMouseDown={stopPropagation}
          onClick={() => count < def.max && onPortCount?.(id, group, count + 1)}
        >
          +
        </span>
      </div>
    );
  };

  const renderColumn = (dir: PortDir) => {
    const shown = portsOf(nodeData, dir).filter(
      (port) => visible(port) && !isPrimaryActivatePort(port),
    );
    const controlsShown = new Set<string>();
    const rows = shown.map((port) => {
      const group = portGroupOf(nodeData, port.id);
      let extra: React.ReactNode;
      if (group !== null && !controlsShown.has(group)) {
        controlsShown.add(group);
        extra = renderGroupControls(group);
      }
      return renderPort(dir, port, extra);
    });
    // handle extendable ports with 0 visible ports
    for (const group of Object.keys(groups)) {
      if (controlsShown.has(group)) {
        continue;
      }
      const ownsColumn = portsOf(nodeData, dir).some(
        (p) => portGroupOf(nodeData, p.id) === group,
      );
      if (!ownsColumn) {
        continue;
      }
      controlsShown.add(group);
      rows.push(
        <div key={`group-${group}`} className="rote-node__port-group-row">
          {renderGroupControls(group)}
        </div>,
      );
    }
    return rows;
  };

  const inputs = portsOf(nodeData, 'in').filter(visible);
  const outputs = portsOf(nodeData, 'out').filter(visible);
  const desc = String(nodeData.desc ?? '').trim();

  const level: 'error' | 'warning' | 'skipped' | null = issues?.some(
    (issue) => issue.severity === 'error',
  )
    ? 'error'
    : issues?.some((issue) => issue.severity === 'warning')
      ? 'warning'
      : issues?.some((issue) => issue.severity === 'skipped')
        ? 'skipped'
        : null;

  // Node description for complexity vars
  const complexityText = (() => {
    if ((nodeData.tags & TAG_FOCI) !== 0) {
      const cap = nodeData.complexity_cap ?? 0;
      return cap > 0 ? `Max Complexity: +${cap}` : '';
    }
    const cost = nodeData.complexity ?? 0;
    return cost > 0 ? `Complexity: +${cost}` : '';
  })();

  return (
    <div
      ref={rootRef}
      className={classes([
        'rote-node',
        'rote-effect',
        nodeClass(nodeData.type),
        selected && 'rote-node--selected',
        highlighted && 'rote-node--unreachable',
        level === 'error' && 'rote-node--issue',
        level === 'warning' && 'rote-node--warning',
        level === 'skipped' && 'rote-node--skipped',
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
            {!!issues?.length && (
              <span
                className="rote-node__info-icon"
                onMouseDown={stopPropagation}
                onClick={(e) => {
                  e.stopPropagation();
                  onExamine?.(id, e);
                }}
              >
                <Icon name="info" />
              </span>
            )}
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
          <div className="rote-node__port-col rote-node__port-col--in">{renderColumn('in')}</div>
          <div className="rote-node__port-col rote-node__port-col--out">{renderColumn('out')}</div>
        </div>

        {(!!complexityText || !!desc) && (
          <div className="rote-node__tooltip">
            {!!complexityText && (
              <>
                <div className="rote-node__tooltip-complexity">{complexityText}</div>
                {!!desc && <div className="rote-node__tooltip-separator" />}
              </>
            )}
            {!!desc && <div>{desc}</div>}
          </div>
        )}
      </div>

    </div>
  );
});
