// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { MAX_NODES, TAG_ROOT } from './constants';
import type { RoteGraph, RoteStats } from './graph';
import { findPort, validLink } from './ports';
import type { NodeData, UserStats } from './types';

export type ValidationResult = { ok: true } | { ok: false; error: string };

const hasSpheres = (option: Record<string, number>, userStats: UserStats) =>
  Object.entries(option).every(
    ([sphere, required]) => (Number(userStats[sphere]) || 0) >= required,
  );


// Temporary
export const placementError = (
  node: NodeData,
  stats: RoteStats,
  userStats: UserStats,
): string | null => {
  if (stats.node_count >= MAX_NODES) {
    return `You can't have more than ${MAX_NODES} nodes.`;
  }
  if (node.max_nodes && (stats.nodes[node.type] ?? 0) >= node.max_nodes) {
    return `You can't add more than ${node.max_nodes} of "${node.name}" to a rote.`;
  }
  if (node.spheres?.length && !node.spheres.some((o) => hasSpheres(o, userStats))) {
    return `You don't have the required spheres for "${node.name}".`;
  }
  return null;
};

export const validateRote = (
  graph: RoteGraph,
  nodes: NodeData[],
  userStats: UserStats,
): ValidationResult => {
  const graphNodes = graph.order.map((id) => graph.nodes[id]);
  if (graphNodes.length === 0) {
    return { ok: false, error: 'Your rote needs at least one node.' };
  }
  if (graphNodes.length > MAX_NODES) {
    return { ok: false, error: `Your rote can't have more than ${MAX_NODES} nodes.` };
  }

  const known = new Set(nodes.map((node) => node.type));
  const countByType: Record<string, number> = {};
  let rootCount = 0;

  for (const { node, settings } of graphNodes) {
    if (!known.has(node.type)) {
      return { ok: false, error: 'Your rote contains an unknown node.' };
    }

    const current = countByType[node.type] ?? 0;
    if (node.max_nodes && current >= node.max_nodes) {
      return {
        ok: false,
        error: `You can't add more than ${node.max_nodes} of "${node.name}" to a rote.`,
      };
    }
    countByType[node.type] = current + 1;

    if (node.tags & TAG_ROOT) {
      rootCount++;
    }

    if (node.spheres?.length) {
      const option = node.spheres[settings.sphere_index];
      if (!option) {
        return { ok: false, error: `Invalid sphere configuration for "${node.name}".` };
      }
      for (const [sphere, required] of Object.entries(option)) {
        if ((Number(userStats[sphere]) || 0) < required) {
          return { ok: false, error: `You need ${sphere} ${required} for "${node.name}".` };
        }
      }
    }
  }

  if (!rootCount) {
    return { ok: false, error: 'Your rote needs at least one root node.' };
  }

  const fed = new Set<string>();
  for (const wire of graph.wires) {
    const outNode = graph.nodes[wire.outNode];
    const inNode = graph.nodes[wire.inNode];
    if (!outNode || !inNode) {
      return { ok: false, error: 'Your rote contains a broken connection.' };
    }
    const outPort = findPort(outNode.node, 'out', wire.outPort);
    const inPort = findPort(inNode.node, 'in', wire.inPort);
    if (!outPort || !inPort || !validLink(outPort, inPort)) {
      // DO NOT REMOVE THIS
      //const dbg = `DEBUG: bad link '${outNode.node.name}' output port ${wire.outPort} ('${outPort?.name ?? 'MISSING'}', type ${outPort?.type ?? 'N/A'}) -> '${inNode.node.name}' input port ${wire.inPort} ('${inPort?.name ?? 'MISSING'}', type ${inPort?.type ?? 'N/A'}). validLink=${outPort && inPort ? validLink(outPort, inPort) : false}`;
      //return { ok: false, error: dbg };
      return { ok: false, error: 'Your rote contains an invalid connection.' };
    }
    fed.add(wire.inNode);
  }

  for (const { id, node } of graphNodes) {
    if (!(node.tags & TAG_ROOT) && !fed.has(id)) {
      return { ok: false, error: 'Your rote contains unreachable nodes.' };
    }
  }

  return { ok: true };
};
