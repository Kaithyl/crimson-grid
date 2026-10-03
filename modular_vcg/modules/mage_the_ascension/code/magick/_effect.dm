/datum/magick_effect/
	abstract_type = /datum/magick_effect/

	// alist<number, list<number, Node>>
	var/alist/edges

	/*
	 * Treat all the vars below as if they are static abstract, since BYOND doesn't support it.
	 */

	var/name
	var/desc

	// For easy searching in UI
	var/tags

	// Requirements to disguise this effect as coincidental
	var/looks_like

	// If this effect may contribute coincidental requirements for future effects
	var/explains

	// Cost to cast effect
	var/quintessence = 0

	// Minimum successes required for this effect
	var/min_successes = 1

	// How much complexity this focus takes up
	var/complexity = 1

	// Maximum number of this node allowed in a spell
	// TODO: Set max executions and prevent loops
	var/max_nodes

	// Available sphere combinations for this effect
	var/list/spheres

	// Blackboard access is alist<Node, alist<number, var>>
	// Port index is the blackboard key
	var/list/datum/magick_port/inputs
	var/list/datum/magick_port/outputs

/datum/magick_port/
	var/name
	var/type_flags

/datum/magick_port/New(name, type_flags)
	src.name = name
	src.type_flags = type_flags

/datum/magick_effect/proc/is_ready(blackboard)
	var/alist/input = blackboard[src]
	if (length(input) != length(inputs))
		return FALSE
	return TRUE

// For handling pre and post cast
// Try to override _cast instead of this
/datum/magick_effect/proc/cast(datum/magick_context/context)
	pre_cast(context)
	context.explains |= explains
	var/output = _cast(context)
	post_cast(context, output)

// Must override this for actually doing the effect
/datum/magick_effect/proc/_cast(datum/magick_context/context)
	return alist()

// Only override for custom handling of checking coincidental casting
/datum/magick_effect/proc/pre_cast(datum/magick_context/context)
	if (!context.paradox && looks_like)
		if ((context.explains & looks_like) != looks_like)
			context.paradox = TRUE

// Only override for custom handling of child nodes
/datum/magick_effect/proc/post_cast(datum/magick_context/context, output)
	var/blackboard = context.blackboard

	if (!output)
		return

	for (var/output_id as anything in edges)
		var/list/tuple = edges[output_id]
		var/input_id = tuple[1]
		var/datum/magick_effect/child = tuple[2]

		var/alist/child_inputs = blackboard[child]
		if (!child_inputs)
			child_inputs = blackboard[child] = alist()

		if (output[output_id])
			// IMPORTANT!!!! Activate connections
			var/datum/magick_port/in_port = child.inputs[input_id]
			if (in_port.type_flags & MAGICK_DATA_TRIGGER)
				child_inputs[input_id] = TRUE
			else
				child_inputs[input_id] = output[output_id]
			if (child.is_ready(blackboard))
				child.cast(context)

/proc/init_magick_effect_static_data()
	var/list/data = list()
	var/list/effects_list = list()

	for(var/effect_type as anything in subtypesof(/datum/magick_effect/))
		var/datum/magick_effect/effect = new effect_type()

		var/list/effect_data = list(
			"name" = effect.name,
			"desc" = effect.desc,
			"type" = "[effect_type]",
			"tags" = effect.tags,
			"looks_like" = effect.looks_like,
			"explains" = effect.explains,
			"quintessence" = effect.quintessence,
			"min_successes" = effect.min_successes,
			"complexity" = effect.complexity,
			"spheres" = effect.spheres,
		)

		var/list/inputs_list = list()
		for(var/datum/magick_port/port as anything in effect.inputs)
			UNTYPED_LIST_ADD(inputs_list, list(
				"name" = port.name,
				"type" = port.type_flags,
			))
		effect_data["inputs"] = inputs_list

		var/list/outputs_list = list()
		for(var/datum/magick_port/port as anything in effect.outputs)
			UNTYPED_LIST_ADD(outputs_list, list(
				"name" = port.name,
				"type" = port.type_flags,
			))
		effect_data["outputs"] = outputs_list

		effects_list += list(effect_data)
		qdel(effect)

	data["effects"] = effects_list
	return data
