/datum/magick_effect/
	abstract_type = /datum/magick_effect/

	// alist<string, list<Node, string>>
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

	// Available sphere combinations for this effect
	var/list/spheres

	// Blackboard access is alist<Node, alist<string, var>>
	var/alist/inputs = alist("Max Success" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)
	var/alist/outputs

/datum/magick_effect/proc/is_ready(blackboard)
	var/alist/input = blackboard[src]
	return (length(input) == length(inputs))

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

	for (var/output_name as anything in edges)
		var/list/tuple = edges[output_name]
		var/input_name = tuple[1]
		var/datum/magick_effect/child = tuple[2]

		var/alist/child_inputs = blackboard[child]
		if (!child_inputs)
			child_inputs = blackboard[child] = alist()

		if (output[output_name])
			child_inputs[input_name] = output[output_name]
			if (child.is_ready(blackboard))
				child.cast(context)
