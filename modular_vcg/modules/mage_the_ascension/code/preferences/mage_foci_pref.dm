/datum/preference_middleware/foci
	key = "instruments"
	action_delegations = list(
		"set_personal_instrument" = PROC_REF(set_personal_instrument),
		"clear_personal_instrument" = PROC_REF(clear_personal_instrument),
		"toggle_discard_instrument" = PROC_REF(toggle_discard_instrument),
		"clear_instruments" = PROC_REF(clear_instruments),
	)

/datum/preference_middleware/foci/get_constant_data()
	var/list/data = list()
	for(var/focus_type in GLOB.magick_foci)
		var/datum/magick_focus/focus = GLOB.magick_foci[focus_type]
		var/list/focus_data = list()
		focus_data["name"] = focus.name
		focus_data["desc"] = focus.desc
		focus_data["icon"] = focus.icon ? "[focus.icon]" : null
		focus_data["icon_state"] = focus.icon_state
		focus_data["paradigms"] = focus.paradigms
		data["[focus_type]"] = focus_data
	return data

/datum/preference_middleware/foci/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()

	var/list/data = list()
	data["instruments"] = preferences.focus_instruments || list()
	data["discarded_instruments"] = preferences.discarded_instruments || list()
	data["paradigm"] = get_paradigm()
	data["instrument_discard_points"] = get_discard_points()
	data["instrument_discard_points_spent"] = length(preferences.discarded_instruments || list())
	return data

/datum/preference_middleware/foci/proc/get_paradigm()
	var/faction_value = preferences.read_preference(/datum/preference/choiced/subsplat/mage_faction)
	var/datum/subsplat/mage_faction/faction = get_mage_faction(faction_value)
	return faction?.base_paradigm || NONE

/datum/preference_middleware/foci/proc/get_discard_points()
	var/datum/st_stat/arete/arete_stat = preferences.preference_storyteller_stats[/datum/st_stat/arete]
	var/arete = arete_stat ? arete_stat.get_pure_score() : 0
	if(get_paradigm() & PARADIGM_MYSTIC)
		return max(0, arete - (ARETE_DISCARD_INSTRUMENT_MYSTIC - 1))
	return max(0, arete - (ARETE_DISCARD_INSTRUMENT_TECHNOMANCER - 1))

/datum/preference_middleware/foci/proc/can_edit_foci(mob/user)
	if(!isnewplayer(user) && ("[user.client.prefs.default_slot]" in user.persistent_client.joined_as_slots))
		to_chat(user, span_warning("You may not adjust the foci of characters that have played in the current round."))
		return FALSE
	return TRUE

/datum/preference_middleware/foci/proc/set_personal_instrument(list/params, mob/user)
	SHOULD_NOT_SLEEP(TRUE)
	if(!can_edit_foci(user))
		return FALSE

	var/sphere = params["sphere"]
	var/instrument = params["instrument"]
	if(!sphere || !instrument)
		return FALSE
	if(!(sphere in ALL_SPHERES))
		return FALSE
	if(!ispath(text2path(instrument), /datum/magick_focus))
		return FALSE

	LAZYSET(preferences.focus_instruments, sphere, instrument)
	preferences.save_character()
	return TRUE

/datum/preference_middleware/foci/proc/clear_personal_instrument(list/params, mob/user)
	SHOULD_NOT_SLEEP(TRUE)
	if(!can_edit_foci(user))
		return FALSE

	var/sphere = params["sphere"]
	if(!sphere)
		return FALSE

	preferences.focus_instruments -= sphere
	preferences.save_character()
	return TRUE

/datum/preference_middleware/foci/proc/toggle_discard_instrument(list/params, mob/user)
	SHOULD_NOT_SLEEP(TRUE)
	if(!can_edit_foci(user))
		return FALSE

	var/instrument = params["instrument"]
	if(!instrument)
		return FALSE
	if(!ispath(text2path(instrument), /datum/magick_focus))
		return FALSE

	if(instrument in (preferences.discarded_instruments || list()))
		preferences.discarded_instruments -= instrument
	else
		if(length(preferences.discarded_instruments || list()) >= get_discard_points())
			to_chat(user, span_warning("You do not have enough points to discard another instrument."))
			return FALSE
		LAZYADD(preferences.discarded_instruments, instrument)

	preferences.save_character()
	return TRUE

/datum/preference_middleware/foci/proc/clear_instruments(list/params, mob/user)
	SHOULD_NOT_SLEEP(TRUE)
	if(!can_edit_foci(user))
		return FALSE

	preferences.focus_instruments = list()
	preferences.discarded_instruments = list()
	preferences.save_character()
	return TRUE

/datum/preference_middleware/foci/post_set_preference(mob/user, preference, value)
	. = ..()
	if(preference != "mage_faction")
		return
	preferences.focus_instruments = list()
	preferences.discarded_instruments = list()
	preferences.save_character()
