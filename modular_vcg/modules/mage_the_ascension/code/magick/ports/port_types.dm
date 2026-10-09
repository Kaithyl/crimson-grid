
/datum/magick_port/output
	input = FALSE

/datum/magick_port/output/assign(value)
	src.__payload = value

/datum/magick_port/number
	var/clamp_min
	var/clamp_max

/datum/magick_port/number/New(name, type, clamp_min, clamp_max, desc=null)
	..(name, MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE, desc)
	if (clamp_min != null)
		src.clamp_min = clamp_min
	if (clamp_max != null)
		src.clamp_max = clamp_max

/datum/magick_port/number/assign(value)
	if (!isnum(value))
		WARNING("Rote expected number for [src.name]")
		return
	src.__payload = value

/datum/magick_port/number/get()
	var/value = __payload
	if (clamp_min != null)
		value = max(value, clamp_min)
	if (clamp_max != null)
		value = min(value, clamp_max)
	return value

/datum/magick_port/string
	var/whitelist

/datum/magick_port/string/New(name, type, whitelist, desc=null)
	..(name, MAGICK_DATA_STRING | MAGICK_DATA_COUNT_ONE, desc)
	if (whitelist != null)
		src.whitelist = whitelist

/datum/magick_port/string/assign(value)
	if (!istext(value))
		WARNING("Rote expected string for [src.name]")
		return
	src.__payload = value

/datum/magick_port/string/get()
	return (__payload in whitelist) ? __payload : ""

/datum/magick_port/_turf
/datum/magick_port/_turf/assign(value)
	if (!istype(value, /turf))
		WARNING("Rote expected turf for [src.name]")
		return
	src.__payload = value

/datum/magick_port/_obj
/datum/magick_port/_obj/assign(value)
	if (!istype(value, /obj))
		WARNING("Rote expected obj for [src.name]")
		return
	src.__payload = value

/datum/magick_port/_mob
/datum/magick_port/_mob/assign(value)
	if (!istype(value, /mob))
		WARNING("Rote expected mob for [src.name]")
		return
	src.__payload = value

/datum/magick_port/any
/datum/magick_port/any/assign(value)
	if (!istype(value, /turf) && !istype(value, /obj) && !istype(value, /mob))
		WARNING("Rote expected mob/obj/turf for [src.name]")
		return
	src.__payload = value
