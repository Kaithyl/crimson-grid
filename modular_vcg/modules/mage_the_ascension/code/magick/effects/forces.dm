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
	inputs = list(
		MAGICK_PORT_ACTIVATE,
		MAGICK_PORT_TARGET,
		MAGICK_PORT_NUMBER_("Max Successes"),
	)
	outputs = list(
		MAGICK_PORT_ACTIVATE,
	)

/datum/magick_effect/fireball/_cast(datum/magick_context/context)
	var/alist/input_values = context.blackboard[src]
	var/caster = context.caster
	var/successes = context.successes
	var/target = input_values[2]

	if (!target || successes < min_successes)
		return null

	var/max_successes = input_values[3]
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

	return alist(1 = target)
