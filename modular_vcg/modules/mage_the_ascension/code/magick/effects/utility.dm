// For each

/datum/magick_effect_data/iterate_list
	name = "Iterate (List)"
	desc = "Iterate over a list of targets, casting child nodes for each one."
	tags = MAGICK_TAG_DATA
	max_nodes = 1
/datum/magick_effect/iterate_list
	data = /datum/magick_effect_data/iterate_list

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

/datum/magick_effect/iterate_list/post_cast(datum/magick_context/context)
	var/list/datum/magick_value/targets = context.get(src, in_targets)
	if (!length(targets))
		return

	var/alist/effect_edges = context.effect_graph[src]
	if (effect_edges == null)
		return

	var/children_processed = 0
	for (var/out_port_key as anything in effect_edges)
		if (children_processed >= MAGICK_FOR_LOOP_MAX_BRANCHES)
			break

		if (context.get(src, out_port_key) == null)
			continue

		var/list/connections = effect_edges[out_port_key]
		var/remaining_successes = context.get_value(src, out_port_key)
		var/remaining_targets = length(targets)

		for (var/list/tuple as anything in connections)
			var/in_port_key = tuple[2]
			var/datum/magick_effect/child = tuple[3]

			var/alist/child_inputs = child.inputs
			var/alist/in_port_def = child_inputs ? child_inputs[in_port_key] : null
			if (in_port_def == null)
				continue

			// Handle recursive casting for activate connections
			var/targets_processed = 0
			for (var/datum/magick_value/target in targets)
				if (targets_processed >= MAGICK_FOR_LOOP_MAX_LIST)
					break

				var/successes_for_target = 0
				if (in_port_def["type"] & MAGICK_DATATYPE_TRIGGER && remaining_targets > 0)
					successes_for_target = max(1, round(remaining_successes / remaining_targets))
					context.assign(child, in_port_key, successes_for_target, MAGICK_DATATYPE_TRIGGER)
				else
					context.assign(child, in_port_key, target)

				if (child.is_ready(context))
					// Track how many successes the branch consumed so leftovers
					// can be redistributed to remaining targets
					var/before = context.successes
					child.__cast(context)
					var/after = context.successes
					var/consumed = before - after
					remaining_successes = max(0, remaining_successes - consumed)
				else
					remaining_successes = max(0, remaining_successes - successes_for_target)

				targets_processed++
				remaining_targets--
		children_processed++

// Target mobs

/datum/magick_effect_data/target_mobs
	name = "AOE Target (Mobs)"
	desc = "Get all mobs within a maximum radius of 7 tiles from the target."
	tags = MAGICK_TAG_DATA
	max_nodes = 1
/datum/magick_effect/target_mobs
	data = /datum/magick_effect_data/target_mobs
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
	var/radius = context.get_value(src, in_radius)
	var/target = context.get_value(src, in_target)

	if (!target)
		context.assign(src, out_targets, list(), MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST)
		return

	var/list/targets = list()
	for (var/mob/living/living_mob in range(radius, target))
		targets += new /datum/magick_value(living_mob)

	context.assign(src, out_targets, targets, MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST)

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
