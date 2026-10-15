/datum/magick_effect/root/
	abstract_type = /datum/magick_effect/root/
	tags = MAGICK_TAG_ROOT | MAGICK_TAG_DATA
	max_nodes = 3
	var/target
	var/needs_crosshair = FALSE
	out_act = MAGICK_PORT_ACTIVATE
	var/datum/magick_port/output/out_target = null

/datum/magick_effect/root/cast(datum/magick_context/context)
	context.assign(out_act, context.successes, MAGICK_DATATYPE_TRIGGER)
	context.assign(out_target, target)

/datum/magick_effect/root/proc/resolve_target(mob/caster)
	return null

/datum/magick_effect/root/proc/is_valid_target(atom/clicked_on, mob/caster)
	return TRUE

/datum/magick_effect/root/target_self
	name = "Target (Self)"
	out_target = new("Target (Origin)", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/root/target_self/resolve_target(mob/caster)
	return caster

/datum/magick_effect/root/target_item_hands
	name = "Target (Item)"
	out_target = new("Target (Origin)", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/root/target_item_hands/resolve_target(mob/caster)
	for (var/obj/item/held_item in caster.held_items)
		if (held_item)
			return held_item
	return null

/datum/magick_effect/root/target_melee
	abstract_type = /datum/magick_effect/root/target_melee
	name = "Target (Melee)"
	needs_crosshair = TRUE
	out_target = new("Target (Origin)", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)
	var/melee_target_type = /atom/movable

/datum/magick_effect/root/target_melee/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, melee_target_type) && (get_dist(caster, clicked_on) <= 1)

/datum/magick_effect/root/target_melee/_turf
	name = "Target (Melee Turf)"
	melee_target_type = /turf
	out_target = new("Target (Origin)", MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/root/target_melee/_mob
	name = "Target (Melee Mob)"
	melee_target_type = /mob/living
	out_target = new("Target (Origin)", MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/root/target_melee/_obj
	name = "Target (Melee Obj)"
	melee_target_type = /obj
	out_target = new("Target (Origin)", MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/root/target_clicked
	abstract_type = /datum/magick_effect/root/target_clicked
	name = "Target (Clicked)"
	needs_crosshair = TRUE
	out_target = new("Target", MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_SINGLE)
	var/clicked_target_type = /atom

/datum/magick_effect/root/target_clicked/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, clicked_target_type)

/datum/magick_effect/root/target_clicked/_turf
	name = "Target (Clicked Turf)"
	clicked_target_type = /turf
	out_target = new("Target (Turf)", MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/root/target_clicked/_mob
	name = "Target (Clicked Mob)"
	clicked_target_type = /mob
	out_target = new("Target (Mob)", MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_SINGLE)

/datum/magick_effect/root/target_clicked/_obj
	name = "Target (Clicked Obj)"
	clicked_target_type = /obj
	out_target = new("Target (Obj)", MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_SINGLE)
