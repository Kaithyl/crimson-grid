export type RoteBuilderData = {
  user_stats: UserStats;
  effects: EffectData[];
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
  name: string;
  type: number;
  desc?: string;
  default_value?: number | string;
  clamp_min?: number;
  clamp_max?: number;
  whitelist?: string[];
  [key: string]: unknown;
};

export type EffectData = {
  name: string;
  desc: string;
  type: string;
  tags: number;
  quintessence: number;
  complexity: number;
  spheres: Record<string, number>[];
  can_add_success: boolean;
  inputs: PortData[];
  outputs: PortData[];
  [key: string]: unknown;
};

export type NodeUserData = {
  label: string;
  success_percentage: number;
  min_success: number;
  max_success: number;
  [key: string]: unknown;
};
