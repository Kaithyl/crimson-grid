/datum/rote_node/effect/iterate_list
	name = "Iterate (List)"
	desc = "Perform a for each loop over a list of targets."
	tags = MAGICK_TAG_DATA
	max_nodes = 1

	var/in_targets = "in_targets"
	var/out_target = "out_target"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_targets = MAGICK_PORT_TARGETS,
	)
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = MAGICK_PORT_TARGET,
	)

/datum/rote_node/effect/iterate_list/post_cast(datum/magick_context/context, auto_traverse = TRUE)
	var/list/targets = context.get_value(in_targets)
	if (!length(targets))
		return
	if (context.effect_graph[context.current_node_id] == null)
		return

	// split successes across each execution branch
	var/remaining_successes = context.get_value(in_act) || 0
	var/remaining_targets = min(length(targets), MAGICK_FOR_LOOP_MAX_LIST)

	var/targets_processed = 0
	for (var/datum/magick_value/target as anything in targets)
		if (targets_processed >= MAGICK_FOR_LOOP_MAX_LIST)
			break
		if (context.nodes_traversed > MAGICK_MAX_TRAVERSAL)
			break

		var/successes_for_target = max(1, round(remaining_successes / max(1, remaining_targets)))

		context.push_scope()
		context.assign(out_target, target)
		context.assign(out_act, successes_for_target, MAGICK_DATATYPE_TRIGGER)

		var/before = context.successes
		..(context, FALSE)
		var/consumed = before - context.successes

		context.pop_scope()

		remaining_successes = max(0, remaining_successes - max(consumed, 0))
		targets_processed++
		remaining_targets--
