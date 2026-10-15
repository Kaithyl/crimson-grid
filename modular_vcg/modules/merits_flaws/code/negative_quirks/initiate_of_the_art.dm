// MTA revised IotA p. 84
/datum/quirk/darkpack/initiate_of_the_art
	name = "Initiate of the Art"
	ttrpg_sources = list(/datum/source_book/mta3/initiates_of_the_art = 84)
	desc = "You are a recently awakened orphan, or an initiate of the Traditions, Crafts, or the Technocracy. \
		At character creation, your Permanent Willpower begins at a minimum of 3 dots instead of 5."
	value = -2
	mob_trait = TRAIT_INITIATE_OF_THE_ART
	quirk_flags = QUIRK_HIDE_FROM_SCAN
	icon = FA_ICON_CHALKBOARD_TEACHER
	allowed_splats = SPLAT_MAGES
	gain_text = span_notice("You find yourself among the newest of the Awakened.")
	lose_text = span_notice("You feel you've outgrown your beginnings as an initiate.")
