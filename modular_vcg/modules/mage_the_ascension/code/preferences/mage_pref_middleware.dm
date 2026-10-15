// This entire file is a spaghetti workaround to get per-splat stats
// and custom stat behavior working in darkpack's system
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

	handle_mage_willpower_setup(user)

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

	if(istype(stat, /datum/st_stat/arete))
		var/datum/st_stat/willpower_stat = preferences.preference_storyteller_stats[STAT_PERMANENT_WILLPOWER]
		if(willpower_stat && (stat.get_pure_score() + 1) > willpower_stat.get_pure_score())
			to_chat(user, span_warning("Arete cannot exceed Permanent Willpower."))
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
	handle_mage_willpower_setup(user)
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
	if(!ispath(current_splat, /datum/splat/mage))
		// No longer a mage, drop the mage Permanent Willpower floor
		revert_mage_willpower_setup()
		refund_all_mage_points()
		preferences.save_character()
		return

	handle_mage_willpower_setup(user)

/datum/preference_middleware/proc/user_has_initiate_of_the_art(mob/user)
	/*if (user)
		if (HAS_TRAIT(user, TRAIT_INITIATE_OF_THE_ART))
			return TRUE
		if (HAS_MIND_TRAIT(user, TRAIT_INITIATE_OF_THE_ART))
			return TRUE*/
	// Above doesn't work before spawning in, have to manually check in character creator
	for(var/quirk_name in preferences.all_quirks)
		var/datum/quirk/quirk_type = SSquirks.quirks[quirk_name]
		if(!isnull(quirk_type) && initial(quirk_type.mob_trait) == TRAIT_INITIATE_OF_THE_ART)
			return TRUE
	return FALSE

/datum/preference_middleware/proc/mage_willpower_minimum(mob/user)
	var/splat = preferences.read_preference(/datum/preference/choiced/splats)
	if(!ispath(splat, /datum/splat/mage))
		return null
	if(user_has_initiate_of_the_art(user))
		return MAGE_MIN_WILLPOWER_INITIATE
	return MAGE_MIN_WILLPOWER

/// Applies the free Permanent WP floor for mages
/datum/preference_middleware/proc/handle_mage_willpower_setup(mob/user)
	var/min_willpower = mage_willpower_minimum(user)
	var/datum/st_stat/willpower_stat = preferences.preference_storyteller_stats[STAT_PERMANENT_WILLPOWER]
	if(isnull(min_willpower) || !willpower_stat)
		return

	// Clear any leftover pool points so Permanent WP always costs freebie points
	var/datum/st_stat/pooled/willpower_category = preferences.preference_storyteller_stats[willpower_stat.abstract_type]
	if(willpower_category)
		willpower_category.set_points(0)

	willpower_stat.min_score = min_willpower
	willpower_stat.starting_score = min_willpower
	if(willpower_stat.get_pure_score() < min_willpower)
		willpower_stat.set_score(min_willpower)
		update_middleware_stats(preferences.preference_storyteller_stats)

	enforce_arete_willpower_cap()

// Copy of same function from quirks.dm to handle mage-specific quirks
/datum/preference_middleware/quirks/give_quirk(list/params, mob/user)
	var/quirk_name = params["quirk"]
	var/datum/st_stat/freebie/freebie_points = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]
	var/datum/quirk/quirk_type = SSquirks.quirks[quirk_name]
	freebie_points.decrease_points(quirk_type.value)
	preferences.validate_quirks()
	var/list/new_quirks = preferences.all_quirks | quirk_name
	if (SSquirks.filter_invalid_quirks(new_quirks) != new_quirks)
		tainted = TRUE
		preferences.update_static_data(user, always_instant = TRUE)
		return TRUE

	preferences.all_quirks = new_quirks
	tainted = TRUE
	preferences.character_preview_view?.update_body()
	handle_initiate_of_the_art_toggle(user, quirk_name, TRUE)
	return TRUE

// Copy of same function from quirks.dm to handle mage-specific quirks
/datum/preference_middleware/quirks/remove_quirk(list/params, mob/user)
	var/quirk_name = params["quirk"]
	var/datum/st_stat/freebie/freebie_points = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]
	var/datum/quirk/quirk_type = SSquirks.quirks[quirk_name]
	freebie_points.increase_points(quirk_type.value)
	var/list/new_quirks = preferences.all_quirks - quirk_name
	if (!(quirk_name in preferences.all_quirks) || SSquirks.filter_invalid_quirks(new_quirks) != new_quirks)
		tainted = TRUE
		preferences.update_static_data(user, always_instant = TRUE)
		return TRUE

	preferences.all_quirks = new_quirks
	tainted = TRUE
	preferences.character_preview_view?.update_body()
	handle_initiate_of_the_art_toggle(user, quirk_name, FALSE)
	return TRUE

// Resets Permanent WP to the floor the quirk now requires and refunds dots that vanish
/datum/preference_middleware/proc/handle_initiate_of_the_art_toggle(mob/user, quirk_name, is_taking)
	if(is_taking != (quirk_name in preferences.all_quirks))
		return
	var/datum/quirk/quirk_type = SSquirks.quirks[quirk_name]
	if(isnull(quirk_type) || initial(quirk_type.mob_trait) != TRAIT_INITIATE_OF_THE_ART)
		return
	var/splat = preferences.read_preference(/datum/preference/choiced/splats)
	if(!ispath(splat, /datum/splat/mage))
		return

	var/min_willpower = is_taking ? MAGE_MIN_WILLPOWER_INITIATE : MAGE_MIN_WILLPOWER
	var/datum/st_stat/willpower_stat = preferences.preference_storyteller_stats[STAT_PERMANENT_WILLPOWER]
	if(!willpower_stat)
		return
	var/datum/st_stat/pooled/willpower_category = preferences.preference_storyteller_stats[willpower_stat.abstract_type]
	var/datum/st_stat/freebie/freebie_stat = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]
	if(willpower_category)
		if(freebie_stat && willpower_category.freebie_cost_spent > 0)
			freebie_stat.increase_freebie_points(willpower_category.freebie_cost_spent)
			willpower_category.freebie_cost_spent = 0
		willpower_category.set_points(0)

	willpower_stat.min_score = min_willpower
	willpower_stat.starting_score = min_willpower
	willpower_stat.set_score(min_willpower)
	update_middleware_stats(preferences.preference_storyteller_stats)

/datum/preference_middleware/proc/revert_mage_willpower_setup()
	var/datum/st_stat/willpower_stat = preferences.preference_storyteller_stats[STAT_PERMANENT_WILLPOWER]
	if(!willpower_stat)
		return

	// Drop the free Permanent WP dots mage granted, and refund anything the
	// player actually paid to raise Willpower above that floor before they stop being a mage.
	var/datum/st_stat/pooled/willpower_category = preferences.preference_storyteller_stats[willpower_stat.abstract_type]
	var/datum/st_stat/freebie/freebie_stat = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]
	if(willpower_category && freebie_stat)
		if(willpower_category.freebie_cost_spent > 0)
			freebie_stat.increase_freebie_points(willpower_category.freebie_cost_spent)
			willpower_category.freebie_cost_spent = 0
		// Clear any leftover pool points so willpower always costs freebie points
		willpower_category.set_points(0)

	willpower_stat.min_score = 0
	willpower_stat.starting_score = 0
	willpower_stat.set_score(0)
	update_middleware_stats(preferences.preference_storyteller_stats)

/datum/preference_middleware/stats/proc/handle_mage_willpower_decrease()
	var/splat = preferences.read_preference(/datum/preference/choiced/splats)
	if(!ispath(splat, /datum/splat/mage))
		return
	enforce_arete_willpower_cap()

/datum/preference_middleware/proc/enforce_arete_willpower_cap()
	var/datum/st_stat/arete/arete_stat = preferences.preference_storyteller_stats[/datum/st_stat/arete]
	var/datum/st_stat/willpower_stat = preferences.preference_storyteller_stats[STAT_PERMANENT_WILLPOWER]
	if(!arete_stat || !willpower_stat)
		return

	var/arete_score = arete_stat.get_pure_score()
	var/willpower_score = willpower_stat.get_pure_score()
	if(arete_score <= willpower_score)
		return

	var/datum/st_stat/freebie/freebie_stat = preferences.preference_storyteller_stats[STAT_FREEBIE_POINTS]
	for(var/i in 1 to arete_score - willpower_score)
		if(!arete_stat.decrease_score(1))
			break
		freebie_stat?.increase_freebie_points(arete_stat.freebie_point_cost)
