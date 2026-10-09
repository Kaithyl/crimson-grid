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
	min_successes = 1
	looks_like = MAGICK_VULGAR_FIRE | MAGICK_VULGAR_EXPLOSION
	ports_typepath = /datum/magick_ports/activatable/fireball

/datum/magick_ports/activatable/fireball
	var/datum/magick_port/any/in_origin = MAGICK_PORT_ORIGIN
	var/datum/magick_port/any/in_target = MAGICK_PORT_TARGET
	var/datum/magick_port/number/in_maxsucc = MAGICK_PORT_NUMBER_("Max Successes", 0, null)

/datum/magick_effect/fireball/pre_cast(datum/magick_context/context)
	..(context)
	var/datum/magick_ports/activatable/fireball/ports = context.blackboard[src]
	var/max_successes = ports.in_maxsucc.get()
	min_successes = max_successes ? min(context.successes, max_successes) : context.successes

/datum/magick_effect/fireball/cast(datum/magick_context/context)
	var/datum/magick_ports/activatable/fireball/ports = context.blackboard[src]
	var/origin = ports.in_origin.get()
	var/target = ports.in_target.get()

	if (!target)
		return

	var/obj/projectile/magic/fireball/projectile = new(get_turf(target))
	projectile.fired_from = origin
	projectile.aim_projectile(target, origin)

	projectile.damage = 2 * (min_successes + 1) TTRPG_DAMAGE
	projectile.exp_heavy = max(0, min_successes - 4)
	projectile.exp_light = clamp(min_successes - 1, 0, 4)
	projectile.exp_fire = clamp(min_successes - 1, 0, 3)
	projectile.exp_flash = clamp(min_successes, 1, 5)

	ports.out_activate.assign(target)
