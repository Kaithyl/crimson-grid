/datum/splat/mage
	abstract_type = /datum/splat/mage

	var/is_inverted = FALSE

	var/quintessence = 0

	var/permanent_paradox = 0
	var/paradox = 0

	// All Mage actions and effects should be attatched to the owner's mind
	var/datum/mind/true_owner

	// Toggleable stance for staving off backlash
	var/datum/action/innate/delay_backlash/delay_backlash_action
	// Quint and WP expenditure for casting is in spell crafting instead of being a stance
	var/datum/action/innate/rote_builder/rote_builder_action

	//var/datum/subsplat/mage/paradigm

	splat_priority = SPLAT_PRIO_MAGE

	splat_traits = list(TRAIT_AWAKENED)

	// TODO: Allow embrace but lose mage splat. Add willpower option to die instead of getting embraced.
	incompatible_splats = list(/datum/splat/werewolf/shifter, /datum/splat/vampire/kindred)
	can_frenzy = FALSE

/datum/splat/mage/on_gain()
	. = ..()

	true_owner = owner.mind

	if (!rote_builder_action)
		rote_builder_action = new(true_owner || owner)
	rote_builder_action.Grant(owner)

	if (!delay_backlash_action)
		delay_backlash_action = new(true_owner || owner)
	delay_backlash_action.Grant(owner)

	adjust_quintessence(owner.st_get_stat(STAT_AVATAR))

/datum/splat/mage/on_lose()
	. = ..()
	qdel(rote_builder_action)
	qdel(delay_backlash_action)

/datum/splat/mage/willworker
	name = "Mage"
	id = SPLAT_WILLWORKER
	//desc = ""

/datum/splat/mage/technocrat
	name = "Technocrat"
	id = SPLAT_TECHNOCRAT
	//desc = ""

/mob/living/carbon/human/splat/mage/willworker
	auto_splats = list(/datum/splat/mage/willworker)

/mob/living/carbon/human/splat/mage/technocrat
	auto_splats = list(/datum/splat/mage/technocrat)
