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
	// Tracks click events for special targeting mechanics (ie. turf preview for building)
	var/atom/movable/screen/fullscreen/cursor_catcher/rote_preview/mouse_tracker

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

/datum/action/innate/rote/set_ranged_ability(mob/living/on_who, text_to_show)
	. = ..()
	if (!rote || !on_who.client)
		return
	mouse_tracker = on_who.overlay_fullscreen("rote_preview", /atom/movable/screen/fullscreen/cursor_catcher/rote_preview, 0)
	mouse_tracker.assign_to_mob(on_who)
	mouse_tracker.rote_action = src
	RegisterSignal(on_who, COMSIG_MOVABLE_MOVED, PROC_REF(on_caster_moved))
	rote.show_target_previews(on_who, get_turf(on_who), null)

/datum/action/innate/rote/unset_ranged_ability(mob/living/on_who, text_to_show)
	if (mouse_tracker)
		on_who.clear_fullscreen("rote_preview", animated = FALSE)
		mouse_tracker = null
	UnregisterSignal(on_who, COMSIG_MOVABLE_MOVED)
	if (rote)
		rote.clear_target_previews(on_who)
	. = ..()
	if (rote?.is_awaiting_target())
		rote.cancel_cast()

// Called by the rote when execution suspends on a node that needs a crosshair target
/datum/action/innate/rote/proc/begin_targeting(datum/magick_context/context)
	var/mob/living/user = owner || context.caster
	if (isnull(user))
		rote.cancel_cast()
		return
	var/node_id = rote.get_awaiting_target_node()
	var/datum/rote_node_data/node_data_entry = rote.node_data ? rote.node_data[node_id] : null
	enable_text = span_notice(MAGICK_TARGET_ENABLE_TEXT(node_data_entry?.label, rote.count_remaining_targets()))
	if (user.click_intercept == src)
		to_chat(user, enable_text)
		rote.show_target_previews(user, mouse_tracker?.given_turf || get_turf(user), mouse_tracker?.get_hovered_atom())
	else
		set_ranged_ability(user, enable_text)
	build_all_button_icons(UPDATE_BUTTON_STATUS)

// Leaves targeting mode without cancelling anything
/datum/action/innate/rote/proc/stop_targeting()
	if (owner && owner.click_intercept == src)
		unset_ranged_ability(owner, disable_text)
	build_all_button_icons(UPDATE_BUTTON_STATUS)

// Re-center previews whenever caster moves
/datum/action/innate/rote/proc/on_caster_moved(atom/source, atom/oldloc, dir, forced)
	SIGNAL_HANDLER
	if (!rote || !mouse_tracker)
		return
	rote.show_target_previews(source, mouse_tracker.given_turf, mouse_tracker.get_hovered_atom())

// Re-centers previews whenever cursor moves
/datum/action/innate/rote/proc/update_target_preview(turf/mouse_turf, atom/hovered_atom)
	if (!rote || !owner)
		return
	rote.show_target_previews(owner, mouse_turf, hovered_atom)

// Whether the caster can still cancel or force cast the spell
/datum/action/innate/rote/proc/can_cancel_or_force()
	if (!rote || !owner || !ROTE_IS_CASTING(rote))
		return FALSE
	// Only the rote currently being focused on can be cancelled or force cast
	var/datum/splat/mage/mage_splat = get_mage_splat(owner)
	return mage_splat?.active_rote == rote \
		&& !rote.active_context.has_consumed_successes \
		&& rote.active_context.status == ROTE_NOT_INTERRUPTED

/datum/action/innate/rote/proc/get_desc()
	PRIVATE_PROC(TRUE)
	var/rote_desc = rote?.desc || ""
	// Only show click controls while the spell is being focused on
	if (!can_cancel_or_force())
		desc = rote_desc
		return
	var/front = "\[LMB\] Cancel | \[RMB\] Force Cast"
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

	// Clicking the action again while picking a target cancels the cast
	if (rote.is_awaiting_target())
		rote.cancel_cast()
		return TRUE

	if (ROTE_IS_CASTING(rote))
		// Only the rote currently being focused on responds to cancel/force cast
		if (can_cancel_or_force())
			// Right-clicking or using the hotkey (clicker is null) force casts
			var/force_cast = !!(trigger_flags & TRIGGER_SECONDARY_ACTION) || isnull(clicker)
			if (force_cast)
				rote.active_context.status = ROTE_INTERRUPT_FORCE_CAST
				to_chat(user, span_notice("You force the spell to completion."))
			else
				rote.active_context.status = ROTE_INTERRUPT_CANCEL
				to_chat(user, span_notice("You stop focusing on your spell."))
		return TRUE

	// Only one rote may be cast at a time, so cancel any other casts
	var/datum/splat/mage/mage_splat = get_mage_splat(user)
	if (mage_splat?.active_rote)
		mage_splat.active_rote.cancel_cast()

	// Executes the stack until finished, or until a source node suspends it for target selection
	rote.pre_cast(user)
	return TRUE

/datum/action/innate/rote/do_ability(mob/living/clicker, atom/clicked_on)
	if (!rote)
		return FALSE

	var/mob/user = clicker || owner
	if (isnull(user))
		return FALSE
	// Nothing is waiting on a target
	if (!rote.is_awaiting_target())
		unset_ranged_ability(user)
		return FALSE

	var/datum/magick_context/context = rote.active_context
	var/node_id = rote.get_awaiting_target_node()
	var/datum/rote_node_data/node_data_entry = rote.node_data ? rote.node_data[node_id] : null
	var/datum/rote_node/source/node = node_data_entry?.node
	if (!istype(node))
		rote.cancel_cast()
		return FALSE

	if (!node.is_valid_target(clicked_on, user))
		to_chat(user, span_warning("That is not a valid target for [node.name]."))
		return TRUE

	var/atom/target = node.get_clicked_target(clicked_on, user)
	if (!target)
		to_chat(user, span_warning("That is not a valid target for [node.name]."))
		return TRUE

	// Assign the target to the suspended node, which re-executes from the front of the stack
	node.push_target(context, node_id, target)
	// Clear the awaiting state first so leaving targeting mode does not cancel the cast
	context.status = ROTE_NOT_INTERRUPTED
	unset_ranged_ability(user)
	build_all_button_icons(UPDATE_BUTTON_STATUS)
	rote.resume_cast(context)
	return TRUE

/datum/action/innate/rote/Remove(mob/removed_from)
	if (removed_from.click_intercept == src)
		unset_ranged_ability(removed_from)
	if (rote)
		rote.cancel_cast()
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

/// ----------------------------------------------------------------------------

// Temporarily putting this here, TODO: will move this somewhere else eventually

/atom/movable/screen/fullscreen/cursor_catcher/rote_preview
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	var/datum/action/innate/rote/rote_action

/atom/movable/screen/fullscreen/cursor_catcher/rote_preview/proc/get_hovered_atom()
	if (!given_turf)
		return null
	var/atom/topmost = given_turf
	for (var/atom/atom_on_turf as anything in given_turf)
		if (atom_on_turf.mouse_opacity == MOUSE_OPACITY_TRANSPARENT || atom_on_turf.invisibility)
			continue
		if (atom_on_turf.layer > topmost.layer)
			topmost = atom_on_turf
	return topmost

/atom/movable/screen/fullscreen/cursor_catcher/rote_preview/MouseMove(location, control, params)
	. = ..()
	if (usr != owner)
		return
	calculate_params()
	rote_action?.update_target_preview(given_turf, get_hovered_atom())

/atom/movable/screen/fullscreen/cursor_catcher/rote_preview/Click(location, control, params)
	if (usr != owner)
		return
	calculate_params()
	var/atom/clicked = get_hovered_atom()
	if (!clicked)
		return
	owner.ClickOn(clicked, params)

/// ----------------------------------------------------------------------------

// Temporarily putting this here, TODO: will move this somewhere else eventually
/datum/storyteller_roll/arete
	numerical = TRUE
	roll_output_type = ROLL_PRIVATE
	applicable_stats = list(STAT_ARETE)
	var/auto_successes = 0

/datum/storyteller_roll/arete/calculate_auto_successes(mob/living/roller)
	. = ..() + auto_successes
