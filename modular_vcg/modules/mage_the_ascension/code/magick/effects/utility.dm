// For each

/datum/magick_effect/iterate_list
	name = "Iterate (List)"
	tags = MAGICK_TAG_DATA
	max_nodes = 1

	in_act = MAGICK_PORT_ACTIVATE
	out_act = MAGICK_PORT_ACTIVATE

	var/datum/magick_port/input/in_targets = MAGICK_PORT_TARGETS
	var/datum/magick_port/output/out_target = MAGICK_PORT_TARGET

/datum/magick_effect/iterate_list/post_cast(datum/magick_context/context)
	var/list/datum/magick_value/targets = context.get(in_targets)
	if (!length(targets))
		return

	var/children_processed = 0
	for (var/datum/magick_port/output/out_port as anything in edges)
		if (children_processed >= MAGICK_FOR_LOOP_MAX_BRANCHES)
			break

		if (context.get(out_port) == null)
			continue

		var/list/connections = edges[out_port]
		var/child_count = length(connections)
		var/successes_per_child = 0
		if (out_port.type_flags & MAGICK_DATATYPE_TRIGGER && child_count > 0)
			successes_per_child = max(1, round(context.get_value(out_port) / child_count))

		for (var/list/tuple in connections)
			var/datum/magick_port/in_port = tuple[1]
			var/datum/magick_effect/child = tuple[2]

			// Handle recursive casting for activate connections
			var/targets_processed = 0
			for (var/datum/magick_value/target in targets)
				if (targets_processed >= MAGICK_FOR_LOOP_MAX_LIST)
					break

				if (in_port.type_flags & MAGICK_DATATYPE_TRIGGER)
					context.assign(in_port, successes_per_child, MAGICK_DATATYPE_TRIGGER)
				else
					context.assign(in_port, target)
				if (child.is_ready(context))
					child.__cast(context)
				targets_processed++
		children_processed++

// Target mobs

/datum/magick_effect/target_mobs
	name = "AOE Target (Mobs)"
	desc = "Get all mobs within a maximum radius of X tiles from the target."
	tags = MAGICK_TAG_DATA
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)
	max_nodes = 1

	var/datum/magick_port/input/in_target = MAGICK_PORT_TARGET
	var/datum/magick_port/input/in_radius = MAGICK_PORT_NUMBER_clamp_("Radius", 1, MAGICK_LINE_OF_SIGHT_DISTANCE, 5)
	var/datum/magick_port/output/out_targets = new("Targets (Mob)", MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST)

/datum/magick_effect/target_mobs/New()
	..()
	desc = "Get all mobs within a maximum radius of [MAGICK_LINE_OF_SIGHT_DISTANCE] tiles from the target."

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

