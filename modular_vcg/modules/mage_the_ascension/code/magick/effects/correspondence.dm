/datum/magick_effect/target_mobs
	name = "Target mobs in area"
	tags = MAGICK_TAG_DATA
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)

	inputs = list(
		MAGICK_PORT_ACTIVATE,
		MAGICK_PORT_TARGET,
		MAGICK_PORT_NUMBER_("Radius"),
	)
	outputs = list(
		MAGICK_PORT_ACTIVATE,
		MAGICK_PORT_TARGET_S,
	)

/datum/magick_effect/target_mobs/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/radius = input_values[3]

	var/list/targets = list()
	for (var/mob/living/living_mob in range(radius, context.caster))
		targets += living_mob

	return alist(2 = targets)

/datum/magick_effect/teleport_self
	name = "Teleport (Self)"
	tags = MAGICK_TAG_UTILITY
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 3,
		),
	)
	inputs = list(
		MAGICK_PORT_ACTIVATE,
		MAGICK_PORT_TARGET,
	)
	outputs = list(
		MAGICK_PORT_ACTIVATE,
	)

/datum/magick_effect/teleport_self/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/target = input_values[2]

	var/mob/caster = context.caster
	caster.forceMove(get_turf(target))
