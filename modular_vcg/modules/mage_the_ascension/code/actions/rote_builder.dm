/datum/action/innate/rote_builder
	name = "Open Rote Builder"

	desc = ""

	button_icon = 'modular_vcg/modules/mage_the_ascension/icons/actions.dmi'
	button_icon_state = "mage"

	// You should be able to modify premade effects while you are unconscious
	// since this is a compromise between rotes and dynamic casting
	//check_flags = NONE

	// Temp
	// Stores autosaved uncompiled changes
	var/draft_name
	var/draft_desc
	var/draft_code

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

	// Temp for dealing with draft data, will beautify this later
	var/datum/splat/mage/mage_splat = get_mage_splat(owner)
	var/list/datum/magick_rote/rotes = mage_splat?.rotes
	if(draft_code)
		data["rote_data"] = draft_code
		data["rote_name"] = draft_name
		data["rote_desc"] = draft_desc
	else if(rotes && rotes[1])
		data["rote_data"] = rotes[1].rote_code
		data["rote_name"] = rotes[1].name
		data["rote_desc"] = rotes[1].desc

	return data

/datum/action/innate/rote_builder/ui_static_data(mob/user)
	return GLOB.rotebuilder_static_data

/datum/action/innate/rote_builder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	if(usr != owner)
		return FALSE

	switch (action)
		if("save_rote")
			var/draft_rote_name = copytext(trim(params["name"] || ""), 1, 41)
			var/draft_rote_desc = copytext(trim(params["desc"] || ""), 1, 501)
			var/draft_rote_code = params["rote_code"]

			if(!istext(draft_rote_code) || !length(draft_rote_code))
				return TRUE

			draft_name = draft_rote_name
			draft_desc = draft_rote_desc
			draft_code = draft_rote_code
			return TRUE

		if("compile_rote")
			var/rote_name = copytext(trim(params["name"]), 1, 41)
			var/rote_desc = copytext(trim(params["desc"] || ""), 1, 501)
			var/rote_rawdata = params["rote_data"]
			var/rote_code = params["rote_code"]

			if(!length(rote_name))
				to_chat(usr, span_warning("Your rote needs a name."))
				return TRUE

			if(!istext(rote_rawdata) || !length(rote_rawdata))
				to_chat(usr, span_warning("Your rote data is missing."))
				return TRUE

			if(!isliving(usr))
				return TRUE

			// Validate rote data
			var/alist/rote_data = validate_rote_data(usr, rote_rawdata)
			if(!rote_data)
				to_chat(usr, span_warning("Your rote failed validation and could not be saved."))
				return TRUE

			var/datum/splat/mage/mage_splat = get_mage_splat(usr)
			if(!mage_splat)
				return TRUE

			var/datum/mind/true_owner = mage_splat.true_owner

			var/datum/magick_rote/new_rote = new()
			new_rote.name = rote_name
			new_rote.desc = rote_desc
			new_rote.rote_code = rote_code
			new_rote.root_nodes = rote_data["root_nodes"]
			new_rote.effect_graph = rote_data["effect_graph"]
			new_rote.reverse_graph = rote_data["reverse_graph"]
			new_rote.node_data = rote_data["node_data"]
			new_rote.complexity = rote_data["complexity"]
			new_rote.expected_success_cost = rote_data["expected_success_cost"]
			new_rote.expected_quint_cost = rote_data["expected_quint_cost"]

			// Replace old rote
			var/datum/magick_rote/old_rote = mage_splat.rotes[1]
			if(old_rote)
				if(old_rote.action)
					old_rote.action.Remove(usr)
					qdel(old_rote.action)
				qdel(old_rote)

			var/datum/action/innate/rote/new_action = new(true_owner, new_rote)
			mage_splat.rotes[1] = new_rote
			new_action.Grant(usr)
			to_chat(usr, span_notice("You save the rote \"[rote_name]\" to the first rote slot."))
			return TRUE

	return FALSE

/datum/action/innate/rote_builder/proc/validate_rote_data(mob/living/user, rote_rawdata)
	var/list/result = compile_rote(user, rote_rawdata)
	if(!result[1])
		validation_fail(user, result[2])
		return null
	return result[1]

/datum/action/innate/rote_builder/proc/validation_fail(mob/living/user, fail_reason)
	PRIVATE_PROC(TRUE)
	//var/msg = "Rote validation failed for [key_name(user)] ([user]): [fail_reason]"
	//user.log_message("Rote validation failed: [fail_reason]", LOG_GAME)
	//message_admins("[ADMIN_LOOKUPFLW(user)]: [msg]")
	to_chat(user, span_warning("Error when building rote: [fail_reason]"))
	//log_game("[msg]")
