// These are root nodes that should execute with player-input values upon casting

/datum/rote_node/source/
	abstract_type = /datum/rote_node/source/
	tags = MAGICK_TAG_DATA

	complexity = 1

	var/out_target = "out_target"

	outputs = new(
		out_target = alist("name" = "Target", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/proc/resolve_target(mob/caster)
	return null

/datum/rote_node/source/proc/is_valid_target(atom/clicked_on, mob/caster)
	return TRUE

// Pushes this source node's resolved target into the correct port
/datum/rote_node/source/proc/push_target(datum/magick_rote/rote, node_id, atom/target)
	rote.set_port_value(node_id, out_target, target, outputs?[out_target]?["type"])

// Target (Self)

/datum/rote_node/source/target_self
	name = "Target (Self)"

/datum/rote_node/source/target_self/resolve_target(mob/caster)
	return caster

// Target (Item)

/datum/rote_node/source/target_item_hands
	name = "Target (Item)"

/datum/rote_node/source/target_item_hands/resolve_target(mob/caster)
	for (var/obj/item/held_item in caster.held_items)
		if (held_item)
			return held_item
	return null

// Target (Melee)

/datum/rote_node/source/target_melee
	//abstract_type = /datum/rote_node/source/target_melee
	name = "Target (Melee)"
	needs_crosshair = TRUE
	var/melee_target_type = /atom/movable

/datum/rote_node/source/target_melee/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, melee_target_type) && (get_dist(caster, clicked_on) <= 1)

/datum/rote_node/source/target_melee/_turf
	name = "Target (Melee Turf)"
	melee_target_type = /turf
	outputs = new(
		out_target = alist("name" = "Target", "type" = MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_melee/_mob
	name = "Target (Melee Mob)"
	melee_target_type = /mob/living
	outputs = new(
		out_target = alist("name" = "Target", "type" = MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_melee/_obj
	name = "Target (Melee Obj)"
	melee_target_type = /obj
	outputs = new(
		out_target = alist("name" = "Target", "type" = MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

// Target (Clicked)

/datum/rote_node/source/target_clicked
	//abstract_type = /datum/rote_node/source/target_clicked
	name = "Target (Clicked)"
	needs_crosshair = TRUE
	var/clicked_target_type = /atom
	outputs = new(
		out_target = alist("name" = "Target", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_clicked/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, clicked_target_type)

/datum/rote_node/source/target_clicked/_turf
	name = "Target (Clicked Turf)"
	clicked_target_type = /turf
	outputs = new(
		out_target = alist("name" = "Target (Turf)", "type" = MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_clicked/_mob
	name = "Target (Clicked Mob)"
	clicked_target_type = /mob
	outputs = new(
		out_target = alist("name" = "Target (Mob)", "type" = MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_clicked/_obj
	name = "Target (Clicked Obj)"
	clicked_target_type = /obj
	outputs = new(
		out_target = alist("name" = "Target (Obj)", "type" = MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_SINGLE),
	)
