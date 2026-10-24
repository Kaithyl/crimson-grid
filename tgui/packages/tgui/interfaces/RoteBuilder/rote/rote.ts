import type { EffectData, NodeUserData } from '../types';

type NodeId = number | string;

type NodeEntry = {
  effect: EffectData;
  userdata: NodeUserData;
};

export type RoteStats = {
  node_count: number;
  complexity: number;
  nodes: Record<string, number>;
};

const nodeMap = new Map<NodeId, NodeEntry>();
const typeCounts = new Map<string, number>();

let node_count = 0;
let node_complexity = 0;

export const registerNode = (
  id: NodeId,
  effect: EffectData,
  userdata?: Partial<NodeUserData>,
) => {
  if (!nodeMap.has(id)) {
    node_count++;
    node_complexity += effect.complexity ?? 0;
    const key = effect.type;
    typeCounts.set(key, (typeCounts.get(key) ?? 0) + 1);
  }

  nodeMap.set(id, {
    effect,
    userdata: {
      label: userdata?.label ?? '',
      success_percentage: userdata?.success_percentage ?? 0,
      min_success: userdata?.min_success ?? 0,
      max_success: userdata?.max_success ?? 0,
      sphere_index: userdata?.sphere_index ?? 0,
    },
  });
};

export const unregisterNode = (id: NodeId): NodeEntry | undefined => {
  const entry = nodeMap.get(id);
  if (entry) {
    node_count = Math.max(0, node_count - 1);
    node_complexity = Math.max(0, node_complexity - (entry.effect.complexity ?? 0));
    const key = entry.effect?.type;
    const next = (typeCounts.get(key) ?? 1) - 1;
    if (next <= 0) {
      typeCounts.delete(key);
    } else {
      typeCounts.set(key, next);
    }
  }
  nodeMap.delete(id);
  return entry;
};

export const getNodeEntry = (id: NodeId): NodeEntry | undefined => {
  return nodeMap.get(id);
};

export const getEffectData = (id: NodeId): EffectData | undefined => {
  return nodeMap.get(id)?.effect;
};

export const getUserData = (id: NodeId): NodeUserData | undefined => {
  return nodeMap.get(id)?.userdata;
};

export const updateUserData = (id: NodeId, data: Partial<NodeUserData>) => {
  const entry = nodeMap.get(id);
  if (entry) {
    entry.userdata = { ...entry.userdata, ...data };
  }
};

export const getAllNodes = (): Map<NodeId, NodeEntry> => {
  return new Map(nodeMap);
};

export const getTypeCount = (effect: EffectData): number =>
  typeCounts.get(effect.type) ?? 0;

export const countNodeInstances = (): Record<string, number> => {
  const counts: Record<string, number> = {};
  for (const [key, count] of typeCounts) {
    counts[key] = count;
  }
  return counts;
};

export const getRoteStats = (): RoteStats => {
  return {
    node_count: node_count,
    complexity: node_complexity,
    nodes: countNodeInstances(),
  };
};

export const resetRote = () => {
  nodeMap.clear();
  typeCounts.clear();
  node_count = 0;
  node_complexity = 0;
};

export const clearRegistry = () => {
  nodeMap.clear();
  typeCounts.clear();
  node_count = 0;
  node_complexity = 0;
};
