import {
  compressToEncodedURIComponent,
  decompressFromEncodedURIComponent,
} from 'lz-string';

import { DEFAULT_SETTINGS, type RoteGraph, type RoteNode, type Wire } from './graph';
import { findPort } from './ports';
import type { NodeData, NodeSettings, NodeUserData } from './types';

const PORT_VALUE_PREFIX = 'port_';
const LEGACY_STASHED_VALUE_PREFIX = 'stashed_port_';

type DMConnection = { out_id: string; out_port: string; in_id: string; in_port: string };

type DMNode = {
  id: string;
  type_index: number;
  sphere_index?: number;
  port_values?: Record<string, string>;
  userdata?: NodeUserData;
};

export type DMRoteData = { nodes: DMNode[]; connections: DMConnection[] };

type RoteCodeUserData = NodeSettings & {
  values?: Record<string, string>;
  stashed_values?: Record<string, string>;
};

type RoteCode = {
  nodes: {
    id: string;
    type_index: number;
    pos_x: number;
    pos_y: number;
    userdata: RoteCodeUserData;
  }[];
  connections: DMConnection[];
};

export const sphereOptions = (node: NodeData): Record<string, number>[] => {
  const spheres = node.spheres as unknown;
  if (!spheres) {
    return [];
  }
  if (Array.isArray(spheres)) {
    return spheres as Record<string, number>[];
  }
  if (typeof spheres === 'object') {
    return Object.keys(spheres as Record<string, unknown>)
      .sort((a, b) => Number(a) - Number(b))
      .map((key) => (spheres as Record<string, Record<string, number>>)[key]);
  }
  return [];
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

const toCodeUserData = (node: RoteNode): RoteCodeUserData => {
  const userdata: RoteCodeUserData = { ...node.settings };
  if (Object.keys(node.values).length) {
    userdata.values = { ...node.values };
  }
  if (node.stashedValues && Object.keys(node.stashedValues).length) {
    userdata.stashed_values = { ...node.stashedValues };
  }
  return userdata;
};

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
        userdata: { ...node.settings },
      };
      if (sphereOptions(node.node).length) {
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
      userdata: toCodeUserData(node),
    })),
    connections: graph.wires.map(toConnection),
  };
  return compressToEncodedURIComponent(JSON.stringify(code));
};

const isRecord = (value: unknown): value is Record<string, unknown> =>
  !!value && typeof value === 'object' && !Array.isArray(value);

const readValues = (raw: Record<string, unknown>) => {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(raw)) {
    if (value !== null && value !== undefined && value !== '') {
      out[key] = String(value);
    }
  }
  return out;
};

// Legacy codes stored values flat as "port_x" / "stashed_port_x" next to the settings
const SETTINGS_KEYS = new Set(Object.keys(DEFAULT_SETTINGS));

const readLegacyValues = (userdata: Record<string, unknown>) => {
  const values: Record<string, string> = {};
  const stashedValues: Record<string, string> = {};
  for (const [key, value] of Object.entries(userdata)) {
    if (value === null || value === undefined || value === '' || SETTINGS_KEYS.has(key)) {
      continue;
    }
    if (key.startsWith(LEGACY_STASHED_VALUE_PREFIX)) {
      stashedValues[key.slice(LEGACY_STASHED_VALUE_PREFIX.length)] = String(value);
    } else if (key.startsWith(PORT_VALUE_PREFIX)) {
      values[key.slice(PORT_VALUE_PREFIX.length)] = String(value);
    }
  }
  return { values, stashedValues };
};

const fromUserData = (raw: unknown) => {
  const userdata: Partial<NodeUserData> = isRecord(raw) ? raw : {};
  const portCounts: Record<string, number> = {};
  if (userdata.port_counts && typeof userdata.port_counts === 'object') {
    for (const [group, count] of Object.entries(userdata.port_counts)) {
      portCounts[group] = Number(count) || 0;
    }
  }
  const settings: NodeSettings = {
    label: String(userdata.label ?? DEFAULT_SETTINGS.label),
    success_percentage: Number(userdata.success_percentage) || 0,
    min_success: Number(userdata.min_success) || 0,
    max_success: Number(userdata.max_success) || 0,
    sphere_index: Number(userdata.sphere_index) || 0,
    port_counts: portCounts,
  };
  const isNested = isRecord(userdata.values) || isRecord(userdata.stashed_values);
  const { values, stashedValues } = isNested
    ? {
        values: isRecord(userdata.values) ? readValues(userdata.values) : {},
        stashedValues: isRecord(userdata.stashed_values) ? readValues(userdata.stashed_values) : {},
      }
    : readLegacyValues(userdata);
  return {
    settings,
    values,
    stashedValues: Object.keys(stashedValues).length ? stashedValues : undefined,
  };
};

export const decodeRote = (code: string, nodes: NodeData[]): RoteGraph | null => {
  const json = decompressFromEncodedURIComponent(code);
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
