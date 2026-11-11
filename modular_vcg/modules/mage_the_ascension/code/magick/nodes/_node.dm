// This holds the actual code execution per node
/datum/rote_node/
	abstract_type = /datum/rote_node/

	var/name
	var/desc
	var/tags

	// Maximum number of this subtype of node allowed in a spell
	// Mostly to prevent lag for costly effects
	var/max_nodes

	// requires the caster to pick a target with a crosshair
	var/needs_crosshair = FALSE

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

	// alist<id_prefix = alist("min" = 1, "max" = MAGICK_MAX_LIST_SIZE, "default" = 1)>
	// Port key = id_prefix + index
	var/alist/extendable_ports

GLOBAL_LIST_INIT_TYPED(rote_nodes, /datum/rote_node, init_subtypes_w_path_keys(/datum/rote_node, list()))
GLOBAL_LIST_INIT(rotebuilder_static_data, init_rotebuilder_static_data())

// Whether this node can be cast without being activated by a parent node.
// Any changes to this should be reflected in
// RoteBuilder\lib\validator.ts\canCastUnprompted()
/datum/rote_node/proc/can_cast_unprompted(datum/rote_node_data/node_data)
	var/alist/input_defs = src.inputs
	for (var/port_key as anything in input_defs)
		var/alist/port_def = input_defs[port_key]
		if (port_def == null)
			continue
		// Optional port
		if (port_def["default_value"] == "")
			continue
		// Player inputted value from the rote builder
		if (node_data?.port_values?["port_[port_key]"] != null)
			continue
		return FALSE
	return TRUE

/datum/rote_node/proc/is_ready(datum/magick_context/context)
	var/alist/in_edges = context.reverse_graph ? context.reverse_graph[context.current_node_id] : null
	var/alist/input_defs = src.inputs
	for (var/port_key as anything in input_defs)
		if (context.get(port_key) != null)
			continue
		// if not optional or optional but has wire, wait for port to be filled
		if (in_edges?[port_key])
			return FALSE
	return TRUE

// For handling pre and post cast
/datum/rote_node/proc/__cast(datum/magick_context/context)
	SHOULD_NOT_OVERRIDE(TRUE)
	// Force stop spell if someone manages to pass the traversal limit
	if (++context.nodes_traversed > ROTE_MAX_TRAVERSAL)
		return

	// Prevent large spell graphs from monopolizing server execution
	if (context.nodes_traversed % ROTE_SLEEP_INTERVAL == 0)
		sleep(0)

	// Effects that require successes are skipped before the arete roll
	if (!context.arete_locked_in && istype(src, /datum/rote_node/effect))
		var/datum/rote_node/effect/effect_node = src
		if (effect_node.min_success_cost > 0)
			return

	if (!(context.arete_locked_in && (tags & MAGICK_TAG_FOCI)))
		// increase the complexity cap once per foci type
		if ((tags & MAGICK_TAG_FOCI) && !ROTE_NODE_TYPE_VISITED(context, type))
			var/datum/rote_node/focus/focus_node = src
			context.complexity_cap += focus_node.complexity_cap

		// count complexity for each node on first traversal
		if (!ROTE_NODE_VISITED(context, context.current_node_id))
			if (context.complexity > context.complexity_cap && complexity > 0)
				context.aborted = TRUE
				return
			context.complexity += complexity

		pre_cast(context)
		context.visited_nodes |= context.current_node_id
		context.visited_node_types |= type
		if (context.aborted || context.interrupted)
			return
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
/datum/rote_node/proc/post_cast(datum/magick_context/context, auto_traverse = TRUE)
	PROTECTED_PROC(TRUE)
	var/node_id = context.current_node_id
	var/alist/edges = context.effect_graph[node_id]
	if (edges == null)
		return

	var/datum/rote_node/current = context.get_node()
	var/has_trigger_out = FALSE
	for (var/port_key as anything in current?.outputs)
		var/alist/trigger_port_def = current.outputs[port_key]
		if (trigger_port_def != null && (trigger_port_def["type"] & MAGICK_DATATYPE_TRIGGER))
			has_trigger_out = TRUE
			break

	// Activate children by default
	if (auto_traverse && has_trigger_out && edges[out_act] && current?.inputs?[in_act] && context.get(out_act) == null)
		var/incoming = context.get_value(in_act)
		if (incoming != null)
			context.assign(out_act, incoming, MAGICK_DATATYPE_TRIGGER)

	var/alist/trigger_branches = new()
	if (has_trigger_out)
		for (var/out_port_key as anything in edges)
			if (context.get(out_port_key) == null)
				continue
			// Only trigger actual output ports
			var/alist/out_port_def = current.outputs[out_port_key]
			if (out_port_def == null || !(out_port_def["type"] & MAGICK_DATATYPE_TRIGGER))
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
			"extendable_ports" = node.extendable_ports,
		)

		// Effect nodes
		if(istype(node, /datum/rote_node/effect))
			var/datum/rote_node/effect/effect_node = node
			node_data["quintessence"] = effect_node.quintessence
			node_data["min_success_cost"] = effect_node.min_success_cost
			node_data["can_add_success"] = effect_node.can_add_success
		else
			node_data["quintessence"] = 0
			node_data["min_success_cost"] = 0
			node_data["can_add_success"] = FALSE

		if(istype(node, /datum/rote_node/focus))
			var/datum/rote_node/focus/focus_node = node
			node_data["complexity_cap"] = focus_node.complexity_cap
		else
			node_data["complexity_cap"] = 0

		var/list/inputs_list = list()
		var/list/outputs_list = list()

		// Ports
		for(var/port_id as anything in node.inputs)
			var/alist/def = node.inputs[port_id]
			var/list/port_data = list(
				"id" = port_id,
				"name" = def["name"],
				"type" = def["type"],
				"desc" = def["desc"],
				"default_value" = def["default_value"],
				"promise" = def["promise"],
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
		for(var/port_id as anything in node.outputs)
			var/alist/def = node.outputs[port_id]
			var/list/port_data = list(
				"id" = port_id,
				"name" = def["name"],
				"type" = def["type"],
				"desc" = def["desc"],
			)
			UNTYPED_LIST_ADD(outputs_list, port_data)

		node_data["inputs"] = inputs_list
		node_data["outputs"] = outputs_list

		nodes_list += list(node_data)

	data["nodes"] = nodes_list
	return data
