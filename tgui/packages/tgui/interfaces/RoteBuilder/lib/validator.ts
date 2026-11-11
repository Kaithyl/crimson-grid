// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { FLAG_TRIGGER, MAX_NODES, TAG_CAST, TAG_FOCI } from './constants';
import {
  fociNodes,
  getStats,
  type RoteGraph,
  type RoteStats,
  skippedFoci,
} from './graph';
import { findPort, validLink } from './ports';
import { isPortVisible } from './ports';
import { sphereOptions } from './serializer';
import type { NodeData, NodeSettings, UserStats } from './types';

export type ValidationResult = { ok: true } | { ok: false; error: string };

export type NodeIssueSeverity = 'warning' | 'skipped' | 'error' | 'info';
export type NodeIssue = { text: string; severity: NodeIssueSeverity };

// Any changes to this should be reflected in /datum/rote_node/proc/can_cast_unprompted()
const canCastUnprompted = (node: NodeData, values: Record<string, string>): boolean => {
  const inputs = node.inputs ?? [];
  return inputs.every(
    (port) => port.default_value === '' || values[port.id] !== undefined,
  );
};

const isRootNode = (node: NodeData, values: Record<string, string>): boolean =>
  canCastUnprompted(node, values);

export const findUnreachableNodes = (graph: RoteGraph): Set<string> => {
  const fed = new Set<string>();
  for (const wire of graph.wires) {
    const outNode = graph.nodes[wire.outNode];
    const inNode = graph.nodes[wire.inNode];
    if (!outNode || !inNode) {
      continue;
    }
    // Ignore wires attached to ports that are currently hidden
    if (
      !isPortVisible(outNode.node, wire.outPort, outNode.settings.port_counts) ||
      !isPortVisible(inNode.node, wire.inPort, inNode.settings.port_counts)
    ) {
      continue;
    }
    const outPort = findPort(outNode.node, 'out', wire.outPort);
    const inPort = findPort(inNode.node, 'in', wire.inPort);
    if (!outPort || !inPort || !validLink(outPort, inPort)) {
      continue;
    }
    fed.add(wire.inNode);
  }

  const unreachable = new Set<string>();
  for (const id of graph.order) {
    const entry = graph.nodes[id];
    if (!entry) {
      continue;
    }
    if (!isRootNode(entry.node, entry.values) && !fed.has(id)) {
      unreachable.add(id);
    }
  }
  return unreachable;
};

export const unmetSphereRequirements = (
  node: NodeData,
  settings: NodeSettings,
  userStats: UserStats,
): string[] => {
  const options = sphereOptions(node);
  if (!options.length) {
    return [];
  }
  const option = options[settings.sphere_index];
  if (!option) {
    return [];
  }
  const missing: string[] = [];
  for (const [sphere, required] of Object.entries(option)) {
    const have = Number(userStats[sphere]) || 0;
    if (have < required) {
      const label = sphere.charAt(0).toUpperCase() + sphere.slice(1);
      missing.push(`${label} ${required} (you have ${have})`);
    }
  }
  return missing;
};

// For reporting compilation errors and warnings
export const computeNodeIssues = (
  graph: RoteGraph,
  userStats: UserStats,
  includeStranded: boolean,
): Map<string, NodeIssue[]> => {
  const issues = new Map<string, NodeIssue[]>();
  const add = (id: string, text: string, severity: NodeIssueSeverity) => {
    const list = issues.get(id);
    if (list) {
      list.push({ text, severity });
    } else {
      issues.set(id, [{ text, severity }]);
    }
  };

  // Foci reached after the arete roll are skipped during casting
  const skipped = skippedFoci(graph);
  // Effects in the foci chain that require successes are skipped
  const foci = fociNodes(graph);

  const connected = new Set<string>();
  const wiredInputs = new Set<string>();
  for (const wire of graph.wires) {
    connected.add(wire.outNode);
    connected.add(wire.inNode);
    wiredInputs.add(`${wire.inNode}:${wire.inPort}`);
  }

  for (const id of graph.order) {
    const entry = graph.nodes[id];
    if (!entry) {
      continue;
    }
    const { node, settings, values } = entry;

    for (const missing of unmetSphereRequirements(node, settings, userStats)) {
      add(id, `Requires ${missing}.`, 'warning');
    }

    if (skipped.has(id)) {
      add(
        id,
        'Instruments after the arete roll are skipped, and do not contribute complexity cap.',
        'skipped',
      );
    }

    if (foci.has(id) && (node.min_success_cost ?? 0) > 0) {
      add(
        id,
        'Effect nodes that require successes before instruments are completed are skipped.',
        'skipped',
      );
    }

    if (includeStranded) {
      const stranded = !connected.has(id) && !isRootNode(node, values);
      if (stranded) {
        add(id, 'This node is stranded - it is not connected to the rest of the rote.', 'error');
      } else {
        // A required port has no default and must be wired or given a value
        for (const port of node.inputs ?? []) {
          const required =
            (port.default_value === undefined || port.default_value === null) &&
            (port.type & FLAG_TRIGGER) === 0;
          if (!required) {
            continue;
          }
          if (wiredInputs.has(`${id}:${port.id}`) || values[port.id] !== undefined) {
            continue;
          }
          add(id, `Input "${port.name}" is required.`, 'error');
        }
      }
    }
  }

  const cappedTypes = new Set<string>();
  for (const id of graph.order) {
    const entry = graph.nodes[id];
    if (!entry) {
      continue;
    }
    const { node } = entry;
    if ((node.tags & TAG_FOCI) === 0 || skipped.has(id)) {
      continue;
    }
    if (cappedTypes.has(node.type)) {
      add(
        id,
        'Each instrument type only provides complexity once.',
        'info',
      );
    } else {
      cappedTypes.add(node.type);
    }
  }

  return issues;
};

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
  // Nodes that don't meet sphere requirements can be placed but are flagged
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
  let castCount = 0;

  for (const { node, settings, values } of graphNodes) {
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

    if ((node.tags & TAG_CAST) !== 0) {
      castCount++;
    }

    const options = sphereOptions(node);
    if (options.length) {
      const option = options[settings.sphere_index];
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

  if (!castCount) {
    return { ok: false, error: 'Your rote needs at least one cast node.' };
  }

  // Foci port requires at least one focus in the chain
  const castEntry = graphNodes.find(({ node }) => (node.tags & TAG_CAST) !== 0);
  if (castEntry) {
    const hasExtendValue = castEntry.values['in_succ'] !== undefined;
    const hasExtendWire = graph.wires.some(
      (wire) => wire.inNode === castEntry.id && wire.inPort === 'in_succ',
    );
    if (hasExtendValue || hasExtendWire) {
      const hasFoci = [...fociNodes(graph)].some((id) => {
        const entry = graph.nodes[id];
        return entry !== undefined && (entry.node.tags & TAG_FOCI) !== 0;
      });
      if (!hasFoci) {
        return {
          ok: false,
          error: `"${castEntry.node.name}" is set to cast as extended but has no foci.`,
        };
      }
    }
  }

  const { complexity, max_complexity } = getStats(graph);
  if (complexity > max_complexity) {
    return {
      ok: false,
      error: `Your rote's complexity exceeds the maximum complexity.`,
    };
  }

  for (const wire of graph.wires) {
    const outNode = graph.nodes[wire.outNode];
    const inNode = graph.nodes[wire.inNode];
    if (!outNode || !inNode) {
      return { ok: false, error: 'Your rote contains a broken connection.' };
    }
    // Ignore wires attached to ports that are currently hidden
    if (
      !isPortVisible(outNode.node, wire.outPort, outNode.settings.port_counts) ||
      !isPortVisible(inNode.node, wire.inPort, inNode.settings.port_counts)
    ) {
      continue;
    }
    const outPort = findPort(outNode.node, 'out', wire.outPort);
    const inPort = findPort(inNode.node, 'in', wire.inPort);
    if (!outPort || !inPort || !validLink(outPort, inPort)) {
      // DO NOT REMOVE THIS
      //const dbg = `DEBUG: bad link '${outNode.node.name}' output port ${wire.outPort} ('${outPort?.name ?? 'MISSING'}', type ${outPort?.type ?? 'N/A'}) -> '${inNode.node.name}' input port ${wire.inPort} ('${inPort?.name ?? 'MISSING'}', type ${inPort?.type ?? 'N/A'}). validLink=${outPort && inPort ? validLink(outPort, inPort) : false}`;
      //return { ok: false, error: dbg };
      return { ok: false, error: 'Your rote contains an invalid connection.' };
    }
  }

  if (findUnreachableNodes(graph).size) {
    return { ok: false, error: 'Your rote contains unreachable nodes.' };
  }

  // Every required input port must be wired or given a value
  const wiredInputs = new Set<string>();
  for (const wire of graph.wires) {
    wiredInputs.add(`${wire.inNode}:${wire.inPort}`);
  }
  for (const id of graph.order) {
    const entry = graph.nodes[id];
    if (!entry) {
      continue;
    }
    const { node, settings, values } = entry;
    for (const port of node.inputs ?? []) {
      if (!isPortVisible(node, port.id, settings.port_counts)) {
        continue;
      }
      // A required port has no default and is not a trigger port
      const required =
        (port.default_value === undefined || port.default_value === null) &&
        (port.type & FLAG_TRIGGER) === 0;
      if (!required) {
        continue;
      }
      if (wiredInputs.has(`${id}:${port.id}`) || values[port.id] !== undefined) {
        continue;
      }
      return {
        ok: false,
        error: `"${node.name}" is missing a required value for input "${port.name}".`,
      };
    }
  }

  return { ok: true };
};
