/// Container for important global values per spell
/// A new context is initialized per cast
/// partial implementation of context vars are split between context.dm, execution.dm and scope.dm

/datum/magick_context
	var/mob/caster
	// Mage splat of caster
	var/datum/splat/mage/mage_splat

	var/successes
	var/paradox = FALSE

	var/complexity = 0
	var/complexity_cap = 0

	var/willpower_auto_success = FALSE
	var/quint_diff_reduction = 0

	//var/list/visited_nodes = list()
	//var/list/visited_node_types = list()

	var/debug = FALSE

// Both vars will be modified, so if passing from magick_rote, make sure to COPY instead of pass by ref
/datum/magick_context/New(execution_stack = null, port_values = null)
	src.execution_stack = execution_stack
	//src.port_values = port_values
	current_scope.port_values = port_values

/// Per-node userdata configured in the rote builder
/datum/rote_node_data/
	// The node singleton this node uses
	var/datum/rote_node/node
	// Name given to node
	var/label
	// What percentage of global success to allocate
	var/success_percentage
	// Success die clamps
	var/min_success
	var/max_success
	// alist<id_prefix, visible port count> for extendable ports
	var/alist/port_counts

// returns the rote-specific node data
/datum/magick_context/proc/get_node_data()
	RETURN_TYPE(/datum/rote_node_data)
	var/datum/rote_node_data/data = node_data ? node_data[current_node_id] : null
	return data

// returns the global singleton for a node
/datum/magick_context/proc/get_node(node_id = current_node_id)
	RETURN_TYPE(/datum/rote_node)
	var/datum/rote_node_data/data = node_data ? node_data[node_id] : null
	return data?.node

// helper function for getting the port definition
/datum/magick_context/proc/get_port(port)
	RETURN_TYPE(/alist)
	PRIVATE_PROC(TRUE)
	var/datum/rote_node_data/data = get_node_data()
	var/datum/rote_node/node = data?.node
	if (node == null)
		return null
	var/alist/def = node.inputs?[port]
	if (def == null)
		def = node.outputs?[port]
	return def

/// Holds a ref or a primitive value, flags are for easy typechecking with ports
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

// Converts the payload into a BYOND string
// Datums without a name return "Unknown" instead of their path
/datum/magick_value/proc/to_string()
	if (isdatum(value))
		var/datum/D = value
		if (!("name" in D.vars))
			return "Unknown"
	return "[value]"

// returns the magick_value, or null if the port is unset
/datum/magick_context/proc/get(port)
	RETURN_TYPE(/datum/magick_value)
	if (get_port(port) == null)
		return null
	return read(current_node_id, port)

// returns the payload, with clamps/whitelist applied
/datum/magick_context/proc/get_value(port)
	var/alist/def = get_port(port)
	if (def == null)
		return null
	var/datum/magick_value/payload = get(port)
	if (payload == null)
		return null

	var/value = payload.value
	if (isnum(value) && def["type"] & MAGICK_DATATYPE_NUMBER && def["type"] & MAGICK_DATATYPE_FLAG_SINGLE)
		if (def["min_clamp"] != null)
			value = max(value, def["min_clamp"])
		if (def["max_clamp"] != null)
			value = min(value, def["max_clamp"])
	else if (def["type"] & MAGICK_DATATYPE_STRING && def["type"] & MAGICK_DATATYPE_FLAG_SINGLE)
		if (def["whitelist"] != null && !(value in def["whitelist"]))
			value = ""
	if ((payload.type_flags & MAGICK_DATATYPE_FLAG_DIRECTION) && (!value || value == MAGICK_DIRECTION_CASTER))
		value = caster?.dir || NORTH
	return value

// assigns a value to a port on an node
/datum/magick_context/proc/assign(port, value, type_flags=null)
	var/alist/def = get_port(port)
	if (def == null)
		stack_trace("Rote Builder attempted to assign to unknown port '[port]' on node '[current_node_id]'")
		return

	var/datum/magick_value/payload
	if (istype(value, /datum/magick_value/))
		var/datum/magick_value/value_ref = value
		if (type_flags == null)
			type_flags = value_ref.type_flags
		// Inherit port flags
		type_flags |= (def["type"] & (MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE | MAGICK_DATATYPE_FLAG_LIST))
		if (!MAGICK_DATATYPES_VALID(type_flags, def["type"]))
			stack_trace("Rote Builder Port '[def["name"]]' (node '[current_node_id]' :: [port]) received incompatible types. Expected flags: [def["type"]], got: [type_flags]")
			return
		payload = value_ref
	else
		if (type_flags == null)
			type_flags = magick_get_datatype(value)
		// Inherit port flags
		type_flags |= (def["type"] & (MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE | MAGICK_DATATYPE_FLAG_LIST))
		if (!MAGICK_DATATYPES_VALID(type_flags, def["type"]))
			stack_trace("Rote Builder Port '[def["name"]]' (node '[current_node_id]' :: [port]) received incompatible types. Expected flags: [def["type"]], got: [type_flags]")
			return
		payload = new /datum/magick_value(value, type_flags)

	current_scope.set_port_value(current_node_id, port, payload)

	// activating trigger port immediately sends signal to children
	if ((def["type"] & MAGICK_DATATYPE_TRIGGER) && payload.value)
		var/alist/edges = rote_graph ? rote_graph[current_node_id] : null
		var/list/tuples = edges?[port]
		if (tuples)
			for (var/list/tuple as anything in tuples)
				var/in_port = tuple[2]
				var/child_id = tuple[3]
				var/datum/rote_node/child = get_node(child_id)
				var/alist/in_def = child?.inputs?[in_port]
				if (in_def == null)
					continue
				enqueue_stack(child_id, current_scope.successes)

/datum/rote_node/proc/debug(datum/magick_context/context)
	to_chat(context.caster, span_info("DEBUG: --- [name] ([type]) ---"))
	to_chat(context.caster, span_info("DEBUG: Global successes: [context.successes]"))
	for (var/port_key as anything in inputs)
		var/datum/magick_value/port_val = context.get(port_key)
		var/alist/port_def = inputs[port_key]
		if (!isnull(port_val))
			to_chat(context.caster, span_info("DEBUG:   input '[port_def["name"]]' = [port_val.value]"))
		else
			to_chat(context.caster, span_info("DEBUG:   input '[port_def["name"]]' = EMPTY"))
	for (var/port_key as anything in outputs)
		var/datum/magick_value/port_val = context.get(port_key)
		var/alist/port_def = outputs[port_key]
		if (!isnull(port_val))
			to_chat(context.caster, span_info("DEBUG:   output '[port_def["name"]]' = [port_val.value]"))
		else
			to_chat(context.caster, span_info("DEBUG:   output '[port_def["name"]]' = EMPTY"))
