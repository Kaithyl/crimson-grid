import type Drawflow from 'drawflow';

import { BG_SCALE, GRID_SIZE } from './constants';
import { getPorts, isTriggerPort, validConnection, portIndex } from './nodes/port'
import type { EffectData } from './types';

// All event handlers created inside a useEffect should return this function for cleaning themselves
type CleanupHandler = () => void;

const PORT_INVALID = 'rote-port--invalid';
const PORT_TRIGGER = 'rote-port--activate';

export const createCanvasEventHandler = (df: Drawflow, el: HTMLElement): CleanupHandler => {
	const updateBackground = (c_x: number = df.canvas_x, c_y: number = df.canvas_y) => {
		const zoom = df.zoom;
		const tile = GRID_SIZE * BG_SCALE * zoom;
		const w = df.precanvas.clientWidth;
		const h = df.precanvas.clientHeight;
		const x = c_x + (w / 2) * (1 - zoom);
		const y = c_y + (h / 2) * (1 - zoom);
		el.style.backgroundSize = `${tile}px ${tile}px`;
		el.style.backgroundPosition = `${x}px ${y}px`;
	};

	updateBackground();

	df.on('translate', ({ x, y }: { x: number; y: number }) => updateBackground(x, y));
	df.on('zoom', () => requestAnimationFrame(() => updateBackground()));

	const onResize = () => updateBackground();
	window.addEventListener('resize', onResize);

	return () => window.removeEventListener('resize', onResize);
}

export const createNodeEventHandler = (df: Drawflow, el: HTMLElement): CleanupHandler => {
	df.on('nodeCreated', (id) => {
		const node = df.getNodeFromId(id);
		const nodeEl = el.querySelector(`#node-${id}`);
		if (!node || !nodeEl) {
			return;
		}

		getPorts(node.data, 'inputs').forEach((port, i) => {
			if (isTriggerPort(port)) {
				nodeEl.querySelector(`.inputs .input_${i + 1}`)?.classList.add(PORT_TRIGGER);
			}
		});

		getPorts(node.data, 'outputs').forEach((port, i) => {
			if (isTriggerPort(port)) {
				nodeEl.querySelector(`.outputs .output_${i + 1}`)?.classList.add(PORT_TRIGGER);
			}
		});
	});

	df.on('nodeRemoved', (id) => console.log('Node removed:', id));
	return () => {};
};

export const createPortEventHandler = (df: Drawflow, el: HTMLElement): CleanupHandler => {
	const clearDragHints = () => {
		el.querySelectorAll(`.${PORT_INVALID}`).forEach((el) => el.classList.remove(PORT_INVALID));
	};

	// Mark every input port that the dragged output can't connect to
	df.on('connectionStart', ({ output_id, output_class }) => {
		const outPort = getPorts(df.getNodeFromId(output_id)?.data, 'outputs')[portIndex(output_class)];
		if (!outPort) {
			return;
		}

		const nodes = df.drawflow.drawflow[df.module].data as Record<string, { data: EffectData }>;

		for (const [id, node] of Object.entries(nodes)) {
			const nodeEl = el.querySelector(`#node-${id}`);
			if (!nodeEl) {
				continue;
			}

			getPorts(node.data, 'inputs').forEach((inPort, i) => {
				if (String(id) !== String(output_id) && validConnection(outPort, inPort)) {
					return;
				}

				const cls = `input_${i + 1}`;
				nodeEl.querySelector(`.inputs .${cls}`)?.classList.add(PORT_INVALID);
				nodeEl.querySelector(`.rote-node__port-label[data-port="${cls}"]`)?.classList.add(PORT_INVALID);
			});
		}
	});

	df.on('connectionCancel', clearDragHints);

	df.on('connectionCreated', (conn) => {
		clearDragHints();

		const outNode = df.getNodeFromId(conn.output_id);
		const inNode = df.getNodeFromId(conn.input_id);

		const outPort = getPorts(outNode?.data, 'outputs')[portIndex(conn.output_class)];
		const inPort = getPorts(inNode?.data, 'inputs')[portIndex(conn.input_class)];

		if (!outPort || !inPort || !validConnection(outPort, inPort)) {
			df.removeSingleConnection(conn.output_id, conn.input_id, conn.output_class, conn.input_class);
			return;
		}

		// Make sure input ports can't have more than one parent
		const connections = inNode.inputs?.[conn.input_class]?.connections ?? [];
		connections.slice(0, -1).forEach((connection) => {
			df.removeSingleConnection(connection.node, conn.input_id, connection.input, conn.input_class);
		});
	});

	window.addEventListener('mouseup', clearDragHints);
	window.addEventListener('touchend', clearDragHints);

	return () => {
		window.removeEventListener('mouseup', clearDragHints);
		window.removeEventListener('touchend', clearDragHints);
	};
};
