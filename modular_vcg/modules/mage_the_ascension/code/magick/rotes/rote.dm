/datum/magick_rote
	var/name
	var/desc

	var/datum/action/innate/rote/action

	// Compressed rote json using lz-string uri-safe
	var/rote_code

	// Sphere requirements to cast this rote
	var/alist/spheres
	// Highest sphere dots used by this rote
	var/highest_sphere

	/// Casting
	// context of current spell requiring instruments
	var/datum/magick_context/active_context
	// Tile preview images shown to the caster while targeting
	var/list/preview_images

	// TODO: Make this clickable icons on the action to toggle on/off
	var/willpower_auto_success = FALSE
	var/quint_diff_reduction = 0

	var/expected_success_cost = 0
	var/expected_quint_cost = 0

	/*
	 *	Compiled rote data
	 */
	// Root node ids
	var/list/source_nodes
	// alist <node_id, alist<output_port_key, list<list(out_port_key, in_port_key, child_node_id)>>>
	var/alist/rote_graph
	// alist <node_id, alist<input_port_key, list<list(out_port_key, in_port_key, source_node_id)>>>
	var/alist/rote_graph_reverse
	// Per-node userdata configured in the rote builder
	// alist <node_id, /datum/rote_node_data>
	var/alist/node_data
	// alist<node_id, alist<port_key, magick_value>>
	var/alist/port_values = new()

	/*	ROTE_EXECUTION_DATA = list<alist<"id" = node_id, "scope" = magick_scope, "success" = successes allocated>>
	 *	Execution signals are breadth-first and go to the back
	 *	Data updates are depth-first and go to the front
	 */
	var/list/execution_stack

/datum/magick_rote/Destroy()
	if (action)
		action.rote = null
		action = null
	clear()
	return ..()

/datum/magick_rote/proc/clear()
	source_nodes = null
	execution_stack = null
	rote_graph = null
	rote_graph_reverse = null
	port_values = null
	node_data = null
	preview_images = null

/datum/magick_rote/proc/set_port_value(node_id, port, value, type_flags)
	var/alist/node_values = port_values[node_id]
	if (node_values == null)
		node_values = new()
		port_values[node_id] = node_values
	node_values[port] = new /datum/magick_value(value, type_flags)

// Whether the cast is suspended waiting for the caster to pick a target
/datum/magick_rote/proc/is_awaiting_target()
	return ROTE_IS_CASTING(src) && active_context.status == ROTE_AWAITING_TARGET

// The suspended node is always re-queued at the front of the stack
/datum/magick_rote/proc/get_awaiting_target_node()
	if (!is_awaiting_target() || !length(active_context.execution_stack))
		return null
	var/alist/task = active_context.execution_stack[1]
	return task["id"]

/datum/magick_rote/proc/count_remaining_targets()
	if (!ROTE_IS_CASTING(src))
		return 0
	var/count = 0
	for (var/node_id as anything in node_data)
		var/datum/rote_node_data/node_data_entry = node_data[node_id]
		var/datum/rote_node/source/node = node_data_entry?.node
		if (!istype(node) || !isnull(active_context.read(node_id, node.out_value)))
			continue
		if (node.requires_crosshair(active_context, node_id))
			count++
	return max(count, 1)

/datum/magick_rote/proc/show_target_previews(mob/caster, turf/mouse_turf, atom/hovered_atom)
	clear_target_previews(caster)
	var/node_id = get_awaiting_target_node()
	if (isnull(node_id))
		return
	var/datum/rote_node_data/node_data_entry = node_data ? node_data[node_id] : null
	var/datum/rote_node/source/node = node_data_entry?.node
	if (!istype(node))
		return
	var/atom/origin = node.get_preview_origin(caster, mouse_turf, hovered_atom)
	if (!origin)
		return
	node.show_target_preview(src, active_context, node_id, caster, origin)

/datum/magick_rote/proc/clear_target_previews(mob/caster)
	if (!length(preview_images))
		return
	if (caster?.client)
		caster.client.images -= preview_images
	preview_images = null

/datum/magick_rote/proc/pre_cast(mob/clicker)
	var/datum/splat/mage/mage_splat = get_mage_splat(clicker)

	if (!mage_splat)
		return FALSE

	// Push promises
	for (var/node_id as anything in node_data)
		var/datum/rote_node_data/node_data_entry = node_data[node_id]
		var/datum/rote_node/node = node_data_entry?.node
		if (!node)
			continue
		var/alist/in_edges = rote_graph_reverse ? rote_graph_reverse[node_id] : null
		for (var/port_key as anything in node.inputs)
			if (in_edges?[port_key])
				continue
			var/alist/def = node.inputs[port_key]
			if (def["promise"] == "caster")
				set_port_value(node_id, port_key, clicker, def["type"])

	// var/datum/magick_context/context = new(execution_stack.Copy(), port_values.Copy())
	// Make a deep copy to avoid accidentally editing write-once data
	var/list/execution_stack_copy = list()
	for (var/alist/task as anything in execution_stack)
		execution_stack_copy += list(task.Copy())

	var/alist/port_values_copy = alist()
	for (var/node_id as anything in port_values)
		var/alist/node_values = port_values[node_id]
		var/alist/node_values_copy = alist()
		for (var/port as anything in node_values)
			var/datum/magick_value/payload = node_values[port]
			node_values_copy[port] = payload ? new /datum/magick_value(payload.value, payload.type_flags) : null
		port_values_copy[node_id] = node_values_copy

	var/datum/magick_context/context = new(execution_stack_copy, port_values_copy)
	context.caster = clicker
	context.mage_splat = mage_splat
	context.willpower_auto_success = willpower_auto_success
	context.quint_diff_reduction = quint_diff_reduction

	// Pass precompiled execution data by ref
	context.rote_graph = rote_graph
	context.rote_graph_reverse = rote_graph_reverse
	context.node_data = node_data

	// TEMP
	context.debug = TRUE

	// TEMP - Lock casting to this rote until arete has been rolled
	active_context = context
	mage_splat.set_active_rote(src)
	action?.build_all_button_icons(UPDATE_BUTTON_OVERLAY)

	return resume_cast(context)

/datum/magick_rote/proc/resume_cast(datum/magick_context/context)
	context.status = ROTE_NOT_INTERRUPTED
	cast(context)

	if (context.status == ROTE_AWAITING_TARGET && active_context == context)
		action?.begin_targeting(context)
		return FALSE

	return finish_cast(context)

/datum/magick_rote/proc/cancel_cast()
	if (!ROTE_IS_CASTING(src))
		return
	var/datum/magick_context/context = active_context
	var/was_awaiting = context.status == ROTE_AWAITING_TARGET
	context.status = ROTE_INTERRUPT_CANCEL
	if (was_awaiting)
		action?.stop_targeting()
		finish_cast(context)

/datum/magick_rote/proc/finish_cast(datum/magick_context/context)
	// TEMP - The spell counts as cast once arete has been rolled
	if (active_context == context)
		active_context = null
	var/datum/splat/mage/mage_splat = context.mage_splat
	if (mage_splat?.active_rote == src)
		mage_splat.set_active_rote(null)
	action?.build_all_button_icons(UPDATE_BUTTON_OVERLAY | UPDATE_BUTTON_STATUS)

	if (context.status != ROTE_NOT_INTERRUPTED)
		return FALSE
	return TRUE
