// TODO: Make action stacking, so mage can perform verbal and somatic actions at the same time

/datum/magick_focus/
	abstract_type = /datum/magick_focus/

	var/name
	var/desc

	// Flags for actions allowed during casting that won't interupt
	VAR_PROTECTED/timed_action_flags = 0

	// Valid paradigms associated with this tool
	var/paradigms

	var/icon
	var/icon_state

	// sfx that plays to caster and whoever notices
	var/start_sound
	var/finish_sound

	// sfx that always plays
	var/start_public_sound
	var/finish_public_sound

	// if the initial cast requires cast time
	var/precast_time
	// cast time for extended effects
	var/cast_time
	// how many effects this focus can support
	var/complexity
	// bonus dice to stealthily cast vs other awareness
	var/subtlety

GLOBAL_LIST_INIT_TYPED(magick_foci, /datum/magick_focus, init_subtypes_w_path_keys(/datum/magick_focus, list()))

/datum/magick_focus/proc/get_action_flags(mob/user)
	return timed_action_flags

/datum/magick_focus/proc/can_use(mob/user)
	return TRUE
