#define UI_LIVING_QUINTESSENCE_AND_PARADOX "EAST-2:20,CENTER-1:40"

/datum/hud/proc/add_mage_elements(datum/splat/mage/mage_splat)
	add_screen_object(/atom/movable/screen/quintessence_and_paradox, HUD_MOB_QUINTESSENCE_AND_PARADOX, HUD_GROUP_INFO)

/datum/splat/mage/add_relevent_huds(datum/hud/hud_used)
	hud_used.add_mage_elements(src)

/mob/living/proc/update_mage_hud()
	if(!hud_used)
		return
	hud_used.screen_objects[HUD_MOB_QUINTESSENCE_AND_PARADOX]?.update_icon()

/atom/movable/screen/quintessence_and_paradox
	name = "quintessence and paradox"
	icon = 'modular_vcg/modules/mage_the_ascension/icons/hud_meters.dmi'
	icon_state = "quint0"
	screen_loc = UI_LIVING_QUINTESSENCE_AND_PARADOX
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/quintessence_and_paradox/Initialize(mapload, datum/hud/hud_owner)
	. = ..()

	update_icon()
	register_context()

/atom/movable/screen/quintessence_and_paradox/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	context[SCREENTIP_CONTEXT_LMB] = "Check Quintessence and Paradox"

	return CONTEXTUAL_SCREENTIP_SET

/atom/movable/screen/quintessence_and_paradox/Click(location, control, params)
	if(isliving(usr))
		var/mob/living/mob = usr
		//mob.update_mage_hud()

		var/datum/splat/mage/our_splat = get_mage_splat(mob)
		if(!istype(our_splat))
			return ..()

		to_chat(mob, span_bolddanger("You have [our_splat.quintessence] Quintessence, [our_splat.paradox] Paradox, and [our_splat.permanent_paradox] Permanent Paradox."))
		//to_chat(mob, span_bolddanger("[our_splat.owner?.st_get_stat(STAT_AVATAR)]"))

	return ..()

// Not really necessary since we're going to call get_mage_splat
/*/mob/living/proc/update_mage_hud()
	if(!hud_used)
		return
	hud_used.screen_objects[HUD_MOB_QUINTESSENCE_AND_PARADOX]?.update_icon()*/

/atom/movable/screen/quintessence_and_paradox/update_icon_state()
	var/mob/living/owner = hud?.mymob
	if(!istype(owner))
		return

	var/datum/splat/mage/our_splat = get_mage_splat(owner)
	if(!istype(our_splat))
		return

	icon_state = "quint[our_splat.quintessence]"

	var/total_dox = min(our_splat.permanent_paradox + our_splat.paradox, 20)

	// See werewolf UI for why this is here instead of in update_overlays
	cut_overlays()
	add_overlay("dox[min(total_dox, 20)]")
	add_overlay("permadox[min(our_splat.permanent_paradox, 20)]")

	// TODO: Add a state for paradox 20+ overflow

	// If Nephandi, flip UI vertically
	//if (our_splat.is_inverted)
	//	src.transform = matrix(1, 0, 0, 0, -1, 0)

	return ..()

#undef UI_LIVING_QUINTESSENCE_AND_PARADOX
