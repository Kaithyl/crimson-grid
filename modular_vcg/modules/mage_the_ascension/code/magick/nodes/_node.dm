// This holds the actual code execution per node
/datum/rote_node/
	abstract_type = /datum/rote_node/

	var/name
	var/desc
	var/tags

	// Maximum number of this subtype of node allowed in a spell
	// Mostly to prevent lag for costly effects
	var/max_nodes

	// How much complexity this node takes up
	var/complexity = 0

	// Sphere combinations for this node
	var/list/spheres

	// Port system for nodes
	var/in_act = "in_act"
	var/out_act = "out_act"

	// alist<port_key, alist("name" = ..., "type" = ..., ...)>
	var/alist/inputs
	var/alist/outputs

GLOBAL_LIST_INIT_TYPED(rote_nodes, /datum/rote_node, init_subtypes_w_path_keys(/datum/rote_node, list()))
GLOBAL_LIST_INIT(rotebuilder_static_data, init_rotebuilder_static_data())

/datum/rote_node/proc/is_ready(datum/magick_context/context)
	var/alist/input_defs = src.inputs
	for (var/port_key as anything in input_defs)
		if (context.get(port_key) == null)
			// Check if this port has an incoming connection in the effect graph
			var/has_connection = FALSE
			for (var/source_id as anything in context.effect_graph)
				var/alist/out_edges = context.effect_graph[source_id]
				for (var/out_port_key as anything in out_edges)
					for (var/list/tuple as anything in out_edges[out_port_key])
						if (tuple[3] == context.current_node_id && tuple[2] == port_key)
							has_connection = TRUE
							break
					if (has_connection)
						break
				if (has_connection)
					break
			if (has_connection)
				return FALSE
	return TRUE

// For handling pre and post cast
/datum/rote_node/proc/__cast(datum/magick_context/context)
	SHOULD_NOT_OVERRIDE(TRUE)
	// Fizzle spell if someone manages to pass the traversal limit
	if (++context.nodes_traversed > MAGICK_MAX_TRAVERSAL)
		return

	// Prevent large spell graphs from monopolizing server execution
	if (context.nodes_traversed % MAGICK_SLEEP_INTERVAL == 0)
		sleep(0)

	pre_cast(context)
	cast(context)

	if (context.debug)
		debug_to_user(context)

	post_cast(context)

// Must override this for actually doing the effect
/datum/rote_node/proc/cast(datum/magick_context/context)
	PROTECTED_PROC(TRUE)
	return

// This will be for pre-processing data that will be used in cast
/datum/rote_node/proc/pre_cast(datum/magick_context/context)
	PROTECTED_PROC(TRUE)
	return

// Only override for custom handling of child nodes.
// Uses the effect graph dictionary on the context set by the rote.
// auto_traverse is only here to make code reuse easier for iteration/for each nodes
// TODO: replace auto_traverse when if there is a better architecture
/datum/rote_node/proc/post_cast(datum/magick_context/context, auto_traverse = TRUE)
	PROTECTED_PROC(TRUE)
	var/node_id = context.current_node_id
	var/alist/edges = context.effect_graph[node_id]
	if (edges == null)
		return

	// Activate children by default
	if (auto_traverse && edges[out_act] && inputs?[in_act] && outputs?[out_act] && context.get(out_act) == null)
		var/incoming = context.get_value(in_act)
		if (incoming != null)
			context.assign(out_act, incoming, MAGICK_DATATYPE_TRIGGER)

	// count trigger branches per output port for success splitting
	var/alist/trigger_branches = new()
	for (var/out_port_key as anything in edges)
		if (context.get(out_port_key) == null)
			continue
		var/count = 0
		for (var/list/tuple as anything in edges[out_port_key])
			var/in_port_key = tuple[2]
			var/child_id = tuple[3]
			var/datum/rote_node/child = context.get_node(child_id)
			var/alist/child_inputs = child.inputs
			var/alist/in_port_def = child_inputs ? child_inputs[in_port_key] : null
			if (in_port_def != null && (in_port_def["type"] & MAGICK_DATATYPE_TRIGGER))
				count++
		if (count)
			trigger_branches[out_port_key] = count

	// fill ports and check is_ready() after each fill
	for (var/out_port_key as anything in edges)
		if (context.get(out_port_key) == null)
			continue

		var/list/connections = edges[out_port_key]
		var/remaining_successes = context.get_value(out_port_key)
		var/remaining_branches = trigger_branches[out_port_key] || length(connections)

		for (var/list/tuple as anything in connections)
			var/in_port_key = tuple[2]
			var/child_id = tuple[3]
			var/datum/rote_node/child = context.get_node(child_id)

			var/alist/child_inputs = child.inputs
			var/alist/in_port_def = child_inputs ? child_inputs[in_port_key] : null
			if (in_port_def == null)
				remaining_branches--
				continue

			if (in_port_def["type"] & MAGICK_DATATYPE_TRIGGER && remaining_branches > 0)
				var/successes_for_branch = max(1, round(remaining_successes / remaining_branches))
				context.current_node_id = child_id
				context.assign(in_port_key, successes_for_branch, MAGICK_DATATYPE_TRIGGER)
				remaining_branches--

				if (child.is_ready(context))
					var/before = context.successes
					child.__cast(context)
					var/after = context.successes
					var/consumed = before - after
					remaining_successes = max(0, remaining_successes - consumed)
				else
					remaining_successes = max(0, remaining_successes - successes_for_branch)
			else
				var/parent_value = context.get(out_port_key)
				context.current_node_id = child_id
				context.assign(in_port_key, parent_value)
				remaining_branches--

				if (child.is_ready(context))
					child.__cast(context)
			context.current_node_id = node_id

/datum/rote_node/proc/debug_to_user(datum/magick_context/context)
	PRIVATE_PROC(TRUE)
	to_chat(context.caster, span_info("DEBUG: --- [name] ([type]) ---"))
	to_chat(context.caster, span_info("DEBUG: Global successes: [context.successes]"))
	for (var/port_key as anything in inputs)
		var/datum/magick_value/port_val = context.get(port_key)
		var/alist/port_def = inputs[port_key]
		if (port_val != null)
			to_chat(context.caster, span_info("DEBUG:   input '[port_def["name"]]' = [port_val.value]"))
		else
			to_chat(context.caster, span_info("DEBUG:   input '[port_def["name"]]' = EMPTY"))
	for (var/port_key as anything in outputs)
		var/datum/magick_value/port_val = context.get(port_key)
		var/alist/port_def = outputs[port_key]
		if (port_val != null)
			to_chat(context.caster, span_info("DEBUG:   output '[port_def["name"]]' = [port_val.value]"))
		else
			to_chat(context.caster, span_info("DEBUG:   output '[port_def["name"]]' = EMPTY"))

// For UI
/proc/init_rotebuilder_static_data()
	var/list/data = list()
	var/list/nodes_list = list()

	for(var/node_path in GLOB.rote_nodes)
		var/datum/rote_node/node = GLOB.rote_nodes[node_path]
		if(!node)
			continue

		var/list/node_data = list(
			"name" = node.name,
			"desc" = node.desc,
			"type" = "[node.type]",
			"tags" = node.tags,
			"complexity" = node.complexity,
			"max_nodes" = node.max_nodes,
			"spheres" = node.spheres,
		)

		// Effect-specific fields, defaulted for non-effect nodes
		if(istype(node, /datum/rote_node/effect))
			var/datum/rote_node/effect/effect_node = node
			node_data["quintessence"] = effect_node.quintessence
			node_data["min_success_cost"] = effect_node.min_success_cost
			node_data["can_add_success"] = effect_node.can_add_success
		else
			node_data["quintessence"] = 0
			node_data["min_success_cost"] = 0
			node_data["can_add_success"] = FALSE

		var/list/inputs_list = list()
		var/list/outputs_list = list()

		for(var/port_key as anything in node.inputs)
			var/alist/def = node.inputs[port_key]
			var/list/port_data = list(
				"key" = port_key,
				"name" = def["name"],
				"type" = def["type"],
				"desc" = def["desc"],
				"default_value" = def["default_value"],
			)
			if (def["type"] & MAGICK_DATATYPE_NUMBER)
				if (def["min_clamp"] != null)
					port_data["min_clamp"] = def["min_clamp"]
				if (def["max_clamp"] != null)
					port_data["max_clamp"] = def["max_clamp"]
			else if (def["type"] & MAGICK_DATATYPE_STRING)
				if (def["whitelist"] != null)
					port_data["whitelist"] = def["whitelist"]
			UNTYPED_LIST_ADD(inputs_list, port_data)
		for(var/port_key as anything in node.outputs)
			var/alist/def = node.outputs[port_key]
			var/list/port_data = list(
				"key" = port_key,
				"name" = def["name"],
				"type" = def["type"],
				"desc" = def["desc"],
				"default_value" = def["default_value"],
			)
			UNTYPED_LIST_ADD(outputs_list, port_data)

		node_data["inputs"] = inputs_list
		node_data["outputs"] = outputs_list

		nodes_list += list(node_data)

	data["nodes"] = nodes_list
	return data
