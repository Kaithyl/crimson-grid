// This holds the actual code execution per node and variables that should be treated as abstract static
/datum/rote_node/
	abstract_type = /datum/rote_node/

	var/name
	var/desc
	var/tags

	// Maximum number of this subtype of node allowed in a spell
	var/max_nodes

	// requires the caster to pick a target with a crosshair
	var/needs_crosshair = FALSE

	// How much complexity this node takes up
	var/complexity = 0

	// Sphere combinations for this node
	var/list/spheres

	/*
	 * Port system for nodes
	 */
	var/in_act = "in_act"
	var/out_act = "out_act"

	// Reference defines/../rote_builder/ports.dm
	var/alist/inputs
	var/alist/outputs

	// alist<id_prefix = alist("min" = 1, "max" = MAGICK_MAX_LIST_SIZE, "default" = 1)>
	// Port key = id_prefix + index
	var/alist/extendable_ports

	/*
	 *	These are set upon init to prevent redundant checking during runtime
	 */

	// whether this node has a trigger output port
	var/outputs_trigger_signal = FALSE

	// input port keys that are not optional nor have a default value
	var/list/required_inputs

GLOBAL_LIST_INIT_TYPED(rote_nodes, /datum/rote_node, init_subtypes_w_path_keys(/datum/rote_node, list()))
GLOBAL_LIST_INIT(rotebuilder_static_data, init_rotebuilder_static_data())

/*
 *	Must override this to implement node functionaltiy
 *	Use context.get_value() or context.get() to get input port vars
 *	and context.assign() to fill output ports
 */
/datum/rote_node/proc/execute(datum/magick_context/context)
	return

/datum/rote_node/New()
	. = ..()
	required_inputs = list()
	for (var/port_key as anything in inputs)
		var/alist/port_def = inputs[port_key]
		if ((!port_def) || port_def["optional"] || !isnull(port_def["default_value"]))
			continue
		required_inputs += port_key
	for (var/port_key as anything in outputs)
		var/alist/port_def = outputs[port_key]
		if (port_def != null && (port_def["type"] & MAGICK_DATATYPE_TRIGGER))
			outputs_trigger_signal = TRUE
			break

// If there are required inputs that have been filled with user values
/datum/rote_node/proc/has_required_values(alist/port_values)
	for (var/port_key as anything in required_inputs)
		// Player inputted value from the rote builder
		if (!isnull(port_values?["port_[port_key]"]))
			continue
		return FALSE
	return TRUE

// For UI
/proc/init_rotebuilder_static_data()
	var/list/data = list()
	var/list/nodes_list = list()

	for(var/node_path in GLOB.rote_nodes)
		var/datum/rote_node/node = GLOB.rote_nodes[node_path]
		if(!node)
			continue

		var/list/node_data = list(
			"name" = node.name,
			"desc" = node.desc,
			"type" = "[node.type]",
			"tags" = node.tags,
			"complexity" = node.complexity,
			"max_nodes" = node.max_nodes,
			"spheres" = node.spheres,
			"extendable_ports" = node.extendable_ports,
		)

		// Effect nodes
		if(istype(node, /datum/rote_node/effect))
			var/datum/rote_node/effect/effect_node = node
			node_data["quintessence"] = effect_node.quintessence
			node_data["min_success_cost"] = effect_node.min_success_cost
			node_data["can_add_success"] = effect_node.can_add_success
		else
			node_data["quintessence"] = 0
			node_data["min_success_cost"] = 0
			node_data["can_add_success"] = FALSE

		if(istype(node, /datum/rote_node/focus))
			var/datum/rote_node/focus/focus_node = node
			node_data["complexity_cap"] = focus_node.complexity_cap
		else
			node_data["complexity_cap"] = 0

		var/list/inputs_list = list()
		var/list/outputs_list = list()

		// Ports
		for(var/port_id as anything in node.inputs)
			var/alist/def = node.inputs[port_id]
			var/list/port_data = list(
				"id" = port_id,
				"name" = def["name"],
				"type" = def["type"],
				"desc" = def["desc"],
				"default_value" = def["default_value"],
				"optional" = def["optional"],
				"promise" = def["promise"],
				"manual" = def["manual"],
			)
			if (def["type"] & MAGICK_DATATYPE_NUMBER)
				if (def["min_clamp"] != null)
					port_data["min_clamp"] = def["min_clamp"]
				if (def["max_clamp"] != null)
					port_data["max_clamp"] = def["max_clamp"]
			if (def["whitelist"] != null)
				port_data["whitelist"] = def["whitelist"]
			UNTYPED_LIST_ADD(inputs_list, port_data)
		for(var/port_id as anything in node.outputs)
			var/alist/def = node.outputs[port_id]
			var/list/port_data = list(
				"id" = port_id,
				"name" = def["name"],
				"type" = def["type"],
				"desc" = def["desc"],
				"default_value" = def["default_value"],
				"manual" = def["manual"],
			)
			if (def["type"] & MAGICK_DATATYPE_NUMBER)
				if (def["min_clamp"] != null)
					port_data["min_clamp"] = def["min_clamp"]
				if (def["max_clamp"] != null)
					port_data["max_clamp"] = def["max_clamp"]
			if (def["whitelist"] != null)
				port_data["whitelist"] = def["whitelist"]
			if (def["type"] & MAGICK_DATATYPE_PATTERN)
				port_data["size"] = def["size"]
			UNTYPED_LIST_ADD(outputs_list, port_data)

		node_data["inputs"] = inputs_list
		node_data["outputs"] = outputs_list

		nodes_list += list(node_data)

	data["nodes"] = nodes_list
	return data
