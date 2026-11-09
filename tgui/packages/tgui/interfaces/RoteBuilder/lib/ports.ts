import {
  FLAG_ATOM,
  FLAG_NUMBER,
  FLAG_ORIGIN,
  FLAG_STRING,
  FLAG_TRIGGER,
} from './constants';
import type { NodeData, PortData, PortDir } from './types';

// Any changes to this function should be reflected in
// code\__DEFINES\~~crimson_defines\rote_builder\datatypes.dm\#define MAGICK_DATATYPES_VALID
export const validLink = (output: PortData, input: PortData): boolean => {
  // Trigger ports can only connect to each other
  const outTrigger = output.type & FLAG_TRIGGER;
  const inTrigger = input.type & FLAG_TRIGGER;
  if (outTrigger || inTrigger) {
    return outTrigger === inTrigger;
  }
  // Atom subtypes can connect to the general ATOM flag but not to each other
  const atomCheck = (output.type & ~input.type & FLAG_ATOM) === 0;
  // The output's non-atom type must be a subset of the input's non-atom type,
  // ignoring origin so that origin values may flow into plain targets
  const isSubset = (output.type & ~input.type & ~FLAG_ATOM & ~FLAG_ORIGIN) === 0;
  // Origin may go into targets, but targets cannot go into an origin
  const originCheck = (input.type & FLAG_ORIGIN) === 0 || (output.type & FLAG_ORIGIN) !== 0;
  return atomCheck && isSubset && originCheck;
};

export const isTriggerPort = (port: PortData) => (port.type & FLAG_TRIGGER) !== 0;
export const isNumberPort = (port: PortData) => (port.type & FLAG_NUMBER) !== 0;
export const isStringPort = (port: PortData) => (port.type & FLAG_STRING) !== 0;
export const hasWhitelist = (port: PortData) => !!port.whitelist?.length;

export const portsOf = (node: NodeData, dir: PortDir): PortData[] =>
  (dir === 'in' ? node.inputs : node.outputs) ?? [];

export const findPort = (node: NodeData, dir: PortDir, key: string) =>
  portsOf(node, dir).find((port) => port.key === key);

// Identifies one port on one node
export type PortHandle = { nodeId: string; dir: PortDir; port: PortData };

// Key for a port inside its node
export const portSlot = (dir: PortDir, key: string) => `${dir}:${key}`;

export const samePort = (a: PortHandle, b: PortHandle) =>
  a.nodeId === b.nodeId && a.dir === b.dir && a.port.key === b.port.key;

export const canLink = (a: PortHandle, b: PortHandle): boolean => {
  if (a.dir === b.dir || a.nodeId === b.nodeId) {
    return false;
  }
  const [out, inp] = a.dir === 'out' ? [a, b] : [b, a];
  return validLink(out.port, inp.port);
};
