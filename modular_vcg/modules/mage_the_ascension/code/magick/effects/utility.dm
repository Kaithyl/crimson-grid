/datum/magick_effect/activatable
	var/datum/magick_port/input/in_act = MAGICK_PORT_ACTIVATE
	var/datum/magick_port/output/out_act = MAGICK_PORT_ACTIVATE

// Count
/*/datum/magick_effect/count
	name = "Count"
	tags = MAGICK_TAG_DATA
	complexity = 0

	var/datum/magick_port/input/in_list = MAGICK_PORT_TARGETS
	var/datum/magick_port/output/out_num = MAGICK_PORT_NUMBER

/datum/magick_effect/count/cast(datum/magick_context/context)
	var/list/targets = in_list.get_value(context)
	out_num.assign(context, length(targets))*/

// Add

/datum/magick_effect/add
	name = "Add"
	tags = MAGICK_TAG_DATA
	complexity = 0

	var/datum/magick_port/input/in_a = MAGICK_PORT_NUMBER
	var/datum/magick_port/input/in_b = MAGICK_PORT_NUMBER
	var/datum/magick_port/output/out_sum = MAGICK_PORT_NUMBER

/datum/magick_effect/add/cast(datum/magick_context/context)
	var/a = context.get(in_a)
	var/b = context.get(in_b)
	context.assign(out_sum, a + b, MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE)

// For each

/datum/magick_effect/activatable/for_each
	name = "For Each"
	tags = MAGICK_TAG_DATA
	complexity = 0
	max_nodes = 1

	var/datum/magick_port/input/in_targets = MAGICK_PORT_TARGETS
	var/datum/magick_port/output/out_target = MAGICK_PORT_TARGET

/datum/magick_effect/activatable/for_each/post_cast(datum/magick_context/context)
	var/list/datum/magick_value/targets = context.get(in_targets)
	if (!length(targets))
		return

	for (var/datum/magick_port/output/out_port as anything in edges)
		if (context.get(out_port) == null)
			continue

		var/list/connections = edges[out_port]
		for (var/list/tuple in connections)
			var/datum/magick_port/in_port = tuple[1]
			var/datum/magick_effect/child = tuple[2]

			// Handle recursive casting for activate connections
			for (var/datum/magick_value/target in targets)
				if (in_port.type_flags & MAGICK_DATATYPE_TRIGGER)
					context.assign(in_port, /datum/magick_value/trigger::get_singleton())
				else
					context.assign(in_port, target)
				if (child.is_ready(context))
					child.__cast(context)
