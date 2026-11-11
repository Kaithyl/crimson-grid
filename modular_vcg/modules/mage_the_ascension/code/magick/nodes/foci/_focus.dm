/datum/rote_node/focus
	abstract_type = /datum/rote_node/focus
	tags = MAGICK_TAG_FOCI

	VAR_PROTECTED/datum/magick_focus/focus_type
	var/datum/magick_focus/focus

	// How much complexity cap this instrument provides
	// TODO: Use complexity cap from focus_type instead
	var/complexity_cap

/datum/rote_node/focus/New()
	. = ..()
	focus = GLOB.magick_foci[focus_type]
	name = !isnull(name) ? name : focus.name
	desc = !isnull(desc) ? desc : focus.desc

// TODO: -1 difficulty if instrument's assigned sphere is the dominant sphere of this rote
/datum/rote_node/focus/pre_cast(datum/magick_context/context)
	SHOULD_NOT_OVERRIDE(TRUE)
	context.foci_cast = TRUE

	var/mob/living/caster = context.caster
	if (!caster)
		return

	var/has_instrument = focus.can_use(caster)
	var/timed_action_flags = focus.get_action_flags(caster)
	var/list/discarded_instruments = MAGE_GET_DISCARDED_INSTRUMENTS(caster)
	var/list/instruments = MAGE_GET_INSTRUMENTS(caster)
	var/focus_path = "[focus.type]"
	var/discarded = (focus_path in discarded_instruments)
	var/is_standard_instrument = FALSE
	for (var/sphere in instruments)
		if (instruments[sphere] == focus_path)
			is_standard_instrument = TRUE
			break

	if (!has_instrument && !discarded)
		to_chat(caster, span_warning("You attempt to cast with a missing instrument."))

	// Use precast_time only when this node type is first traversed
	// For now, TODO: Make regular/extended casting more obvious in builder
	var/cast_delay = ROTE_NODE_TYPE_VISITED(context, type) ? focus.cast_time : focus.precast_time
	if (cast_delay)
		var/datum/callback/extra_checks = CALLBACK(src, PROC_REF(still_valid), context)
		var/cast_start = world.time
		if (!do_after(caster, cast_delay, caster, timed_action_flags = timed_action_flags, extra_checks = extra_checks))
			// Canceled by the caster
			if (context.aborted)
				return
			if (context.interrupted)
				return
			// Interrupted externally
			on_interrupted(context, world.time - cast_start, cast_delay)
			to_chat(caster, span_warning("You were interrupted."))
			context.interrupted = TRUE
			return
		has_instrument = focus.can_use(caster)

	if (discarded)
		if (has_instrument && !context.discarded_instrument_bonus)
			context.discarded_instrument_bonus = TRUE
			if (context.debug)
				to_chat(caster, span_warning("DEBUG: [name] discarded instrument reduces difficulty by [MAGICK_DIFF_DISCARDED_INSTRUMENT]."))
		return

	if (is_standard_instrument && has_instrument)
		return

	if (!has_instrument)
		MAGICK_APPLY_INSTRUMENT_PENALTY(context, MAGICK_DIFF_NO_INSTRUMENT)
		if (context.debug)
			to_chat(caster, span_warning("DEBUG: [name] missing instrument penalty [context.instrument_penalty]."))
		if (caster?.st_get_stat(STAT_TEMPORARY_WILLPOWER) >= MAGICK_WILLPOWER_NO_INSTRUMENT)
			caster.st_change_stat(STAT_TEMPORARY_WILLPOWER, -MAGICK_WILLPOWER_NO_INSTRUMENT)
		else
			to_chat(caster, span_warning("You lack the Willpower to cast without an instrument."))
		return

	MAGICK_APPLY_INSTRUMENT_PENALTY(context, MAGE_PARADIGM_PENALTY(focus.paradigms, context.mage_splat?.paradigm || NONE))
	if (context.debug)
		to_chat(caster, span_warning("DEBUG: [name] paradigm penalty [context.instrument_penalty]."))

/datum/rote_node/focus/proc/still_valid(datum/magick_context/context)
	return !context.aborted && !context.interrupted && focus.can_use(context.caster)

// Called when the cast is interrupted externally
// elapsed and total are in deciseconds
/datum/rote_node/focus/proc/on_interrupted(datum/magick_context/context, elapsed, total)
	return
