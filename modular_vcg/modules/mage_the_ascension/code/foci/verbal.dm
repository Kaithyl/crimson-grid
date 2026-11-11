/datum/magick_focus/verbal
	abstract_type = /datum/magick_focus/verbal

	// Placeholders until I can find a good mouth sprite
	icon = 'icons/obj/medical/organs/organs.dmi'
	icon_state = "tongue"
	//icon = 'icons/mob/effects/talk.dmi'
	//icon_state = "default0"

	cast_time = 1 SECONDS
	timed_action_flags = IGNORE_USER_LOC_CHANGE | IGNORE_HELD_ITEM

	var/required_language

/datum/magick_focus/verbal/can_use(mob/user)
	if(required_language && !user.has_language(required_language, SPOKEN_LANGUAGE))
		return FALSE
	if(HAS_TRAIT(user, TRAIT_MUTE) || HAS_TRAIT(user, TRAIT_SILENCED))
		return FALSE
	return TRUE

/datum/magick_focus/verbal/vow_spirit
	name = "Verbal Action - Vow (Spirit)"
	paradigms = PARADIGM_MYSTIC | PARADIGM_ANIMIST
	desc = "Make a vow with a spirit."
