// Trigger

#define MAGICK_PORT_ACTIVATE \
	alist("name" = "Activate", "type" = MAGICK_DATATYPE_TRIGGER)

// Number

#define MAGICK_PORT_NUMBER(default) \
	alist("name" = "Number", "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default)

#define MAGICK_PORT_NUMBER_clamp(min, max, default) \
	alist("name" = "Number", "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default, "min_clamp" = min, "max_clamp" = max)

#define MAGICK_PORT_NUMBER_(name, default) \
	alist("name" = name, "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default)

#define MAGICK_PORT_NUMBER_clamp_(name, min, max, default) \
	alist("name" = name, "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default, "min_clamp" = min, "max_clamp" = max)

// Origin

#define MAGICK_PORT_ORIGIN \
	alist("name" = "Origin", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

// Target

#define MAGICK_PORT_TARGET \
	alist("name" = "Target", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_SINGLE)

#define MAGICK_PORT_TARGETS \
	alist("name" = "Targets", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_LIST)

// String

#define MAGICK_PORT_STRING(name, whitelist) \
	alist("name" = name, "type" = MAGICK_DATATYPE_STRING | MAGICK_DATATYPE_FLAG_SINGLE, "whitelist" = whitelist)
