/datum/magick_effect/
	abstract_type = /datum/magick_effect/

	// alist<number, list<number, Node>>
	var/alist/edges

	// Minimum successes required for this effect
	var/min_successes = 0

	/*
	 * Treat all the vars below as if they are abstract static, since BYOND doesn't support it.
	 */

	var/name
	var/desc

	// For easy searching in UI
	var/tags

	// Requirements to disguise this effect as coincidental
	var/looks_like

	// If this effect may contribute coincidental requirements for future effects
	//TODO: Turn this into a component system that checks for/adds effect origin
	var/explains

	// Cost to cast effect
	var/quintessence = 0

	// How much complexity this focus takes up
	var/complexity = 1

	// Maximum number of this node allowed in a spell
	// Mostly to prevent lag for costly effects
	var/max_nodes

	// Available sphere combinations for this effect
	var/list/spheres

	// Blackboard access is alist<Node, datum/magick_ports>
	// Only stores the typepath. Retrieve the actual value from the blackboard
	var/ports_typepath

/datum/magick_effect/proc/is_ready(blackboard)
	var/datum/magick_ports/ports = blackboard[src]
	if (!ports)
		return FALSE
	for (var/datum/magick_port/in_port as anything in ports.inputs)
		if (in_port.get() == null)
			return FALSE
	return TRUE

// For handling pre and post cast
/datum/magick_effect/proc/__cast(datum/magick_context/context)
	SHOULD_NOT_OVERRIDE(TRUE)
	// Fizzle spell if someone manages to pass the traversal limit
	if (++context.nodes_traversed > MAGICK_MAX_TRAVERSAL)
		return

	// Prevent large spell graphs from monopolizing server execution
	if (context.nodes_traversed % MAGICK_SLEEP_INTERVAL == 0)
		sleep(0)

	pre_cast(context)
	if (context.successes < min_successes)
		return
	context.successes -= min_successes
	context.explains |= explains
	cast(context)
	post_cast(context)

// Must override this for actually doing the effect
/datum/magick_effect/proc/cast(datum/magick_context/context)
	return

// Only override for custom handling of checking coincidental casting
/datum/magick_effect/proc/pre_cast(datum/magick_context/context)
	if (!context.paradox && looks_like)
		if ((context.explains & looks_like) != looks_like)
			context.paradox = TRUE

// Only override for custom handling of child nodes
/datum/magick_effect/proc/post_cast(datum/magick_context/context)
	var/datum/magick_ports/ports = context.blackboard[src]
	if (!ports)
		return

	for (var/output_id as anything in edges)
		var/list/tuple = edges[output_id]
		var/input_id = tuple[1]
		var/datum/magick_effect/child = tuple[2]

		var/datum/magick_port/output/out_port = ports.outputs[output_id]
		if (out_port && out_port.get() != null)
			var/datum/magick_ports/child_ports = context.blackboard[child]
			if (!child_ports)
				child_ports = new child.ports_typepath()
				context.blackboard[child] = child_ports

			// IMPORTANT!!!! Activate connections
			var/datum/magick_port/in_port = child_ports.inputs[input_id]
			if (in_port.type_flags & MAGICK_DATA_TRIGGER)
				in_port.assign(TRUE)
			else
				in_port.assign(out_port.get())
			if (child.is_ready(context.blackboard))
				child.__cast(context)

/proc/init_magick_effect_static_data()
	var/list/data = list()
	var/list/effects_list = list()

	for(var/effect_type as anything in subtypesof(/datum/magick_effect/))

		var/datum/magick_effect/effect = new effect_type()

		if (effect_type == effect.abstract_type)
			qdel(effect)
			continue

		var/list/effect_data = list(
			"name" = effect.name,
			"desc" = effect.desc,
			"type" = "[effect_type]",
			"tags" = effect.tags,
			"looks_like" = effect.looks_like,
			"explains" = effect.explains,
			"quintessence" = effect.quintessence,
			"min_successes" = effect.min_successes,
			"complexity" = effect.complexity,
			"spheres" = effect.spheres,
		)

		var/list/inputs_list = list()
		var/list/outputs_list = list()

		if (effect.ports_typepath)
			var/datum/magick_ports/ports = new effect.ports_typepath()

			for(var/datum/magick_port/port as anything in ports.inputs)
				var/list/port_data = list(
					"name" = port.name,
					"type" = port.type_flags,
					"desc" = port.desc,
				)
				if (istype(port, /datum/magick_port/number))
					var/datum/magick_port/number/num_port = port
					if (num_port.clamp_min != null)
						port_data["clamp_min"] = num_port.clamp_min
					if (num_port.clamp_max != null)
						port_data["clamp_max"] = num_port.clamp_max
				else if (istype(port, /datum/magick_port/string))
					var/datum/magick_port/string/str_port = port
					if (str_port.whitelist != null)
						port_data["whitelist"] = str_port.whitelist
				UNTYPED_LIST_ADD(inputs_list, port_data)

			for(var/datum/magick_port/port as anything in ports.outputs)
				UNTYPED_LIST_ADD(outputs_list, list(
					"name" = port.name,
					"type" = port.type_flags,
					"desc" = port.desc,
				))

			qdel(ports)

		effect_data["inputs"] = inputs_list
		effect_data["outputs"] = outputs_list

		effects_list += list(effect_data)
		qdel(effect)

	data["effects"] = effects_list
	return data
