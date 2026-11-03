/datum/action/innate/rote_builder
	name = "Open Rote Builder"

	desc = ""

	button_icon = 'modular_vcg/modules/mage_the_ascension/icons/actions.dmi'
	button_icon_state = "mage"

	// You should be able to modify premade effects while you are unconscious
	// since this is a compromise between rotes and dynamic casting
	//check_flags = NONE

	// TODO: Move this into the splat instead
	var/list/datum/action/innate/rote/rotes

	allow_observer_click = TRUE

/datum/action/innate/rote_builder/New()
	..()
	rotes = list()
	rotes.len = MAGICK_MAX_ROTES

/datum/action/innate/rote_builder/Trigger(mob/user, trigger_flags)
	if(!..())
		return FALSE

	SEND_SOUND(owner, sound('sound/misc/menu/ui_select1.ogg', volume = 50))

	ui_interact(user)

/datum/action/innate/rote_builder/ui_host(mob/user)
	return owner

/datum/action/innate/rote_builder/ui_state(mob/user)
	return GLOB.always_state

/datum/action/innate/rote_builder/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/plane_background))

/datum/action/innate/rote_builder/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "RoteBuilder", name)
		ui.open()

/datum/action/innate/rote_builder/ui_data(mob/user)

	var/list/data = list()
	data["view_only"] = (owner != user)
	// Send arete, paradigm and sphere info
	if(!isliving(user))
		return data

	var/mob/living/st_user = user

	var/user_stats = list(
		"arete" = st_user.st_get_stat(STAT_ARETE),
		//"paradigm" = ""
	)

	for(var/sphere as anything in ALL_SPHERES)
		user_stats[sphere] = st_user.st_get_stat(ALL_SPHERES[sphere])

	data["user_stats"] = user_stats

	// Temp
	if(rotes[1])
		data["rote_data"] = rotes[1].rote_code
		data["rote_name"] = rotes[1].name

	return data

/datum/action/innate/rote_builder/ui_static_data(mob/user)
	return GLOB.rotebuilder_static_effect_data

/datum/action/innate/rote_builder/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	if(usr != owner)
		return FALSE

	switch (action)
		if("save_rote")
			var/rote_name = copytext(trim(params["name"]), 1, 41)
			var/rote_rawdata = params["rote_data"]
			var/rote_code = params["rote_code"]

			if(!length(rote_name))
				to_chat(usr, span_warning("Your rote needs a name."))
				return TRUE

			if(!istext(rote_rawdata) || !length(rote_rawdata))
				to_chat(usr, span_warning("Your rote data is missing."))
				return TRUE

			if(!isliving(usr))
				return TRUE

			// Validate rote data
			var/alist/rote_data = validate_rote_data(usr, rote_rawdata)
			if(!rote_data)
				to_chat(usr, span_warning("Your rote failed validation and could not be saved."))
				return TRUE

			var/datum/splat/mage/mage_splat = get_mage_splat(usr)
			if(!mage_splat)
				return TRUE

			var/datum/mind/true_owner = mage_splat.true_owner

			var/datum/action/innate/rote/new_rote = new(true_owner)
			new_rote.name = rote_name
			new_rote.rote_code = rote_code
			new_rote.root_nodes = rote_data["root_nodes"]
			new_rote.effect_graph = rote_data["effect_graph"]
			new_rote.node_data = rote_data["node_data"]
			new_rote.complexity = rote_data["complexity"]
			new_rote.expected_success_cost = rote_data["expected_success_cost"]
			new_rote.expected_quint_cost = rote_data["expected_quint_cost"]

			// Replace old rote
			if(rotes[1])
				rotes[1].Remove(usr)
				rotes[1].clear()
				qdel(rotes[1])

			rotes[1] = new_rote
			new_rote.Grant(usr)
			to_chat(usr, span_notice("You save the rote \"[rote_name]\" to the first rote slot."))
			return TRUE

	return FALSE

/datum/action/innate/rote_builder/proc/validate_rote_data(mob/living/user, rote_rawdata)
	var/list/parsed = json_decode(rote_rawdata)
	if(!istype(parsed) || !islist(parsed["nodes"]) || !islist(parsed["connections"]))
		validation_fail(user, "rote data has no 'nodes'/'connections' lists (raw: [copytext(rote_rawdata, 1, 256)])")
		return null

	var/list/effects = GLOB.rotebuilder_static_effect_data["effects"]
	var/list/type_counts = list()
	var/list/known_ids = list()
	var/list/types_by_id = list()
	var/list/effect_instances = list()
	var/list/connected_inputs = list()
	var/list/root_nodes = list()
	var/alist/effect_graph = new()
	var/alist/node_data = new()
	var/complexity_sum = 0
	var/expected_success_cost = 0
	var/expected_quint_cost = 0
	var/root_count = 0
	var/node_count = 0

	for(var/list/node in parsed["nodes"])
		if(!islist(node))
			validation_fail(user, "node #[node_count + 1] is not a list: [json_encode(node)]")
			return null

		node_count++
		if(node_count > MAGICK_MAX_NODES)
			validation_fail(user, "node count [node_count] exceeds MAGICK_MAX_NODES ([MAGICK_MAX_NODES])")
			return null

		var/id = "[node["id"]]"
		if(!length(id) || known_ids[id])
			validation_fail(user, "node #[node_count] has invalid/duplicate id '[id]'")
			return null
		known_ids[id] = TRUE

		var/type_index = isnum(node["type_index"]) ? round(node["type_index"]) : text2num("[node["type_index"]]")
		if(isnull(type_index) || type_index < 1 || type_index > length(effects))
			validation_fail(user, "node #[node_count] (id '[id]') has out of range type_index '[type_index]' (effects: [length(effects)])")
			return null

		var/list/effect_data = effects[type_index]
		types_by_id[id] = effect_data

		// Check if per-type max nodes
		var/max_nodes = effect_data["max_nodes"]
		if(max_nodes)
			if((type_counts[effect_data["type"]] || 0) >= max_nodes)
				validation_fail(user, "node #[node_count] (id '[id]') exceeds max_nodes [max_nodes] for effect '[effect_data["name"]]'")
				return null
			type_counts[effect_data["type"]] = (type_counts[effect_data["type"]] || 0) + 1

		// Check sphere requirements
		var/list/options = effect_data["spheres"]
		if(options)
			var/sphere_index = isnum(node["sphere_index"]) ? round(node["sphere_index"]) : text2num("[node["sphere_index"]]")
			if(isnull(sphere_index) || sphere_index < 1 || sphere_index > length(options) || !validate_spheres(user, options[sphere_index]))
				validation_fail(user, "node #[node_count] (id '[id]', effect '[effect_data["name"]]') failed sphere requirements (sphere_index '[sphere_index]', options: [json_encode(options)])")
				return null

		// Resolve the effect singleton
		var/effect_type = text2path(effect_data["type"])
		var/datum/magick_effect/effect = GLOB.magick_effects[effect_type]
		if(!effect)
			validation_fail(user, "node #[node_count] (id '[id]') has unknown effect type '[effect_data["type"]]'")
			return null

		// Build per-node data
		var/datum/magick_node_data/node_data_entry = new()
		node_data_entry.effect = effect
		if(node["port_values"])
			node_data_entry.port_values = node["port_values"]
		if(node["userdata"])
			var/list/userdata = node["userdata"]
			node_data_entry.label = userdata["label"]
			node_data_entry.success_percentage = userdata["success_percentage"]
			node_data_entry.min_success = userdata["min_success"]
			node_data_entry.max_success = userdata["max_success"]
		node_data[id] = node_data_entry

		effect_instances[id] = effect

		if(effect_data["tags"] & MAGICK_TAG_ROOT)
			root_count++
			root_nodes += id

		complexity_sum += effect_data["complexity"]
		expected_success_cost += effect_data["min_success_cost"]
		expected_quint_cost += effect_data["quintessence"]

	if(!root_count)
		validation_fail(user, "rote has no root nodes")
		return null

	// Build connections
	for(var/list/connection in parsed["connections"])
		if(!islist(connection))
			validation_fail(user, "connection is not a list: [json_encode(connection)]")
			return null

		var/out_id = "[connection["out_id"]]"
		var/in_id = "[connection["in_id"]]"
		var/out_key = "[connection["out_port"]]"
		var/in_key = "[connection["in_port"]]"
		if(!known_ids[out_id] || !known_ids[in_id] || !length(out_key) || !length(in_key))
			validation_fail(user, "connection out_id '[out_id]' -> in_id '[in_id]' (out_port '[out_key]', in_port '[in_key]') references unknown nodes or empty ports")
			return null

		var/datum/magick_effect/source = effect_instances[out_id]
		var/datum/magick_effect/target = effect_instances[in_id]

		var/alist/source_outputs = source.outputs
		var/alist/target_inputs = target.inputs
		var/alist/out_port_data = source_outputs ? source_outputs[out_key] : null
		var/alist/in_port_data = target_inputs ? target_inputs[in_key] : null
		if(out_port_data == null || in_port_data == null)
			validation_fail(user, "connection out_id '[out_id]' (port '[out_key]') -> in_id '[in_id]' (port '[in_key]') references unknown ports")
			return null

		if(!MAGICK_DATATYPES_VALID(out_port_data["type"], in_port_data["type"]))
			validation_fail(user, "connection out_id '[out_id]' (port '[out_key]', '[out_port_data["name"]]', type [out_port_data["type"]]) -> in_id '[in_id]' (port '[in_key]', '[in_port_data["name"]]', type [in_port_data["type"]]) has incompatible port types")
			return null

		connected_inputs[in_id] = TRUE

		// Build the effect graph dictionary
		if(!effect_graph[out_id])
			effect_graph[out_id] = alist()
		if(!effect_graph[out_id][out_key])
			effect_graph[out_id][out_key] = list()
		effect_graph[out_id][out_key] += list(list(out_key, in_key, in_id))

	// Check for islands
	for(var/id in known_ids)
		if(types_by_id[id]["tags"] & MAGICK_TAG_ROOT)
			continue
		if(connected_inputs[id])
			continue

		var/list/effect_data = types_by_id[id]
		var/list/inputs = effect_data["inputs"]
		var/has_required_input = FALSE
		for(var/list/input_data in inputs)
			if(input_data["default_value"] == null)
				has_required_input = TRUE
				break

		if(has_required_input)
			validation_fail(user, "node '[id]' ('[effect_data["name"]]') is unreachable but has required inputs")
			return null

	return alist(
		"root_nodes" = root_nodes,
		"effect_graph" = effect_graph,
		"node_data" = node_data,
		"complexity" = complexity_sum,
		"expected_success_cost" = expected_success_cost,
		"expected_quint_cost" = expected_quint_cost,
	)

/datum/action/innate/rote_builder/proc/validate_spheres(mob/living/user, list/option)
	for(var/sphere in option)
		if(user.st_get_stat(ALL_SPHERES[sphere]) < option[sphere])
			return FALSE
	return TRUE

/datum/action/innate/rote_builder/proc/validation_fail(mob/living/user, fail_reason)
	PRIVATE_PROC(TRUE)
	//var/msg = "Rote validation failed for [key_name(user)] ([user]): [fail_reason]"
	//user.log_message("Rote validation failed: [fail_reason]", LOG_GAME)
	//message_admins("[ADMIN_LOOKUPFLW(user)]: [msg]")
	to_chat(user, span_warning("Error when building rote: [fail_reason]"))
	//log_game("[msg]")
