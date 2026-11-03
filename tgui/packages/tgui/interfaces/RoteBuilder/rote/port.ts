import { FLAG_TRIGGER, FLAG_NUMBER, FLAG_STRING, FLAG_STRING_OR_NUMBER, FLAG_ATOM } from '../constants';
import type { EffectData, PortData } from '../types';

// Any changes to this function should be reflected in
// code\__DEFINES\~~crimson_defines\mage\rote_builder.dm\#define MAGICK_DATATYPES_VALID
export const validConnection = (output: PortData, input: PortData): boolean => {
  // Make sure trigger ports can only connect to each other
  const outAct = output.type & FLAG_TRIGGER;
  const inAct = input.type & FLAG_TRIGGER;
  if (outAct || inAct) {
    return outAct === inAct;
  }

  // Atom subtypes can connect to general ATOM flag but not each other
  const atom_check = (output.type & ~input.type & FLAG_ATOM) === 0;

  // Output non-atom type must be a subset of input non-atom type
  const is_subset = (output.type & ~input.type & ~FLAG_ATOM) === 0;

  return atom_check && is_subset;
};

export const isTriggerPort = (port: PortData): boolean =>
  (port.type & FLAG_TRIGGER) !== 0;

export const isNumberPort = (port: PortData): boolean =>
  (port.type & FLAG_NUMBER) !== 0;

export const isStringPort = (port: PortData): boolean =>
  (port.type & FLAG_STRING) !== 0;

export const isStringOrNumberPort = (port: PortData): boolean =>
  (port.type & FLAG_STRING_OR_NUMBER) !== 0;

export const hasWhitelist = (port: PortData): boolean =>
  port.whitelist !== undefined && port.whitelist.length > 0;

export const getPorts = (
  data: EffectData | undefined,
  dir: 'inputs' | 'outputs',
): PortData[] => data?.[dir] ?? [];

export const portIndex = (portClass: string): number => Number(portClass.split('_')[1]) - 1;
