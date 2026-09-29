// Not a power but an innate "stance change"
/datum/action/innate/delay_backlash
	name = "Delay Paradox Backlash"

	// When stance is on, if a backlash would occur, spend 1 point of temp wp to delay by 1 scene
	desc = ""

	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spacetime"

	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/delay_backlash/Activate()
	active = TRUE
	to_chat(owner, span_info("You steady your willpower to stave off Paradox."))
	SEND_SOUND(owner, sound('sound/misc/menu/ui_select1.ogg', volume = 50))

/datum/action/innate/delay_backlash/Deactivate()
	active = FALSE
	to_chat(owner, span_info("You relax your willpower."))
	SEND_SOUND(owner, sound('sound/misc/menu/ui_select1.ogg', volume = 50))
