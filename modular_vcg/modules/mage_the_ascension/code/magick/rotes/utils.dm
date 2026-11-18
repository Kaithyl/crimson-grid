// Helper functions
// TODO: Move more mage defines into here?

// Returns a tuple (alist(rote_data), failure_message)
/proc/compile_rote(mob/living/user, rote_rawdata)
	RETURN_TYPE(/list)

	var/list/parsed = json_decode(rote_rawdata)
	if(!istype(parsed) || !islist(parsed["nodes"]) || !islist(parsed["connections"]))
		return list(null, "rote data has no 'nodes'/'connections' lists (raw: [copytext(rote_rawdata, 1, 256)])")

	var/list/nodes = GLOB.rotebuilder_static_data["nodes"]
	var/list/type_counts = list()
	var/list/known_ids = list()
	var/list/types_by_id = list()
	var/list/node_instances = list()
	var/list/connected_inputs = list()
	// "[node_id]:[port_key]"
	var/list/connected_ports = list()
	var/list/source_nodes = list()
	var/alist/port_values = new()
	var/list/raw_port_values = list()
	// alist<node_id, alist<output_port_key, list<list(out_port_key, in_port_key, child_node_id)>>>
	var/alist/rote_graph = new()
	// alist<node_id, alist<input_port_key, list<list(out_port_key, in_port_key, source_node_id)>>>
	var/alist/rote_graph_reverse = new()
	var/alist/node_data = new()
	// alist<sphere, highest level used>
	var/alist/rote_spheres = new()
	var/highest_sphere = 0
	var/complexity_sum = 0
	var/expected_success_cost = 0
	var/expected_quint_cost = 0
	var/cast_count = 0
	var/node_count = 0

	for(var/list/node in parsed["nodes"])
		if(!islist(node))
			return list(null, "node #[node_count + 1] is not a list: [json_encode(node)]")

		node_count++
		if(node_count > ROTE_MAX_NODES)
			return list(null, "node count [node_count] exceeds max of ([ROTE_MAX_NODES])")

		var/id = "[node["id"]]"
		if(!length(id) || known_ids[id])
			return list(null, "node #[node_count] has invalid/duplicate id '[id]'")
		known_ids[id] = TRUE

		var/type_index = isnum(node["type_index"]) ? round(node["type_index"]) : text2num("[node["type_index"]]")
		if(isnull(type_index) || type_index < 1 || type_index > length(nodes))
			return list(null, "node #[node_count] (id '[id]') has out of range type_index '[type_index]' (nodes: [length(nodes)])")

		var/list/node_def = nodes[type_index]
		types_by_id[id] = node_def

		// Check if per-type max nodes
		var/max_nodes = node_def["max_nodes"]
		if(max_nodes)
			if((type_counts[node_def["type"]] || 0) >= max_nodes)
				return list(null, "node #[node_count] (id '[id]') exceeds max_nodes [max_nodes] for node '[node_def["name"]]'")
			type_counts[node_def["type"]] = (type_counts[node_def["type"]] || 0) + 1

		// Check sphere requirements
		var/list/options = node_def["spheres"]
		if(options)
			var/sphere_index = isnum(node["sphere_index"]) ? round(node["sphere_index"]) : text2num("[node["sphere_index"]]")
			// Default to the first option if the client omitted the index
			if(isnull(sphere_index))
				sphere_index = 1
			var/spheres_met = FALSE
			if(sphere_index >= 1 && sphere_index <= length(options))
				ROTE_SPHERES_VALID(user, options[sphere_index], spheres_met)
			if(sphere_index < 1 || sphere_index > length(options) || !spheres_met)
				return list(null, "node #[node_count] (id '[id]', node '[node_def["name"]]') failed sphere requirements (sphere_index '[sphere_index]', options: [json_encode(options)])")

			// calculate spheres used
			for (var/sphere as anything in options[sphere_index])
				var/level = options[sphere_index][sphere]
				if (rote_spheres[sphere] == null || level > rote_spheres[sphere])
					rote_spheres[sphere] = level
				highest_sphere = max(highest_sphere, level)

		// Resolve the node singleton
		var/node_type = text2path(node_def["type"])
		var/datum/rote_node/node_singleton = GLOB.rote_nodes[node_type]
		if(!node_singleton)
			return list(null, "node #[node_count] (id '[id]') has unknown node type '[node_def["type"]]'")

		// Build per-node data
		var/datum/rote_node_data/node_data_entry = new()
		node_data_entry.node = node_singleton
		if(node["port_values"])
			raw_port_values[id] = node["port_values"]
		if(node["userdata"])
			var/list/userdata = node["userdata"]
			node_data_entry.label = userdata["label"]
			node_data_entry.success_percentage = userdata["success_percentage"]
			node_data_entry.min_success = userdata["min_success"]
			node_data_entry.max_success = userdata["max_success"]
			if(islist(userdata["port_counts"]))
				node_data_entry.port_counts = userdata["port_counts"]
		node_data[id] = node_data_entry

		node_instances[id] = node_singleton

		if(node_def["tags"] & MAGICK_TAG_RITUAL)
			cast_count++

		complexity_sum += node_def["complexity"]
		expected_success_cost += node_def["min_success_cost"]
		expected_quint_cost += node_def["quintessence"]

	if(!cast_count)
		return list(null, "rote has no cast node")

	// Build connections
	for(var/list/connection in parsed["connections"])
		if(!islist(connection))
			return list(null, "connection is not a list: [json_encode(connection)]")

		var/out_id = "[connection["out_id"]]"
		var/in_id = "[connection["in_id"]]"
		var/out_key = "[connection["out_port"]]"
		var/in_key = "[connection["in_port"]]"
		if(!known_ids[out_id] || !known_ids[in_id] || !length(out_key) || !length(in_key))
			return list(null, "connection out_id '[out_id]' -> in_id '[in_id]' (out_port '[out_key]', in_port '[in_key]') references unknown nodes or empty ports")

		var/datum/rote_node/source = node_instances[out_id]
		var/datum/rote_node/target = node_instances[in_id]

		var/alist/source_outputs = source.outputs
		var/alist/target_inputs = target.inputs
		var/alist/out_port_data = source_outputs ? source_outputs[out_key] : null
		var/alist/in_port_data = target_inputs ? target_inputs[in_key] : null
		if(out_port_data == null || in_port_data == null)
			return list(null, "connection out_id '[out_id]' (port '[out_key]') -> in_id '[in_id]' (port '[in_key]') references unknown ports")

		if(!MAGICK_DATATYPES_VALID(out_port_data["type"], in_port_data["type"]))
			return list(null, "connection out_id '[out_id]' (port '[out_key]', '[out_port_data["name"]]', type [out_port_data["type"]]) -> in_id '[in_id]' (port '[in_key]', '[in_port_data["name"]]', type [in_port_data["type"]]) has incompatible port types")

		connected_inputs[in_id] = TRUE
		connected_ports["[in_id]:[in_key]"] = TRUE

		// Build the effect graph dictionary
		if(!rote_graph[out_id])
			rote_graph[out_id] = alist()
		if(!rote_graph[out_id][out_key])
			rote_graph[out_id][out_key] = list()
		rote_graph[out_id][out_key] += list(list(out_key, in_key, in_id))

		if(!rote_graph_reverse[in_id])
			rote_graph_reverse[in_id] = alist()
		if(!rote_graph_reverse[in_id][in_key])
			rote_graph_reverse[in_id][in_key] = list()
		rote_graph_reverse[in_id][in_key] += list(list(out_key, in_key, out_id))

	// Root nodes are nodes with no parents whose ports are all filled
	for(var/id in known_ids)
		if(connected_inputs[id])
			continue
		var/datum/rote_node/source_singleton = node_instances[id]
		if(!length(source_singleton?.required_inputs) || source_singleton?.has_required_values(raw_port_values[id]))
			source_nodes += id

	if(!length(source_nodes))
		return list(null, "rote has no source nodes")

	// Check for islands
	for(var/id in known_ids)
		if(connected_inputs[id])
			continue

		var/datum/rote_node/node_singleton = node_instances[id]
		if(!length(node_singleton?.required_inputs) || node_singleton?.has_required_values(raw_port_values[id]))
			continue

		var/list/node_def = types_by_id[id]
		var/list/inputs = node_def["inputs"]
		var/has_required_input = FALSE
		for(var/list/input_data in inputs)
			if(input_data["default_value"] == null && !input_data["optional"])
				has_required_input = TRUE
				break

		if(has_required_input)
			return list(null, "node '[id]' ('[node_def["name"]]') is unreachable but has required inputs")

	// Every required input port must be wired or given a value
	// Logic should mirror RoteBuilder/lib/validator.ts/validateRote()
	for(var/id in known_ids)
		var/datum/rote_node/node_singleton = node_instances[id]
		var/alist/input_defs = node_singleton?.inputs
		if(!input_defs)
			continue
		for(var/port_key as anything in input_defs)
			var/alist/port_def = input_defs[port_key]
			if(port_def == null)
				continue
			if(port_def["type"] & MAGICK_DATATYPE_TRIGGER)
				continue
			// A port with a default value or marked optional is not required
			if(!isnull(port_def["default_value"]) || port_def["optional"])
				continue
			// Wired
			if(connected_ports["[id]:[port_key]"])
				continue
			// Player inputted value from the rote builder
			if(raw_port_values[id]?["port_[port_key]"] != null)
				continue
			var/list/node_def = types_by_id[id]
			return list(null, "node '[id]' ('[node_def["name"]]') is missing a required value for input '[port_def["name"]]'")

	// Foci reached after the arete roll are skipped and provide no complexity cap
	var/list/skipped_foci = list()
	var/cast_id
	for(var/id in known_ids)
		var/list/cast_def = types_by_id[id]
		if(cast_def["tags"] & MAGICK_TAG_RITUAL)
			cast_id = id
			break
	if(cast_id)
		var/list/queue = list()
		var/alist/cast_edges = rote_graph[cast_id]
		if(cast_edges && cast_edges["out_act_cast"])
			for(var/list/tuple in cast_edges["out_act_cast"])
				queue += tuple[3]
		var/list/visited = list()
		while(length(queue))
			var/cur = queue[1]
			queue.Cut(1, 2)
			if(visited[cur])
				continue
			visited[cur] = TRUE
			var/alist/edges = rote_graph[cur]
			if(edges)
				for(var/out_key in edges)
					for(var/list/tuple in edges[out_key])
						queue += tuple[3]
		for(var/id in visited)
			var/list/def = types_by_id[id]
			if(def["tags"] & MAGICK_TAG_FOCI)
				skipped_foci[id] = TRUE

	// Extended casting requires at least one focus in the foci chain
	if(cast_id)
		var/has_extend_value = raw_port_values[cast_id]?["port_in_succ"] != null
		var/has_extend_connection = connected_ports["[cast_id]:in_succ"]
		if(has_extend_value || has_extend_connection)
			var/list/foci_queue = list()
			var/alist/foci_edges = rote_graph[cast_id]
			if(foci_edges && foci_edges["out_act_foci"])
				for(var/list/tuple in foci_edges["out_act_foci"])
					foci_queue += tuple[3]
			var/list/foci_visited = list()
			var/has_foci = FALSE
			while(length(foci_queue))
				var/cur = foci_queue[1]
				foci_queue.Cut(1, 2)
				if(foci_visited[cur])
					continue
				foci_visited[cur] = TRUE
				var/list/def = types_by_id[cur]
				if(def["tags"] & MAGICK_TAG_FOCI)
					has_foci = TRUE
					break
				var/alist/edges = rote_graph[cur]
				if(edges)
					for(var/out_key in edges)
						for(var/list/tuple in edges[out_key])
							foci_queue += tuple[3]
			if(!has_foci)
				return list(null, "cast node '[cast_id]' is set to cast as extended but has no foci")

	// Count actual complexity cap
	var/max_complexity_sum = 0
	var/list/capped_types = list()
	for(var/id in known_ids)
		var/list/def = types_by_id[id]
		if(!(def["tags"] & MAGICK_TAG_FOCI))
			continue
		if(skipped_foci[id])
			continue
		if(capped_types[def["type"]])
			continue
		capped_types[def["type"]] = TRUE
		max_complexity_sum += def["complexity_cap"]

	if(complexity_sum > max_complexity_sum)
		return list(null, "rote complexity [complexity_sum] exceeds the maximum complexity [max_complexity_sum]")

	// Precompute the initial execution stack
	var/list/data_roots = list()
	var/list/trigger_roots = list()
	for(var/id in source_nodes)
		var/datum/rote_node/node = node_instances[id]
		if(node?.outputs_trigger_signal)
			trigger_roots += id
		else
			data_roots += id
	var/list/execution_stack = list()
	for(var/id in data_roots + trigger_roots)
		execution_stack += list(ROTE_EXECUTION_DATA(id, null, 0))

	// Precompute port values from user input
	for(var/id in known_ids)
		var/datum/rote_node/node = node_instances[id]
		if(!node)
			continue
		var/alist/in_edges = rote_graph_reverse[id]
		var/alist/raw_values = raw_port_values[id]
		for(var/port_key as anything in node.inputs)
			if(in_edges?[port_key])
				continue
			var/alist/def = node.inputs[port_key]
			var/value = raw_values ? raw_values["port_[port_key]"] : null
			if(value == null)
				continue
			if(def["type"] & MAGICK_DATATYPE_NUMBER)
				value = text2num(value)
			var/alist/node_values = port_values[id]
			if(node_values == null)
				node_values = new()
				port_values[id] = node_values
			node_values[port_key] = new /datum/magick_value(value, def["type"])

	return list(alist(
		"source_nodes" = source_nodes,
		"execution_stack" = execution_stack,
		"rote_graph" = rote_graph,
		"rote_graph_reverse" = rote_graph_reverse,
		"port_values" = port_values,
		"node_data" = node_data,
		"spheres" = rote_spheres,
		"highest_sphere" = highest_sphere,
		"complexity" = complexity_sum,
		"expected_success_cost" = expected_success_cost,
		"expected_quint_cost" = expected_quint_cost,
	), null)

// Returns appropriate type_flag for the value
/proc/magick_get_datatype(value)
	if(islist(value))
		. = MAGICK_DATATYPE_FLAG_LIST
		// TODO: Probably needs a more robust system for enforcing or checking monotype lists
		for(var/datum/magick_value/item in value)
			. |= item.type_flags
		// drop SINGLE flag
		. &= ~MAGICK_DATATYPE_FLAG_SINGLE
		return

	if(isnum(value))
		return MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE

	if(istext(value))
		return MAGICK_DATATYPE_STRING | MAGICK_DATATYPE_FLAG_SINGLE

	if(istype(value, /turf))
		return MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_SINGLE

	if(istype(value, /obj))
		return MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_SINGLE

	if(istype(value, /mob))
		return MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_SINGLE

	return MAGICK_DATATYPE_FLAG_SINGLE
