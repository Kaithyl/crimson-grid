// DM Types

export type RoteBuilderData = {
  user_stats: UserStats;
  nodes: NodeData[];
  view_only?: boolean;
  rote_data?: string;
  rote_name?: string;
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
  key: string;
  name: string;
  type: number;
  desc?: string;
  default_value?: number | string;
  min_clamp?: number;
  max_clamp?: number;
  whitelist?: string[];
  [key: string]: unknown;
};

export type NodeData = {
  name: string;
  desc: string;
  type: string;
  tags: number;
  quintessence: number;
  complexity: number;
  max_nodes?: number;
  min_success_cost?: number;
  spheres: Record<string, number>[];
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
};

export type Position = { x: number; y: number };

export type PortOffsets = Record<string, Position>;
