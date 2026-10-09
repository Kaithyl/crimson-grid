import { FLAG_TRIGGER, FLAG_NUMBER, FLAG_STRING } from '../constants';
import type { EffectData, PortData } from '../types';

export const validConnection = (output: PortData, input: PortData): boolean => {
  const outAct = output.type & FLAG_TRIGGER;
  const inAct = input.type & FLAG_TRIGGER;
  if (outAct || inAct) {
    return outAct === inAct;
  }
  return (input.type & ~output.type) === 0;
};

export const isTriggerPort = (port: PortData): boolean =>
  (port.type & FLAG_TRIGGER) !== 0;

export const isNumberPort = (port: PortData): boolean =>
  (port.type & FLAG_NUMBER) !== 0;

export const isStringPort = (port: PortData): boolean =>
  (port.type & FLAG_STRING) !== 0;

export const hasWhitelist = (port: PortData): boolean =>
  port.whitelist !== undefined && port.whitelist.length > 0;

export const getPorts = (
  data: EffectData | undefined,
  dir: 'inputs' | 'outputs',
): PortData[] => data?.[dir] ?? [];

export const portIndex = (portClass: string): number => Number(portClass.split('_')[1]) - 1;
