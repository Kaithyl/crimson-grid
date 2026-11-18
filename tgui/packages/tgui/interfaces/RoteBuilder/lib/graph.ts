import { FLAG_TRIGGER, TAG_RITUAL, TAG_FOCI } from './constants';
import { findPort, hiddenPortIds, type PortHandle, portSlot } from './ports';
import type { NodeData, NodeSettings, Position } from './types';

export type RoteNode = {
  id: string;
  node: NodeData;
  x: number;
  y: number;
  settings: NodeSettings;
  /** Values typed into input ports, keyed by port key */
  values: Record<string, string>;
  stashedValues?: Record<string, string>;
};

export type Wire = { outNode: string; outPort: string; inNode: string; inPort: string };

export type RoteGraph = {
  order: string[];
  nodes: Record<string, RoteNode>;
  wires: Wire[];
  nextId: number;
};

export type RoteStats = {
  node_count: number;
  complexity: number;
  max_complexity: number;
  nodes: Record<string, number>;
};

export const DEFAULT_SETTINGS: NodeSettings = {
  label: '',
  success_percentage: 0,
  min_success: 0,
  max_success: 0,
  sphere_index: 0,
  port_counts: {},
};

export const EMPTY_GRAPH: RoteGraph = { order: [], nodes: {}, wires: [], nextId: 1 };

export const makePreviewNode = (node: NodeData): RoteNode => ({
  id: 'preview',
  node,
  x: 0,
  y: 0,
  settings: DEFAULT_SETTINGS,
  values: {},
});

export const wireBetween = (a: PortHandle, b: PortHandle): Wire => {
  const [out, inp] = a.dir === 'out' ? [a, b] : [b, a];
  return { outNode: out.nodeId, outPort: out.port.id, inNode: inp.nodeId, inPort: inp.port.id };
};

export type GraphAction =
  | { type: 'load'; graph: RoteGraph }
  | { type: 'add'; node: NodeData; at: Position }
  | { type: 'remove'; id: string }
  | { type: 'move'; id: string; at: Position }
  | { type: 'link'; wire: Wire }
  | { type: 'unlink'; port: PortHandle }
  | { type: 'settings'; id: string; settings: NodeSettings }
  | { type: 'value'; id: string; key: string; value: string | null }
  | { type: 'port_count'; id: string; group: string; count: number };

const patchNode = (
  state: RoteGraph,
  id: string,
  patch: (node: RoteNode) => RoteNode,
): RoteGraph => {
  const node = state.nodes[id];
  return node ? { ...state, nodes: { ...state.nodes, [id]: patch(node) } } : state;
};

const stashValue = (node: RoteNode, port: string): RoteNode => {
  if (!(port in node.values)) {
    return node;
  }
  const { [port]: stashed, ...values } = node.values;
  return { ...node, values, stashedValues: { ...node.stashedValues, [port]: stashed } };
};

const restoreValue = (node: RoteNode, port: string): RoteNode => {
  const stashed = node.stashedValues?.[port];
  if (stashed === undefined) {
    return node;
  }
  const { [port]: _restored, ...stashedValues } = node.stashedValues ?? {};
  return {
    ...node,
    values: { ...node.values, [port]: stashed },
    stashedValues: Object.keys(stashedValues).length ? stashedValues : undefined,
  };
};

export const graphReducer = (state: RoteGraph, action: GraphAction): RoteGraph => {
  switch (action.type) {
    case 'load':
      return action.graph;
    case 'add': {
      const id = String(state.nextId);
      const node: RoteNode = {
        id,
        node: action.node,
        x: action.at.x,
        y: action.at.y,
        settings: DEFAULT_SETTINGS,
        values: {},
      };
      return {
        ...state,
        nextId: state.nextId + 1,
        order: [...state.order, id],
        nodes: { ...state.nodes, [id]: node },
      };
    }
    case 'remove': {
      if (!state.nodes[action.id]) {
        return state;
      }
      const { [action.id]: _removed, ...nodes } = state.nodes;
      const wires = state.wires.filter((w) => w.outNode !== action.id && w.inNode !== action.id);
      const freed = state.wires.filter((w) => !wires.includes(w) && w.inNode !== action.id);
      const next = freed.reduce(
        (graph, w) => patchNode(graph, w.inNode, (node) => restoreValue(node, w.inPort)),
        { ...state, nodes },
      );
      return {
        ...next,
        order: state.order.filter((id) => id !== action.id),
        wires,
      };
    }
    case 'move':
      return patchNode(state, action.id, (node) => ({ ...node, x: action.at.x, y: action.at.y }));
    case 'link': {
      const wire = action.wire;
      // An input port only has one source - the newest wire wins
      const kept = state.wires.filter(
        (w) => !(w.inNode === wire.inNode && w.inPort === wire.inPort),
      );
      // Stash custom values when input port is overwritten
      const next = patchNode(state, wire.inNode, (node) => stashValue(node, wire.inPort));
      return { ...next, wires: [...kept, wire] };
    }
    case 'unlink': {
      const { nodeId, dir, port } = action.port;
      const wires = state.wires.filter((w) =>
        dir === 'out'
          ? !(w.outNode === nodeId && w.outPort === port.id)
          : !(w.inNode === nodeId && w.inPort === port.id),
      );
      if (wires.length === state.wires.length) {
        return state;
      }
      // Restore stashed values when port is freed
      const freed = state.wires.filter((w) => !wires.includes(w) && w.inNode === nodeId);
      const next = freed.reduce(
        (graph, w) => patchNode(graph, w.inNode, (node) => restoreValue(node, w.inPort)),
        state,
      );
      return { ...next, wires };
    }
    case 'settings':
      return patchNode(state, action.id, (node) => ({ ...node, settings: { ...action.settings } }));
    case 'value':
      return patchNode(state, action.id, (node) => {
        const values = { ...node.values };
        if (action.value === null) {
          delete values[action.key];
        } else {
          values[action.key] = action.value;
        }
        return { ...node, values };
      });
    case 'port_count': {
      const node = state.nodes[action.id];
      if (!node) {
        return state;
      }
      const portCounts = { ...node.settings.port_counts, [action.group]: action.count };
      const next = patchNode(state, action.id, (n) => ({
        ...n,
        settings: { ...n.settings, port_counts: portCounts },
      }));
      // Sever any wires attached to ports that are now hidden
      const hidden = hiddenPortIds(node.node, action.group, action.count);
      if (!hidden.size) {
        return next;
      }
      const wires = next.wires.filter(
        (w) =>
          !(w.inNode === action.id && hidden.has(w.inPort)) &&
          !(w.outNode === action.id && hidden.has(w.outPort)),
      );
      if (wires.length === next.wires.length) {
        return next;
      }

      const freed = next.wires.filter((w) => !wires.includes(w) && w.inNode !== action.id);
      const restored = freed.reduce(
        (graph, w) => patchNode(graph, w.inNode, (node) => restoreValue(node, w.inPort)),
        next,
      );
      return { ...restored, wires };
    }
    default:
      return state;
  }
};

const rootNodeId = (graph: RoteGraph): string | undefined =>
  graph.order.find((id) => (graph.nodes[id].node.tags & TAG_RITUAL) !== 0);

// Ordered node ids in the execution chain
export const executionChain = (graph: RoteGraph): string[] => {
  const castId = rootNodeId(graph);
  if (!castId) {
    return [];
  }
  const order: string[] = [];
  const visited = new Set<string>();
  const queue: string[] = [castId];
  while (queue.length) {
    const id = queue.shift() as string;
    if (visited.has(id)) {
      continue;
    }
    visited.add(id);
    order.push(id);
    for (const wire of graph.wires) {
      if (wire.outNode !== id) {
        continue;
      }
      const outPort = findPort(graph.nodes[id].node, 'out', wire.outPort);
      if (outPort && (outPort.type & FLAG_TRIGGER) !== 0) {
        queue.push(wire.inNode);
      }
    }
  }
  return order;
};

// Instruments that come after a node requiring successes are skipped and
// provide no complexity cap.
export const skippedFoci = (graph: RoteGraph): Set<string> => {
  const skipped = new Set<string>();
  let seenSuccess = false;
  for (const id of executionChain(graph)) {
    const entry = graph.nodes[id];
    if (!entry) {
      continue;
    }
    if ((entry.node.min_success_cost ?? 0) > 0) {
      seenSuccess = true;
    } else if (seenSuccess && (entry.node.tags & TAG_FOCI) !== 0) {
      skipped.add(id);
    }
  }
  return skipped;
};

// Nodes requiring successes that come before any instrument are skipped.
export const skippedEffects = (graph: RoteGraph): Set<string> => {
  const skipped = new Set<string>();
  let seenInstrument = false;
  for (const id of executionChain(graph)) {
    const entry = graph.nodes[id];
    if (!entry) {
      continue;
    }
    if ((entry.node.tags & TAG_FOCI) !== 0) {
      seenInstrument = true;
    } else if (!seenInstrument && (entry.node.min_success_cost ?? 0) > 0) {
      skipped.add(id);
    }
  }
  return skipped;
};

export const getStats = (graph: RoteGraph): RoteStats => {
  const nodes: Record<string, number> = {};
  const skipped = skippedFoci(graph);
  // Each foci type only contributes its complexity cap once
  const cappedTypes = new Set<string>();
  let complexity = 0;
  let maxComplexity = 0;
  for (const id of graph.order) {
    const { node } = graph.nodes[id];
    complexity += node.complexity ?? 0;
    if ((node.tags & TAG_FOCI) !== 0 && !skipped.has(id) && !cappedTypes.has(node.type)) {
      cappedTypes.add(node.type);
      maxComplexity += node.complexity_cap ?? 0;
    }
    nodes[node.type] = (nodes[node.type] ?? 0) + 1;
  }
  return {
    node_count: graph.order.length,
    complexity,
    max_complexity: maxComplexity,
    nodes,
  };
};

/** nodeId -> set of portSlots that have at least one wire */
export const linkedSlots = (wires: Wire[]) => {
  const map = new Map<string, Set<string>>();
  const add = (nodeId: string, slot: string) => {
    let set = map.get(nodeId);
    if (!set) {
      set = new Set<string>();
      map.set(nodeId, set);
    }
    set.add(slot);
  };
  for (const w of wires) {
    add(w.outNode, portSlot('out', w.outPort));
    add(w.inNode, portSlot('in', w.inPort));
  }
  return map;
};
