/datum/rote_node/cast
	name = "Cast"
	desc = "This is required for actually casting an effect.\nCast time: Spontaneous\nSuccess cap: Unlimited"
	tags = MAGICK_TAG_RITUAL
	max_nodes = 1

	outputs = new(
		out_act = MAGICK_PORT_ACTIVATE
	)

/datum/rote_node/cast/execute(datum/magick_context/context)
	context.ritual_category = RITUAL_BRIEF_RITE
	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)

/*/datum/rote_node/roll_arete
	name = "Cast"
	desc = "This is required for actually casting a spell and when arete is rolled."
	tags = MAGICK_TAG_RITUAL

	max_nodes = 1

	var/in_succ = "in_succ"

	var/out_act_foci = "out_act_foci"
	var/out_act_cast = "out_act_cast"

	inputs = new(
		in_act = MAGICK_PORT_ACTIVATE,
		in_succ = alist(
			"name" = "Extend To",
			"type" = MAGICK_DATATYPE_NUMBER,
			// M20 p.150
			"desc" = "Leave blank for instant cast. Otherwise, will continue using instruments \
						until successes are reached, capped by arete * willpower, limited to stamina + willpower rolls.",
			"optional" = TRUE,
		)
	)
	outputs = new(
		out_act_foci = alist("name" = "Foci", "type" = MAGICK_DATATYPE_TRIGGER),
		out_act_cast = alist("name" = "Cast", "type" = MAGICK_DATATYPE_TRIGGER)
	)

/datum/rote_node/roll_arete/execute(datum/magick_context/context)
	if (context.arete_locked_in)
		return

	var/mob/living/caster = context.caster
	if (!caster)
		return

	var/datum/splat/mage/mage_splat = context.mage_splat
	if (!mage_splat)
		return

	// Optional willpower auto-success
	var/auto_successes = 0
	if (context.willpower_auto_success)
		if (caster?.st_get_stat(STAT_TEMPORARY_WILLPOWER) >= 1)
			caster.st_change_stat(STAT_TEMPORARY_WILLPOWER, -1)
			auto_successes += 1
		else
			to_chat(caster, span_info("Insufficient Willpower. Continuing without an automatic success."))

	// Optional quintessence difficulty reduction
	var/quint_reduction = 0
	if (context.quint_diff_reduction)
		var/actual_reduction = min(context.quint_diff_reduction, mage_splat.quintessence)
		if (actual_reduction > 0)
			mage_splat.adjust_quintessence(-actual_reduction)
			quint_reduction = actual_reduction
			if (actual_reduction < context.quint_diff_reduction)
				to_chat(caster, span_info("Insufficient Quintessence. Difficulty reduced by [actual_reduction] instead of [context.quint_diff_reduction]."))
		else
			to_chat(caster, span_info("Insufficient Quintessence. Continuing without difficulty reduction."))

	// Extended casting
	var/extend_to = context.get_value(in_succ)
	var/total_successes = 0
	var/max_rolls = 1
	var/max_successes = INFINITY
	if (extend_to)
		max_successes = max(1, caster.st_get_stat(STAT_ARETE) * caster.st_get_stat(STAT_TEMPORARY_WILLPOWER))
		max_rolls = max(1, caster.st_get_stat(STAT_STAMINA) + caster.st_get_stat(STAT_TEMPORARY_WILLPOWER))

	var/datum/storyteller_roll/arete/arete = new()
	arete.bumper_text = name
	arete.auto_successes = auto_successes

	var/rolls = 0
	while (TRUE)
		rolls++
		// Recompute difficulty each roll
		var/discarded_bonus = context.discarded_instrument_bonus ? MAGICK_DIFF_DISCARDED_INSTRUMENT : 0
		arete.difficulty = MAGICK_BASE_DIFFICULTY + context.difficulty_mod + discarded_bonus - quint_reduction
		if (context.debug)
			to_chat(caster, span_warning("DEBUG: Difficulty [arete.difficulty] (base [MAGICK_BASE_DIFFICULTY], mod [context.difficulty_mod], discarded [discarded_bonus], quint [-quint_reduction])."))
		total_successes = min(total_successes + arete.st_roll(caster, caster), max_successes)

		if (extend_to)
			to_chat(caster, span_info("You have accumulated [total_successes] of [extend_to] successes."))

		if (!extend_to || total_successes >= extend_to)
			break

		if (rolls >= max_rolls)
			to_chat(caster, span_warning("You cannot sustain the extended effect any longer."))
			break

		context.foci_cast = FALSE
		cast_foci(context)

		// Canceled by the caster
		if (context.status == ROTE_INTERRUPT_CANCEL)
			return
		// Interrupted externally
		if (context.status != ROTE_NOT_INTERRUPTED)
			break

		if (!context.foci_cast)
			to_chat(caster, span_warning("You cannot sustain an extended effect without specifying an instrument."))
			context.status = ROTE_INTERRUPT_DISRUPTED
			break

	var/datum/magick_rote/active_rote = mage_splat.active_rote
	if (active_rote?.active_context == context)
		active_rote.active_context = null
		mage_splat.set_active_rote(null)
		active_rote.action?.build_all_button_icons(UPDATE_BUTTON_OVERLAY)

	context.status = ROTE_NOT_INTERRUPTED
	context.arete_locked_in = TRUE
	context.successes = total_successes
	// Successes are carried to child nodes by the execution scope
	context.current_scope.successes = total_successes
	context.assign(out_act_cast, TRUE, MAGICK_DATATYPE_TRIGGER)

/datum/rote_node/roll_arete/proc/cast_foci(datum/magick_context/context)
	PRIVATE_PROC(TRUE)
	context.assign(out_act_foci, TRUE, MAGICK_DATATYPE_TRIGGER)
*/
