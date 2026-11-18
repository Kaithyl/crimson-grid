// partial implementation of context vars are split between context.dm, execution.dm and scope.dm
/datum/magick_context
	VAR_PRIVATE/scope_id = 0
	var/datum/magick_scope/current_scope = new(0, null)

// Scopes are sub-contexts for split execution, like "for loop" or "while" nodes
/datum/magick_scope/
	var/id
	var/datum/magick_scope/parent
	// alist<magick_scope, TRUE/NULL>
	var/alist/children = new()
	// Successes allocated to this execution branch
	var/successes = 0
	// alist<node_id, alist<port_key, magick_value>>
	var/alist/port_values = new()

/datum/magick_scope/New(id, datum/magick_scope/parent)
	src.id = id
	src.parent = parent
	parent?.children[src] = TRUE

// Writes a port value to this scope and propagates it down to all children scopes
/datum/magick_scope/proc/set_port_value(node_id, port, payload)
	var/alist/node_values = port_values[node_id]
	if (node_values == null)
		node_values = new()
		port_values[node_id] = node_values
	node_values[port] = payload
	for (var/datum/magick_scope/child as anything in children)
		child.set_port_value(node_id, port, payload)

// Enter a new execution scope to handle split branches. Returns its ID.
/datum/magick_context/proc/push_scope()
	current_scope = new /datum/magick_scope(++scope_id, current_scope)
	return current_scope.id

// Context does not keep track of scope list, so cleanup will be handled by garbage collection
/datum/magick_context/proc/pop_scope()
	if (current_scope.parent == null)
		// TODO: Throw error message that root was being popped
		return
	var/datum/magick_scope/old = current_scope
	current_scope = old.parent
	old.parent = null
