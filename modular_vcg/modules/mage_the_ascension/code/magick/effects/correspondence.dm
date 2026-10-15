/datum/magick_effect/correspondence/
	abstract_type = /datum/magick_effect/correspondence/
	min_success_cost = 1
	in_act = MAGICK_PORT_ACTIVATE
	out_act = MAGICK_PORT_ACTIVATE

/*/datum/magick_effect/correspondence/pre_cast(datum/magick_context/context)
	..(context)
	// Increase successes required depending on distance or line of sight
*/

// Remote effect

/datum/magick_effect/correspondence/remote_effect
	name = "Remote Effect"
	desc = "Convert a target into the remote origin for an effect."
	tags = MAGICK_TAG_UTILITY
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)
	var/datum/magick_port/input/in_target = MAGICK_PORT_TARGET
	var/datum/magick_port/output/out_origin = new("Origin", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/correspondence/remote_effect/cast(datum/magick_context/context)
	var/datum/magick_value/target = context.get(in_target)
	target.type_flags |= MAGICK_DATATYPE_FLAG_ORIGIN
	context.assign(out_origin, target)

/datum/magick_effect/correspondence/teleport_self
	name = "Teleport (Self)"
	tags = MAGICK_TAG_UTILITY
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 3,
		),
	)

	var/datum/magick_port/input/in_target = MAGICK_PORT_TARGET

/datum/magick_effect/correspondence/teleport_self/cast(datum/magick_context/context)
	var/target = context.get_value(in_target)

	var/mob/caster = context.caster
	caster.forceMove(get_turf(target))
