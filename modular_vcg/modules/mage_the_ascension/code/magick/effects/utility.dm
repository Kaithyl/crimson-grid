/datum/magick_effect/count
	name = "Count"
	tags = MAGICK_TAG_DATA
	inputs = alist("Targets" = MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ANY)
	outputs = alist("Number" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)

/datum/magick_effect/count/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	return length(input_values["Targets"])

/datum/magick_effect/add
	name = "Add"
	tags = MAGICK_TAG_DATA
	inputs = alist(
		"Number 1" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE,
		"Number 2" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE
	)
	outputs = alist("Number" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)

/datum/magick_effect/add/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	return alist("Number" = input_values["Number 1"] + input_values["Number 2"])

/datum/magick_effect/for_each
	name = "For Each"
	tags = MAGICK_TAG_DATA
	inputs = alist("Targets" = MAGICK_DATA_ANY | MAGICK_DATA_COUNT_LIST)
	outputs = alist("Target" = MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ONE)

/datum/magick_effect/for_each/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/list/targets = input_values["Targets"]
	if (!length(targets))
		return null
	return alist("Target" = targets[1])

/datum/magick_effect/for_each/post_cast(datum/magick_context/context, output)
	var/blackboard = context.blackboard
	var/alist/input_values = blackboard[src]
	var/list/targets = input_values["Targets"]

	if (!length(targets))
		return

	for (var/output_name as anything in edges)
		var/list/tuple = edges[output_name]
		var/input_name = tuple[1]
		var/datum/magick_effect/child = tuple[2]

		for (var/target in targets)
			var/alist/child_inputs = blackboard[child]
			if (!child_inputs)
				child_inputs = blackboard[child] = alist()
			child_inputs[input_name] = target
			if (child.is_ready(blackboard))
				child.cast(context)
