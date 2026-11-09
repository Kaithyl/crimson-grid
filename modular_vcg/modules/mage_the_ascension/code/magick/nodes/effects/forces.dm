/*
 *	For general forces rotes:
 *	Magical damage translates to 2 levels of health/damage per success
 *	Damaging forces spells add 1 success die to final damage total
 */

// Fireball

/datum/rote_node/effect/fireball
	name = "Fireball"
	tags = MAGICK_TAG_DAMAGE
	min_success_cost = 2
	can_add_success = TRUE
	spheres = list(
		alist(
			SPHERE_FORCES = 3,
			SPHERE_PRIME = 2,
		),
	)

	var/in_origin = "in_origin"
	var/in_target = "in_target"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_origin = MAGICK_PORT_ORIGIN,
		in_target = MAGICK_PORT_TARGET,
	)

	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE
	)

/datum/rote_node/effect/fireball/cast(datum/magick_context/context)

	// Temporary - TODO: Add getting + consuming successes handling to base _effect.dm
	var/successes = context.get_value(in_act)
	if (!successes || successes < min_success_cost)
		return

	var/origin = context.get_value(in_origin)
	var/target = context.get_value(in_target)

	if (!origin || !target)
		return

	var/obj/projectile/magic/fireball/projectile = new(origin)
	projectile.firer = context.caster
	projectile.aim_projectile(target, origin)
	projectile.set_homing_target(target)
	projectile.can_hit_turfs = TRUE

	/*
	 * TODO: If origin is also the caster, scale this based on Dexterity + Athletics/Firearms?
	 * however, according to (M20, page 543) the caster can just create the fireball on the target when
	 * in line of sight without using correspondence, so with the added nerf for requiring correspondence
	 * to teleport a fireball directly on a target giving it perfect accuracy/homing seems like a fair trade-off
	 */
	// removes all inaccuracy within line of sight distance
	projectile.homing_turn_speed = 360
	// accuracy formula: clamp(accurate_range - (accuracy_falloff * distance), 5, 100)
	projectile.accurate_range = 100 + 7 * MAGICK_LINE_OF_SIGHT_DISTANCE
	projectile.spread = 0
	projectile.homing_inaccuracy_min = 0
	projectile.homing_inaccuracy_max = 0

	// apply successes
	projectile.damage = 2 * (successes + 1) TTRPG_DAMAGE
	projectile.damage_type = AGGRAVATED
	projectile.exp_heavy = max(0, successes - 4)
	projectile.exp_light = clamp(successes - 1, 0, 4)
	projectile.exp_fire = clamp(successes - 1, 0, 3)
	projectile.exp_flash = clamp(successes, 1, 5)

	projectile.fire()

// Lightning Bolt

/datum/rote_node/effect/lightningbolt
	name = "Lightning Bolt"
	tags = MAGICK_TAG_DAMAGE
	min_success_cost = 2
	can_add_success = TRUE
	spheres = list(
		alist(
			SPHERE_FORCES = 3,
			SPHERE_PRIME = 2,
		),
	)

	var/in_origin = "in_origin"
	var/in_target = "in_target"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_origin = MAGICK_PORT_ORIGIN,
		in_target = MAGICK_PORT_TARGET,
	)

	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE
	)

/datum/rote_node/effect/lightningbolt/cast(datum/magick_context/context)
	var/successes = context.get_value(in_act)
	if (!successes || successes < min_success_cost)
		return

	var/origin = context.get_value(in_origin)
	var/target = context.get_value(in_target)

	if (!origin || !target)
		return

	var/obj/projectile/magic/aoe/lightning/projectile = new(origin)
	projectile.firer = context.caster
	projectile.aim_projectile(target, origin)
	projectile.set_homing_target(target)
	projectile.can_hit_turfs = TRUE

	projectile.homing_turn_speed = 360
	projectile.accurate_range = 100 + 7 * MAGICK_LINE_OF_SIGHT_DISTANCE
	projectile.spread = 0
	projectile.homing_inaccuracy_min = 0
	projectile.homing_inaccuracy_max = 0

	// apply successes
	projectile.damage = 2 * (successes + 1) TTRPG_DAMAGE
	projectile.damage_type = AGGRAVATED
	// tesla_zap only uses zap_range for the first jump. each recursive jump instead
	// uses a hardcoded next_range of 5 (living) / 7 (silicons) and keeps chaining
	// while power >= cutoff (1e3), so keep the power low so the chain dies out fast
	// TODO: Make lightning child class that only overrides tesla zap
	projectile.zap_power = 1000 + 500 * successes
	projectile.zap_range = clamp(successes - 1, 1, 2)
	projectile.zap_flags = ZAP_MOB_DAMAGE | ZAP_LOW_POWER_GEN
	if (successes >= 4)
		projectile.zap_flags |= ZAP_OBJ_DAMAGE

	projectile.fire()
