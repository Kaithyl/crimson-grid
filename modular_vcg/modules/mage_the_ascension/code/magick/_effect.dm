// This is a workaround method to have abstract static variables
// DO NOT INSTANTIATE THIS
/datum/magick_effect_data/
	abstract_type = /datum/magick_effect_data/

	var/name
	var/desc
	var/tags

	// Cost to cast effect
	var/quintessence = 0

	// Minimum successes required for this spell to have an effect
	var/min_success_cost = 0

	// If the spell's effect can be enhanced by adding multiple successes
	var/can_add_success = FALSE

	// How much complexity this focus takes up
	var/complexity = 1

	// Maximum number of this subtype of node allowed in a spell
	// Mostly to prevent lag for costly effects
	var/max_nodes

// This holds the actual code execution for effects
/datum/magick_effect/
	abstract_type = /datum/magick_effect/

	// Static data
	var/datum/magick_effect_data/data

	/*
	 * I absolutely hate this language, I had a perfect workaround for making pseudo abstract static
	 * variables by using initial() to pull vars from magick_effect_data until it turns out that
	 * lists are not set during compile so this always returns empty list!!!!
	 */

	// Available sphere combinations for this effect
	var/list/spheres

	// Port system for nodes
	var/in_act = "in_act"
	var/out_act = "out_act"

	// alist<port_key, alist("name" = ..., "type" = ..., ...)>
	var/alist/inputs
	var/alist/outputs

	/*
	 * These are userdata that are manually set by the player
	 */

	// Name given to effect node
	var/label
	// Success settings are only visible if can_add_success is true
	// What percentage of global success to allocate
	var/success_percentage
	// Success die clamps
	var/min_success
	var/max_success

	// alist<"port_[port_key]", value>
	var/alist/port_values

/datum/magick_effect/proc/is_ready(datum/magick_context/context)
	var/alist/input_defs = src.inputs
	for (var/port_key as anything in input_defs)
		if (context.get(src, port_key) == null)
			// Check if this port has an incoming connection in the effect graph
			var/has_connection = FALSE
			for (var/datum/magick_effect/source as anything in context.effect_graph)
				var/alist/out_edges = context.effect_graph[source]
				for (var/out_port_key as anything in out_edges)
					for (var/list/tuple as anything in out_edges[out_port_key])
						if (tuple[3] == src && tuple[2] == port_key)
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
/datum/magick_effect/proc/__cast(datum/magick_context/context)
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
/datum/magick_effect/proc/cast(datum/magick_context/context)
	PROTECTED_PROC(TRUE)
	return

// Only override for custom handling of checking coincidental casting
/datum/magick_effect/proc/pre_cast(datum/magick_context/context)
	PROTECTED_PROC(TRUE)
	return

// Only override for custom handling of child nodes.
// Uses the effect graph dictionary on the context set by the rote.
/datum/magick_effect/proc/post_cast(datum/magick_context/context)
	PROTECTED_PROC(TRUE)
	var/alist/edges = context.effect_graph[src]
	if (edges == null)
		return

	// count trigger branches per output port for success splitting
	var/alist/trigger_branches = new()
	for (var/out_port_key as anything in edges)
		if (context.get(src, out_port_key) == null)
			continue
		var/count = 0
		for (var/list/tuple as anything in edges[out_port_key])
			var/in_port_key = tuple[2]
			var/datum/magick_effect/child = tuple[3]
			var/alist/child_inputs = child.inputs
			var/alist/in_port_def = child_inputs ? child_inputs[in_port_key] : null
			if (in_port_def != null && (in_port_def["type"] & MAGICK_DATATYPE_TRIGGER))
				count++
		if (count)
			trigger_branches[out_port_key] = count

	// fill ports and check is_ready() after each fill
	for (var/out_port_key as anything in edges)
		if (context.get(src, out_port_key) == null)
			continue

		var/list/connections = edges[out_port_key]
		var/remaining_successes = context.get_value(src, out_port_key)
		var/remaining_branches = trigger_branches[out_port_key] || length(connections)

		for (var/list/tuple as anything in connections)
			var/in_port_key = tuple[2]
			var/datum/magick_effect/child = tuple[3]

			var/alist/child_inputs = child.inputs
			var/alist/in_port_def = child_inputs ? child_inputs[in_port_key] : null
			if (in_port_def == null)
				remaining_branches--
				continue

			if (in_port_def["type"] & MAGICK_DATATYPE_TRIGGER && remaining_branches > 0)
				var/successes_for_branch = max(1, round(remaining_successes / remaining_branches))
				context.assign(child, in_port_key, successes_for_branch, MAGICK_DATATYPE_TRIGGER)
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
				context.assign(child, in_port_key, context.get(src, out_port_key))
				remaining_branches--

				if (child.is_ready(context))
					child.__cast(context)

/datum/magick_effect/proc/debug_to_user(datum/magick_context/context)
	PRIVATE_PROC(TRUE)
	to_chat(context.caster, span_info("DEBUG: --- [data::name] ([type]) ---"))
	to_chat(context.caster, span_info("DEBUG: Global successes: [context.successes]"))
	for (var/port_key as anything in inputs)
		var/datum/magick_value/port_val = context.get(src, port_key)
		var/alist/port_def = inputs[port_key]
		if (port_val != null)
			to_chat(context.caster, span_info("DEBUG:   input '[port_def["name"]]' = [port_val.value]"))
		else
			to_chat(context.caster, span_info("DEBUG:   input '[port_def["name"]]' = EMPTY"))
	for (var/port_key as anything in outputs)
		var/datum/magick_value/port_val = context.get(src, port_key)
		var/alist/port_def = outputs[port_key]
		if (port_val != null)
			to_chat(context.caster, span_info("DEBUG:   output '[port_def["name"]]' = [port_val.value]"))
		else
			to_chat(context.caster, span_info("DEBUG:   output '[port_def["name"]]' = EMPTY"))

/proc/init_magick_effect_static_data()
	var/list/data = list()
	var/list/effects_list = list()

	for(var/datum/magick_effect/effect_type as anything in subtypesof(/datum/magick_effect/))

		if (effect_type == effect_type::abstract_type)
			continue

		var/datum/magick_effect_data/effect = effect_type::data
		if (effect == null)
			continue

		// Have to instantiate because getting initial var doesn't work on lists
		var/datum/magick_effect/temp = new effect_type()

		var/list/effect_data = list(
			"name" = effect.name,
			"desc" = effect.desc,
			"type" = "[effect_type]",
			"tags" = effect.tags,
			"quintessence" = effect.quintessence,
			"complexity" = effect.complexity,
			"max_nodes" = effect.max_nodes,
			"min_success_cost" = effect.min_success_cost,
			"spheres" = temp.spheres,
			"can_add_success" = effect.can_add_success,
		)

		var/list/inputs_list = list()
		var/list/outputs_list = list()

		for(var/port_key as anything in temp.inputs)
			var/alist/def = temp.inputs[port_key]
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
		for(var/port_key as anything in temp.outputs)
			var/alist/def = temp.outputs[port_key]
			var/list/port_data = list(
				"key" = port_key,
				"name" = def["name"],
				"type" = def["type"],
				"desc" = def["desc"],
				"default_value" = def["default_value"],
			)
			UNTYPED_LIST_ADD(outputs_list, port_data)

		qdel(temp)

		effect_data["inputs"] = inputs_list
		effect_data["outputs"] = outputs_list

		effects_list += list(effect_data)

	data["effects"] = effects_list
	return data
