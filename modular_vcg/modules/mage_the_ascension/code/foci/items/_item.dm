/datum/magick_focus/item/
	abstract_type = /datum/magick_focus/item/

	timed_action_flags = IGNORE_USER_LOC_CHANGE

	var/item_type

	// Items that can be used as substitute at +1 diff
	var/list/substitute_types

// /datum/magick_focus/item/get_action_flags(mob/user)
	// TODO: implement add IGNORE_HELD_ITEM, but only if caster has Ambidextrous merit

/datum/magick_focus/item/can_use(mob/user)
	for (var/obj/item/I in user.held_items)
		if (istype(I, type))
			return TRUE
	return FALSE
