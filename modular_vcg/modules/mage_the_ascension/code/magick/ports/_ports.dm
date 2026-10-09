/datum/magick_ports/
	abstract_type = /datum/magick_ports/

	VAR_PROTECTED/list/portvars

	var/list/inputs
	var/list/outputs

/datum/magick_ports/activatable
	var/datum/magick_port/in_activate = MAGICK_PORT_ACTIVATE
	var/datum/magick_port/output/out_activate = MAGICK_PORT_ACTIVATE

/datum/magick_ports/New()
	inputs = list()
	outputs = list()

	// If this is too suboptimal, switch to manually filling
	// inputs/outputs with created vars in subclass
	for(var/v_name in src.vars)
		var/v_value = src.vars[v_name]

		if(istype(v_value, /datum/magick_port/))
			var/datum/magick_port/port = v_value
			if (port.input)
				inputs += v_value
			else
				outputs += v_value

/datum/magick_port/
	abstract_type = /datum/magick_port/

	VAR_PROTECTED/__payload
	// Treat vars below as if they are static abstract
	var/input = TRUE
	var/name
	var/desc
	var/type_flags

/datum/magick_port/New(name, type_flags, desc=null)
	src.name = name
	src.desc = desc
	src.type_flags = type_flags

/datum/magick_port/proc/get()
	return __payload

/datum/magick_port/proc/assign(value)
	if (type_flags & MAGICK_DATA_COUNT_ONE && istype(value, /list))
		WARNING("Rote expected single value, got list for [src.name]")
		return
	if (type_flags & MAGICK_DATA_COUNT_LIST && !istype(value, /list))
		WARNING("Rote expected list, got single for [src.name]")
		return
	src.__payload = value
