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
	complexity = 2
	can_add_success = TRUE
	spheres = list(
		alist(
			SPHERE_FORCES = 3,
			SPHERE_PRIME = 2,
		),
	)

	var/in_origin = "in_origin"
	var/in_target = "in_target"

	inputs = new(
		in_act = MAGICK_PORT_ACTIVATE,
		in_origin = MAGICK_PORT_ORIGIN,
		in_target = MAGICK_PORT_TARGET,
	)

	outputs = new(
		out_act = MAGICK_PORT_ACTIVATE
	)

/datum/rote_node/effect/fireball/execute(datum/magick_context/context)

	// Temporary - TODO: Add getting + consuming successes handling to base _effect.dm
	var/successes = context.current_scope.successes
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
	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)

// Lightning Bolt

/datum/rote_node/effect/lightningbolt
	name = "Lightning Bolt"
	tags = MAGICK_TAG_DAMAGE
	min_success_cost = 2
	complexity = 2
	can_add_success = TRUE
	spheres = list(
		alist(
			SPHERE_FORCES = 3,
			SPHERE_PRIME = 2,
		),
	)

	var/in_origin = "in_origin"
	var/in_target = "in_target"

	inputs = new(
		in_act = MAGICK_PORT_ACTIVATE,
		in_origin = MAGICK_PORT_ORIGIN,
		in_target = MAGICK_PORT_TARGET,
	)

	outputs = new(
		out_act = MAGICK_PORT_ACTIVATE
	)

/datum/rote_node/effect/lightningbolt/execute(datum/magick_context/context)
	var/successes = context.current_scope.successes
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
	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)

// Create Fire

/datum/rote_node/effect/createfire
	name = "Create Fire"
	desc = "Magnifies and transmutes the ambient energy in the environment into fire."
	tags = MAGICK_TAG_UTILITY
	min_success_cost = 1
	complexity = 2
	can_add_success = TRUE
	spheres = list(
		alist(
			SPHERE_FORCES = 3,
		)
	)

	var/in_origin = "in_origin"
	var/in_pattern = "in_pattern"
	var/in_dir = "in_dir"

	inputs = new(
		in_act = MAGICK_PORT_ACTIVATE,
		in_origin = MAGICK_PORT_ORIGIN,
		in_pattern = MAGICK_PORT_PATTERN(FALSE, null, FALSE),
		in_dir = MAGICK_PORT_DIRECTION(TRUE, TRUE),
	)
	outputs = new(
		out_act = MAGICK_PORT_ACTIVATE,
	)

/datum/rote_node/effect/createfire/execute(datum/magick_context/context)
	var/available = context.current_scope.successes
	if (!available)
		return

	var/origin = context.get_value(in_origin)
	var/list/pattern = context.get_value(in_pattern)
	if (!origin || !islist(pattern) || !length(pattern))
		return

	var/turf/origin_turf = get_turf(origin)
	if (!origin_turf)
		return

	var/direction = context.get_value(in_dir)
	var/list/rotated = rotate_pattern(pattern, direction)

	// Select the turfs, grouped by ring (Chebyshev distance from the origin + 1, since lists start at 1)
	var/list/rings = list()
	var/total = 0
	var/max_ring = 0
	for (var/list/offset in rotated)
		var/dx = offset[1]
		var/dy = offset[2]
		var/turf/target = locate(origin_turf.x + dx, origin_turf.y + dy, origin_turf.z)
		if (!isopenturf(target) || isspaceturf(target))
			continue
		// Because in BYOND lists start at index 1
		var/ring = max(abs(dx), abs(dy)) + 1
		if (length(rings) < ring)
			rings.len = ring
		if (!rings[ring])
			rings[ring] = list()
		rings[ring] += target
		total++
		if (ring > max_ring)
			max_ring = ring

	// going to go with M20 RAI that non-direct damaging effects scale exponentially
	// 5^(x-1) turfs where x = successes
	var/covered = min(total, 5 ** (available - 1))

	if (context.debug)
		to_chat(context.caster, span_info("DEBUG: [name] covered [covered], max_ring [max_ring]"))

	// radiate fire outwards
	if (covered > 0)
		INVOKE_ASYNC(src, PROC_REF(apply_fire), rings, covered, max_ring, context)

	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)

/datum/rote_node/effect/createfire/proc/apply_fire(list/rings, budget, max_ring, datum/magick_context/context)
	var/remaining = budget
	for (var/ring = 1 to max_ring)
		var/list/turfs = rings[ring]
		if (!turfs)
			continue
		if (context?.debug)
			to_chat(context.caster, span_info("DEBUG: [name] ring [ring] - [length(turfs)] turf\s, [remaining] remaining."))
		for (var/turf/target in turfs)
			if (remaining <= 0)
				return
			target.ignite_turf(30)
			remaining--
		sleep(1)
