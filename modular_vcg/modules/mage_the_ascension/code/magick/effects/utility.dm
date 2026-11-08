// For each

/datum/magick_effect/iterate_list
	name = "Iterate (List)"
	desc = "Iterate over a list of targets."
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

/datum/magick_effect/iterate_list/post_cast(datum/magick_context/context, auto_activate = TRUE)
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

// Target mobs

/datum/magick_effect/target_mobs
	name = "AOE Target (Mobs)"
	desc = "Get all mobs within a maximum radius of 7 tiles from the target."
	tags = MAGICK_TAG_DATA
	max_nodes = 1
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)

	var/in_radius = "in_radius"
	var/in_target = "in_target"
	var/out_targets = "out_targets"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_radius = MAGICK_PORT_NUMBER_clamp_("Radius", 1, MAGICK_LINE_OF_SIGHT_DISTANCE, 5),
		in_target = MAGICK_PORT_TARGET,
	)
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_targets = alist("name" = "Targets (Mob)", "type" = MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST),
	)

/datum/magick_effect/target_mobs/cast(datum/magick_context/context)
	var/radius = context.get_value(in_radius)
	var/target = context.get_value(in_target)

	if (!target)
		context.assign(out_targets, list(), MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST)
		return

	var/list/targets = list()
	for (var/mob/living/living_mob in range(radius, target))
		targets += new /datum/magick_value(living_mob)

	context.assign(out_targets, targets, MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST)

// Count

/*/datum/magick_effect/count
	name = "Count"
	tags = MAGICK_TAG_DATA

	var/datum/magick_port/input/in_list = MAGICK_PORT_TARGETS
	var/datum/magick_port/output/out_num = MAGICK_PORT_NUMBER

/datum/magick_effect/count/cast(datum/magick_context/context)
	var/list/targets = in_list.get_value(context)
	out_num.assign(context, length(targets))*/

// Add

/*/datum/magick_effect/add
	name = "Add"
	tags = MAGICK_TAG_DATA

	var/datum/magick_port/input/in_a = MAGICK_PORT_NUMBER
	var/datum/magick_port/input/in_b = MAGICK_PORT_NUMBER
	var/datum/magick_port/output/out_sum = MAGICK_PORT_NUMBER

/datum/magick_effect/add/cast(datum/magick_context/context)
	var/a = context.get(in_a)
	var/b = context.get(in_b)
	context.assign(out_sum, a + b, MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE)*/
