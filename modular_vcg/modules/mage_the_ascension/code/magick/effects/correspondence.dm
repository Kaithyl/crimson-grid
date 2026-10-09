/datum/magick_effect/correspondence/
	min_successes = 1

/*/datum/magick_effect/correspondence/pre_cast(datum/magick_context/context)
	..(context)
	// Increase successes required depending on distance or line of sight
*/

/datum/magick_effect/correspondence/target_to_origin
	name = "Originate spell at target"
	tags = MAGICK_TAG_DATA
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)
	ports_typepath = /datum/magick_ports/activatable/target_to_origin

/datum/magick_ports/activatable/target_to_origin
	var/datum/magick_port/any/in_target = MAGICK_PORT_TARGET
	var/datum/magick_port/output/out_origin = new("Origin", MAGICK_DATA_ANY | MAGICK_DATA_ORIGIN | MAGICK_DATA_COUNT_ONE)

/datum/magick_effect/correspondence/target_to_origin/cast(datum/magick_context/context)
	var/datum/magick_ports/activatable/target_to_origin/ports = context.blackboard[src]
	ports.out_origin.assign(ports.in_target.get())

/datum/magick_effect/target_mobs
	name = "Target mobs in area"
	tags = MAGICK_TAG_DATA
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 2,
		),
	)
	ports_typepath = /datum/magick_ports/activatable/target_mobs

/datum/magick_ports/activatable/target_mobs
	var/datum/magick_port/any/in_target = MAGICK_PORT_TARGET
	var/datum/magick_port/number/in_radius = MAGICK_PORT_NUMBER_("Radius", 1, 5)

	var/datum/magick_port/output/out_targets = MAGICK_PORT_TARGET_S

/datum/magick_effect/target_mobs/cast(datum/magick_context/context)
	var/datum/magick_ports/activatable/target_mobs/ports = context.blackboard[src]
	var/radius = ports.in_radius.get()

	var/list/targets = list()
	for (var/mob/living/living_mob in range(radius, context.caster))
		targets += living_mob

	ports.out_targets.assign(targets)

/datum/magick_effect/correspondence/teleport_self
	name = "Teleport (Self)"
	tags = MAGICK_TAG_UTILITY
	spheres = list(
		alist(
			SPHERE_CORRESPONDENCE = 3,
		),
	)
	ports_typepath = /datum/magick_ports/activatable/teleport_self

/datum/magick_ports/activatable/teleport_self
	var/datum/magick_port/any/in_target = MAGICK_PORT_TARGET

/datum/magick_effect/correspondence/teleport_self/cast(datum/magick_context/context)
	var/datum/magick_ports/activatable/teleport_self/ports = context.blackboard[src]
	var/target = ports.in_target.get()

	var/mob/caster = context.caster
	caster.forceMove(get_turf(target))

	ports.out_activate.assign(TRUE)
