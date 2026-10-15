/datum/magick_context
	var/mob/caster
	// Avoid manually adjusting successes
	var/successes
	var/explains = 0
	var/paradox = FALSE
	var/nodes_traversed = 0

	// Blackboard access is alist<magick_port, magick_value>
	// and alist<magick_effect, magick_node_context>
	VAR_PRIVATE/alist/blackboard = new()

/datum/magick_context/proc/get(datum/magick_port/port)
	var/datum/magick_value/payload = blackboard[port]
	return payload == null ? null : port.validate(payload)

/datum/magick_context/proc/get_value(datum/magick_port/port)
	var/datum/magick_value/v = get(port)
	return v.value

/datum/magick_context/proc/assign(datum/magick_port/port, value, type_flags=null)
	if (istype(value, /datum/magick_value/))
		var/datum/magick_value/v = value
		if (MAGICK_DATATYPES_VALID(v.type_flags, port.type_flags))
			blackboard[port] = value
		return

	if (type_flags == null)
		type_flags = magick_get_datatype(value)

	if (!MAGICK_DATATYPES_VALID(type_flags, port.type_flags))
		stack_trace("Rote Builder Port '[port.name]' received incompatible types. Expected: [port.type_flags], got: [type_flags]")
		return

	blackboard[port] = new /datum/magick_value(value, type_flags)
