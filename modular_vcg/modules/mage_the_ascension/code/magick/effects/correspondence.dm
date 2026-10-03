/datum/magick_effect/target_mobs
	name = "Target mobs in area"
	tags = MAGICK_TAG_DATA
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)
	inputs = alist(
		"Activate" = MAGICK_DATA_ACTIVATE,
		"Radii" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE
	)
	outputs = alist(
		"Activate" = MAGICK_DATA_ACTIVATE,
		"Targets" = MAGICK_DATA_MOB | MAGICK_DATA_COUNT_ANY
	)

/datum/magick_effect/target_mobs/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/radii = input_values["Radii"]

	var/list/targets = list()
	for (var/mob/living/living_mob in range(radii, context.caster))
		targets += living_mob

	return alist("Target" = targets)

/datum/magick_effect/teleport_self
	name = "Teleport (Self)"
	tags = MAGICK_TAG_UTILITY
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 3,
		),
	)
	inputs = alist(
		"Activate" = MAGICK_DATA_ACTIVATE,
		"Target" = MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ONE
	)
	outputs = alist(
		"Activate" = MAGICK_DATA_ACTIVATE
	)

/datum/magick_effect/teleport_self/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/target = input_values["Target"]

	var/mob/caster = context.caster
	caster.forceMove(get_turf(target))

	return alist("Target" = target)
