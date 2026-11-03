/datum/preference/choiced/subsplat/mage_faction
	savefile_key = "mage_faction"
	main_feature_name = "Faction"
	must_be_accessible = TRUE

/datum/preference/choiced/subsplat/mage_faction/init_possible_values()
	return assoc_to_keys(GLOB.mage_faction_list)

/datum/preference/choiced/subsplat/mage_faction/icon_for(value)
	return uni_icon('icons/effects/effects.dmi', "nothing")

/datum/preference/choiced/subsplat/mage_faction/apply_to_human(mob/living/carbon/human/target, value, datum/preferences/preferences)
	var/joining_round = !isdummy(target)
	target.set_mage_faction(value, joining_round)

/datum/preference/choiced/subsplat/mage_faction/post_set_preference(mob/user, value)
	var/datum/subsplat/mage_faction/faction = get_mage_faction(value)
	faction?.show_lore(user)

/datum/preference/choiced/subsplat/mage_faction/is_accessible(datum/preferences/preferences)
	. = ..()
	var/datum/splat/splat_path = preferences.read_preference(/datum/preference/choiced/splats)
	if(!ispath(splat_path, /datum/splat/mage))
		return FALSE
