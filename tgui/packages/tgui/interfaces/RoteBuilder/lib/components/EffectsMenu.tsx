// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import type { MouseEvent as ReactMouseEvent } from 'react';

import type { EffectData } from '../types';

type Props = {
  effects: EffectData[];
  onPickUp: (effect: EffectData, e: ReactMouseEvent) => void;
};

export const EffectsMenu = ({ effects, onPickUp }: Props) => (
  <div className="rote-builder__effects-menu">
    <div className="rote-builder__effects-menu-header">Effects</div>
    {effects.map((effect) => (
      <div
        key={effect.name}
        className="rote-builder__effect"
        title={effect.desc}
        onMouseDown={(e) => onPickUp(effect, e)}
      >
        {effect.name}
      </div>
    ))}
  </div>
);
