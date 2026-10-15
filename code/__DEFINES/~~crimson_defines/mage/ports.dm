// Trigger

#define MAGICK_PORT_ACTIVATE \
	new("Activate", MAGICK_DATATYPE_TRIGGER)

// Number

#define MAGICK_PORT_NUMBER(default) \
	new("Number", MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, default)

#define MAGICK_PORT_NUMBER_clamp(min, max, default) \
	new("Number", MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, default, min_clamp=min, max_clamp=max)

#define MAGICK_PORT_NUMBER_(name, default) \
	new(name, MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, default)

#define MAGICK_PORT_NUMBER_clamp_(name, min, max, default) \
	new(name, MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, default, min_clamp=min, max_clamp=max)

// Origin

#define MAGICK_PORT_ORIGIN \
	new("Origin", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

// Target

#define MAGICK_PORT_TARGET \
	new("Target", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_SINGLE)

#define MAGICK_PORT_TARGETS \
	new("Targets", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_LIST)

// String

#define MAGICK_PORT_STRING(name, whitelist) \
	new(name, whitelist)
