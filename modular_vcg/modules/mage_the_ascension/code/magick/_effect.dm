/datum/magick_effect/
	abstract_type = /datum/magick_effect/

	// alist<number, list<number, Node>>
	VAR_PROTECTED/alist/edges

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

	/*
	 * Treat all the vars below as if they are abstract static, since BYOND doesn't support it.
	 */

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

	// Available sphere combinations for this effect
	var/list/spheres

	// Define these if you want in and out activation ports
	var/datum/magick_port/input/in_act
	var/datum/magick_port/output/out_act

	var/list/inputs
	var/list/outputs

/datum/magick_effect/New(edges)
	src.edges = edges
	inputs = list()
	outputs = list()

	// If this is too suboptimal, switch to manually filling
	// inputs/outputs with created vars in subclass
	for(var/v_name in src.vars)
		var/v_value = src.vars[v_name]

		if(v_value && istype(v_value, /datum/magick_port/))
			var/datum/magick_port/port = v_value
			if (port.input)
				inputs += v_value
			else
				outputs += v_value

/datum/magick_effect/proc/is_ready(datum/magick_context/context)
	for (var/datum/magick_port/in_port as anything in inputs)
		if (context.get(in_port) == null)
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
	/*if (context.successes < success_cost)
		return
	context.successes -= success_cost
	if (in_act && out_act)
		context.assign(out_act, context.get_value(in_act) - success_cost, MAGICK_DATATYPE_TRIGGER)*/
	post_cast(context)

// Must override this for actually doing the effect
/datum/magick_effect/proc/cast(datum/magick_context/context)
	return

// Only override for custom handling of checking coincidental casting
/datum/magick_effect/proc/pre_cast(datum/magick_context/context)
	/*if (!context.paradox && looks_like)
		if ((context.explains & looks_like) != looks_like)
			context.paradox = TRUE*/

// Only override for custom handling of child nodes
/datum/magick_effect/proc/post_cast(datum/magick_context/context)
	for (var/datum/magick_port/output/out_port as anything in edges)
		if (context.get(out_port) == null)
			continue

		var/list/connections = edges[out_port]
		var/branch_count = length(connections)
		var/successes_per_branch = 0
		if (out_port.type_flags & MAGICK_DATATYPE_TRIGGER && branch_count > 0)
			successes_per_branch = max(1, round(context.get_value(out_port) / branch_count))

		for (var/list/tuple as anything in connections)
			var/datum/magick_port/in_port = tuple[1]
			var/datum/magick_effect/child = tuple[2]

			if (in_port.type_flags & MAGICK_DATATYPE_TRIGGER)
				context.assign(in_port, successes_per_branch, MAGICK_DATATYPE_TRIGGER)
			else
				context.assign(in_port, context.get(out_port))
			if (child.is_ready(context))
				child.__cast(context)

/proc/init_magick_effect_static_data()
	var/list/data = list()
	var/list/effects_list = list()

	for(var/effect_type as anything in subtypesof(/datum/magick_effect/))

		var/datum/magick_effect/effect = new effect_type(null)

		if (effect_type == effect.abstract_type)
			qdel(effect)
			continue

		var/list/effect_data = list(
			"name" = effect.name,
			"desc" = effect.desc,
			"type" = "[effect_type]",
			"tags" = effect.tags,
			"quintessence" = effect.quintessence,
			"complexity" = effect.complexity,
			"spheres" = effect.spheres,
			"can_add_success" = effect.can_add_success,
		)

		var/list/inputs_list = list()
		var/list/outputs_list = list()

		for(var/datum/magick_port/port as anything in effect.inputs)
			var/list/port_data = list(
				"name" = port.name,
				"type" = port.type_flags,
				"desc" = port.desc,
				"default_value" = port.default_value,
			)
			if (port.type_flags & MAGICK_DATATYPE_NUMBER)
				if (port.min_clamp != null)
					port_data["min_clamp"] = port.min_clamp
				if (port.max_clamp != null)
					port_data["max_clamp"] = port.max_clamp
			else if (port.type_flags & MAGICK_DATATYPE_STRING)
				if (port.whitelist != null)
					port_data["whitelist"] = port.whitelist
			UNTYPED_LIST_ADD(inputs_list, port_data)

		for(var/datum/magick_port/port as anything in effect.outputs)
			UNTYPED_LIST_ADD(outputs_list, list(
				"name" = port.name,
				"type" = port.type_flags,
				"desc" = port.desc,
				"default_value" = port.default_value,
			))

		effect_data["inputs"] = inputs_list
		effect_data["outputs"] = outputs_list

		effects_list += list(effect_data)
		qdel(effect)

	data["effects"] = effects_list
	return data
