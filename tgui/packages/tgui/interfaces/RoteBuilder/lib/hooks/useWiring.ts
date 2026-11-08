// Adapted from IntegratedCircuit (handlePortClick / handlePortUp / handlePortRelease)
import { type MouseEvent as ReactMouseEvent, useCallback, useEffect, useRef, useState } from 'react';

import { MOUSE_BUTTON_LEFT, TIME_UNTIL_PORT_RELEASE_WORKS } from '../constants';
import { canLink, type PortHandle, samePort } from '../ports';
import type { Position } from '../types';
import { useLatest } from '../util';

type Args = {
  toPlane: (clientX: number, clientY: number) => Position | null;
  readOnly: boolean;
  onLink: (a: PortHandle, b: PortHandle) => void;
  onUnlink: (port: PortHandle) => void;
};

export type PortMouseHandler = (handle: PortHandle, e: ReactMouseEvent) => void;

export const useWiring = (args: Args) => {
  const { toPlane, readOnly } = args;
  const onLink = useLatest(args.onLink);
  const onUnlink = useLatest(args.onUnlink);

  const pendingRef = useRef<{ handle: PortHandle; startedAt: number } | null>(null);
  const [pending, setPending] = useState<PortHandle | null>(null);
  const [cursor, setCursor] = useState<Position | null>(null);

  const cancel = useCallback(() => {
    pendingRef.current = null;
    setPending(null);
    setCursor(null);
  }, []);

  const complete = useCallback(
    (target: PortHandle) => {
      const current = pendingRef.current;
      if (!current) {
        return;
      }
      if (canLink(current.handle, target)) {
        onLink.current(current.handle, target);
      }
      cancel();
    },
    [cancel],
  );

  const onPortMouseDown: PortMouseHandler = useCallback(
    (handle, e) => {
      // Stop the node from dragging and the plane from panning
      e.stopPropagation();
      if (e.button !== MOUSE_BUTTON_LEFT || readOnly) {
        return;
      }
      const current = pendingRef.current;
      if (current) {
        // Second click of click-to-link. Clicking the same port again cancels.
        if (samePort(current.handle, handle)) {
          cancel();
        } else {
          complete(handle);
        }
        return;
      }
      pendingRef.current = { handle, startedAt: Date.now() };
      setPending(handle);
      setCursor(toPlane(e.clientX, e.clientY));
    },
    [readOnly, toPlane, cancel, complete],
  );

  const onPortMouseUp: PortMouseHandler = useCallback(
    (handle) => {
      const current = pendingRef.current;
      if (current && !samePort(current.handle, handle)) {
        complete(handle);
      }
    },
    [complete],
  );

  const onPortRightClick: PortMouseHandler = useCallback(
    (handle, e) => {
      e.preventDefault();
      e.stopPropagation();
      if (readOnly) {
        return;
      }
      cancel();
      onUnlink.current(handle);
    },
    [readOnly, cancel],
  );

  // While a wire is held: follow the mouse. Cancel on a release over empty space
  // (after the click grace period), on a click on empty space, or on Escape.
  useEffect(() => {
    if (!pending) {
      return;
    }
    let frame = 0;
    let x = 0;
    let y = 0;
    const onMove = (e: MouseEvent) => {
      x = e.clientX;
      y = e.clientY;
      if (!frame) {
        frame = requestAnimationFrame(() => {
          frame = 0;
          setCursor(toPlane(x, y));
        });
      }
    };
    const onUp = () => {
      const current = pendingRef.current;
      if (current && Date.now() - current.startedAt > TIME_UNTIL_PORT_RELEASE_WORKS) {
        cancel();
      }
    };
    // Ports and nodes stop propagation, so this only fires for clicks on empty space
    const onDown = () => cancel();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        cancel();
      }
    };

    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
    window.addEventListener('mousedown', onDown);
    window.addEventListener('keydown', onKey);
    return () => {
      if (frame) {
        cancelAnimationFrame(frame);
      }
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
      window.removeEventListener('mousedown', onDown);
      window.removeEventListener('keydown', onKey);
    };
  }, [pending, toPlane, cancel]);

  return { pending, cursor, cancel, onPortMouseDown, onPortMouseUp, onPortRightClick };
};
