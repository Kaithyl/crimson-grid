import Drawflow from 'drawflow';
import { useEffect, useRef } from 'react';

import { resolveAsset } from '../../assets';

import { createCanvasEventHandler, createNodeEventHandler, createPortEventHandler } from './events';

export const useCanvas = () => {
  const canvasRef = useRef<HTMLDivElement | null>(null);
  const drawflowRef = useRef<Drawflow | null>(null);

  useEffect(() => {
    const container = canvasRef.current;
    if (!container) {
      return;
    }

    const el = document.createElement('div');
    el.className = 'rote-drawflow-host';
    el.style.backgroundImage = `url("${resolveAsset('grid_background.png')}")`;
    container.appendChild(el);

    const df = new Drawflow(el);
    df.reroute = false;
    df.start();
    drawflowRef.current = df;

    const eventHandlers = [
      createCanvasEventHandler(df, el),
      createNodeEventHandler(df, el),
      createPortEventHandler(df, el),
    ];

    return () => {
      eventHandlers.forEach((cleanup) => cleanup());
      drawflowRef.current = null;
      df.clear();
      el.remove();
    };
  }, []);

  return { canvasRef, drawflowRef };
};
