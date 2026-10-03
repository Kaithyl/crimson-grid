/datum/magick_effect/count
	name = "Count"
	tags = MAGICK_TAG_DATA
	complexity = 0
	inputs = list(
		MAGICK_PORT_TARGET_S,
	)
	outputs = list(
		MAGICK_PORT_NUMBER,
	)

/datum/magick_effect/count/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	return alist(1 = length(input_values[1]))

/datum/magick_effect/add
	name = "Add"
	tags = MAGICK_TAG_DATA
	complexity = 0
	inputs = list(
		MAGICK_PORT_NUMBER,
		MAGICK_PORT_NUMBER,
	)
	outputs = list(
		MAGICK_PORT_NUMBER,
	)

/datum/magick_effect/add/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	return alist(1 = input_values[1] + input_values[2])

/datum/magick_effect/for_each
	name = "For Each"
	tags = MAGICK_TAG_DATA
	complexity = 0
	max_nodes = 1
	inputs = list(
		MAGICK_PORT_ACTIVATE,
		MAGICK_PORT_TARGET_S,
	)
	outputs = list(
		MAGICK_PORT_ACTIVATE,
		MAGICK_PORT_TARGET,
	)

/datum/magick_effect/for_each/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/list/targets = input_values[2]
	if (!length(targets))
		return null
	return alist(2 = targets[1])

/datum/magick_effect/for_each/post_cast(datum/magick_context/context, output)
	var/blackboard = context.blackboard
	var/alist/input_values = blackboard[src]
	var/list/targets = input_values[2]

	if (!output || !length(targets))
		return

	for (var/output_id as anything in edges)
		var/list/tuple = edges[output_id]
		var/input_id = tuple[1]
		var/datum/magick_effect/child = tuple[2]

		for (var/target in targets)
			var/alist/child_inputs = blackboard[child]
			if (!child_inputs)
				child_inputs = blackboard[child] = alist()
			// IMPORTANT!!!! Activate connections
			var/datum/magick_port/in_port = child.inputs[input_id]
			if (in_port.type_flags & MAGICK_DATA_TRIGGER)
				child_inputs[input_id] = TRUE
			else
				child_inputs[input_id] = target
			if (child.is_ready(blackboard))
				child.cast(context)
