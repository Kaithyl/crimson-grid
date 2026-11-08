// Adapted from IntegratedCircuit (handleMouseDownComponent / handleComponentDropped)
import {
  type MouseEvent as ReactMouseEvent,
  type RefObject,
  useCallback,
  useEffect,
  useRef,
  useState,
} from 'react';

import { MOUSE_BUTTON_LEFT, PLACEMENT_GRAB } from '../constants';
import type { EffectData, Position } from '../types';
import { trackPointer, useLatest } from '../util';

type Args = {
  canvasRef: RefObject<HTMLDivElement | null>;
  toPlane: (clientX: number, clientY: number) => Position | null;
  disabled: boolean;
  onPlace: (effect: EffectData, at: Position) => void;
};

export type Ghost = { effect: EffectData; x: number; y: number };

const grabPoint = (e: { clientX: number; clientY: number }) => ({
  x: e.clientX - PLACEMENT_GRAB.x,
  y: e.clientY - PLACEMENT_GRAB.y,
});

export const usePlacement = ({ canvasRef, toPlane, disabled, onPlace }: Args) => {
  const [ghost, setGhost] = useState<Ghost | null>(null);
  const onPlaceRef = useLatest(onPlace);
  const stopRef = useRef<(() => void) | null>(null);

  useEffect(() => () => stopRef.current?.(), []);

  const pickUp = useCallback(
    (effect: EffectData, e: ReactMouseEvent) => {
      if (e.button !== MOUSE_BUTTON_LEFT || disabled) {
        return;
      }
      e.preventDefault(); // no text selection while dragging
      setGhost({ effect, ...grabPoint(e) });

      stopRef.current?.();
      stopRef.current = trackPointer(
        (ev) => setGhost({ effect, ...grabPoint(ev) }),
        (ev) => {
          stopRef.current = null;
          setGhost(null);
          // The ghost has pointer-events: none, so ev.target is whatever is under the cursor.
          // Dropping on the menu or save panel (outside the canvas) cancels.
          const target = ev.target as Node | null;
          if (!target || !canvasRef.current?.contains(target)) {
            return;
          }
          const { x, y } = grabPoint(ev);
          const at = toPlane(x, y);
          if (at) {
            onPlaceRef.current(effect, at);
          }
        },
      );
    },
    [disabled, toPlane, canvasRef],
  );

  return { ghost, pickUp };
};
