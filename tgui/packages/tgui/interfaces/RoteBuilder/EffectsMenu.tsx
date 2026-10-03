import type { DragEvent } from 'react';
import type { EffectData } from './types';

type Props = {
  effects: EffectData[];
  onDragStart: (event: DragEvent, id: string) => void;
  onDragEnd: () => void;
};

export const EffectsMenu = (props: Props) => {
  const { effects, onDragStart, onDragEnd } = props;
  return (
    <div className="rote-builder__effects-menu">
      <div className="rote-builder__effects-menu-header">Effects</div>
      {effects.map((rote_effect) => (
        <div
          key={rote_effect.name}
          className="rote-builder__effect"
          title={rote_effect.desc}
          draggable
          onDragStart={(e) => onDragStart(e, rote_effect.name)}
          onDragEnd={onDragEnd}
        >
          {rote_effect.name}
        </div>
      ))}
    </div>
  );
};
