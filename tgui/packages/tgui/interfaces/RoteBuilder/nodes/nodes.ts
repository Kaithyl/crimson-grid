import type { EffectData, NodeUserData } from '../types';

type NodeId = number | string;

type NodeEntry = {
  effect: EffectData;
  userdata: NodeUserData;
};

const nodeMap = new Map<NodeId, NodeEntry>();

export const registerNode = (
  id: NodeId,
  effect: EffectData,
  userdata?: Partial<NodeUserData>,
) => {
  nodeMap.set(id, {
    effect,
    userdata: {
      label: userdata?.label ?? '',
      success_percentage: userdata?.success_percentage ?? 0,
      min_success: userdata?.min_success ?? 0,
      max_success: userdata?.max_success ?? 0,
    },
  });
};

export const unregisterNode = (id: NodeId) => {
  nodeMap.delete(id);
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

export const clearRegistry = () => {
  nodeMap.clear();
};
