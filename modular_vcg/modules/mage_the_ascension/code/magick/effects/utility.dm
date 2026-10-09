/datum/magick_effect/count
	name = "Count"
	tags = MAGICK_TAG_DATA
	complexity = 0
	ports_typepath = /datum/magick_ports/count

/datum/magick_ports/count
	var/datum/magick_port/any/in_targets = MAGICK_PORT_TARGET_S

	var/datum/magick_port/output/out_number = new("Number", MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)

/datum/magick_effect/count/cast(datum/magick_context/context)
	var/datum/magick_ports/count/ports = context.blackboard[src]
	ports.out_number.assign(length(ports.in_targets.get()))

/datum/magick_effect/add
	name = "Add"
	tags = MAGICK_TAG_DATA
	complexity = 0
	ports_typepath = /datum/magick_ports/add

/datum/magick_ports/add
	var/datum/magick_port/number/in_a = new("Number", MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)
	var/datum/magick_port/number/in_b = new("Number", MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)

	var/datum/magick_port/output/out_sum = new("Number", MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)

/datum/magick_effect/add/cast(datum/magick_context/context)
	var/datum/magick_ports/add/ports = context.blackboard[src]
	ports.out_sum.assign(ports.in_a.get() + ports.in_b.get())

/datum/magick_effect/for_each
	name = "For Each"
	tags = MAGICK_TAG_DATA
	complexity = 0
	max_nodes = 1
	ports_typepath = /datum/magick_ports/activatable/for_each

/datum/magick_ports/activatable/for_each
	var/datum/magick_port/any/in_targets = MAGICK_PORT_TARGET_S

	var/datum/magick_port/output/out_target = MAGICK_PORT_TARGET
	var/datum/magick_port/output/out_succ = MAGICK_PORT_NUMBER_("Successes", null, null)

/datum/magick_effect/for_each/cast(datum/magick_context/context)
	var/datum/magick_ports/activatable/for_each/ports = context.blackboard[src]
	ports.out_succ.assign(context.successes)

/datum/magick_effect/for_each/post_cast(datum/magick_context/context)
	var/datum/magick_ports/activatable/for_each/ports = context.blackboard[src]
	if (!ports)
		return

	var/list/targets = ports.in_targets.get()
	if (!length(targets))
		return

	for (var/output_id as anything in edges)
		var/list/tuple = edges[output_id]
		var/input_id = tuple[1]
		var/datum/magick_effect/child = tuple[2]

		// Check if output to input is out_succ
		var/datum/magick_port/output/out_port = ports.outputs[output_id]
		if (out_port == ports.out_succ)
			var/datum/magick_ports/child_ports = context.blackboard[child]
			if (!child_ports)
				child_ports = new child.ports_typepath()
				context.blackboard[child] = child_ports

			var/datum/magick_port/in_port = child_ports.inputs[input_id]
			if (in_port.type_flags & MAGICK_DATA_TRIGGER)
				in_port.assign(TRUE)
			else
				in_port.assign(out_port.get())
			if (child.is_ready(context.blackboard))
				child.__cast(context)
			continue

		// Handle recursive casting for activate connections
		for (var/target in targets)
			var/datum/magick_ports/child_ports = context.blackboard[child]
			if (!child_ports)
				child_ports = new child.ports_typepath()
				context.blackboard[child] = child_ports

			var/datum/magick_port/in_port = child_ports.inputs[input_id]
			if (in_port.type_flags & MAGICK_DATA_TRIGGER)
				in_port.assign(TRUE)
			else
				in_port.assign(target)
			if (child.is_ready(context.blackboard))
				child.__cast(context)
