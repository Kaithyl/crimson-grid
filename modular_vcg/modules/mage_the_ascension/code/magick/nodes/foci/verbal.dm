/datum/rote_node/focus/verbal
	abstract_type = /datum/rote_node/focus/verbal

	var/in_message = "in_message"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE_root,
		in_message = MAGICK_PORT_STRING_required("Text", null)
	)
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
	)

/datum/rote_node/focus/verbal/cast(datum/magick_context/context)
	var/mob/caster = context.caster
	if (!caster)
		return

	var/message = context.get_value(in_message)
	if (!message)
		return

	caster.say(message)

/datum/rote_node/focus/verbal/on_interrupted(datum/magick_context/context, elapsed, total)
	if (total <= 0 || elapsed < total * 0.3)
		return

	var/mob/caster = context.caster
	if (!caster)
		return

	var/message = context.get_value(in_message)
	if (!message)
		return

	var/cut = round(length(message) * 0.5)
	var/spoken = copytext(message, 1, cut + 1)
	caster.say("[spoken]—")

/datum/rote_node/focus/verbal/vow_spirit
	focus_type = /datum/magick_focus/verbal/vow_spirit
	complexity_cap = 3
