import type Drawflow from 'drawflow';
import { compressToEncodedURIComponent, decompressFromEncodedURIComponent } from 'lz-string';

import { MAX_NODES, TAG_ROOT } from '../constants';
import { getUserData, registerNode } from './rote';
import { makeNodeHtml } from './node';
import { validConnection } from './port';
import type { EffectData, NodeUserData } from '../types';

type RoteNodeRef = {
  id: string;
  type_index: number;
  sphere_index?: number;
  port_values?: Record<string, string>;
};

type RoteConnectionRef = {
  out_id: string;
  out_port: string;
  in_id: string;
  in_port: string;
};

type RoteData = {
  nodes: RoteNodeRef[];
  connections: RoteConnectionRef[];
};

type RoteGraph = {
  nodes: {
    id: string;
    effect: EffectData;
    pos_x: number;
    pos_y: number;
    userdata: NodeUserData;
  }[];
  connections: RoteConnectionRef[];
};

type SerializedRote = {
  nodes: (RoteNodeRef & {
    pos_x: number;
    pos_y: number;
    userdata: NodeUserData;
  })[];
  connections: RoteConnectionRef[];
};

const DEFAULT_USERDATA: NodeUserData = {
  label: '',
  success_percentage: 0,
  min_success: 0,
  max_success: 0,
  sphere_index: 0,
};

type ValidationResult =
  | { ok: true }
  | { ok: false; error: string };

const getIndex = (effect: EffectData, effects: EffectData[]): number =>
  effects.findIndex((candidate) => candidate.type === effect.type) + 1;

const getPortIndex = (cls: string | number | undefined | null): number => {
  if (typeof cls !== 'string') {
    return 0;
  }
  // Drawflow port classes are in the format: "output_1" / "input_2"
  return Number(cls.split('_')[1]);
};

// Resolves the port key for a port class on a node's effect data
const getPortKey = (
  effect: EffectData | undefined,
  dir: 'inputs' | 'outputs',
  cls: string | number | undefined | null,
): string | undefined => {
  const index = getPortIndex(cls);
  if (!index) {
    return undefined;
  }
  return effect?.[dir]?.[index - 1]?.key ?? undefined;
};

export const buildRoteData = (
  df: Drawflow,
  effects: EffectData[],
): RoteData => {
  const data = df?.drawflow?.drawflow?.[df.module]?.data ?? {};
  const nodes: RoteNodeRef[] = [];
  const connections: RoteConnectionRef[] = [];

  const nodesById = new Map<string, EffectData>();
  for (const [id, node] of Object.entries(data)) {
    nodesById.set(id, (node as { data: EffectData }).data);
  }

  for (const [id, node] of Object.entries(data)) {
    const effect = node.data as EffectData;
    const userdata = getUserData(`node-${id}`);
    const nodeRef: RoteNodeRef = {
      id,
      type_index: getIndex(effect, effects),
    };

    if (effect.spheres?.length) {
      nodeRef.sphere_index = (userdata?.sphere_index ?? 0) + 1;
    }

    if (userdata) {
      const portValues: Record<string, string> = {};
      for (const [key, value] of Object.entries(userdata)) {
        if (key.startsWith('port_')) {
          portValues[key] = String(value);
        }
      }
      if (Object.keys(portValues).length > 0) {
        nodeRef.port_values = portValues;
      }
    }

    nodes.push(nodeRef);

    for (const [outClass, outConn] of Object.entries(node.outputs ?? {})) {
      const outKey = getPortKey(effect, 'outputs', outClass);
      if (!outKey) {
        continue;
      }
      for (const conn of outConn?.connections ?? []) {
        if (!conn || conn.node === undefined || conn.node === null) {
          continue;
        }
        const inKey = getPortKey(nodesById.get(String(conn.node)), 'inputs', conn.output ?? conn.input);
        if (!inKey) {
          continue;
        }
        connections.push({
          out_id: id,
          out_port: outKey,
          in_id: conn.node,
          in_port: inKey,
        });
      }
    }
  }

  return { nodes, connections };
};

export const serializeRoteData = (
  df: Drawflow,
  effects: EffectData[],
): string => {
  const data = df?.drawflow?.drawflow?.[df.module]?.data ?? {};
  const serialized: SerializedRote = { nodes: [], connections: [] };

  const nodesById = new Map<string, EffectData>();
  for (const [id, node] of Object.entries(data)) {
    nodesById.set(id, (node as { data: EffectData }).data);
  }

  for (const [id, node] of Object.entries(data)) {
    const effect = node.data as EffectData;
    const userdata = getUserData(`node-${id}`);

    serialized.nodes.push({
      id,
      type_index: getIndex(effect, effects),
      pos_x: Math.round((node.pos_x ?? 0) * 10) / 10,
      pos_y: Math.round((node.pos_y ?? 0) * 10) / 10,
      userdata: userdata ?? DEFAULT_USERDATA,
    });

    for (const [outClass, outConn] of Object.entries(node.outputs ?? {})) {
      const outKey = getPortKey(effect, 'outputs', outClass);
      if (!outKey) {
        continue;
      }
      for (const conn of outConn?.connections ?? []) {
        if (!conn || conn.node === undefined || conn.node === null) {
          continue;
        }
        const inKey = getPortKey(nodesById.get(String(conn.node)), 'inputs', conn.output ?? conn.input);
        if (!inKey) {
          continue;
        }
        serialized.connections.push({
          out_id: id,
          out_port: outKey,
          in_id: conn.node,
          in_port: inKey,
        });
      }
    }
  }

  return `ROTE1\n${compressToEncodedURIComponent(JSON.stringify(serialized))}`;
};

export const parseRoteData = (
  code: string,
  effects: EffectData[],
): RoteGraph | null => {
  const lines = code.split('\n');
  if (lines[0] !== 'ROTE1') {
    return null;
  }

  const decompressed = decompressFromEncodedURIComponent(lines.slice(1).join('\n'));
  if (!decompressed) {
    return null;
  }

  let serialized: SerializedRote;
  try {
    serialized = JSON.parse(decompressed);
  } catch {
    return null;
  }

  if (
    !serialized ||
    !Array.isArray(serialized.nodes) ||
    !Array.isArray(serialized.connections)
  ) {
    return null;
  }

  const nodes: RoteGraph['nodes'] = [];
  for (const ref of serialized.nodes) {
    const effect = effects[ref.type_index - 1];
    if (!ref.id || !effect) {
      return null;
    }

    nodes.push({
      id: ref.id,
      effect,
      pos_x: ref.pos_x || 0,
      pos_y: ref.pos_y || 0,
      userdata: ref.userdata ?? DEFAULT_USERDATA,
    });
  }

  return { nodes, connections: serialized.connections };
};

export const loadRoteIntoEditor = (df: Drawflow, graph: RoteGraph): boolean => {
  const idMap = new Map<string, string | number>();
  const effectById = new Map<string, EffectData>();

  for (const node of graph.nodes) {
    const effect = node.effect;
    effectById.set(node.id, effect);
    const id = df.addNode(
      effect.name,
      effect.inputs.length,
      effect.outputs.length,
      node.pos_x,
      node.pos_y,
      `rote-effect rote-effect--${String(effect.type).split('/').pop()}`,
      effect,
      makeNodeHtml(effect, node.userdata?.label),
      false,
    );
    idMap.set(node.id, id);
    registerNode(`node-${id}`, effect, node.userdata);
  }

  for (const conn of graph.connections) {
    const outId = idMap.get(conn.out_id);
    const inId = idMap.get(conn.in_id);
    if (outId === undefined || inId === undefined) {
      df.clear();
      return false;
    }

    const outEffect = effectById.get(conn.out_id);
    const inEffect = effectById.get(conn.in_id);
    const outIndex = (outEffect?.outputs ?? []).findIndex((p) => p.key === conn.out_port) + 1;
    const inIndex = (inEffect?.inputs ?? []).findIndex((p) => p.key === conn.in_port) + 1;
    if (!outIndex || !inIndex) {
      df.clear();
      return false;
    }
    df.addConnection(outId, inId, `output_${outIndex}`, `input_${inIndex}`);
  }

  return true;
};

export const validateRote = (
  rote: RoteData,
  effects: EffectData[],
  userStats: Record<string, unknown>,
): ValidationResult => {
  if (rote.nodes.length === 0) {
    return { ok: false, error: 'Your rote needs at least one node.' };
  }

  if (rote.nodes.length > MAX_NODES) {
    return { ok: false, error: `Your rote can't have more than ${MAX_NODES} nodes.` };
  }

  const countByType: Record<string, number> = {};
  const effectsById = new Map<string, EffectData>();
  let rootCount = 0;

  for (const ref of rote.nodes) {
    const effect = effects[ref.type_index - 1];
    if (!effect) {
      return { ok: false, error: 'Your rote contains an unknown effect.' };
    }
    effectsById.set(ref.id, effect);

    const typeKey = effect.type ?? effect.name;
    const current = countByType[typeKey] ?? 0;
    if (effect.max_nodes && current >= effect.max_nodes) {
      return {
        ok: false,
        error: `You can't add more than ${effect.max_nodes} of "${effect.name}" to a rote.`,
      };
    }
    countByType[typeKey] = current + 1;

    if (effect.tags & TAG_ROOT) {
      rootCount++;
    }

    if (effect.spheres?.length) {
      const sphereIndex = (ref.sphere_index ?? 1) - 1;
      const option = effect.spheres[sphereIndex];
      if (!option) {
        return { ok: false, error: `Invalid sphere configuration for "${effect.name}".` };
      }
      for (const [sphere, required] of Object.entries(option)) {
        if ((Number(userStats[sphere]) || 0) < (required as number)) {
          return {
            ok: false,
            error: `You need ${sphere} ${required} for "${effect.name}".`,
          };
        }
      }
    }
  }

  if (!rootCount) {
    return { ok: false, error: 'Your rote needs at least one root node.' };
  }

  const fedInputs = new Set<string>();
  for (const conn of rote.connections) {
    if (!effectsById.has(conn.out_id) || !effectsById.has(conn.in_id)) {
      return { ok: false, error: 'Your rote contains a broken connection.' };
    }
    const outEffect = effectsById.get(conn.out_id)!;
    const inEffect = effectsById.get(conn.in_id)!;
    const outPort = outEffect.outputs?.find((p) => p.key === conn.out_port);
    const inPort = inEffect.inputs?.find((p) => p.key === conn.in_port);
    if (!outPort || !inPort || !validConnection(outPort, inPort)) {
      // DO NOT REMOVE THIS
      //const dbg = `DEBUG: bad connection '${outEffect.name}' output#${conn.out_port} ('${outPort?.name ?? 'MISSING'}', type ${outPort?.type ?? 'N/A'}) -> '${inEffect.name}' input#${conn.in_port} ('${inPort?.name ?? 'MISSING'}', type ${inPort?.type ?? 'N/A'}). validConnection=${outPort && inPort ? validConnection(outPort, inPort) : false}`;
      //return { ok: false, error: dbg };
      return { ok: false, error: 'Your rote contains an invalid connection.' };
    }
    fedInputs.add(conn.in_id);
  }

  for (const ref of rote.nodes) {
    const effect = effectsById.get(ref.id);
    if (effect && !(effect.tags & TAG_ROOT) && !fedInputs.has(ref.id)) {
      return { ok: false, error: 'Your rote contains unreachable nodes.' };
    }
  }

  return { ok: true };
};
