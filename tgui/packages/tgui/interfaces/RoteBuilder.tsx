// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import { useEffect, useRef } from 'react';
import { Box } from 'tgui-core/components';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Window } from '../layouts';

import Drawflow from 'drawflow';
import DOMPurify from 'dompurify';

// @ts-ignore
import 'drawflow/dist/drawflow.min.css';
// @ts-ignore
import '../styles/interfaces/RoteBuilder.scss'; // Load this last to override default drawflow styles

type EffectData = {
  name: string;
  desc: string;
  type: string;
  tags: number;
  looks_like: number;
  explains: number;
  quintessence: number;
  min_successes: number;
  complexity: number;
  spheres: Record<string, number>[];
  inputs: Record<string, number>;
  outputs: Record<string, number>;
};

type UserStats = {
  arete: number;
  correspondence?: number;
  entropy?: number;
  forces?: number;
  life?: number;
  matter?: number;
  mind?: number;
  prime?: number;
  spirit?: number;
  time?: number;
};

type RoteBuilderData = {
  user_stats: UserStats;
  effects: EffectData[];
};

type PortDef = [string, number];

type RoteNodeData = {
  name: string;
  desc: string;
  type: string;
  inputs: PortDef[];
  outputs: PortDef[];
};

type DrawflowConnectionEvent = {
  output_id: string;
  input_id: string;
  output_class: string;
  input_class: string;
};

type DrawflowConnectionStartEvent = {
  output_id: string;
  output_class: string;
};

type InputConnection = { node: string; input: string };

const GRID_SIZE = 900;

const toPortDefs = (ports?: Record<string, number> | unknown[]): PortDef[] =>
  ports && !Array.isArray(ports)
    ? Object.entries(ports).map(([name, type]) => [name, type])
    : [];

const portIndex = (portClass: string) => Number(portClass.split('_')[1]) - 1;

const portsCompatible = (outType: number, inType: number) => outType === inType;

const isActivate = (name: string) => name.toLowerCase() === 'activate';

export const RoteBuilder = () => {
  const { data } = useBackend<RoteBuilderData>();
  const { effects = [] } = data;

  const containerRef = useRef<HTMLDivElement | null>(null);
  const editorRef = useRef<Drawflow | null>(null);
  const draggedEffectRef = useRef<string | null>(null);

  const effectsRef = useRef(effects);
  effectsRef.current = effects;

  useEffect(() => {
    const container = containerRef.current;
    if (!container) {
      return;
    }

    const host = document.createElement('div');
    host.className = 'rote-drawflow-host';
    host.style.backgroundImage = `url("${resolveAsset('grid_background.png')}")`;
    host.style.backgroundSize = `${GRID_SIZE}px`;
    container.appendChild(host);

    const editor = new Drawflow(host);
    editor.reroute = false;
    editor.start();
    editorRef.current = editor;

    /* Drag hints */

    const clearDragHints = () => {
      host
        .querySelectorAll('.rote-port--invalid')
        .forEach((el) => el.classList.remove('rote-port--invalid'));
    };

    editor.on(
      'connectionStart',
      ({ output_id, output_class }: DrawflowConnectionStartEvent) => {
        const outData = editor.getNodeFromId(output_id).data as RoteNodeData;
        const outPort = outData.outputs[portIndex(output_class)];
        if (!outPort) {
          return;
        }

        const nodes = editor.drawflow.drawflow[editor.module].data as Record<
          string,
          { data: RoteNodeData }
        >;

        for (const [id, node] of Object.entries(nodes)) {
          const nodeEl = host.querySelector(`#node-${id}`);
          if (!nodeEl) {
            continue;
          }

          node.data.inputs.forEach(([, inType], i) => {
            if (portsCompatible(outPort[1], inType)) {
              return;
            }

            const cls = `input_${i + 1}`;
            nodeEl.querySelector(`.${cls}`)?.classList.add('rote-port--invalid');
            nodeEl
              .querySelector(`.rote-node__port-label[data-port="${cls}"]`)
              ?.classList.add('rote-port--invalid');
          });
        }
      },
    );

    editor.on('connectionCancel', clearDragHints);

    /* Connection validation */

    editor.on('connectionCreated', (conn: DrawflowConnectionEvent) => {
      clearDragHints();

      const outData = editor.getNodeFromId(conn.output_id).data as RoteNodeData;
      const inNode = editor.getNodeFromId(conn.input_id);
      const inData = inNode.data as RoteNodeData;

      const outPort = outData.outputs[portIndex(conn.output_class)];
      const inPort = inData.inputs[portIndex(conn.input_class)];

      if (!outPort || !inPort || !portsCompatible(outPort[1], inPort[1])) {
        editor.removeSingleConnection(
          conn.output_id,
          conn.input_id,
          conn.output_class,
          conn.input_class,
        );
        return;
      }

      const existing = [
        ...(inNode.inputs[conn.input_class].connections as InputConnection[]),
      ].slice(0, -1);

      existing.forEach((old) => {
        editor.removeSingleConnection(
          old.node,
          conn.input_id,
          old.input,
          conn.input_class,
        );
      });
    });

    window.addEventListener('mouseup', clearDragHints);
    window.addEventListener('touchend', clearDragHints);

    /* Canvas */

    editor.on('translate', ({ x, y }: { x: number; y: number }) => {
      host.style.backgroundPosition = `${x}px ${y}px`;
    });

    editor.on('zoom', (zoom: number) => {
      host.style.backgroundSize = `${GRID_SIZE * zoom}px`;
    });

    /* Nodes */
    editor.on('nodeCreated', (id) => {
      const node = editor.getNodeFromId(id);
      const nodeEl = host.querySelector(`#node-${id}`);
      if (!node || !nodeEl) {
        return;
      }

      const nodeData = node.data as RoteNodeData;

      nodeData.inputs.forEach(([name], i) => {
        if (isActivate(name)) {
          nodeEl.querySelector(`.input_${i + 1}`)?.classList.add('rote-port--activate');
        }
      });

      nodeData.outputs.forEach(([name], i) => {
        if (isActivate(name)) {
          nodeEl.querySelector(`.output_${i + 1}`)?.classList.add('rote-port--activate');
        }
      });
    });

    editor.on('nodeRemoved', (id) => console.log('Node removed:', id));

    return () => {
      window.removeEventListener('mouseup', clearDragHints);
      window.removeEventListener('touchend', clearDragHints);
      editorRef.current = null;
      editor.clear();
      host.remove();
    };
  }, []);

  const onDragStart = (event: React.DragEvent, effectName: string) => {
    draggedEffectRef.current = effectName;
    event.dataTransfer.setData('text/plain', effectName);
    event.dataTransfer.effectAllowed = 'copy';
  };

  const onDragOver = (event: React.DragEvent) => {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'copy';
  };

  const onDrop = (event: React.DragEvent) => {
    event.preventDefault();

    const editor = editorRef.current;
    const effectName =
      event.dataTransfer.getData('text/plain') || draggedEffectRef.current;

    draggedEffectRef.current = null;

    if (!editor || !effectName) {
      return;
    }

    const effect = effectsRef.current.find((e) => e.name === effectName);
    if (!effect) {
      return;
    }

    const rect = editor.precanvas.getBoundingClientRect();
    const x = (event.clientX - rect.left) / editor.zoom;
    const y = (event.clientY - rect.top) / editor.zoom;

    const inputs = toPortDefs(effect.inputs);
    const outputs = toPortDefs(effect.outputs);

    const nodeData: RoteNodeData = {
      name: effect.name,
      desc: effect.desc ?? '',
      type: effect.type,
      inputs,
      outputs,
    };

    const portLabels = (ports: PortDef[], dir: 'input' | 'output') =>
      ports
        .map(([name, type], i) => ({ name, type, cls: `${dir}_${i + 1}` }))
        .filter(({ name }) => !isActivate(name))
        .map(
          ({ name, type, cls }) => `
            <div
              class="rote-node__port-label"
              data-port="${cls}"
              title="${DOMPurify.sanitize(`${name} (type ${type})`)}"
            >${DOMPurify.sanitize(name)}</div>
          `,
        )
        .join('');

    const desc = (effect.desc ?? '').trim();

    const html = `
      <div class="rote-node__body">
        <div class="rote-node__title">${DOMPurify.sanitize(effect.name)}</div>

        <div class="rote-node__ports">
          <div class="rote-node__port-col rote-node__port-col--in">
            ${portLabels(inputs, 'input')}
          </div>
          <div class="rote-node__port-col rote-node__port-col--out">
            ${portLabels(outputs, 'output')}
          </div>
        </div>

        ${desc ? `<div class="rote-node__tooltip">${DOMPurify.sanitize(desc)}</div>` : ''}
      </div>
    `;

    editor.addNode(
      effect.name,
      inputs.length,
      outputs.length,
      x,
      y,
      `rote-effect rote-effect--${effect.type}`,
      nodeData,
      html,
      false,
    );
  };

  return (
    <Window width={1200} height={800} title="Rote Builder">
      <Window.Content className="rote-builder__content">
        <div className="rote-builder">
          {/* Drawflow */}
          <div
            ref={containerRef}
            className="rote-builder__canvas"
            onDragOver={onDragOver}
            onDrop={onDrop}
          />

          {/* Effects list */}
          <Box className="rote-builder__palette">
            <Box className="rote-builder__palette-header">Effects</Box>

            {effects.map((effect) => (
              <div
                key={effect.name}
                className="rote-builder__effect"
                draggable
                title={effect.desc}
                onDragStart={(e) => onDragStart(e, effect.name)}
                onDragEnd={() => {
                  draggedEffectRef.current = null;
                }}
              >
                {effect.name}
              </div>
            ))}
          </Box>
        </div>
      </Window.Content>
    </Window>
  );
};
