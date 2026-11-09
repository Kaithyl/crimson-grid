// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import type { MouseEvent as ReactMouseEvent } from 'react';

import type { NodeData } from '../types';

type Props = {
  nodes: NodeData[];
  onPickUp: (node: NodeData, e: ReactMouseEvent) => void;
};

export const NodesMenu = ({ nodes, onPickUp }: Props) => (
  <div className="rote-builder__effects-menu">
    <div className="rote-builder__effects-menu-header">Nodes</div>
    {nodes.map((node) => (
      <div
        key={node.name}
        className="rote-builder__effect"
        title={node.desc}
        onMouseDown={(e) => onPickUp(node, e)}
      >
        {node.name}
      </div>
    ))}
  </div>
);
