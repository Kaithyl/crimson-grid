/datum/action/innate/rote_builder
	name = "Open Rote Builder"

	desc = ""

	button_icon = 'modular_vcg/modules/mage_the_ascension/icons/actions.dmi'
	button_icon_state = "mage"

	// You should be able to modify premade effects while you are unconscious
	// since this is a compromise between rotes and dynamic casting
	//check_flags = NONE

	allow_observer_click = TRUE

/datum/action/innate/rote_builder/Trigger(mob/user, trigger_flags)
	if(!..())
		return FALSE

	SEND_SOUND(owner, sound('sound/misc/menu/ui_select1.ogg', volume = 50))

	ui_interact(user)

/datum/action/innate/rote_builder/ui_host(mob/user)
    return owner

/datum/action/innate/rote_builder/ui_state(mob/user)
    return GLOB.always_state

/datum/action/innate/rote_builder/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/plane_background))

/datum/action/innate/rote_builder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "RoteBuilder", name)
		ui.open()

/datum/action/innate/rote_builder/ui_data(mob/user)

	var/list/data = list()
	data["view_only"] = (owner != user)
	// Send arete, paradigm and sphere info
	if(!isliving(user))
		return data

	var/mob/living/st_user = user

	var/user_stats = list(
		"arete" = st_user.st_get_stat(STAT_ARETE),
		//"paradigm" = ""
	)

	for(var/sphere as anything in ALL_SPHERES)
		user_stats[sphere] = st_user.st_get_stat(ALL_SPHERES[sphere])

	data["user_stats"] = user_stats
	return data

/datum/action/innate/rote_builder/ui_static_data(mob/user)
	return GLOB.magick_effect_static_data

/datum/action/innate/rote_builder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	// Don't let spectating ghosts modify rotes
	if(usr != owner)
		return FALSE

	switch (action)
		if("button_clicked")
			to_chat(usr, span_notice("You clicked a button in the menu!"))
			return TRUE

	return FALSE
