// This is a spaghetti workaround to get per-splat stats working in darkpack's system
/datum/preference_middleware/mage_stats
	action_delegations = list(
		"increase_mage_stat" = PROC_REF(increase_stat),
		"decrease_mage_stat" = PROC_REF(decrease_stat),
		"reset_mage_stats" = PROC_REF(reset_stats),
	)

// Copy of discipline_pref_middleware.dm warning player on join without any spheres
/mob/dead/new_player/proc/check_sphere_warning()
	if(!client?.prefs)
		return TRUE
	var/splat = client.prefs.read_preference(/datum/preference/choiced/splats)
	if(!ispath(splat, /datum/splat/mage))
		return TRUE
	for(var/stat_type in client.prefs.preference_storyteller_stats)
		var/datum/st_stat/stat = client.prefs.preference_storyteller_stats[stat_type]
		if(!istype(stat, /datum/st_stat/sphere))
			continue
		if(stat.get_pure_score() > 0)
			return TRUE
	var/choice = tgui_alert(src, "You have not allocated any Sphere dots! Without Spheres, you will be unable to practice Magick. Are you sure you want to join without any Spheres?", "Spheres Not Configured", list("Yes", "Go Back"))
	return choice == "Yes"

/datum/preference_middleware/mage_stats/get_ui_data(mob/user)
	if(preferences.current_window != PREFERENCE_TAB_CHARACTER_PREFERENCES)
		return list()
	var/list/data = list()
	data["mage_stats"] = list()

	for(var/typepath in preferences.preference_storyteller_stats)
		var/datum/st_stat/stat = preferences.preference_storyteller_stats[typepath]

		if(!stat)
			continue
		// Only show mage-specific stats
		if(!stat.required_trait)
			continue

		var/list/stat_data = list()
		stat_data["name"] = stat.name
		stat_data["desc"] = stat.description
		stat_data["editable"] = stat.editable
		stat_data["category"] = stat.category
		stat_data["subcategory"] = stat.subcategory
		stat_data["max_score"] = stat.max_score
		stat_data["points"] = stat.get_points()
		stat_data["score"] = stat.get_pure_score()
		stat_data["bonus_score"] = max(stat.get_bonus_score(), 0)
		stat_data["abstract_type"] = "[stat.abstract_type]"
		data["mage_stats"]["[stat.type]"] = stat_data

	return data

/datum/preference_middleware/mage_stats/proc/increase_stat(list/params, mob/user)
	SHOULD_NOT_SLEEP(TRUE)

	if("[user.client.prefs.default_slot]" in user.persistent_client.joined_as_slots)
		to_chat(user, span_warning("You cannot be spawned in as this character to adjust its stats."))
		return FALSE

	var/datum/st_stat/stat = preferences.preference_storyteller_stats[text2path(params["stat"])]
	if(!stat)
		return FALSE

	if(istype(stat, /datum/st_stat/arete) && stat.get_pure_score() >= MAX_STARTING_ARETE)
		to_chat(user, span_warning("Arete cannot exceed [MAX_STARTING_ARETE] at character creation."))
		return FALSE

	if(istype(stat, /datum/st_stat/sphere))
		var/datum/st_stat/arete/arete_stat = preferences.preference_storyteller_stats[/datum/st_stat/arete]
		if(arete_stat && (stat.get_pure_score() + 1) > arete_stat.get_pure_score())
			to_chat(user, span_warning("Spheres cannot exceed Arete."))
			return FALSE

	// We want this to be null for arete and background since the base st_stat isn't in preference_storyteller_stats
	var/datum/st_stat/stat_category = preferences.preference_storyteller_stats[stat.abstract_type]
	var/old_value = stat.get_pure_score()

	var/datum/st_stat/freebie/freebie_point_stat = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]

	if(!stat.can_increase_score(1))
		return FALSE

	if((stat.get_pure_score() + 1) > stat.starting_score)
		if(stat_category)
			if(stat_category.can_decrease_points(1))
				stat_category.decrease_points(1)
			else if(freebie_point_stat?.can_decrease_freebie_points(stat.freebie_point_cost))
				freebie_point_stat.decrease_freebie_points(stat.freebie_point_cost)
				stat_category.freebie_cost_spent += stat.freebie_point_cost
			else
				return FALSE
		else
			if(freebie_point_stat?.can_decrease_freebie_points(stat.freebie_point_cost))
				freebie_point_stat.decrease_freebie_points(stat.freebie_point_cost)
			else
				return FALSE

	stat.increase_score(1)

	var/new_value = stat.get_pure_score()
	var/real_name = user.client.prefs.read_preference(/datum/preference/name/real_name)
	user.log_message("increased mage stat '[stat.name]' from [old_value] to [new_value] on [real_name]", LOG_STATS)
	return TRUE

/datum/preference_middleware/mage_stats/proc/decrease_stat(list/params, mob/user)
	SHOULD_NOT_SLEEP(TRUE)

	if(!isnewplayer(user))
		to_chat(user, span_warning("You have to be in the main menu to adjust your stats."))
		return FALSE

	var/datum/st_stat/stat = preferences.preference_storyteller_stats[text2path(params["stat"])]
	if(!stat)
		return FALSE

	var/datum/st_stat/stat_category = preferences.preference_storyteller_stats[stat.abstract_type]
	var/old_value = stat.get_pure_score()

	var/datum/st_stat/freebie/freebie_point_stat = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]

	if(!stat.can_decrease_score(1))
		return FALSE

	if((stat.get_pure_score() - 1) >= stat.starting_score)
		if(stat_category)
			if(stat_category.freebie_cost_spent >= stat.freebie_point_cost)
				freebie_point_stat.increase_freebie_points(stat.freebie_point_cost)
				stat_category.freebie_cost_spent -= stat.freebie_point_cost
			else
				stat_category.increase_points(1)
		else
			freebie_point_stat?.increase_freebie_points(stat.freebie_point_cost)

	stat.decrease_score(1)

	// If arete was decreased, bump down spheres that exceed the new arete
	if (istype(stat, /datum/st_stat/arete))
		var/new_arete = stat.get_pure_score()
		var/datum/st_stat/sphere/sphere_category = preferences.preference_storyteller_stats[/datum/st_stat/sphere]
		for (var/sphere_type in subtypesof(/datum/st_stat/sphere))
			var/datum/st_stat/sphere/sphere_stat = preferences.preference_storyteller_stats[sphere_type]
			if(!sphere_stat)
				continue
			var/sphere_score = sphere_stat.get_pure_score()
			if (sphere_score > new_arete)
				for (var/i in 1 to sphere_score - new_arete)
					sphere_stat.decrease_score(1)
					var/datum/st_stat/freebie/freebie_stat = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]
					if (sphere_category?.freebie_cost_spent >= sphere_category.freebie_point_cost)
						freebie_stat.increase_freebie_points(sphere_category.freebie_point_cost)
						sphere_category.freebie_cost_spent -= sphere_category.freebie_point_cost
					else
						sphere_category?.increase_points(1)

	var/new_value = stat.get_pure_score()
	var/real_name = user.client.prefs.read_preference(/datum/preference/name/real_name)
	user.log_message("decreased mage stat '[stat.name]' from [old_value] to [new_value] on '[real_name]'", LOG_STATS)
	return TRUE

/datum/preference_middleware/mage_stats/proc/reset_stats(list/params, mob/user)
	SHOULD_NOT_SLEEP(TRUE)

	if(!isnewplayer(user))
		to_chat(user, span_warning("You have to be in the main menu to adjust your stats."))
		return FALSE

	var/real_name = user.client.prefs.read_preference(/datum/preference/name/real_name)
	user.log_message("reset all true magick stats to default values on '[real_name]'", LOG_STATS)

	refund_all_mage_points()
	return TRUE

/datum/preference_middleware/mage_stats/proc/refund_all_mage_points()
	var/datum/st_stat/freebie/freebie_stat = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]
	if(!freebie_stat)
		return

	var/points_to_refund = 0
	for(var/stat_typepath in preferences.preference_storyteller_stats)
		var/datum/st_stat/stat = preferences.preference_storyteller_stats[stat_typepath]
		if(!stat || !stat.required_trait)
			continue

		if(stat.freebie_cost_spent > 0)
			points_to_refund += stat.freebie_cost_spent
			stat.freebie_cost_spent = 0

		var/datum/st_stat/stat_category = preferences.preference_storyteller_stats[stat.abstract_type]
		if(!stat_category || stat_category == stat)
			var/points_above_starting = stat.get_pure_score() - stat.starting_score
			if(points_above_starting > 0)
				points_to_refund += points_above_starting * stat.freebie_point_cost

		stat.set_score(stat.starting_score)
		// Reset category points for pooled stats
		if(stat_category && stat_category == stat)
			var/datum/st_stat/new_category = new stat_category.type()
			stat_category.set_points(new_category.get_points())

	if(points_to_refund > 0)
		freebie_stat.increase_freebie_points(points_to_refund)

// Refund all sphere and freebie points in creator when player switches out of mage
/datum/preference_middleware/mage_stats/post_set_preference(mob/user, preference, value)
	. = ..()
	if(preference != "splats")
		return

	var/current_splat = preferences.read_preference(/datum/preference/choiced/splats)
	if(ispath(current_splat, /datum/splat/mage))
		return

	refund_all_mage_points()
	preferences.save_character()
