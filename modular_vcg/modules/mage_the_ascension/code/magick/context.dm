// Container for important global values per spell
/datum/magick_context
	var/mob/caster
	var/successes
	var/complexity
	//var/explains = 0
	var/paradox = FALSE
	var/nodes_traversed = 0
	var/debug = FALSE

	// alist<magick_effect, alist<output_port_key, list<list(out_port_key, in_port_key, child)>>>
	var/alist/effect_graph

	// alist<node_id, /datum/magick_node_data>
	// Per-node userdata configured in the rote builder
	var/alist/node_data
	// The node currently being executed
	var/current_node_id

	VAR_PRIVATE/datum/magick_scope/scope
	VAR_PRIVATE/scope_id = 0

// Per-node userdata configured in the rote builder
/datum/magick_node_data/
	// The effect singleton this node uses
	var/datum/magick_effect/effect
	// Target selected for this node (root nodes)
	var/target
	// Name given to effect node
	var/label
	// What percentage of global success to allocate
	var/success_percentage
	// Success die clamps
	var/min_success
	var/max_success
	// alist<"port_[port_key]", value>
	var/alist/port_values

/datum/magick_context/New()
	..()
	scope = new /datum/magick_scope(0, null)

// Enter a new execution scope to handle split branches. Returns its ID.
/datum/magick_context/proc/push_scope()
	scope = new /datum/magick_scope(++scope_id, scope)
	return scope.id

/datum/magick_context/proc/pop_scope()
	if (scope.parent == null)
		// TODO: Throw error message that root was being popped
		return
	var/datum/magick_scope/old = scope
	scope = old.parent
	old.parent = null

/datum/magick_context/proc/get_scope_id()
	return scope.id

// Execution scope for the context
/datum/magick_scope/
	var/id
	var/datum/magick_scope/parent
	// alist<magick_effect, alist<port_key, magick_value>>
	var/alist/port_values = new()
	// alist<magick_effect, var>
	// Use this to send per-node data from pre_cast to cast, etc
	var/alist/blackboard = new()

/datum/magick_scope/New(id, datum/magick_scope/parent)
	src.id = id
	src.parent = parent

// Allows additional data to be associated with values
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

// Returns the effect singleton for a node, defaulting to the node currently being executed
/datum/magick_context/proc/get_effect(node_id = current_node_id)
	var/datum/magick_node_data/data = node_data ? node_data[node_id] : null
	return data?.effect

// helper function for getting the port definition
/datum/magick_context/proc/get_port(port)
	PRIVATE_PROC(TRUE)
	var/datum/magick_effect/node = get_effect()
	if (node == null)
		return null
	var/alist/def = node.inputs?[port]
	if (def == null)
		def = node.outputs?[port]
	return def

// returns the magick_value, or null if the port is unset
/datum/magick_context/proc/get(port)
	if (get_port(port) == null)
		return null
	var/datum/magick_scope/current = scope
	// check current scope first, then each parent scope
	while (current)
		var/alist/node_values = current.port_values[current_node_id]
		if (node_values != null)
			var/datum/magick_value/payload = node_values[port]
			if (payload != null)
				return payload
		current = current.parent
	return null

// returns the payload, with clamps/whitelist applied
/datum/magick_context/proc/get_value(port)
	var/alist/def = get_port(port)
	if (def == null)
		return null
	var/datum/magick_value/payload = get(port)
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
/datum/magick_context/proc/assign(port, value, type_flags=null)
	var/alist/def = get_port(port)
	if (def == null)
		stack_trace("Rote Builder: attempted to assign to unknown port '[port]' on node '[current_node_id]'")
		return

	var/datum/magick_value/payload
	if (istype(value, /datum/magick_value/))
		var/datum/magick_value/value_ref = value
		if (type_flags == null)
			type_flags = value_ref.type_flags
		// Inherit port flags (e.g. FLAG_ORIGIN) that the value doesn't inherently have
		type_flags |= (def["type"] & (MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE | MAGICK_DATATYPE_FLAG_LIST))
		if (!MAGICK_DATATYPES_VALID(type_flags, def["type"]))
			stack_trace("Rote Builder Port '[def["name"]]' (node '[current_node_id]' :: [port]) received incompatible types. Expected: [def["type"]], got: [type_flags]")
			return
		payload = value_ref
	else
		if (type_flags == null)
			type_flags = magick_get_datatype(value)
		// Inherit port flags (e.g. FLAG_ORIGIN) that the value doesn't inherently have
		type_flags |= (def["type"] & (MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE | MAGICK_DATATYPE_FLAG_LIST))
		if (!MAGICK_DATATYPES_VALID(type_flags, def["type"]))
			stack_trace("Rote Builder Port '[def["name"]]' (node '[current_node_id]' :: [port]) received incompatible types. Expected: [def["type"]], got: [type_flags]")
			return
		payload = new /datum/magick_value(value, type_flags)

	var/alist/node_values = scope.port_values[current_node_id]
	if (node_values == null)
		node_values = new()
		scope.port_values[current_node_id] = node_values
	node_values[port] = payload
