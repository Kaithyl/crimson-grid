/datum/splat/mage/willworker/prepare_human_for_preview(mob/living/carbon/human/human)
	/*human.set_haircolor("#C3BA88", update = FALSE)
	human.set_eye_color("B2B2B2", "B2B2B2")
	human.set_hairstyle("Bangs (Diagonal Alt)", update = TRUE)
	human.undershirt = "Shirt (Ian)"
	human.update_body()*/

/datum/splat/mage/willworker/get_splat_description()
	return "..."

/datum/splat/mage/willworker/get_splat_lore()
	return list(
		"..."
	)

/datum/splat/mage/willworker/create_pref_unique_perks()
	var/list/to_add = list()

	to_add += list(
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_STAR,
			SPECIES_PERK_NAME = "True Magick",
			SPECIES_PERK_DESC = "Mages can do almost anything as long as they have enough dots in the \
			right Spheres, which are capped by their Arete score.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_BRAIN,
			SPECIES_PERK_NAME = "Willworker",
			SPECIES_PERK_DESC = "Mages begin 5 free dots in Permanent Willpower, which can be \
			refunded to a minimum of 3. A Mage's Arete cannot be raised past their Permanent Willpower.",
		),
		/*list(
			SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
			SPECIES_PERK_ICON = FA_ICON_PERSON,
			SPECIES_PERK_NAME = "Mortal",
			SPECIES_PERK_DESC = "Can do everything a normal human can do.",
		),*/
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = FA_ICON_BOMB,
			SPECIES_PERK_NAME = "Paradox",
			SPECIES_PERK_DESC = "...",
		),
	)

	return to_add
