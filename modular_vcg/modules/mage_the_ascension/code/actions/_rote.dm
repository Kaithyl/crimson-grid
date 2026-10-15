// Abstract class for true magick spells
/datum/action/innate/rote

	click_action = TRUE
	ranged_mousepointer = 'icons/effects/mouse_pointers/weapon_pointer.dmi'
	enable_text = span_notice("Select a target for your effect.")
	disable_text = span_notice("You cancel your effect.")

	// Effect components
	// TODO: Instruments used for casting
	var/list/datum/magick_focus/foci
	// Root nodes of the effect tree
	var/list/datum/magick_effect/root/root_nodes
	// String format of effect graph for loading into UI
	var/rote_data

	// Casting
	// Root nodes still awaiting target selection via crosshair
	var/list/datum/magick_effect/root/pending_target_nodes

	// TODO: Make this right clickable icons on the action to toggle on/off
	var/willpower_auto_success = FALSE
	var/quint_diff_reduction = 0

	var/complexity
	var/max_complexity

	var/expected_success_cost = 0
	var/expected_quint_cost = 0
	var/spheres

/datum/action/innate/rote/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return FALSE

	// If already in targeting mode, toggle off
	if (click_action && owner?.click_intercept == src)
		unset_ranged_ability(clicker, disable_text)
		pending_target_nodes = null
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return TRUE

	// Determine which root nodes need target selection
	var/list/datum/magick_effect/root/needs_selection = list()
	for (var/datum/magick_effect/root/node as anything in root_nodes)
		if (node.needs_crosshair)
			needs_selection += node

	if (length(needs_selection))
		// Enter ranged targeting mode with crosshair cursor
		pending_target_nodes = needs_selection
		var/datum/magick_effect/root/first_node = needs_selection[1]
		enable_text = span_notice(MAGICK_TARGET_ENABLE_TEXT(first_node.label, length(pending_target_nodes)))
		set_ranged_ability(clicker, enable_text)
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return TRUE

	// All nodes are self-select, cast directly without targeting mode
	Cast(clicker)
	return TRUE

/datum/action/innate/rote/do_ability(mob/living/clicker, atom/clicked_on)
	if (!length(pending_target_nodes))
		unset_ranged_ability(clicker)
		return FALSE

	var/datum/magick_effect/root/node = pending_target_nodes[1]

	if (!node.is_valid_target(clicked_on, clicker))
		to_chat(clicker, span_warning("That is not a valid target for [node.name]."))
		return TRUE

	// Assign the clicked atom as the target for the next pending root node
	pending_target_nodes -= node
	node.target = clicked_on

	if (length(pending_target_nodes))
		to_chat(clicker, span_notice(MAGICK_TARGET_ENABLE_TEXT(node.label, length(pending_target_nodes))))
		return TRUE

	// Cast when all targets have been assigned
	unset_ranged_ability(clicker)
	Cast(clicker)
	return TRUE

/datum/action/innate/rote/Remove(mob/removed_from)
	if (removed_from.click_intercept == src)
		unset_ranged_ability(removed_from)
	pending_target_nodes = null
	return ..()

/datum/action/innate/rote/proc/Cast(mob/clicker)

	var/datum/splat/mage/mage_splat = get_mage_splat(clicker)

	if (!mage_splat)
		return FALSE

	// If foci empty return

	// Auto-assign self-selecting root nodes
	for (var/datum/magick_effect/root/node as anything in root_nodes)
		var/target = node.resolve_target(clicker)
		if (target)
			node.target = target

	var/casting_without_focus = FALSE
	var/difficulty = MAGICK_BASE_DIFFICULTY
	var/cast_time = 1 // turn

	// focus

	/*if (!focus.cast(clicker)) // TODO: Add check for discarded and unique foci
		if (!mage_splat.owner?.st_get_stat(STAT_TEMPORARY_WILLPOWER) > 0)
			to_chat(clicker, span_warning("You lack the willpower required to cast without an instrument."))
			return FALSE

		to_chat(clicker, span_info("You attempt to cast without your instrument."))
		casting_without_focus = TRUE
		difficulty += 3*/

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
		var/actual_reduction = min(quint_diff_reduction, mage_splat.quintessence)
		if (actual_reduction > 0)
			mage_splat.adjust_quintessence(-actual_reduction)
			difficulty -= actual_reduction
			if (actual_reduction < quint_diff_reduction)
				to_chat(clicker, span_info("Insufficient Quintessence. Difficulty reduced by [actual_reduction] instead of [quint_diff_reduction]."))
		else
			to_chat(clicker, span_info("Insufficient Quintessence. Continuing without difficulty reduction."))

	// TODO: Handle time sphere for delayed/contingent spells

	// check for witnesses around target and if spell is coincidental or vulgar
	// and apply paradox penalty
	// going to go with m1e difficulty and checking for paradox during cast

	// roll arete with required_success

	var/successes = 0

	var/datum/magick_context/context = new()
	context.caster = clicker
	context.successes = successes

	// Cast each root node with its assigned target
	for (var/datum/magick_effect/root/node as anything in root_nodes)
		node.__cast(context)
