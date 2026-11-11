// DM Types

export type RoteBuilderData = {
  user_stats: UserStats;
  nodes: NodeData[];
  view_only?: boolean;
  rote_data?: string;
  rote_name?: string;
  rote_desc?: string;
};

export type UserStats = {
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
  [key: string]: unknown;
};

export type PortData = {
  id: string;
  name: string;
  type: number;
  desc?: string;
  default_value?: number | string;
  promise?: string;
  min_clamp?: number;
  max_clamp?: number;
  whitelist?: string[];
  [key: string]: unknown;
};

export type ExtendablePortGroup = {
  min: number;
  max: number;
  default: number;
};

export type NodeData = {
  name: string;
  desc: string;
  type: string;
  tags: number;
  quintessence: number;
  complexity: number;
  complexity_cap?: number;
  max_nodes?: number;
  min_success_cost?: number;
  spheres: Record<string, number>[] | Record<string, Record<string, number>>;
  extendable_ports?: Record<string, ExtendablePortGroup> | ExtendablePortGroup[];
  can_add_success: boolean;
  inputs: PortData[];
  outputs: PortData[];
  [key: string]: unknown;
};

export type NodeUserData = NodeSettings & { [key: string]: unknown };

// UI Types

export type PortDir = 'in' | 'out';

export type NodeSettings = {
  label: string;
  success_percentage: number;
  min_success: number;
  max_success: number;
  sphere_index: number;
  port_counts: Record<string, number>;
};

export type Position = { x: number; y: number };

export type PortOffsets = Record<string, Position>;
