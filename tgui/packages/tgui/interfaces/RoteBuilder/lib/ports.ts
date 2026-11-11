 import {
  FLAG_ANY,
FLAG_ATOM,
  FLAG_LIST,
  FLAG_MOB,
  FLAG_NUMBER,
  FLAG_OBJ,
  FLAG_ORIGIN,
  FLAG_STRING,
  FLAG_STRING_OR_NUMBER,
  FLAG_TRIGGER,
  FLAG_TURF,
  PRIMARY_ACTIVATE_KEYS,
} from './constants';
import type { ExtendablePortGroup, NodeData, PortData, PortDir } from './types';

// Any changes to this function should be reflected in
// code\__DEFINES\~~crimson_defines\rote_builder\datatypes.dm\#define MAGICK_DATATYPES_VALID
export const validLink = (output: PortData, input: PortData): boolean => {
  // Trigger ports can only connect to each other
  const outTrigger = output.type & FLAG_TRIGGER;
  const inTrigger = input.type & FLAG_TRIGGER;
  if (outTrigger || inTrigger) {
    return outTrigger === inTrigger;
  }
  // A list input only accepts list outputs, and vice versa
  if ((output.type & FLAG_LIST) !== (input.type & FLAG_LIST)) {
    return false;
  }
  // String inputs accept any non-trigger value (it gets converted to text)
  if (input.type & FLAG_STRING) {
    return true;
  }
  // Atom subtypes can connect to the general ATOM flag but not to each other
  const atomCheck = (output.type & ~input.type & FLAG_ATOM) === 0;
  const isSubset = (output.type & ~input.type & ~FLAG_ATOM & ~FLAG_ORIGIN) === 0;
  // Origin may go into targets, but targets cannot go into an origin
  const originCheck = (input.type & FLAG_ORIGIN) === 0 || (output.type & FLAG_ORIGIN) !== 0;
  return atomCheck && isSubset && originCheck;
};
export const isTriggerPort = (port: PortData) => (port.type & FLAG_TRIGGER) !== 0;
export const isOptionalPort = (port: PortData) => port.default_value === '';
export const isOptionalTriggerPort = (port: PortData) => isTriggerPort(port) && isOptionalPort(port);
export const isPrimaryActivatePort = (port: PortData) => PRIMARY_ACTIVATE_KEYS.includes(port.id) && !isOptionalTriggerPort(port);
export const isNumberPort = (port: PortData) => (port.type & FLAG_NUMBER) !== 0;
export const isStringPort = (port: PortData) => (port.type & FLAG_STRING) !== 0;
export const isListPort = (port: PortData) => (port.type & FLAG_LIST) !== 0;
export const isOriginPort = (port: PortData) => (port.type & FLAG_ORIGIN) !== 0;
export const hasWhitelist = (port: PortData) => !!port.whitelist?.length;

export const hasPromise = (port: PortData) => !!port.promise && !isStringPort(port) && !isNumberPort(port);

export const promiseLabel = (port: PortData): string => {
  const promise = String(port.promise ?? '');
  return promise ? promise.charAt(0).toUpperCase() + promise.slice(1) : '';
};

export const portTypeLabel = (port: PortData): string => {
  const { type } = port;
  if (type & FLAG_TRIGGER) {
    return 'signal';
  }
  const parts: string[] = [];
  if (type & FLAG_LIST) {
    parts.push('list');
  }
  if ((type & FLAG_ANY) === FLAG_ANY) {
    parts.push('any');
  } else {
    if ((type & FLAG_STRING_OR_NUMBER) === FLAG_STRING_OR_NUMBER) {
      parts.push('value');
    } else if (type & FLAG_NUMBER) {
      parts.push('number');
    } else if (type & FLAG_STRING) {
      parts.push('string');
    }
    if ((type & FLAG_ATOM) === FLAG_ATOM) {
      parts.push('atom');
    } else if (type & FLAG_TURF) {
      parts.push('turf');
    } else if (type & FLAG_OBJ) {
      parts.push('obj');
    } else if (type & FLAG_MOB) {
      parts.push('mob');
    }
    if (type & FLAG_ORIGIN) {
      parts.push('origin');
    }
  }

  return parts.length ? parts.join(' | ') : 'any';
};

export const portsOf = (node: NodeData, dir: PortDir): PortData[] =>
  (dir === 'in' ? node.inputs : node.outputs) ?? [];

export const extendablePortGroups = (node: NodeData): Record<string, ExtendablePortGroup> => {
  const groups = node.extendable_ports as unknown;
  if (!groups) {
    return {};
  }
  if (Array.isArray(groups)) {
    return {};
  }
  return groups as Record<string, ExtendablePortGroup>;
};

// Returns the id_prefix of the extendable group a port belongs to, or null
export const portGroupOf = (node: NodeData, portId: string): string | null => {
  const groups = extendablePortGroups(node);
  for (const prefix of Object.keys(groups)) {
    if (portId.startsWith(prefix) && /^\d+$/.test(portId.slice(prefix.length))) {
      return prefix;
    }
  }
  return null;
};

export const hiddenPortIds = (node: NodeData, group: string, count: number): Set<string> => {
  const hidden = new Set<string>();
  for (const port of [...portsOf(node, 'in'), ...portsOf(node, 'out')]) {
    if (portGroupOf(node, port.id) !== group) {
      continue;
    }
    const index = Number(port.id.slice(group.length));
    if (index >= count) {
      hidden.add(port.id);
    }
  }
  return hidden;
};

export const isPortVisible = (node: NodeData, portId: string, portCounts: Record<string, number>) => {
  const group = portGroupOf(node, portId);
  if (group === null) {
    return true;
  }
  const count = portCounts[group];
  if (count === undefined) {
    return true;
  }
  return Number(portId.slice(group.length)) < count;
};

export const findPort = (node: NodeData, dir: PortDir, id: string) =>
  portsOf(node, dir).find((port) => port.id === id);

// Identifies one port on one node
export type PortHandle = { nodeId: string; dir: PortDir; port: PortData };

// Uses direction in case of redundancy
export const portSlot = (dir: PortDir, id: string) => `${dir}:${id}`;

export const samePort = (a: PortHandle, b: PortHandle) =>
  a.nodeId === b.nodeId && a.dir === b.dir && a.port.id === b.port.id;

export const canLink = (a: PortHandle, b: PortHandle): boolean => {
  if (a.dir === b.dir || a.nodeId === b.nodeId) {
    return false;
  }
  const [out, inp] = a.dir === 'out' ? [a, b] : [b, a];
  return validLink(out.port, inp.port);
};
