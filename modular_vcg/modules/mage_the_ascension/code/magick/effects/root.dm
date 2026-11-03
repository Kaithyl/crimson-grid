/datum/magick_effect/root/
	abstract_type = /datum/magick_effect/root/
	tags = MAGICK_TAG_ROOT | MAGICK_TAG_DATA

	var/needs_crosshair = FALSE

	var/out_target = "out_target"

	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target (Origin)", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/magick_effect/root/cast(datum/magick_context/context)
	var/datum/magick_node_data/node_data = context.node_data ? context.node_data[context.current_node_id] : null
	context.assign(out_act, context.successes, MAGICK_DATATYPE_TRIGGER)
	context.assign(out_target, node_data?.target)

/datum/magick_effect/root/proc/resolve_target(mob/caster)
	return null

/datum/magick_effect/root/proc/is_valid_target(atom/clicked_on, mob/caster)
	return TRUE

// Target (Self)

/datum/magick_effect/root/target_self
	name = "Target (Self)"

/datum/magick_effect/root/target_self/resolve_target(mob/caster)
	return caster

// Target (Item)

/datum/magick_effect/root/target_item_hands
	name = "Target (Item)"

/datum/magick_effect/root/target_item_hands/resolve_target(mob/caster)
	for (var/obj/item/held_item in caster.held_items)
		if (held_item)
			return held_item
	return null

// Target (Melee)

/datum/magick_effect/root/target_melee
	//abstract_type = /datum/magick_effect/root/target_melee
	name = "Target (Melee)"
	needs_crosshair = TRUE
	var/melee_target_type = /atom/movable

/datum/magick_effect/root/target_melee/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, melee_target_type) && (get_dist(caster, clicked_on) <= 1)

/datum/magick_effect/root/target_melee/_turf
	name = "Target (Melee Turf)"
	melee_target_type = /turf
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target (Origin)", "type" = MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/magick_effect/root/target_melee/_mob
	name = "Target (Melee Mob)"
	melee_target_type = /mob/living
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target (Origin)", "type" = MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/magick_effect/root/target_melee/_obj
	name = "Target (Melee Obj)"
	melee_target_type = /obj
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target (Origin)", "type" = MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

// Target (Clicked)

/datum/magick_effect/root/target_clicked
	//abstract_type = /datum/magick_effect/root/target_clicked
	name = "Target (Clicked)"
	needs_crosshair = TRUE
	var/clicked_target_type = /atom
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/magick_effect/root/target_clicked/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, clicked_target_type)

/datum/magick_effect/root/target_clicked/_turf
	name = "Target (Clicked Turf)"
	clicked_target_type = /turf
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target (Turf)", "type" = MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/magick_effect/root/target_clicked/_mob
	name = "Target (Clicked Mob)"
	clicked_target_type = /mob
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target (Mob)", "type" = MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/magick_effect/root/target_clicked/_obj
	name = "Target (Clicked Obj)"
	clicked_target_type = /obj
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
		out_target = alist("name" = "Target (Obj)", "type" = MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_SINGLE),
	)
