/datum/magick_context
	var/mob/caster
	// Avoid manually adjusting successes
	var/successes
	var/explains = 0
	var/paradox = FALSE
	var/nodes_traversed = 0
	var/debug = FALSE

	// alist<magick_effect, alist<output_port_key, list<list(out_port_key, in_port_key, child)>>>
	var/alist/effect_graph

	// alist<magick_effect, alist<port_key, magick_value>>
	VAR_PRIVATE/alist/port_values = new()

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

// helper function for getting the port definition
/datum/magick_context/proc/get_port(datum/magick_effect/node, port)
	PRIVATE_PROC(TRUE)
	if (node == null)
		return null
	var/alist/def = node.inputs?[port]
	if (def == null)
		def = node.outputs?[port]
	return def

// returns the magick_value, or null if the port is unset
/datum/magick_context/proc/get(datum/magick_effect/node, port)
	if (get_port(node, port) == null)
		return null
	var/alist/node_values = port_values[node]
	if (node_values == null)
		return null
	return node_values[port]

// returns the payload, with clamps/whitelist applied
/datum/magick_context/proc/get_value(datum/magick_effect/node, port)
	var/alist/def = get_port(node, port)
	if (def == null)
		return null
	var/datum/magick_value/payload = get(node, port)
	if (payload == null)
		return null

	var/value = payload.value
	if (def["type"] & MAGICK_DATATYPE_NUMBER && def["type"] & MAGICK_DATATYPE_FLAG_SINGLE)
		if (def["min_clamp"] != null)
			value = max(value, def["min_clamp"])
		if (def["max_clamp"] != null)
			value = min(value, def["max_clamp"])
	else if (def["type"] & MAGICK_DATATYPE_STRING && def["type"] & MAGICK_DATATYPE_FLAG_SINGLE)
		if (def["whitelist"] != null && !(value in def["whitelist"]))
			value = ""
	return value

// assigns a value to a port on an effect node
/datum/magick_context/proc/assign(datum/magick_effect/node, port, value, type_flags=null)
	var/alist/def = get_port(node, port)
	if (def == null)
		stack_trace("Rote Builder: attempted to assign to unknown port '[port]' on [node.type]")
		return

	var/datum/magick_value/payload
	if (istype(value, /datum/magick_value/))
		var/datum/magick_value/value_ref = value
		if (type_flags == null)
			type_flags = value_ref.type_flags
		// Inherit port flags (e.g. FLAG_ORIGIN) that the value doesn't inherently have
		type_flags |= (def["type"] & (MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE | MAGICK_DATATYPE_FLAG_LIST))
		if (!MAGICK_DATATYPES_VALID(type_flags, def["type"]))
			stack_trace("Rote Builder Port '[def["name"]]' ([node.type] :: [port]) received incompatible types. Expected: [def["type"]], got: [type_flags]")
			return
		payload = value_ref
	else
		if (type_flags == null)
			type_flags = magick_get_datatype(value)
		// Inherit port flags (e.g. FLAG_ORIGIN) that the value doesn't inherently have
		type_flags |= (def["type"] & (MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE | MAGICK_DATATYPE_FLAG_LIST))
		if (!MAGICK_DATATYPES_VALID(type_flags, def["type"]))
			stack_trace("Rote Builder Port '[def["name"]]' ([node.type] :: [port]) received incompatible types. Expected: [def["type"]], got: [type_flags]")
			return
		payload = new /datum/magick_value(value, type_flags)

	var/alist/node_values = port_values[node]
	if (node_values == null)
		node_values = new()
		port_values[node] = node_values
	node_values[port] = payload
