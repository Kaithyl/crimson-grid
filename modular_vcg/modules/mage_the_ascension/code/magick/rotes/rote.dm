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
	// Root node ids still awaiting target selection via crosshair
	var/list/pending_target_nodes
	// context of current spell requiring instruments
	var/datum/magick_context/active_context

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

/datum/magick_rote/proc/set_port_value(node_id, port, value, type_flags)
	var/alist/node_values = port_values[node_id]
	if (node_values == null)
		node_values = new()
		port_values[node_id] = node_values
	node_values[port] = new /datum/magick_value(value, type_flags)

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

	// Push input nodes
	for (var/node_id as anything in source_nodes)
		var/datum/rote_node_data/node_data_entry = node_data ? node_data[node_id] : null
		var/datum/rote_node/source/node = node_data_entry?.node
		if (!istype(node))
			continue
		var/target = node.resolve_target(clicker)
		if (target)
			node.push_target(src, node_id, target)

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

	cast(context)

	// TEMP - The spell counts as cast once arete has been rolled
	active_context = null
	if (mage_splat.active_rote == src)
		mage_splat.set_active_rote(null)
	action?.build_all_button_icons(UPDATE_BUTTON_OVERLAY)

	if (context.status != ROTE_NOT_INTERRUPTED)
		return FALSE
