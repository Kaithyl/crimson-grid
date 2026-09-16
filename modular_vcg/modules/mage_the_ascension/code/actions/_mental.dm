// Actions that transfer with the character's mind instead of body
/datum/action/innate/mental
	abstract_type = /datum/action/innate/mental

	button_icon = 'modular_vcg/modules/mage_the_ascension/icons/actions.dmi'
	button_icon_state = "mage"

/datum/action/innate/Grant(mob/grant_to)
	if(istype(target, /datum/mind))
		var/datum/mind/mind_target = target
		if(mind_target.current != grant_to)
			return

	. = ..()
	if(!owner)
		return
