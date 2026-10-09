// Abstract class for true magick spells
/datum/action/innate/rote
	abstract_type = /datum/action/innate/rote

	var/datum/magick_focus/focus

	// Root nodes of the effect tree
	//var/list/root_effects

	var/initial_target

	// TODO: Make this right clickable icons on the action to toggle on/off
	var/casting_subtly = FALSE
	var/willpower_auto_success = FALSE
	var/quint_diff_reduction = FALSE

	var/required_success = 1
	var/required_spheres

/datum/action/innate/rote/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if (!.)
		return

	return pre_cast(clicker)

/datum/action/innate/rote/proc/pre_cast(mob/clicker)

	var/datum/splat/mage/mage_splat = get_mage_splat(clicker)

	if (!mage_splat || !focus)
		return FALSE

	var/casting_without_focus = FALSE
	var/difficulty = MAGICK_BASE_DIFFICULTY
	var/cast_time = 1 // turn

	// focus

	if (!focus.cast(clicker)) // TODO: Add check for discarded and unique foci
		if (!mage_splat.owner?.st_get_stat(STAT_TEMPORARY_WILLPOWER) > 0)
			to_chat(clicker, span_warning("You lack the willpower required to cast without an instrument."))
			return FALSE

		to_chat(clicker, span_info("You attempt to cast without your instrument."))
		casting_without_focus = TRUE
		difficulty += 3

	if (!target)
		return FALSE

	/*var/result = do_after(clicker, (cast_time + 0.01 * focus.penalty) TURNS , target)
	if(!result)
		to_chat(clicker, span_warning("You were interrupted."))
		return FALSE*/

	if (casting_without_focus)
		if (mage_splat.owner?.st_get_stat(STAT_TEMPORARY_WILLPOWER) > 0)
			mage_splat.owner?.st_change_stat(STAT_TEMPORARY_WILLPOWER, -1)
		else
			// TODO: Display message that you fell below willpower requirements during casting
			return FALSE

	// optional willpower

	var/auto_successes = 0
	if (willpower_auto_success)
		if (mage_splat.owner?.st_get_stat(STAT_TEMPORARY_WILLPOWER) > 0)
			mage_splat.owner?.st_change_stat(STAT_TEMPORARY_WILLPOWER, -1)
			auto_successes += 1
		else
			to_chat(clicker, span_info("Insufficient Willpower. Continuing without an automatic success."))

	// optional quintessence

	if (quint_diff_reduction)
		if (mage_splat.adjust_quintessence(-1))
			difficulty -= 1
		else
			to_chat(clicker, span_info("Insufficient Quintessence. Continuing without difficulty reduction."))

	// TODO: Handle time sphere for delayed/contingent spells

	// check for witnesses around target and if spell is coincidental or vulgar
	// and apply paradox penalty
	// going to go with m1e difficulty and checking for paradox during cast

	// roll arete with required_success

	/*var/successes

	var/alist/context = alist(
		"caster" = clicker,
		"subtle" = casting_subtly,
		"successes" = successes,
		"explanations" = 0,
		"paradox" = FALSE,
	)*/

	//get effect then cast
