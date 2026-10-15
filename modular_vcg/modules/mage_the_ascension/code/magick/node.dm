/datum/magick_value/
	var/value
	var/type_flags

/datum/magick_value/New(value, type_flags=null)
	if (type_flags != null)
		// Trust that the user gave the correct flags
		src.type_flags = type_flags
	else
		src.type_flags = magick_get_datatype(value)
	src.value = value

/datum/magick_port/
	abstract_type = /datum/magick_port/
	// Treat vars below as if they are static abstract
	var/input
	var/default_value
	var/name
	var/desc
	var/type_flags
	var/min_clamp
	var/max_clamp
	var/whitelist

/datum/magick_port/New(name, type_flags, default_value=null, desc=null, min_clamp=null, max_clamp=null, whitelist=null)
	src.name = name
	src.desc = desc
	src.type_flags = type_flags
	src.default_value = default_value
	src.min_clamp = min_clamp
	src.max_clamp = max_clamp
	src.whitelist = whitelist

/datum/magick_port/input
	input = TRUE

/datum/magick_port/output
	input = FALSE

/datum/magick_port/proc/validate(datum/magick_value/payload_ref)
	var/value = payload_ref.value
	if (type_flags & MAGICK_DATATYPE_NUMBER && type_flags & MAGICK_DATATYPE_FLAG_SINGLE)
		if (min_clamp != null)
			value = max(value, min_clamp)
		if (max_clamp != null)
			value = min(value, max_clamp)
		return new /datum/magick_value(value, payload_ref.type_flags)
	if (type_flags & MAGICK_DATATYPE_STRING && type_flags & MAGICK_DATATYPE_FLAG_SINGLE)
		if (whitelist)
			return (value in whitelist) ? payload_ref : new /datum/magick_value("", payload_ref.type_flags)
	return payload_ref
