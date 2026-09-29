/datum/magick_focus/
	abstract_type = /datum/magick_focus/
	// if the focus may explain effects
	var/explains
	// cast time penalty
	var/penalty = 0
	// how many effects this focus can support
	var/complexity = 1
	// bonus dice to stealthily cast vs other awareness
	var/subtlety = 0

/datum/magick_focus/proc/cast(mob/user)
	return TRUE

/datum/magick_focus/item/
	var/item_type

/datum/magick_focus/item/New(type)
	item_type = type

/datum/magick_focus/item/cast(mob/user)
	for(var/obj/item/I in user.held_items)
		if(istype(I, item_type))
			return TRUE
	return FALSE
