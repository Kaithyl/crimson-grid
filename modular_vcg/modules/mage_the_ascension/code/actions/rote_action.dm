/datum/action/innate/rote

	click_action = TRUE
	ranged_mousepointer = 'icons/effects/mouse_pointers/weapon_pointer.dmi'
	enable_text = span_notice("Select a target for your effect.")
	disable_text = span_notice("You cancel your effect.")
	check_flags = AB_CHECK_CONSCIOUS

	// Placeholder for now
	overlay_icon = 'icons/mob/actions/actions_items.dmi'
	overlay_icon_state = "bci_blank"

	// The rote this action represents
	var/datum/magick_rote/rote

/datum/action/innate/rote/New(Target, datum/magick_rote/rote)
	..(Target)
	src.rote = rote
	if (rote)
		rote.action = src
		name = rote.name
		get_desc()

/datum/action/innate/rote/proc/refresh_state()
	get_desc()
	build_all_button_icons(UPDATE_BUTTON_NAME)

// Whether the caster can still cancel or force cast the spell
/datum/action/innate/rote/proc/can_cancel_or_force()
	if (!rote || !owner || !ROTE_IS_CASTING(rote))
		return FALSE
	// Only the rote currently being focused on can be cancelled or force cast
	var/datum/splat/mage/mage_splat = get_mage_splat(owner)
	return mage_splat?.active_rote == rote \
		&& !rote.active_context.arete_locked_in \
		&& !rote.active_context.aborted \
		&& !rote.active_context.interrupted

/datum/action/innate/rote/proc/get_desc()
	PRIVATE_PROC(TRUE)
	var/rote_desc = rote?.desc || ""
	// Only show click controls while the spell is being focused on
	if (!can_cancel_or_force())
		desc = rote_desc
		return
	var/list/context = list(
		SCREENTIP_CONTEXT_LMB = "Cancel",
		SCREENTIP_CONTEXT_RMB = "Force Cast",
	)
	var/front = "[build_context(context, SCREENTIP_CONTEXT_LMB, TRUE)] | [build_context(context, SCREENTIP_CONTEXT_RMB, TRUE)]"
	desc = "[front]\n\n[rote_desc]"

/datum/action/innate/rote/Destroy()
	if (rote)
		rote.action = null
		rote = null
	return ..()

/datum/action/innate/rote/Trigger(mob/clicker, trigger_flags)
	// datum/action requires parent function to be called
	// so temporarily setting click_action to false to avoid blocking
	var/click_action_was = click_action
	click_action = FALSE
	. = ..()
	click_action = click_action_was
	if(!.)
		return FALSE

	if (!rote)
		return FALSE

	// If using a hotkey for this action, the clicker is null, so fall back to owner
	var/mob/user = clicker || owner
	if (isnull(user))
		return FALSE

	if (ROTE_IS_CASTING(rote))
		// Only the rote currently being focused on responds to cancel/force cast
		if (can_cancel_or_force())
			// Right-clicking or using the hotkey (clicker is null) force casts
			var/force_cast = !!(trigger_flags & TRIGGER_SECONDARY_ACTION) || isnull(clicker)
			if (force_cast)
				rote.active_context.interrupted = TRUE
				to_chat(user, span_notice("You force the spell to completion."))
			else
				rote.active_context.aborted = TRUE
				to_chat(user, span_notice("You stop focusing on your spell."))
		return TRUE

	// Only one rote may be cast at a time, so cancel any other casts
	var/datum/splat/mage/mage_splat = get_mage_splat(user)
	if (mage_splat?.active_rote)
		mage_splat.active_rote.active_context.aborted = TRUE

	// If already in targeting mode, toggle off
	if (click_action && owner?.click_intercept == src)
		unset_ranged_ability(user, disable_text)
		rote.pending_target_nodes = null
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return TRUE

	// Determine which root nodes need target selection
	var/list/needs_selection = list()
	for (var/node_id as anything in rote.root_nodes)
		var/datum/rote_node_data/node_data_entry = rote.node_data ? rote.node_data[node_id] : null
		var/datum/rote_node/node = node_data_entry?.node
		if (node?.needs_crosshair)
			needs_selection += node_id

	if (length(needs_selection))
		// Enter ranged targeting mode with crosshair cursor
		rote.pending_target_nodes = needs_selection
		var/first_id = needs_selection[1]
		var/datum/rote_node_data/first_data = rote.node_data ? rote.node_data[first_id] : null
		enable_text = span_notice(MAGICK_TARGET_ENABLE_TEXT(first_data?.label, length(rote.pending_target_nodes)))
		set_ranged_ability(user, enable_text)
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return TRUE

	// All nodes are self-select, cast directly without targeting mode
	rote.Cast(user)
	return TRUE

/datum/action/innate/rote/do_ability(mob/living/clicker, atom/clicked_on)
	if (!rote)
		return FALSE

	var/mob/user = clicker || owner
	if (isnull(user))
		return FALSE
	if (!length(rote.pending_target_nodes))
		unset_ranged_ability(user)
		return FALSE

	// Another rote took over the cast while we were targeting
	var/datum/splat/mage/mage_splat = get_mage_splat(user)
	if (mage_splat?.active_rote && mage_splat.active_rote != rote)
		unset_ranged_ability(user)
		rote.pending_target_nodes = null
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return FALSE

	var/node_id = rote.pending_target_nodes[1]
	var/datum/rote_node_data/node_data_entry = rote.node_data ? rote.node_data[node_id] : null
	var/datum/rote_node/root/node = node_data_entry?.node
	if (!istype(node))
		rote.pending_target_nodes -= node_id
		return TRUE

	if (!node.is_valid_target(clicked_on, user))
		to_chat(user, span_warning("That is not a valid target for [node.name]."))
		return TRUE

	// Assign the clicked atom as the target for the next pending root node
	rote.pending_target_nodes -= node_id
	node_data_entry.target = clicked_on

	if (length(rote.pending_target_nodes))
		to_chat(user, span_notice(MAGICK_TARGET_ENABLE_TEXT(node_data_entry?.label, length(rote.pending_target_nodes))))
		return TRUE

	// Cast when all targets have been assigned
	unset_ranged_ability(user)
	rote.Cast(user)
	return TRUE

/datum/action/innate/rote/Remove(mob/removed_from)
	if (removed_from.click_intercept == src)
		unset_ranged_ability(removed_from)
	if (rote)
		rote.pending_target_nodes = null
		if (ROTE_IS_CASTING(rote))
			rote.active_context.aborted = TRUE
	return ..()

// Only show the focus overlay while this rote is actively casting
/datum/action/innate/rote/apply_button_overlay(atom/movable/screen/movable/action_button/current_button, force)
	var/overlay_icon_state_was = overlay_icon_state
	var/should_show_overlay = can_cancel_or_force()
	if (!should_show_overlay)
		overlay_icon_state = null
	. = ..()
	overlay_icon_state = overlay_icon_state_was

	if (!should_show_overlay && current_button.button_overlay)
		current_button.cut_overlay(current_button.button_overlay)
		current_button.button_overlay = null
		current_button.active_overlay_icon_state = null

// Temporarily putting this here
/datum/storyteller_roll/arete
	numerical = TRUE
	roll_output_type = ROLL_PRIVATE
	applicable_stats = list(STAT_ARETE)
	var/auto_successes = 0

/datum/storyteller_roll/arete/calculate_auto_successes(mob/living/roller)
	. = ..() + auto_successes
