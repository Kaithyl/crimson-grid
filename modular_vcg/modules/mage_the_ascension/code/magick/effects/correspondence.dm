/*
 * TODO: Increase successes required depending on distance or line of sight
 */

// Remote effect

/datum/magick_effect_data/remote_effect
	name = "Remote Effect"
	desc = "Convert a target into the remote origin for an effect."
	tags = MAGICK_TAG_UTILITY
	min_success_cost = 1
/datum/magick_effect/remote_effect
	data = /datum/magick_effect_data/remote_effect
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)

	var/in_target = "in_target"
	var/out_origin = "out_origin"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_target = MAGICK_PORT_TARGET,
	)
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_origin = alist("name" = "Origin", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/magick_effect/remote_effect/cast(datum/magick_context/context)
	var/datum/magick_value/target = context.get(src, in_target)
	if (!target)
		return
	target.type_flags |= MAGICK_DATATYPE_FLAG_ORIGIN
	context.assign(src, out_origin, target)

// Teleport (Self)

/datum/magick_effect_data/teleport_self
	name = "Teleport (Self)"
	desc = "Teleport the caster to the target's location."
	tags = MAGICK_TAG_UTILITY
	min_success_cost = 1
/datum/magick_effect/teleport_self
	data = /datum/magick_effect_data/teleport_self
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 3,
		),
	)

	var/in_target = "in_target"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_target = MAGICK_PORT_TARGET,
	)
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
	)

/datum/magick_effect/teleport_self/cast(datum/magick_context/context)
	var/target = context.get_value(src, in_target)
	if (!target)
		return

	var/mob/caster = context.caster
	caster.forceMove(get_turf(target))
