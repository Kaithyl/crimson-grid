/*
 *	For general forces rotes:
 *	Magical damage translates to 2 levels of health/damage per success
 *	Damaging forces spells add 1 success die to final damage total
 */

/datum/magick_effect/fireball
	name = "Fireball"
	tags = MAGICK_TAG_DAMAGE
	spheres = list(
		alist(
			SPHERE_FORCES = 3,
			SPHERE_PRIME = 2,
		),
	)
	looks_like = MAGICK_VULGAR_FIRE | MAGICK_VULGAR_EXPLOSION
	inputs = alist(
		"Activate" = MAGICK_DATA_ACTIVATE,
		"Target" = MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ONE,
		"Max Success" = MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE
	)
	outputs = alist(
		"Activate" = MAGICK_DATA_ACTIVATE
	)

/datum/magick_effect/fireball/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/caster = context.caster
	var/successes = context.successes
	var/target = input_values["Target"]

	if (!target || successes < min_successes)
		return null

	var/max_successes = input_values["Max Success"]
	if (max_successes)
		successes = min(successes, max_successes)

	var/obj/projectile/magic/fireball/projectile = new(get_turf(target))
	var/origin = context.subtle ? target : caster
	//if not subtle set fired_from depending on foci
	//projectile.fired_from
	projectile.aim_projectile(target, origin)

	projectile.damage = 2 * (successes + 1) TTRPG_DAMAGE
	projectile.exp_heavy = max(0, successes - 4)
	projectile.exp_light = clamp(successes - 1, 0, 4)
	projectile.exp_fire = clamp(successes - 1, 0, 3)
	projectile.exp_flash = clamp(successes, 1, 5)

	context.successes -= successes

	return alist("Target" = target)
