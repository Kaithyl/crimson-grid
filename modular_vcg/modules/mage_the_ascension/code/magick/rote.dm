/datum/magick_rote
	var/name
	var/desc

	// String format of effect graph for loading into UI
	var/rote_code

	// Effect components
	// Root nodes of the effect tree (node ids)
	var/list/root_nodes
	// alist<node_id, alist<output_port_key, list<list(out_port_key, in_port_key, child_node_id)>>>
	var/alist/effect_graph
	// alist<node_id, alist<input_port_key, list<list(out_port_key, in_port_key, source_node_id)>>>
	var/alist/reverse_graph
	// alist<node_id, /datum/rote_node_data>
	// Per-node userdata configured in the rote builder
	var/alist/node_data

	// Casting
	// Root node ids still awaiting target selection via crosshair
	var/list/pending_target_nodes
	// context of current spell requiring instruments
	var/datum/magick_context/active_context

	// TODO: Make this clickable icons on the action to toggle on/off
	var/willpower_auto_success = FALSE
	var/quint_diff_reduction = 0

	var/complexity
	var/spheres

	var/expected_success_cost = 0
	var/expected_quint_cost = 0

	// The action button that represents this rote
	var/datum/action/innate/rote/action

/datum/magick_rote/Destroy()
	if (action)
		action.rote = null
		action = null
	clear()
	return ..()

/datum/magick_rote/proc/clear()
	root_nodes = null
	effect_graph = null
	reverse_graph = null
	node_data = null

/datum/magick_rote/proc/Cast(mob/clicker)
	var/datum/splat/mage/mage_splat = get_mage_splat(clicker)

	if (!mage_splat)
		return FALSE

	// Auto-assign self-selecting root nodes
	for (var/node_id as anything in root_nodes)
		var/datum/rote_node_data/node_data_entry = node_data ? node_data[node_id] : null
		var/datum/rote_node/root/node = node_data_entry?.node
		if (!istype(node))
			continue
		var/target = node.resolve_target(clicker)
		if (target)
			node_data_entry.target = target

	var/datum/magick_context/context = new()
	context.caster = clicker
	context.mage_splat = mage_splat
	context.effect_graph = effect_graph
	context.reverse_graph = reverse_graph
	context.node_data = node_data
	context.willpower_auto_success = willpower_auto_success
	context.quint_diff_reduction = quint_diff_reduction

	// TEMP
	context.debug = TRUE

	for (var/node_id as anything in node_data)
		if (node_id in root_nodes)
			continue
		var/datum/rote_node_data/node_data_entry = node_data[node_id]
		var/datum/rote_node/node = node_data_entry?.node
		if (node?.can_cast_unprompted(node_data_entry))
			root_nodes += node_id

	var/list/visited = list()
	for (var/node_id as anything in root_nodes)
		prefill_node_ports(node_id, context, visited)

	// find root nodes without parents
	var/list/fed_roots = list()
	for (var/source_id as anything in effect_graph)
		var/alist/out_edges = effect_graph[source_id]
		for (var/out_port_key as anything in out_edges)
			for (var/list/tuple as anything in out_edges[out_port_key])
				fed_roots[tuple[3]] = TRUE

	// Lock casting to this rote until arete has been rolled
	active_context = context
	mage_splat.set_active_rote(src)
	action?.build_all_button_icons(UPDATE_BUTTON_OVERLAY)

	// Order root nodes so pure data nodes run first so other nodes aren't missing data inputs
	var/list/data_roots = list()
	var/list/trigger_roots = list()
	for (var/node_id as anything in root_nodes)
		if (fed_roots[node_id])
			continue
		var/datum/rote_node/node = context.get_node(node_id)
		if (!node)
			continue
		var/has_trigger_out = FALSE
		for (var/port_key as anything in node.outputs)
			var/alist/port_def = node.outputs[port_key]
			if (port_def != null && (port_def["type"] & MAGICK_DATATYPE_TRIGGER))
				has_trigger_out = TRUE
				break
		if (has_trigger_out)
			trigger_roots += node_id
		else
			data_roots += node_id

	// cast root nodes
	for (var/node_id as anything in data_roots + trigger_roots)
		context.current_node_id = node_id
		var/datum/rote_node/node = context.get_node(node_id)
		node.__cast(context)
		if (context.aborted || context.interrupted)
			break

	// The spell counts as cast once arete has been rolled
	active_context = null
	if (mage_splat.active_rote == src)
		mage_splat.set_active_rote(null)
	action?.build_all_button_icons(UPDATE_BUTTON_OVERLAY)

	if (context.aborted || context.interrupted)
		return FALSE

/datum/magick_rote/proc/prefill_node_ports(node_id, datum/magick_context/context, list/visited)
	PRIVATE_PROC(TRUE)
	if (node_id in visited)
		return
	visited += node_id

	var/datum/rote_node_data/node_data_entry = context.node_data ? context.node_data[node_id] : null
	var/datum/rote_node/effect/effect_node = node_data_entry?.node
	if (!effect_node)
		return

	context.current_node_id = node_id
	var/alist/in_edges = context.reverse_graph ? context.reverse_graph[node_id] : null
	var/alist/input_defs = effect_node.inputs
	for (var/port_key as anything in input_defs)
		if (context.get(port_key) != null)
			continue
		if (in_edges?[port_key])
			continue
		var/alist/def = input_defs[port_key]
		var/value = node_data_entry.port_values ? node_data_entry.port_values["port_[port_key]"] : null
		if (value != null)
			if (def["type"] & MAGICK_DATATYPE_NUMBER)
				context.assign(port_key, text2num(value), def["type"])
			else
				context.assign(port_key, value, def["type"])

		// Fullfill ports with promises
		else if (def["promise"] == "caster" && context.caster)
			context.assign(port_key, context.caster, def["type"])
		// TODO
		// else if def == caster direction
		// else if def == caster turf... etc

	var/alist/effect_edges = context.effect_graph ? context.effect_graph[node_id] : null
	if (effect_edges)
		for (var/out_port_key as anything in effect_edges)
			var/list/connections = effect_edges[out_port_key]
			for (var/list/tuple as anything in connections)
				var/child_id = tuple[3]
				prefill_node_ports(child_id, context, visited)

// Returns a tuple (built rote, optional failure message)
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
	// "[node_id]:[port_key]" for every wired input port
	var/list/connected_ports = list()
	var/list/root_nodes = list()
	// alist<node_id, alist<output_port_key, list<list(out_port_key, in_port_key, child_node_id)>>>
	var/alist/effect_graph = new()
	// alist<node_id, alist<input_port_key, list<list(out_port_key, in_port_key, source_node_id)>>>
	var/alist/reverse_graph = new()
	var/alist/node_data = new()
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

		// Resolve the node singleton
		var/node_type = text2path(node_def["type"])
		var/datum/rote_node/node_singleton = GLOB.rote_nodes[node_type]
		if(!node_singleton)
			return list(null, "node #[node_count] (id '[id]') has unknown node type '[node_def["type"]]'")

		// Build per-node data
		var/datum/rote_node_data/node_data_entry = new()
		node_data_entry.node = node_singleton
		if(node["port_values"])
			node_data_entry.port_values = node["port_values"]
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

		if(node_def["tags"] & MAGICK_TAG_CAST)
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
		if(!effect_graph[out_id])
			effect_graph[out_id] = alist()
		if(!effect_graph[out_id][out_key])
			effect_graph[out_id][out_key] = list()
		effect_graph[out_id][out_key] += list(list(out_key, in_key, in_id))

		if(!reverse_graph[in_id])
			reverse_graph[in_id] = alist()
		if(!reverse_graph[in_id][in_key])
			reverse_graph[in_id][in_key] = list()
		reverse_graph[in_id][in_key] += list(list(out_key, in_key, out_id))

	// Root nodes are nodes with no parents whose ports are all filled
	for(var/id in known_ids)
		if(connected_inputs[id])
			continue
		var/datum/rote_node/root_singleton = node_instances[id]
		if(root_singleton?.can_cast_unprompted(node_data[id]))
			root_nodes += id

	if(!length(root_nodes))
		return list(null, "rote has no root nodes")

	// Check for islands
	for(var/id in known_ids)
		if(connected_inputs[id])
			continue

		var/datum/rote_node/node_singleton = node_instances[id]
		if(node_singleton?.can_cast_unprompted(node_data[id]))
			continue

		var/list/node_def = types_by_id[id]
		var/list/inputs = node_def["inputs"]
		var/has_required_input = FALSE
		for(var/list/input_data in inputs)
			if(input_data["default_value"] == null)
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
		var/datum/rote_node_data/node_data_entry = node_data[id]
		for(var/port_key as anything in input_defs)
			var/alist/port_def = input_defs[port_key]
			if(port_def == null)
				continue
			// Trigger ports are activation ports and are optional
			if(port_def["type"] & MAGICK_DATATYPE_TRIGGER)
				continue
			// A port with a default value (including "" for optional ports) is not required
			if(!isnull(port_def["default_value"]))
				continue
			// Wired
			if(connected_ports["[id]:[port_key]"])
				continue
			// Player inputted value from the rote builder
			if(node_data_entry?.port_values?["port_[port_key]"] != null)
				continue
			var/list/node_def = types_by_id[id]
			return list(null, "node '[id]' ('[node_def["name"]]') is missing a required value for input '[port_def["name"]]'")

	// Foci reached after the arete roll are skipped and provide no complexity cap
	var/list/skipped_foci = list()
	var/cast_id
	for(var/id in known_ids)
		var/list/cast_def = types_by_id[id]
		if(cast_def["tags"] & MAGICK_TAG_CAST)
			cast_id = id
			break
	if(cast_id)
		var/list/queue = list()
		var/alist/cast_edges = effect_graph[cast_id]
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
			var/alist/edges = effect_graph[cur]
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
		var/datum/rote_node_data/cast_node_data = node_data[cast_id]
		var/has_extend_value = cast_node_data?.port_values?["port_in_succ"] != null
		var/has_extend_connection = connected_ports["[cast_id]:in_succ"]
		if(has_extend_value || has_extend_connection)
			var/list/foci_queue = list()
			var/alist/foci_edges = effect_graph[cast_id]
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
				var/alist/edges = effect_graph[cur]
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

	return list(alist(
		"root_nodes" = root_nodes,
		"effect_graph" = effect_graph,
		"reverse_graph" = reverse_graph,
		"node_data" = node_data,
		"complexity" = complexity_sum,
		"expected_success_cost" = expected_success_cost,
		"expected_quint_cost" = expected_quint_cost,
	), null)
