// partial implementation of context vars are split between context.dm, execution.dm and scope.dm
/datum/magick_context
	/*
	 *	Vars that are copied from /datum/magick_rote
	 */
	var/list/execution_stack = new()
	var/alist/port_values

	/*
	 *	Direct refs to same vars held by the /datum/magick_rote
	 *	Please do not alter these vars during runtime
	 */
	var/alist/rote_graph
	var/alist/rote_graph_reverse
	var/alist/node_data

	/*
	 *	State-tracking vars
	 */
	var/current_node_id

	var/has_consumed_successes = FALSE
	var/status = ROTE_NOT_INTERRUPTED
	var/ritual_category

	var/alist/difficulty_mods = new()

// Queues to back of execution list
/datum/magick_context/proc/enqueue_stack(node_id, successes = 0)
	var/alist/task = ROTE_EXECUTION_DATA(node_id, current_scope, successes)
	execution_stack += list(task)

// Pushes to front of execution list
/datum/magick_context/proc/push_stack(node_id, successes = 0)
	var/alist/task = ROTE_EXECUTION_DATA(node_id, current_scope, successes)
	execution_stack.Insert(1, list(task))

// Pops from front of execution list
/datum/magick_context/proc/pop_stack()
	RETURN_TYPE(/alist)
	if (!length(execution_stack))
		return null
	var/alist/task = execution_stack[1]
	execution_stack.Cut(1, 2)
	return task

// Get port value from the current scope first
// if none, check each parent scope
/datum/magick_context/proc/read(node_id, port)
	RETURN_TYPE(/datum/magick_value)
	var/datum/magick_scope/scope = current_scope
	while (scope)
		var/datum/magick_value/payload = scope.port_values[node_id]?[port]
		if (payload != null)
			return payload
		scope = scope.parent
	return null

/datum/magick_context/proc/push_outputs(node_id)
	var/alist/edges = rote_graph ? rote_graph[node_id] : null
	if (!edges)
		return
	var/datum/rote_node/node = get_node(node_id)
	// alist<child_id, TRUE = back of queue / FALSE = front of queue>
	var/alist/queued = alist()
	for (var/out_port as anything in edges)
		var/alist/out_def = node?.outputs?[out_port]
		// Trigger ports are activated manually
		if (out_def != null && (out_def["type"] & MAGICK_DATATYPE_TRIGGER))
			continue
		var/datum/magick_value/payload = read(node_id, out_port)
		if (payload == null)
			continue
		for (var/list/tuple as anything in edges[out_port])
			var/in_port = tuple[2]
			var/child_id = tuple[3]
			var/datum/rote_node/child = get_node(child_id)
			var/alist/in_def = child?.inputs?[in_port]
			if (in_def == null)
				continue
			current_node_id = child_id
			assign(in_port, payload)
			// Nodes that require activation are only queued when pulsed
			if (child.in_act in child.required_inputs)
				continue
			if (!(child_id in queued))
				queued[child_id] = FALSE
	current_node_id = node_id
	for (var/child_id as anything in queued)
		push_stack(child_id, current_scope.successes)

/datum/magick_rote/proc/cast(datum/magick_context/context)
	for (var/steps = 0 to ROTE_MAX_TRAVERSAL)
		if (context.status != ROTE_NOT_INTERRUPTED || !length(context.execution_stack))
			break

		var/alist/task = context.pop_stack()
		var/node_id = task["id"]
		var/datum/rote_node/node = context.get_node(node_id)
		if (!node)
			continue
		context.current_node_id = node_id
		context.current_scope.successes = task["success"]

		node.execute(context)

		//context.visited_nodes |= node_id
		//context.visited_node_types |= node.type

		if (context.debug)
			node.debug(context)

		if (!context.has_consumed_successes && istype(node, /datum/rote_node/effect/))
			var/datum/rote_node/effect/effect_node = node
			if (effect_node.min_success_cost > 0)
				context.has_consumed_successes = TRUE

		context.push_outputs(node_id)

