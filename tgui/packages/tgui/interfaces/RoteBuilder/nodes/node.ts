import DOMPurify from 'dompurify';
import type Drawflow from 'drawflow';

import { isTriggerPort, isNumberPort, isStringPort, hasWhitelist } from './port';
import { registerNode } from './nodes';
import type { EffectData, PortData } from '../types';

const makePortControls = (port: PortData): string => {
  if (isNumberPort(port)) {
    const min =
      port.clamp_min !== null && port.clamp_min !== undefined
        ? `min="${DOMPurify.sanitize(String(port.clamp_min))}"`
        : '';

    const max =
      port.clamp_max !== null && port.clamp_max !== undefined
        ? `max="${DOMPurify.sanitize(String(port.clamp_max))}"`
        : '';

    const value =
      port.default_value !== null && port.default_value !== undefined
        ? `value="${DOMPurify.sanitize(String(port.default_value))}"`
        : '';

    return `
      <input
        type="number"
        step="any"
        class="rote-port__value"
        ${min}
        ${max}
        ${value}
      />
    `;
  }

  if (isStringPort(port)) {
    if (hasWhitelist(port)) {
      const options = port.whitelist!.map((s) =>
        `<option value="${DOMPurify.sanitize(s)}">${DOMPurify.sanitize(s)}</option>`,
      );

      return `
        <select class="rote-port__whitelist">
          <option value="">—</option>
          ${options.join('')}
        </select>
      `;
    }

    const value =
      port.default_value !== null && port.default_value !== undefined
        ? `value="${DOMPurify.sanitize(String(port.default_value))}"`
        : '';

    return `
      <input
        type="text"
        class="rote-port__value"
        ${value}
      />
    `;
  }

  return '';
};

const makePortLabels = (ports: PortData[], dir: 'input' | 'output'): string =>
  ports
    .map((port, i) => ({ port, cls: `${dir}_${i + 1}` }))
    .filter(({ port }) => !isTriggerPort(port))
    .map(
      ({ port, cls }) => `
        <div
          class="rote-node__port-label"
          data-port="${cls}"
          title="${DOMPurify.sanitize(`${port.name} (type ${port.type})`)}"
        >
          <span>${DOMPurify.sanitize(port.name)}</span>
          ${dir === 'input' ? makePortControls(port) : ''}
          ${port.desc ? `<div class="rote-port__tooltip">${DOMPurify.sanitize(port.desc)}</div>` : ''}
        </div>
      `,
    )
    .join('');

export const makeNodeHtml = (effect: EffectData, label?: string): string => {
  const desc = String(effect.desc ?? '').trim();
  const sanitizedName = DOMPurify.sanitize(effect.name);
  const sanitizedLabel = label ? DOMPurify.sanitize(label) : '';
  const labelHidden = sanitizedLabel ? '' : ' rote-node__label--hidden';

  const labelHtml = `<div class="rote-node__label${labelHidden}">${sanitizedLabel}</div>`;

  return `
    <div class="rote-node__body">
      <div class="rote-node__header">
        <div class="rote-node__title-row">
          <span class="rote-node__title-text">${sanitizedName}</span>
          <span class="rote-node__settings-icon" title="Edit node settings">⚙</span>
        </div>
        ${labelHtml}
      </div>

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

  const nodeId = editor.addNode(
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

  registerNode(`node-${nodeId}`, effect);

  return nodeId;
};

