/datum/rote_node/iterate_list
	name = "Iterate (List)"
	desc = "Perform a for each loop over a list of targets."
	tags = MAGICK_TAG_DATA
	max_nodes = 1

	var/in_targets = "in_targets"
	var/out_act_loop = "out_act_loop"
	var/out_target = "out_target"

	inputs = new(
		in_act = MAGICK_PORT_ACTIVATE,
		in_targets = MAGICK_PORT_TARGETS,
	)
	outputs = new(
		out_act = MAGICK_PORT_ACTIVATE,
		out_act_loop = alist("name" = "Loop", "type" = MAGICK_DATATYPE_TRIGGER),
		out_target = MAGICK_PORT_TARGET,
	)

/datum/rote_node/iterate_list/execute(datum/magick_context/context)
	var/list/targets = context.get_value(in_targets)

	for(var/i = 1 to min(length(targets), ROTE_FOR_LOOP_MAX_LIST))
		// Briefly enter a new execution scope and pass port values to it
		context.push_scope()
		context.assign(out_target, targets[i])
		context.assign(out_act_loop, TRUE, MAGICK_DATATYPE_TRIGGER)
		context.pop_scope()

	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)

/datum/rote_node/source/lists/
	abstract_type = /datum/rote_node/source/lists/
	tags = MAGICK_TAG_DATA
	complexity = 0

	inputs = new()

	var/val_type
	var/val_id
	var/val_name

	var/out_list = "out_list"
	extendable_ports = new()

/datum/rote_node/source/lists/New()
	. = ..()
	if(!val_id)
		return

	for(var/i = 0 to ROTE_NODE_MAX_LIST_SIZE)
		inputs[val_id+num2text(i)] = alist("name" = val_name, "type" = val_type, "optional" = TRUE, "manual" = TRUE)

	extendable_ports[val_id] = alist("min" = 1, "max" = ROTE_NODE_MAX_LIST_SIZE, "default" = 3)

/datum/rote_node/source/lists/execute(datum/magick_context/context)
	var/list/values = list()
	for (var/port_key as anything in inputs)
		var/value = context.get_value(port_key)
		if (value != null)
			values += new /datum/magick_value(value, val_type)
	context.assign(out_list, values)

	if (outputs?[out_act])
		context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)

/datum/rote_node/source/lists/strings
	name = "List (Text)"

	val_type = MAGICK_DATATYPE_STRING | MAGICK_DATATYPE_FLAG_SINGLE
	val_id = "in_string"
	val_name = "Text"

	outputs = new(
		out_list = alist("name" = "Text", "type" = MAGICK_DATATYPE_STRING | MAGICK_DATATYPE_FLAG_LIST),
	)

// List random pick

/datum/rote_node/list_random_pick
	name = "Pick Random (List)"
	desc = "Pick a random value from a list."
	tags = MAGICK_TAG_DATA

	var/in_list = "in_list"
	var/out_value = "out_value"

	inputs = new(
		in_act = MAGICK_PORT_ACTIVATE,
		in_list = alist("name" = "List", "type" = MAGICK_DATATYPE_ANY | MAGICK_DATATYPE_FLAG_LIST),
	)
	outputs = new(
		out_act = MAGICK_PORT_ACTIVATE,
		out_value = alist("name" = "Value", "type" = MAGICK_DATATYPE_ANY | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/list_random_pick/execute(datum/magick_context/context)
	var/list/values = context.get_value(in_list)
	if (!length(values))
		return

	var/datum/magick_value/picked = pick(values)
	context.assign(out_value, picked)
	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)
