export const MAX_ROTENAME_CHARS = 40;

// DM Constants
// Any changes should be updated in ~~crimson_defines/rote_builder/nodes.dm
export const MAX_NODES = 20;

export const TAG_CAST = 1 << 0;
export const TAG_FOCI = 1 << 1;
export const TAG_DATA = 1 << 2;
export const TAG_UTILITY = 1 << 3;
export const TAG_DAMAGE = 1 << 4;
export const TAG_BUFF = 1 << 5;
export const TAG_DEBUFF = 1 << 6;

export const FLAG_TRIGGER = 1 << 0;
export const FLAG_NUMBER = 1 << 1;
export const FLAG_STRING = 1 << 2;
export const FLAG_STRING_OR_NUMBER = FLAG_NUMBER | FLAG_STRING;
export const FLAG_TURF = 1 << 3;
export const FLAG_OBJ = 1 << 4;
export const FLAG_MOB = 1 << 5;
export const FLAG_ATOM = FLAG_TURF | FLAG_OBJ | FLAG_MOB;

export const FLAG_ANY = FLAG_STRING_OR_NUMBER | FLAG_ATOM;

export const FLAG_ORIGIN = 1 << 21;
export const FLAG_SINGLE = 1 << 22;
export const FLAG_LIST = 1 << 23;

// UI Constants

export const GRID_SIZE = 900;
export const BG_SCALE = 0.5;
export const GRID_TILE = GRID_SIZE * BG_SCALE;

export const WIRE_COLOR = '#4682b4';
export const WIRE_WIDTH = 5;

// Temp vars for ports whose outputs should skip foci or effects
// TODO: Make more robust system
export const CAST_OUT_PORT = 'out_act_cast';
export const CAST_FOCI_PORT = 'out_act_foci';

// primary activate ports always render at top of node
export const PRIMARY_ACTIVATE_KEYS = ['in_act', 'out_act'];

// from IntegratedCircuit/constants.ts
export const MOUSE_BUTTON_LEFT = 0;
export const TIME_UNTIL_PORT_RELEASE_WORKS = 100;
export const PLACEMENT_GRAB = { x: 24, y: 16 };
