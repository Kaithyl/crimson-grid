/*
 *	For general forces rotes:
 *	Magical damage translates to 2 levels of health/damage per success
 *	Damaging forces spells add 1 success die to final damage total
 */
/datum/magick_effect/forces/
	abstract_type = /datum/magick_effect/forces/
	in_act = MAGICK_PORT_ACTIVATE
	out_act = MAGICK_PORT_ACTIVATE

/datum/magick_effect/forces/fireball
	name = "Fireball"
	tags = MAGICK_TAG_DAMAGE
	spheres = list(
		alist(
			SPHERE_FORCES = 3,
			SPHERE_PRIME = 2,
		),
	)
	min_success_cost = 2
	can_add_success = TRUE

	var/datum/magick_port/input/in_origin = MAGICK_PORT_ORIGIN
	var/datum/magick_port/input/in_target = MAGICK_PORT_TARGET

/datum/magick_effect/forces/fireball/cast(datum/magick_context/context)
	var/origin = context.get_value(in_origin)
	var/target = context.get_value(in_target)

	var/successes = 0

	if (!origin || !target)
		return

	var/obj/projectile/magic/fireball/projectile = new(origin)
	//projectile.firer = origin //cast to mob
	//projectile.fired_from = origin //get mob's hands
	projectile.aim_projectile(target, origin)

	projectile.damage = 2 * (successes + 1) LETHAL_TTRPG_DAMAGE
	projectile.exp_heavy = max(0, successes - 4)
	projectile.exp_light = clamp(successes - 1, 0, 4)
	projectile.exp_fire = clamp(successes - 1, 0, 3)
	projectile.exp_flash = clamp(successes, 1, 5)
