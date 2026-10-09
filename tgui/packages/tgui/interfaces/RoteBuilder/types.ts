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
};

export type PortData = {
  name: string;
  type: number;
  desc?: string;
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
  looks_like: number;
  explains: number;
  quintessence: number;
  min_successes: number;
  complexity: number;
  spheres: Record<string, number>[];
  inputs: PortData[];
  outputs: PortData[];
  [key: string]: unknown;
};
