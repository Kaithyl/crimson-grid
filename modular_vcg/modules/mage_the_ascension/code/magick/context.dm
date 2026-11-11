// Container for important global values per spell
/datum/magick_context
	var/mob/caster
	// Mage splat of caster
	var/datum/splat/mage/mage_splat
	var/successes
	var/complexity = 0
	var/complexity_cap = 0
	//var/explains = 0
	var/paradox = FALSE
	var/nodes_traversed = 0

	var/aborted = FALSE
	var/interrupted = FALSE
	var/arete_locked_in = FALSE
	var/foci_cast = FALSE

	var/difficulty_mod = 0
	var/willpower_auto_success = FALSE
	var/quint_diff_reduction = 0
	var/discarded_instrument_bonus = FALSE
	var/instrument_penalty = 0

	var/list/visited_nodes = list()
	var/list/visited_node_types = list()

	var/debug = FALSE

	// alist<rote_node, alist<output_port_key, list<list(out_port_key, in_port_key, child)>>>
	var/alist/effect_graph
	// alist<rote_node, alist<input_port_key, list<list(out_port_key, in_port_key, source)>>>
	var/alist/reverse_graph

	// alist<node_id, /datum/rote_node_data>
	// Per-node userdata configured in the rote builder
	var/alist/node_data
	// The node currently being executed
	var/current_node_id

	VAR_PRIVATE/datum/magick_scope/scope
	VAR_PRIVATE/scope_id = 0

// Per-node userdata configured in the rote builder
/datum/rote_node_data/
	// The node singleton this node uses
	var/datum/rote_node/node
	// Target selected for this node (root nodes)
	var/target
	// Name given to node
	var/label
	// What percentage of global success to allocate
	var/success_percentage
	// Success die clamps
	var/min_success
	var/max_success
	// alist<"port_[port_key]", value>
	var/alist/port_values
	// alist<id_prefix, visible port count> for extendable ports
	var/alist/port_counts

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
	// alist<rote_node, alist<port_key, magick_value>>
	var/alist/port_values = new()
	// alist<rote_node, var>
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

// Converts payload into a BYOND string
// Datums without a name return "Unknown" instead of their path
/datum/magick_value/proc/to_string()
	if (isdatum(value))
		var/datum/D = value
		if (!("name" in D.vars))
			return "Unknown"
	return "[value]"

// Returns the singleton for a node, defaulting to the node currently being executed
/datum/magick_context/proc/get_node(node_id = current_node_id)
	RETURN_TYPE(/datum/rote_node_data)
	var/datum/rote_node_data/data = node_data ? node_data[node_id] : null
	return data?.node

// helper function for getting the port definition
/datum/magick_context/proc/get_port(port)
	RETURN_TYPE(/alist)
	PRIVATE_PROC(TRUE)
	var/datum/rote_node/node = get_node()
	if (node == null)
		return null
	var/alist/def = node.inputs?[port]
	if (def == null)
		def = node.outputs?[port]
	return def

// returns the magick_value, or null if the port is unset
/datum/magick_context/proc/get(port)
	RETURN_TYPE(/datum/magick_value)
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

// assigns a value to a port on an node
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
		// Inherit port flags
		type_flags |= (def["type"] & (MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE | MAGICK_DATATYPE_FLAG_LIST))
		if (!MAGICK_DATATYPES_VALID(type_flags, def["type"]))
			stack_trace("Rote Builder Port '[def["name"]]' (node '[current_node_id]' :: [port]) received incompatible types. Expected: [def["type"]], got: [type_flags]")
			return
		payload = value_ref
	else
		if (type_flags == null)
			type_flags = magick_get_datatype(value)
		// Inherit port flags
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
