import { useRef } from 'react';

import type { Position } from './types';

// Ref that always holds the latest value, for event handlers that shouldn't be recreated
export const useLatest = <T>(value: T) => {
  const ref = useRef(value);
  ref.current = value;
  return ref;
};

export const trackPointer = (
  onMove: (e: MouseEvent) => void,
  onEnd?: (e: MouseEvent) => void,
) => {
  let frame = 0;
  let last: MouseEvent | null = null;

  const flush = () => {
    frame = 0;
    if (last) {
      onMove(last);
      last = null;
    }
  };
  const move = (e: MouseEvent) => {
    last = e;
    if (!frame) {
      frame = requestAnimationFrame(flush);
    }
  };
  const stop = () => {
    if (frame) {
      cancelAnimationFrame(frame);
    }
    frame = 0;
    window.removeEventListener('mousemove', move);
    window.removeEventListener('mouseup', up);
  };
  const up = (e: MouseEvent) => {
    if (last) {
      onMove(last);
    }
    stop();
    onEnd?.(e);
  };

  window.addEventListener('mousemove', move);
  window.addEventListener('mouseup', up);
  return stop;
};

export const offsetWithin = (el: HTMLElement, root: HTMLElement): Position | null => {
  let x = 0;
  let y = 0;
  let current: HTMLElement | null = el;
  while (current && current !== root) {
    x += current.offsetLeft;
    y += current.offsetTop;
    const parent = current.offsetParent as HTMLElement | null;
    if (parent) {
      x += parent.clientLeft;
      y += parent.clientTop;
    }
    current = parent;
  }
  return current === root ? { x, y } : null;
};

export const isEditableTarget = (target: EventTarget | null) =>
  target instanceof HTMLElement &&
  (target.isContentEditable || ['INPUT', 'SELECT', 'TEXTAREA'].includes(target.tagName));
