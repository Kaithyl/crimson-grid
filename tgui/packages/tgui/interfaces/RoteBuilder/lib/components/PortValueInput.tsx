// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Adapted from IntegratedCircuit/FundamentalTypes.jsx + BasicInput.jsx
import { type KeyboardEvent, type SyntheticEvent, useEffect, useState } from 'react';

import { hasWhitelist, isListPort, isNumberPort, isStringPort, isTriggerPort } from '../ports';
import type { PortData } from '../types';

type Props = {
  port: PortData;
  value: string;
  disabled?: boolean;
  // null clears the stored value, so the port falls back to its default
  onCommit: (value: string | null) => void;
};

export const hasValueEditor = (port: PortData) =>
  !isTriggerPort(port) && !isListPort(port) && (isNumberPort(port) || isStringPort(port));

// Keep clicks in the field from dragging the node or panning the plane
const stopPropagation = (e: SyntheticEvent) => e.stopPropagation();

const blurOnEnter = (e: KeyboardEvent<HTMLInputElement>) => {
  if (e.key === 'Enter') {
    e.currentTarget.blur();
  }
};

const clampToPort = (port: PortData, n: number) => {
  let result = n;
  if (typeof port.min_clamp === 'number') result = Math.max(port.min_clamp, result);
  if (typeof port.max_clamp === 'number') result = Math.min(port.max_clamp, result);
  return result;
};

export const PortValueInput = ({ port, value, disabled, onCommit }: Props) => {
  const [draft, setDraft] = useState(value);
  useEffect(() => setDraft(value), [value]);

  // String ports take priority
  if (isNumberPort(port) && !isStringPort(port)) {
    const commit = () => {
      if (draft.trim() === '') {
        setDraft(value);
        onCommit(null);
        return;
      }
      const parsed = Number(draft);
      if (!Number.isFinite(parsed)) {
        setDraft(value);
        return;
      }
      const next = String(clampToPort(port, parsed));
      setDraft(next);
      if (next !== value) {
        onCommit(next);
      }
    };
    return (
      <input
        type="number"
        step="any"
        className="rote-port__value"
        min={port.min_clamp}
        max={port.max_clamp}
        value={draft}
        disabled={disabled}
        onMouseDown={stopPropagation}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={commit}
        onKeyDown={blurOnEnter}
      />
    );
  }

  if (hasWhitelist(port)) {
    return (
      <select
        className="rote-port__whitelist"
        value={value}
        disabled={disabled}
        onMouseDown={stopPropagation}
        onChange={(e) => onCommit(e.target.value || null)}
      >
        <option value="">—</option>
        {port.whitelist!.map((option) => (
          <option key={option} value={option}>
            {option}
          </option>
        ))}
      </select>
    );
  }

  const commit = () => {
    if (draft !== value) {
      onCommit(draft === '' ? null : draft);
    }
  };
  return (
    <input
      type="text"
      className="rote-port__value"
      value={draft}
      disabled={disabled}
      onMouseDown={stopPropagation}
      onChange={(e) => setDraft(e.target.value)}
      onBlur={commit}
      onKeyDown={blurOnEnter}
    />
  );
};
