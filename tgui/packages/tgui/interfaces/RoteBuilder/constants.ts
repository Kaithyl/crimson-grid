export const GRID_SIZE = 900;
export const BG_SCALE = 0.5;

export const MAX_ROTENAME_CHARS = 40;
export const MAX_NODES = 20;

export const TAG_ROOT = 1 << 0;
export const TAG_DATA = 1 << 1;
export const TAG_UTILITY = 1 << 2;
export const TAG_DAMAGE = 1 << 3;
export const TAG_BUFF = 1 << 4;
export const TAG_DEBUFF = 1 << 5;

export const FLAG_TRIGGER = (1 << 0);
export const FLAG_NUMBER = (1 << 1);
export const FLAG_STRING = (1 << 2);
export const FLAG_STRING_OR_NUMBER = FLAG_NUMBER | FLAG_STRING;
export const FLAG_TURF = (1 << 3);
export const FLAG_OBJ = (1 << 4);
export const FLAG_MOB = (1 << 5);
export const FLAG_ATOM = FLAG_TURF | FLAG_OBJ | FLAG_MOB;
