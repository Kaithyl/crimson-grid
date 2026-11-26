// THIS IS A DARKPACK UI FILE - CRIMSONGRID
// Inline editor for MAGICK_DATATYPE_PATTERN ports
import type { ReactNode, SyntheticEvent } from 'react';
import { classes } from 'tgui-core/react';

import { patternSize } from '../ports';
import type { PortData } from '../types';

type Props = {
  port: PortData;
  value: string;
  disabled?: boolean;
  // null clears the stored value, so the port falls back to its default
  onCommit: (value: string | null) => void;
};

type Cell = [number, number];

type PatternState = {
  origin: Cell;
  selected: Cell[];
};

const ORIGIN = '⬆';

const cellKey = (x: number, y: number) => `${x},${y}`;

const isCell = (value: unknown): value is Cell =>
  Array.isArray(value) && value.length === 2 && value.every((n) => typeof n === 'number');

const defaultState = (size: number): PatternState => {
  const center = Math.floor(size / 2);
  return { origin: [center, center], selected: [] };
};

// Stored format: {"origin": [ox, oy], "selected": [[x, y], ...]}
export const parsePattern = (value: string, size: number): PatternState => {
  if (!value) {
    return defaultState(size);
  }
  try {
    const parsed = JSON.parse(value) as { origin?: unknown; selected?: unknown };
    const origin = isCell(parsed?.origin) ? parsed.origin : null;
    if (!origin) {
      return defaultState(size);
    }
    const selected = Array.isArray(parsed?.selected) ? parsed.selected.filter(isCell) : [];
    return { origin, selected };
  } catch {
    return defaultState(size);
  }
};

export const serializePattern = (state: PatternState) => JSON.stringify(state);

// Keep clicks in the grid from dragging the node, panning the plane, or wiring ports
const stopPropagation = (e: SyntheticEvent) => e.stopPropagation();

export const PatternGrid = ({ port, value, disabled, onCommit }: Props) => {
  const size = patternSize(port);
  const state = parsePattern(value, size);
  const [originX, originY] = state.origin;
  const selected = new Set(state.selected.map(([x, y]) => cellKey(x, y)));

  const commit = (next: PatternState) => onCommit(serializePattern(next));

  const toggleCell = (x: number, y: number) => {
    if (disabled) {
      return;
    }
    const key = cellKey(x, y);
    const nextSelected = selected.has(key)
      ? state.selected.filter(([sx, sy]) => !(sx === x && sy === y))
      : [...state.selected, [x, y] as Cell];
    commit({ origin: state.origin, selected: nextSelected });
  };

  const moveOrigin = (x: number, y: number) => {
    if (disabled) {
      return;
    }
    commit({ origin: [x, y], selected: state.selected });
  };

  const tiles: ReactNode[] = [];
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const key = cellKey(x, y);
      const isOrigin = x === originX && y === originY;
      tiles.push(
        <span
          key={key}
          className={classes([
            'rote-pattern__tile',
            selected.has(key) && 'rote-pattern__tile--selected',
            isOrigin && 'rote-pattern__tile--origin',
            disabled && 'rote-pattern__tile--disabled',
          ])}
          title={isOrigin ? 'Origin — right-click a tile to move it' : undefined}
          onMouseDown={stopPropagation}
          onMouseUp={stopPropagation}
          onClick={() => toggleCell(x, y)}
          onContextMenu={(e) => {
            e.preventDefault();
            e.stopPropagation();
            moveOrigin(x, y);
          }}
        >
          {isOrigin ? ORIGIN : ''}
        </span>,
      );
    }
  }

  return (
    <div
      className="rote-pattern"
      style={{ gridTemplateColumns: `repeat(${size}, 1fr)` }}
      onMouseDown={stopPropagation}
      onMouseUp={stopPropagation}
      onContextMenu={stopPropagation}
    >
      {tiles}
    </div>
  );
};
