// Target mobs

/datum/rote_node/effect/target_mobs
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

/datum/rote_node/effect/target_mobs/cast(datum/magick_context/context)
	var/radius = context.get_value(in_radius)
	var/target = context.get_value(in_target)

	if (!target)
		context.assign(out_targets, list(), MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST)
		return

	var/list/targets = list()
	for (var/mob/living/living_mob in range(radius, target))
		targets += new /datum/magick_value(living_mob)

	context.assign(out_targets, targets, MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_LIST)

// Equals

/datum/rote_node/effect/equals
	name = "Equals"
	desc = "Check if two inputs are the same value."
	tags = MAGICK_TAG_DATA

	var/in_value_a = "in_value_a"
	var/in_value_b = "in_value_b"

	var/out_act_true = "out_act_true"
	var/out_act_false = "out_act_false"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_value_a = alist("name" = "Value", "type" = MAGICK_DATATYPE_ANY),
		in_value_b = alist("name" = "Value", "type" = MAGICK_DATATYPE_ANY),
	)
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE, // This will always trigger regardless if function is true or false
		out_act_true = alist("name" = "True", "type" = MAGICK_DATATYPE_TRIGGER),
		out_act_false = alist("name" = "False", "type" = MAGICK_DATATYPE_TRIGGER),
	)

/datum/rote_node/effect/equals/cast(datum/magick_context/context)
	var/value_a = context.get_value(in_value_a)
	var/value_b = context.get_value(in_value_b)

	var/matched = (value_a == value_b)
	var/successes = context.get_value(in_act) || 0

	context.assign(matched ? out_act_true : out_act_false, successes, MAGICK_DATATYPE_TRIGGER)

// Count

/*/datum/rote_node/effect/count
	name = "Count"
	tags = MAGICK_TAG_DATA

	var/datum/magick_port/input/in_list = MAGICK_PORT_TARGETS
	var/datum/magick_port/output/out_num = MAGICK_PORT_NUMBER

/datum/rote_node/effect/count/cast(datum/magick_context/context)
	var/list/targets = in_list.get_value(context)
	out_num.assign(context, length(targets))*/

// Add

/*/datum/rote_node/effect/add
	name = "Add"
	tags = MAGICK_TAG_DATA

	var/datum/magick_port/input/in_a = MAGICK_PORT_NUMBER
	var/datum/magick_port/input/in_b = MAGICK_PORT_NUMBER
	var/datum/magick_port/output/out_sum = MAGICK_PORT_NUMBER

/datum/rote_node/effect/add/cast(datum/magick_context/context)
	var/a = context.get(in_a)
	var/b = context.get(in_b)
	context.assign(out_sum, a + b, MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE)*/
