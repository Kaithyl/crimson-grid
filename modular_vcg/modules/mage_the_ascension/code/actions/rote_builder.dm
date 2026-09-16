// Not a power but an innate menu
/datum/action/innate/mental/rote_builder
	name = "Open Rote Builder"

	desc = ""

	//click_action = TRUE

	// You should be able to modify premade effects while you are unconscious
	// since this is a compromise between rotes and dynamic casting
	//check_flags = NONE

/datum/action/innate/mental/rote_builder/Trigger(mob/user, trigger_flags)
	if(!..())
		return FALSE

	ui_interact(user)

/datum/action/innate/mental/rote_builder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "RoteBuilder", name)
		ui.open()

/datum/action/innate/mental/rote_builder/ui_data(mob/user)
	var/list/data = list()
	data["user_name"] = user.name
	// Send arete, paradigm and sphere info
	if(!isliving(user))
		return data

	var/mob/living/st_user = user

	var/user_stats = list(
		"arete" = st_user.st_get_stat(STAT_ARETE),
		//"paradigm" = ""
	)

	for(var/sphere in GLOB.all_spheres)
		user_stats[sphere] = st_user.st_get_stat(GLOB.all_spheres[sphere])

	data["user_stats"] = user_stats
	return data

/datum/action/innate/mental/rote_builder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	switch (action)
		if("button_clicked")
			to_chat(usr, span_notice("You clicked a button in the menu!"))
			return TRUE

	return FALSE
