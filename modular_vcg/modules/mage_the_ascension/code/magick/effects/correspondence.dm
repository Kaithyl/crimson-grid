/datum/magick_effect/target_mobs
	name = "Target mobs in area"
	tags = MAGICK_TAG_DATA
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)
	outputs = alist("Target" = MAGICK_DATA_MOB | MAGICK_DATA_COUNT_ANY)
	inputs = alist("Radii" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)

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
	inputs = alist("Target" = MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ONE)

/datum/magick_effect/teleport_self/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/target = input_values["Target"]

	var/mob/caster = context.caster
	caster.forceMove(get_turf(target))

	return alist("Target" = target)
