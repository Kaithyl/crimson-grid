// Abstract class for true magick spells
/datum/action/innate/rote

	click_action = TRUE
	ranged_mousepointer = 'icons/effects/mouse_pointers/weapon_pointer.dmi'
	enable_text = span_notice("Select a target for your effect.")
	disable_text = span_notice("You cancel your effect.")
	check_flags = AB_CHECK_CONSCIOUS

	// TODO: Make an actual rote class so this only needs to hold that

	// Effect components
	// TODO: Instruments used for casting
	var/list/datum/magick_focus/foci
	// Root nodes of the effect tree (node ids)
	var/list/root_nodes
	// alist<node_id, alist<output_port_key, list<list(out_port_key, in_port_key, child_node_id)>>>
	var/alist/effect_graph
	// alist<node_id, /datum/magick_node_data>
	// Per-node userdata configured in the rote builder
	var/alist/node_data
	// String format of effect graph for loading into UI
	var/rote_code

	// Casting
	// Root node ids still awaiting target selection via crosshair
	var/list/pending_target_nodes

	// TODO: Make this right clickable icons on the action to toggle on/off
	var/willpower_auto_success = FALSE
	var/quint_diff_reduction = 0

	var/complexity
	var/spheres

	var/expected_success_cost = 0
	var/expected_quint_cost = 0

/datum/action/innate/rote/Trigger(mob/clicker, trigger_flags)
	// datum/action requires parent function to be called
	// so temporarily setting click_action to false to avoid blocking
	var/click_action_was = click_action
	click_action = FALSE
	. = ..()
	click_action = click_action_was
	if(!.)
		return FALSE

	// If using hotkey this is called with a null clicker, so fall back to owner
	var/mob/user = clicker || owner
	if (isnull(user))
		return FALSE

	// If already in targeting mode, toggle off
	if (click_action && owner?.click_intercept == src)
		unset_ranged_ability(user, disable_text)
		pending_target_nodes = null
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return TRUE

	// Determine which root nodes need target selection
	var/list/needs_selection = list()
	for (var/node_id as anything in root_nodes)
		var/datum/magick_node_data/node_data_entry = node_data ? node_data[node_id] : null
		var/datum/magick_effect/root/node = node_data_entry?.effect
		if (node?.needs_crosshair)
			needs_selection += node_id

	if (length(needs_selection))
		// Enter ranged targeting mode with crosshair cursor
		pending_target_nodes = needs_selection
		var/first_id = needs_selection[1]
		var/datum/magick_node_data/first_data = node_data ? node_data[first_id] : null
		enable_text = span_notice(MAGICK_TARGET_ENABLE_TEXT(first_data?.label, length(pending_target_nodes)))
		set_ranged_ability(user, enable_text)
		build_all_button_icons(UPDATE_BUTTON_STATUS)
		return TRUE

	// All nodes are self-select, cast directly without targeting mode
	Cast(user)
	return TRUE

/datum/action/innate/rote/do_ability(mob/living/clicker, atom/clicked_on)
	var/mob/user = clicker || owner
	if (isnull(user))
		return FALSE
	if (!length(pending_target_nodes))
		unset_ranged_ability(user)
		return FALSE

	var/node_id = pending_target_nodes[1]
	var/datum/magick_node_data/node_data_entry = node_data ? node_data[node_id] : null
	var/datum/magick_effect/root/node = node_data_entry?.effect
	if (!node)
		pending_target_nodes -= node_id
		return TRUE

	if (!node.is_valid_target(clicked_on, user))
		to_chat(user, span_warning("That is not a valid target for [node.name]."))
		return TRUE

	// Assign the clicked atom as the target for the next pending root node
	pending_target_nodes -= node_id
	node_data_entry.target = clicked_on

	if (length(pending_target_nodes))
		to_chat(user, span_notice(MAGICK_TARGET_ENABLE_TEXT(node_data_entry?.label, length(pending_target_nodes))))
		return TRUE

	// Cast when all targets have been assigned
	unset_ranged_ability(user)
	Cast(user)
	return TRUE

/datum/action/innate/rote/proc/clear()
	root_nodes = null
	effect_graph = null
	node_data = null

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
	for (var/node_id as anything in root_nodes)
		var/datum/magick_node_data/node_data_entry = node_data ? node_data[node_id] : null
		var/datum/magick_effect/root/node = node_data_entry?.effect
		if (!node)
			continue
		var/target = node.resolve_target(clicker)
		if (target)
			node_data_entry.target = target

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

	var/datum/storyteller_roll/arete = new()
	arete.bumper_text = name
	arete.numerical = TRUE
	arete.roll_output_type = ROLL_PRIVATE
	arete.difficulty = difficulty
	//arete.spammy_roll = TRUE
	arete.applicable_stats = list(STAT_ARETE)

	var/successes = arete.st_roll(clicker, clicker, auto_successes)

	var/datum/magick_context/context = new()
	context.caster = clicker
	context.successes = successes
	context.effect_graph = effect_graph
	context.node_data = node_data

	var/list/visited = list()
	for (var/node_id as anything in root_nodes)
		prefill_node_ports(node_id, context, visited)

	// Cast each root node with its assigned target
	for (var/node_id as anything in root_nodes)
		context.current_node_id = node_id
		var/datum/magick_effect/root/node = context.get_effect(node_id)
		node.__cast(context)

/datum/action/innate/rote/proc/prefill_node_ports(node_id, datum/magick_context/context, list/visited)
	PRIVATE_PROC(TRUE)
	if (node_id in visited)
		return
	visited += node_id

	var/datum/magick_node_data/node_data_entry = context.node_data ? context.node_data[node_id] : null
	var/datum/magick_effect/effect = node_data_entry?.effect
	if (!effect)
		return

	context.current_node_id = node_id
	if (node_data_entry.port_values)
		var/alist/input_defs = effect.inputs
		for (var/port_key as anything in input_defs)
			var/value = node_data_entry.port_values["port_[port_key]"]
			if (value != null && context.get(port_key) == null)
				var/alist/def = input_defs[port_key]
				if (def["type"] & MAGICK_DATATYPE_NUMBER)
					context.assign(port_key, text2num(value), def["type"])
				else
					context.assign(port_key, value, def["type"])

	var/alist/effect_edges = context.effect_graph ? context.effect_graph[node_id] : null
	if (effect_edges)
		for (var/out_port_key as anything in effect_edges)
			var/list/connections = effect_edges[out_port_key]
			for (var/list/tuple as anything in connections)
				var/child_id = tuple[3]
				prefill_node_ports(child_id, context, visited)
