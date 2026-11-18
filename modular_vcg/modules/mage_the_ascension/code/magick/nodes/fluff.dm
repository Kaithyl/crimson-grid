/datum/rote_node/say
	name = "Say"
	desc = "Say a message."
	tags = MAGICK_TAG_UTILITY

	var/in_message = "in_message"

	inputs = alist(
		in_act = MAGICK_PORT_ACTIVATE,
		in_message = MAGICK_PORT_STRING_REQUIRED("Text", null)
	)
	outputs = alist(
		out_act = MAGICK_PORT_ACTIVATE,
	)

/datum/rote_node/say/execute(datum/magick_context/context)
	var/mob/caster = context.caster
	if (!caster)
		return

	var/message = context.get_value(in_message)
	if (!message)
		return

	caster.say(message)
	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)
