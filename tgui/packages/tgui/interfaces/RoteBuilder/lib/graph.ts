import { type PortHandle, portSlot } from './ports';
import type { NodeData, NodeSettings, Position } from './types';

export type RoteNode = {
  id: string;
  node: NodeData;
  x: number;
  y: number;
  settings: NodeSettings;
  /** Values typed into input ports, keyed by port key */
  values: Record<string, string>;
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
  nodes: Record<string, number>;
};

export const DEFAULT_SETTINGS: NodeSettings = {
  label: '',
  success_percentage: 0,
  min_success: 0,
  max_success: 0,
  sphere_index: 0,
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
  return { outNode: out.nodeId, outPort: out.port.key, inNode: inp.nodeId, inPort: inp.port.key };
};

export type GraphAction =
  | { type: 'add'; node: NodeData; at: Position }
  | { type: 'remove'; id: string }
  | { type: 'move'; id: string; at: Position }
  | { type: 'link'; wire: Wire }
  | { type: 'unlink'; port: PortHandle }
  | { type: 'settings'; id: string; settings: NodeSettings }
  | { type: 'value'; id: string; key: string; value: string | null };

const patchNode = (
  state: RoteGraph,
  id: string,
  patch: (node: RoteNode) => RoteNode,
): RoteGraph => {
  const node = state.nodes[id];
  return node ? { ...state, nodes: { ...state.nodes, [id]: patch(node) } } : state;
};

export const graphReducer = (state: RoteGraph, action: GraphAction): RoteGraph => {
  switch (action.type) {
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
      return {
        ...state,
        nodes,
        order: state.order.filter((id) => id !== action.id),
        wires: state.wires.filter((w) => w.outNode !== action.id && w.inNode !== action.id),
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
      return { ...state, wires: [...kept, wire] };
    }
    case 'unlink': {
      const { nodeId, dir, port } = action.port;
      const wires = state.wires.filter((w) =>
        dir === 'out'
          ? !(w.outNode === nodeId && w.outPort === port.key)
          : !(w.inNode === nodeId && w.inPort === port.key),
      );
      return wires.length === state.wires.length ? state : { ...state, wires };
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
    default:
      return state;
  }
};

export const getStats = (graph: RoteGraph): RoteStats => {
  const nodes: Record<string, number> = {};
  let complexity = 0;
  for (const id of graph.order) {
    const { node } = graph.nodes[id];
    complexity += node.complexity ?? 0;
    nodes[node.type] = (nodes[node.type] ?? 0) + 1;
  }
  return { node_count: graph.order.length, complexity, nodes };
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
