import { useCallback, useRef, useState } from 'react';

import type { Position } from '../types';

export const useViewport = () => {
  const originRef = useRef<HTMLDivElement | null>(null);
  const zoomRef = useRef(1);
  const [zoom, setZoom] = useState(1);

  const onZoomChange = useCallback((next: number) => {
    zoomRef.current = next;
    setZoom(next);
  }, []);

  const toPlane = useCallback((clientX: number, clientY: number): Position | null => {
    const origin = originRef.current;
    if (!origin) {
      return null;
    }
    const rect = origin.getBoundingClientRect();
    return {
      x: (clientX - rect.left) / zoomRef.current,
      y: (clientY - rect.top) / zoomRef.current,
    };
  }, []);

  return { originRef, zoom, zoomRef, onZoomChange, toPlane };
};

export type Viewport = ReturnType<typeof useViewport>;
