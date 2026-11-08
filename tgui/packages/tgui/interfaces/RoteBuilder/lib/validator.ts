// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { MAX_NODES, TAG_ROOT } from './constants';
import type { RoteGraph, RoteStats } from './graph';
import { findPort, validLink } from './ports';
import type { EffectData, UserStats } from './types';

export type ValidationResult = { ok: true } | { ok: false; error: string };

const hasSpheres = (option: Record<string, number>, userStats: UserStats) =>
  Object.entries(option).every(
    ([sphere, required]) => (Number(userStats[sphere]) || 0) >= required,
  );


// Temporary
export const placementError = (
  effect: EffectData,
  stats: RoteStats,
  userStats: UserStats,
): string | null => {
  if (stats.node_count >= MAX_NODES) {
    return `You can't have more than ${MAX_NODES} nodes.`;
  }
  if (effect.max_nodes && (stats.nodes[effect.type] ?? 0) >= effect.max_nodes) {
    return `You can't add more than ${effect.max_nodes} of "${effect.name}" to a rote.`;
  }
  if (effect.spheres?.length && !effect.spheres.some((o) => hasSpheres(o, userStats))) {
    return `You don't have the required spheres for "${effect.name}".`;
  }
  return null;
};

export const validateRote = (
  graph: RoteGraph,
  effects: EffectData[],
  userStats: UserStats,
): ValidationResult => {
  const nodes = graph.order.map((id) => graph.nodes[id]);
  if (nodes.length === 0) {
    return { ok: false, error: 'Your rote needs at least one node.' };
  }
  if (nodes.length > MAX_NODES) {
    return { ok: false, error: `Your rote can't have more than ${MAX_NODES} nodes.` };
  }

  const known = new Set(effects.map((effect) => effect.type));
  const countByType: Record<string, number> = {};
  let rootCount = 0;

  for (const { effect, settings } of nodes) {
    if (!known.has(effect.type)) {
      return { ok: false, error: 'Your rote contains an unknown effect.' };
    }

    const current = countByType[effect.type] ?? 0;
    if (effect.max_nodes && current >= effect.max_nodes) {
      return {
        ok: false,
        error: `You can't add more than ${effect.max_nodes} of "${effect.name}" to a rote.`,
      };
    }
    countByType[effect.type] = current + 1;

    if (effect.tags & TAG_ROOT) {
      rootCount++;
    }

    if (effect.spheres?.length) {
      const option = effect.spheres[settings.sphere_index];
      if (!option) {
        return { ok: false, error: `Invalid sphere configuration for "${effect.name}".` };
      }
      for (const [sphere, required] of Object.entries(option)) {
        if ((Number(userStats[sphere]) || 0) < required) {
          return { ok: false, error: `You need ${sphere} ${required} for "${effect.name}".` };
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
    const outPort = findPort(outNode.effect, 'out', wire.outPort);
    const inPort = findPort(inNode.effect, 'in', wire.inPort);
    if (!outPort || !inPort || !validLink(outPort, inPort)) {
      // DO NOT REMOVE THIS
      //const dbg = `DEBUG: bad link '${outNode.effect.name}' output port ${wire.outPort} ('${outPort?.name ?? 'MISSING'}', type ${outPort?.type ?? 'N/A'}) -> '${inNode.effect.name}' input port ${wire.inPort} ('${inPort?.name ?? 'MISSING'}', type ${inPort?.type ?? 'N/A'}). validLink=${outPort && inPort ? validLink(outPort, inPort) : false}`;
      //return { ok: false, error: dbg };
      return { ok: false, error: 'Your rote contains an invalid connection.' };
    }
    fed.add(wire.inNode);
  }

  for (const { id, effect } of nodes) {
    if (!(effect.tags & TAG_ROOT) && !fed.has(id)) {
      return { ok: false, error: 'Your rote contains unreachable nodes.' };
    }
  }

  return { ok: true };
};
