/*
 *  These are pre-defined port macros for magick effect nodes
 *
 * 	alist<port_key, alist("name" = ..., "type" = ..., "whitelist" = ..., "min_clamp" = ...., "max_clamp" = ...,
 *	"default_value" = ..., "optional" = TRUE/NULL, "manual" = TRUE/NULL, "size"? = ...)>
 *
 *	whitelist can be an alist or list for defining UI drop down menu, if list its keys are also its values
 *	size is only relevant for PATTERNs
 */

// Trigger

#define MAGICK_PORT_ACTIVATE \
	alist("name" = "Activate", "type" = MAGICK_DATATYPE_TRIGGER)

// Origin

#define MAGICK_PORT_ORIGIN \
	alist("name" = "Origin", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE, "optional" = TRUE, "promise" = "caster")

// Target

#define MAGICK_PORT_TARGET \
	alist("name" = "Target", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_SINGLE)

#define MAGICK_PORT_TARGETS \
	alist("name" = "Targets", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_LIST)

// Number

#define MAGICK_PORT_NUMBER(default, manual) \
	alist("name" = "Number", "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default, "manual" = manual)

#define MAGICK_PORT_NUMBER_CLAMP(min, max, default, manual) \
	alist("name" = "Number", "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default, "min_clamp" = min, "max_clamp" = max, "manual" = manual)

#define MAGICK_PORT_NUMBER_(name, default, manual) \
	alist("name" = name, "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default, "manual" = manual)

#define MAGICK_PORT_NUMBER_CLAMP_(name, min, max, default, manual) \
	alist("name" = name, "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE, "default_value" = default, "min_clamp" = min, "max_clamp" = max, "manual" = manual)


// String

#define MAGICK_PORT_STRING(name, whitelist, manual) \
	alist("name" = name, "type" = MAGICK_DATATYPE_STRING | MAGICK_DATATYPE_FLAG_SINGLE, "whitelist" = whitelist, "optional" = TRUE, "manual" = manual)

#define MAGICK_PORT_STRING_REQUIRED(name, whitelist, manual) \
	alist("name" = name, "type" = MAGICK_DATATYPE_STRING | MAGICK_DATATYPE_FLAG_SINGLE, "whitelist" = whitelist, "manual" = manual)

// Pattern
// "size" is the square length in rote builder
// (e.g. 3 = 3x3, 5 = 5x5, 7 = 7x7). origin tile defaults to the grid center.

#define MAGICK_PORT_PATTERN(manual, size, optional) \
	alist("name" = "Pattern", "type" = MAGICK_DATATYPE_PATTERN | MAGICK_DATATYPE_FLAG_SINGLE, "manual" = manual, "size" = size, "optional" = optional)

// Direction
#define MAGICK_PORT_DIRECTION(manual, optional) \
	alist("name" = "Direction", "type" = MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_DIRECTION | MAGICK_DATATYPE_FLAG_SINGLE, "min_clamp" = 1, "max_clamp" = 11, "default_value" = MAGICK_DIRECTION_CASTER, "whitelist" = alist("North" = NORTH, "Northeast" = NORTHEAST, "East" = EAST, "Southeast" = SOUTHEAST, "South" = SOUTH, "Southwest" = SOUTHWEST, "West" = WEST, "Northwest" = NORTHWEST, "Caster" = MAGICK_DIRECTION_CASTER), "manual" = manual, "optional" = optional)
