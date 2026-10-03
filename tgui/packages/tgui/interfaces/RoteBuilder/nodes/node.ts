import DOMPurify from 'dompurify';
import type Drawflow from 'drawflow';

import { isTriggerPort } from './port';
import type { EffectData, PortData } from '../types';

const makePortLabels = (ports: PortData[], dir: 'input' | 'output'): string =>
  ports
    .map((port, i) => ({ port, cls: `${dir}_${i + 1}` }))
    .filter(({ port }) => !isTriggerPort(port))
    .map(
      ({ port: { name, type }, cls }) => `
        <div
          class="rote-node__port-label"
          data-port="${cls}"
          title="${DOMPurify.sanitize(`${name} (type ${type})`)}"
        >${DOMPurify.sanitize(name)}</div>
      `,
    )
    .join('');

export const makeNodeHtml = (effect: EffectData): string => {
  const desc = String(effect.desc ?? '').trim();

  return `
    <div class="rote-node__body">
      <div class="rote-node__title">${DOMPurify.sanitize(effect.name)}</div>

      <div class="rote-node__ports">
        <div class="rote-node__port-col rote-node__port-col--in">
          ${makePortLabels(effect.inputs, 'input')}
        </div>
        <div class="rote-node__port-col rote-node__port-col--out">
          ${makePortLabels(effect.outputs, 'output')}
        </div>
      </div>

      ${desc ? `<div class="rote-node__tooltip">${DOMPurify.sanitize(desc)}</div>` : ''}
    </div>
  `;
};

export const createEffectNode = (editor: Drawflow, effect: EffectData, clientX: number, clientY: number) => {
  const rect = editor.precanvas.getBoundingClientRect();
  const x = (clientX - rect.left) / editor.zoom;
  const y = (clientY - rect.top) / editor.zoom;

  editor.addNode(
    effect.name,
    effect.inputs.length,
    effect.outputs.length,
    x,
    y,
    `rote-effect rote-effect--${String(effect.type).split('/').pop()}`,
    effect,
    makeNodeHtml(effect),
    false,
  );
};
