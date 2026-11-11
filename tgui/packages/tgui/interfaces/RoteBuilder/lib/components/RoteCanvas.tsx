// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import {
  type Dispatch,
  type MouseEvent as ReactMouseEvent,
  type RefObject,
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react';

import { resolveAsset } from '../../../../assets';
import { type Connection, Connections } from '../../../common/Connections';
import { GRID_TILE, MOUSE_BUTTON_LEFT, WIRE_COLOR, WIRE_WIDTH } from '../constants';
import { type GraphAction, linkedSlots, type RoteGraph, wireBetween } from '../graph';
import { portSlot } from '../ports';
import type { Viewport } from '../hooks/useViewport';
import { useWiring } from '../hooks/useWiring';
import type { PortDir, PortOffsets, Position, UserStats } from '../types';
import { isEditableTarget, trackPointer, useLatest } from '../util';
import { computeNodeIssues } from '../validator';
import { NodeCard } from './NodeCard';
import { NodeInfo } from './NodeInfo';
import { RotePlane } from './RotePlane';

type Props = {
  canvasRef: RefObject<HTMLDivElement | null>;
  graph: RoteGraph;
  dispatch: Dispatch<GraphAction>;
  viewport: Viewport;
  readOnly: boolean;
  userStats: UserStats;
  includeStranded: boolean;
  highlightedNodes?: ReadonlySet<string>;
  // Don't use shortcuts while another menu like settings is open
  shortcutsEnabled: boolean;
  onOpenSettings: (nodeId: string) => void;
};

const NO_LINKS: ReadonlySet<string> = new Set();

const sameOffsets = (a: PortOffsets | undefined, b: PortOffsets) => {
  if (!a) {
    return false;
  }
  const keys = Object.keys(b);
  return (
    keys.length === Object.keys(a).length &&
    keys.every((k) => a[k] && a[k].x === b[k].x && a[k].y === b[k].y)
  );
};

export const RoteCanvas = (props: Props) => {
  const {
    canvasRef,
    graph,
    dispatch,
    viewport,
    readOnly,
    userStats,
    includeStranded,
    highlightedNodes,
    shortcutsEnabled,
    onOpenSettings,
  } = props;
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [portOffsets, setPortOffsets] = useState<Record<string, PortOffsets>>({});
  const [examined, setExamined] = useState<{ id: string; x: number; y: number } | null>(null);
  const [panelPos, setPanelPos] = useState<{ x: number; y: number } | null>(null);
  const panelRef = useRef<HTMLDivElement | null>(null);
  const graphRef = useLatest(graph);
  const stopDragRef = useRef<(() => void) | null>(null);

  const wiring = useWiring({
    toPlane: viewport.toPlane,
    readOnly,
    onLink: (a, b) => dispatch({ type: 'link', wire: wireBetween(a, b) }),
    onUnlink: (port) => dispatch({ type: 'unlink', port }),
  });
  const cancelWire = wiring.cancel;

  useEffect(() => () => stopDragRef.current?.(), []);

  // Close the info panel when clicking elsewhere
  useEffect(() => {
    const close = () => setExamined(null);
    window.addEventListener('mousedown', close);
    return () => window.removeEventListener('mousedown', close);
  }, []);

  const handleExamine = useCallback(
    (id: string, e: ReactMouseEvent) => {
      const rect = canvasRef.current?.getBoundingClientRect();
      if (!rect) {
        return;
      }
      setExamined({ id, x: e.clientX - rect.left, y: e.clientY - rect.top });
    },
    [canvasRef],
  );

  // Keep the info panel within the canvas
  useLayoutEffect(() => {
    const canvas = canvasRef.current;
    const panel = panelRef.current;
    if (!examined || !canvas || !panel) {
      setPanelPos(null);
      return;
    }
    const maxX = Math.max(0, canvas.clientWidth - panel.offsetWidth);
    const maxY = Math.max(0, canvas.clientHeight - panel.offsetHeight);
    setPanelPos({
      x: Math.min(Math.max(0, examined.x), maxX),
      y: Math.min(Math.max(0, examined.y), maxY),
    });
  }, [examined, canvasRef]);

  // from IntegratedCircuit ObjectComponent
  const handleNodeMouseDown = useCallback(
    (id: string, e: ReactMouseEvent) => {
      e.stopPropagation(); // don't pan the plane
      if (e.button !== MOUSE_BUTTON_LEFT) {
        return;
      }
      cancelWire();
      setSelectedId(id);

      const node = graphRef.current.nodes[id];
      if (!node) {
        return;
      }
      const start = { x: e.clientX, y: e.clientY };
      const origin = { x: node.x, y: node.y };

      stopDragRef.current?.();
      stopDragRef.current = trackPointer(
        (ev) => {
          const zoom = viewport.zoomRef.current;
          dispatch({
            type: 'move',
            id,
            at: {
              x: origin.x + (ev.clientX - start.x) / zoom,
              y: origin.y + (ev.clientY - start.y) / zoom,
            },
          });
        },
        () => {
          stopDragRef.current = null;
        },
      );
    },
    [dispatch, cancelWire, viewport.zoomRef],
  );

  const removeNode = useCallback(
    (id: string) => {
      if (readOnly) {
        return;
      }
      dispatch({ type: 'remove', id });
      setSelectedId((current) => (current === id ? null : current));
    },
    [readOnly, dispatch],
  );

  const setPortValue = useCallback(
    (id: string, key: string, value: string | null) => {
      if (!readOnly) {
        dispatch({ type: 'value', id, key, value });
      }
    },
    [readOnly, dispatch],
  );

  const setPortCount = useCallback(
    (id: string, group: string, count: number) => {
      if (!readOnly) {
        dispatch({ type: 'port_count', id, group, count });
      }
    },
    [readOnly, dispatch],
  );

  const handleMeasure = useCallback((id: string, offsets: PortOffsets | null) => {
    setPortOffsets((prev) => {
      if (!offsets) {
        if (!(id in prev)) {
          return prev;
        }
        const { [id]: _removed, ...rest } = prev;
        return rest;
      }
      return sameOffsets(prev[id], offsets) ? prev : { ...prev, [id]: offsets };
    });
  }, []);

  // Delete / Backspace removes the selected node
  useEffect(() => {
    if (!selectedId || readOnly || !shortcutsEnabled) {
      return;
    }
    const onKey = (e: KeyboardEvent) => {
      if ((e.key === 'Delete' || e.key === 'Backspace') && !isEditableTarget(e.target)) {
        removeNode(selectedId);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [selectedId, readOnly, shortcutsEnabled, removeNode]);

  // Wires
  const linked = useMemo(() => linkedSlots(graph.wires), [graph.wires]);

  // Per-node problems shown through the node info tooltip
  const nodeIssues = useMemo(
    () => computeNodeIssues(graph, userStats, includeStranded),
    [graph, userStats, includeStranded],
  );

  const connections = useMemo(() => {
    const point = (nodeId: string, dir: PortDir, key: string): Position | undefined => {
      const node = graph.nodes[nodeId];
      const offset = portOffsets[nodeId]?.[portSlot(dir, key)];
      return node && offset ? { x: node.x + offset.x, y: node.y + offset.y } : undefined;
    };

    const list: Connection[] = [];
    for (const wire of graph.wires) {
      const from = point(wire.outNode, 'out', wire.outPort);
      const to = point(wire.inNode, 'in', wire.inPort);
      if (from && to) {
        list.push({ from, to, color: WIRE_COLOR });
      }
    }

    const { pending, cursor } = wiring;
    if (pending && cursor) {
      const anchor = point(pending.nodeId, pending.dir, pending.port.id);
      if (anchor) {
        list.push(
          pending.dir === 'out'
            ? { from: anchor, to: cursor, color: WIRE_COLOR }
            : { from: cursor, to: anchor, color: WIRE_COLOR },
        );
      }
    }
    return list;
  }, [graph.wires, graph.nodes, portOffsets, wiring.pending, wiring.cursor]);

  return (
    <div ref={canvasRef} className="rote-builder__canvas" onMouseDown={() => setSelectedId(null)}>
      <RotePlane
        backgroundImage={resolveAsset('grid_background.png')}
        imageWidth={GRID_TILE}
        onZoomChange={viewport.onZoomChange}
      >
        <div ref={viewport.originRef} className="rote-builder__origin" />
        <Connections connections={connections} lineWidth={WIRE_WIDTH} />
        {graph.order.map((id) => (
          <NodeCard
            key={id}
            node={graph.nodes[id]}
            selected={id === selectedId}
            pending={wiring.pending}
            linked={linked.get(id) ?? NO_LINKS}
            highlighted={highlightedNodes?.has(id)}
            issues={nodeIssues.get(id)}
            readOnly={readOnly}
            onNodeMouseDown={handleNodeMouseDown}
            onPortMouseDown={wiring.onPortMouseDown}
            onPortMouseUp={wiring.onPortMouseUp}
            onPortRightClick={wiring.onPortRightClick}
            onOpenSettings={onOpenSettings}
            onExamine={handleExamine}
            onDelete={removeNode}
            onSetValue={setPortValue}
            onPortCount={setPortCount}
            onMeasure={handleMeasure}
          />
        ))}
      </RotePlane>
      {examined &&
        (() => {
          const entry = graph.nodes[examined.id];
          if (!entry) {
            return null;
          }
          const notices = (nodeIssues.get(examined.id) ?? []).map((issue) => ({
            content: issue.text,
            color:
              issue.severity === 'error'
                ? 'bad'
                : issue.severity === 'warning'
                  ? 'yellow'
                  : 'grey',
            icon:
              issue.severity === 'error'
                ? 'circle-exclamation'
                : issue.severity === 'warning'
                  ? 'triangle-exclamation'
                  : 'circle-info',
          }));
          return (
            <div
              ref={panelRef}
              style={{
                position: 'absolute',
                zIndex: 200,
                top: `${panelPos?.y ?? examined.y}px`,
                left: `${panelPos?.x ?? examined.x}px`,
              }}
            >
              <NodeInfo
                className="CircuitInfo__Examined"
                name={entry.node.name}
                // DO NOT DELETE
                // desc={entry.node.desc}
                notices={notices}
              />
            </div>
          );
        })()}
    </div>
  );
};
