import {
  compressToEncodedURIComponent,
  decompressFromEncodedURIComponent,
} from 'lz-string';

import { ROTE_CODE_HEADER } from './constants';
import { DEFAULT_SETTINGS, type RoteGraph, type RoteNode, type Wire } from './graph';
import { findPort } from './ports';
import type { NodeData, NodeSettings, NodeUserData } from './types';

const PORT_VALUE_PREFIX = 'port_';

type DMConnection = { out_id: string; out_port: string; in_id: string; in_port: string };

type DMNode = {
  id: string;
  type_index: number;
  sphere_index?: number;
  port_values?: Record<string, string>;
  userdata?: NodeUserData;
};

export type DMRoteData = { nodes: DMNode[]; connections: DMConnection[] };

type RoteCode = {
  nodes: { id: string; type_index: number; pos_x: number; pos_y: number; userdata: NodeUserData }[];
  connections: DMConnection[];
};

const typeIndexer = (nodes: NodeData[]) => {
  const map = new Map<string, number>();
  nodes.forEach((node, i) => {
    if (!map.has(node.type)) {
      map.set(node.type, i + 1);
    }
  });
  return (node: NodeData) => map.get(node.type) ?? 0;
};

const toPortValues = (values: Record<string, string>) => {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(values)) {
    out[`${PORT_VALUE_PREFIX}${key}`] = value;
  }
  return out;
};

const toUserData = (node: RoteNode): NodeUserData => ({
  ...node.settings,
  ...toPortValues(node.values),
});

const toConnection = (wire: Wire): DMConnection => ({
  out_id: wire.outNode,
  out_port: wire.outPort,
  in_id: wire.inNode,
  in_port: wire.inPort,
});

const orderedNodes = (graph: RoteGraph) => graph.order.map((id) => graph.nodes[id]);

const roundPos = (value: number) => Math.round((value || 0) * 10) / 10;

export const toRoteData = (graph: RoteGraph, nodes: NodeData[]): DMRoteData => {
  const indexOf = typeIndexer(nodes);
  return {
    nodes: orderedNodes(graph).map((node) => {
      const ref: DMNode = {
        id: node.id,
        type_index: indexOf(node.node),
        userdata: toUserData(node),
      };
      if (node.node.spheres?.length) {
        ref.sphere_index = node.settings.sphere_index + 1;
      }
      if (Object.keys(node.values).length > 0) {
        ref.port_values = toPortValues(node.values);
      }
      return ref;
    }),
    connections: graph.wires.map(toConnection),
  };
};

export const encodeRote = (graph: RoteGraph, nodes: NodeData[]): string => {
  const indexOf = typeIndexer(nodes);
  const code: RoteCode = {
    nodes: orderedNodes(graph).map((node) => ({
      id: node.id,
      type_index: indexOf(node.node),
      pos_x: roundPos(node.x),
      pos_y: roundPos(node.y),
      userdata: toUserData(node),
    })),
    connections: graph.wires.map(toConnection),
  };
  return `${ROTE_CODE_HEADER}\n${compressToEncodedURIComponent(JSON.stringify(code))}`;
};

const fromUserData = (raw: Partial<NodeUserData> | undefined) => {
  const userdata = raw ?? {};
  const settings: NodeSettings = {
    label: String(userdata.label ?? DEFAULT_SETTINGS.label),
    success_percentage: Number(userdata.success_percentage) || 0,
    min_success: Number(userdata.min_success) || 0,
    max_success: Number(userdata.max_success) || 0,
    sphere_index: Number(userdata.sphere_index) || 0,
  };
  const values: Record<string, string> = {};
  for (const [key, value] of Object.entries(userdata)) {
    if (key.startsWith(PORT_VALUE_PREFIX) && value !== null && value !== undefined && value !== '') {
      values[key.slice(PORT_VALUE_PREFIX.length)] = String(value);
    }
  }
  return { settings, values };
};

export const decodeRote = (code: string, nodes: NodeData[]): RoteGraph | null => {
  const [header, ...body] = code.split('\n');
  if (header !== ROTE_CODE_HEADER) {
    return null;
  }
  const json = decompressFromEncodedURIComponent(body.join('\n'));
  if (!json) {
    return null;
  }

  let parsed: RoteCode;
  try {
    parsed = JSON.parse(json);
  } catch {
    return null;
  }
  if (!Array.isArray(parsed?.nodes) || !Array.isArray(parsed?.connections)) {
    return null;
  }

  const graph: RoteGraph = { order: [], nodes: {}, wires: [], nextId: 1 };

  for (const ref of parsed.nodes) {
    const node = nodes[ref.type_index - 1];
    if (!ref.id || !node) {
      return null;
    }
    const id = String(ref.id);
    graph.nodes[id] = {
      id,
      node,
      x: Number(ref.pos_x) || 0,
      y: Number(ref.pos_y) || 0,
      ...fromUserData(ref.userdata),
    };
    graph.order.push(id);
    const numeric = Number(id);
    if (Number.isFinite(numeric)) {
      graph.nextId = Math.max(graph.nextId, numeric + 1);
    }
  }

  for (const conn of parsed.connections) {
    const out = graph.nodes[String(conn.out_id)];
    const inp = graph.nodes[String(conn.in_id)];
    if (
      !out ||
      !inp ||
      !findPort(out.node, 'out', String(conn.out_port)) ||
      !findPort(inp.node, 'in', String(conn.in_port))
    ) {
      return null;
    }
    graph.wires.push({
      outNode: out.id,
      outPort: String(conn.out_port),
      inNode: inp.id,
      inPort: String(conn.in_port),
    });
  }

  return graph;
};
