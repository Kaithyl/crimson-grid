#define MAGICK_PORT_ACTIVATE 					new("Activate", MAGICK_DATA_TRIGGER)

#define MAGICK_PORT_NUMBER(min, max)			new("Number", MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE, min, max)
#define MAGICK_PORT_NUMBER_(name, min, max)		new(name, MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE, min, max)

#define MAGICK_PORT_ORIGIN						new("Origin", MAGICK_DATA_ANY | MAGICK_DATA_ORIGIN | MAGICK_DATA_COUNT_ONE, "Where the effect comes from.")

#define MAGICK_PORT_TARGET						new("Target", MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ONE)
#define MAGICK_PORT_TARGET_S					new("Target(s)", MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ANY)

#define MAGICK_PORT_STRING(name, whitelist)		new(name, whitelist)
