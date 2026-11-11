// THIS IS A DARKPACK UI FILE - CRIMSONGRID
import {
  type KeyboardEvent,
  type MouseEvent as ReactMouseEvent,
  useMemo,
  useRef,
  useState,
} from 'react';

import {
  TAG_BUFF,
  TAG_CAST,
  TAG_DAMAGE,
  TAG_DATA,
  TAG_DEBUFF,
  TAG_FOCI,
  TAG_UTILITY,
} from '../constants';
import type { NodeData } from '../types';

type Props = {
  nodes: NodeData[];
  onPickUp: (node: NodeData, e: ReactMouseEvent) => void;
};

const TAG_NAMES: Record<number, string> = {
  [TAG_CAST]: 'cast',
  [TAG_DATA]: 'data',
  [TAG_FOCI]: 'focus',
  [TAG_UTILITY]: 'utility',
  [TAG_DAMAGE]: 'damage',
  [TAG_BUFF]: 'buff',
  [TAG_DEBUFF]: 'debuff',
};

const tagName = (bit: number) => TAG_NAMES[bit] ?? String(bit);

const nodeTagNames = (node: NodeData): string[] =>
  Object.keys(TAG_NAMES)
    .map(Number)
    .filter((bit) => (node.tags & bit) !== 0)
    .map(tagName);

const matchesQuery = (node: NodeData, query: string) => {
  const needle = query.trim().toLowerCase();
  if (!needle) {
    return true;
  }
  return (
    node.name.toLowerCase().includes(needle) ||
    String(node.desc ?? '').toLowerCase().includes(needle) ||
    nodeTagNames(node).some((tag) => tag.includes(needle))
  );
};

export const NodesMenu = ({ nodes, onPickUp }: Props) => {
  const [tags, setTags] = useState<string[]>([]);
  const [draft, setDraft] = useState('');
  const inputRef = useRef<HTMLInputElement | null>(null);

  const addTag = (raw: string) => {
    const value = raw.trim().toLowerCase();
    if (!value) {
      return;
    }
    setTags((current) => (current.includes(value) ? current : [...current, value]));
    setDraft('');
  };

  const removeTag = (tag: string) => setTags((current) => current.filter((t) => t !== tag));

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addTag(draft);
    } else if (e.key === 'Backspace' && !draft && tags.length) {
      removeTag(tags[tags.length - 1]);
    }
  };

  const visible = useMemo(
    () =>
      nodes.filter(
        (node) =>
          matchesQuery(node, draft) &&
          tags.every((tag) => nodeTagNames(node).some((name) => name.includes(tag))),
      ),
    [nodes, draft, tags],
  );

  return (
    <div className="rote-builder__effects-menu">
      <div className="rote-builder__effects-menu-header">Nodes</div>

      <div className="rote-builder__node-search">
        <div className="rote-builder__tag-box" onClick={() => inputRef.current?.focus()}>
          {tags.map((tag) => (
            <span key={tag} className="rote-builder__tag-chip">
              {tag}
              <span
                className="rote-builder__tag-chip-remove"
                title="Remove tag"
                onClick={(e) => {
                  e.stopPropagation();
                  removeTag(tag);
                }}
              >
                ×
              </span>
            </span>
          ))}
          <input
            ref={inputRef}
            className="rote-builder__tag-input"
            placeholder={tags.length ? '' : 'Search nodes or type a tag...'}
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={onKeyDown}
            onBlur={() => addTag(draft)}
          />
        </div>
      </div>

      {visible.length === 0 && <div className="rote-builder__node-empty">No results.</div>}

      {visible.map((node) => (
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
};
