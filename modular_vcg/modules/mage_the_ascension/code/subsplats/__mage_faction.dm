/datum/subsplat/mage_faction
	abstract_type = /datum/subsplat/mage_faction

	var/icon

	// Bit flags
	var/base_paradigm

	var/whitelisted = FALSE

GLOBAL_LIST_INIT(mage_faction_list, init_subsplat_list(/datum/subsplat/mage_faction))
GLOBAL_LIST_INIT_TYPED(mage_factions, /datum/subsplat/mage_faction, init_subtypes_w_path_keys(/datum/subsplat/mage_faction, list()))

/proc/get_mage_faction(faction_identifier)
	RETURN_TYPE(/datum/subsplat/mage_faction)

	if (ispath(faction_identifier))
		return GLOB.mage_factions[faction_identifier]
	else if (istext(faction_identifier))
		return GLOB.mage_factions[GLOB.mage_faction_list[faction_identifier]]
	else
		return faction_identifier

/datum/splat/mage/proc/set_faction(setting_faction, joining_round)
	var/datum/subsplat/mage_faction/previous_faction = faction

	var/datum/subsplat/mage_faction/new_faction = get_mage_faction(setting_faction)

	previous_faction?.on_lose(owner)

	faction = new_faction

	paradigm = new_faction ? new_faction.base_paradigm : NONE

	if (!new_faction)
		return

	new_faction.on_gain(owner, src, joining_round)

/mob/living/carbon/human/proc/set_mage_faction(setting_faction, joining_round)
	var/datum/splat/mage/mage_splat = get_mage_splat(src)
	if (!mage_splat)
		return
	mage_splat.set_faction(setting_faction, joining_round)
