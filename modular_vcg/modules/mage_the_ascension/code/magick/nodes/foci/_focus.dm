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

// Called when using the foci is interrupted
// elapsed and total are in deciseconds
/datum/rote_node/focus/proc/on_interrupted(datum/magick_context/context, elapsed, total)
	return

/datum/rote_node/focus/proc/valid(datum/magick_context/context)
	return context.status == ROTE_NOT_INTERRUPTED && focus.can_use(context.caster)

// perform the focus's action
/datum/rote_node/focus/proc/perform(datum/magick_context/context)
	return

// TODO: Handle vulgar and witnessed difficulty
/datum/rote_node/focus/execute(datum/magick_context/context)
	SHOULD_NOT_OVERRIDE(TRUE)
	if (context.has_consumed_successes)
		return

	var/mob/living/caster = context.caster
	if (!caster)
		return

	var/datum/splat/mage/mage_splat = context.mage_splat
	if (!mage_splat)
		return

	if (!focus)
		return

	var/has_instrument = focus.can_use(caster)
	var/alist/instruments = MAGE_GET_INSTRUMENTS(caster)
	var/focus_path = "[focus.type]"
	var/discarded = (focus_path in MAGE_GET_DISCARDED_INSTRUMENTS(caster))

	// Highest sphere used by the rote
	var/highest_level = mage_splat.active_rote?.highest_sphere || 0
	var/highest_sphere
	var/alist/rote_spheres = mage_splat.active_rote?.spheres
	if (rote_spheres)
		for (var/sphere as anything in rote_spheres)
			if (rote_spheres[sphere] == highest_level)
				highest_sphere = sphere
				break

	var/matches_highest_sphere = highest_sphere != null && instruments?[highest_sphere] == focus_path

	if (!has_instrument && !discarded)
		to_chat(caster, span_warning("You attempt to cast with a missing instrument."))

	if (focus.cast_time)
		var/datum/callback/extra_checks = CALLBACK(src, PROC_REF(valid), context)
		var/cast_start = world.time
		if (!do_after(caster, focus.cast_time, caster, timed_action_flags = focus.get_action_flags(caster), extra_checks = extra_checks))
			if (context.status != ROTE_NOT_INTERRUPTED)
				return
			// Interrupted externally
			on_interrupted(context, world.time - cast_start, focus.cast_time)
			to_chat(caster, span_warning("You were interrupted."))
			context.status = ROTE_INTERRUPT_DISRUPTED
			return
		has_instrument = focus.can_use(caster)

	// Accumulate difficulty modifiers from how the instrument is being used
	if (discarded && has_instrument)
		context.difficulty_mods[DIFFICULTY_TYPE_INSTRUMENT_DISCARDED] = MAGICK_DIFF_DISCARDED_INSTRUMENT
		if (context.debug)
			to_chat(caster, span_warning("DEBUG: [name] discarded instrument reduces difficulty by [MAGICK_DIFF_DISCARDED_INSTRUMENT]."))
	else if (!has_instrument)
		context.difficulty_mods[DIFFICULTY_TYPE_INSTRUMENT] = MAGICK_DIFF_NO_INSTRUMENT
		if (context.debug)
			to_chat(caster, span_warning("DEBUG: [name] missing instrument penalty [MAGICK_DIFF_NO_INSTRUMENT]."))
		if (caster?.st_get_stat(STAT_TEMPORARY_WILLPOWER) >= MAGICK_WILLPOWER_NO_INSTRUMENT)
			caster.st_change_stat(STAT_TEMPORARY_WILLPOWER, -MAGICK_WILLPOWER_NO_INSTRUMENT)
		else
			to_chat(caster, span_warning("You lack the Willpower to cast without an instrument."))
	else
		context.difficulty_mods[DIFFICULTY_TYPE_INSTRUMENT] = MAGE_PARADIGM_PENALTY(focus.paradigms, mage_splat.paradigm || NONE)
		if (context.debug)
			to_chat(caster, span_warning("DEBUG: [name] paradigm penalty [context.difficulty_mods[DIFFICULTY_TYPE_INSTRUMENT]]."))

	if (matches_highest_sphere)
		context.difficulty_mods[DIFFICULTY_TYPE_INSTRUMENT_SPHERE] = MAGICK_DIFF_UNIQUE_INSTRUMENT

	// Perform the focus's action
	perform(context)

	// Roll arete to gather successes
	var/difficulty_mod = 0
	for (var/mod_type as anything in context.difficulty_mods)
		difficulty_mod += context.difficulty_mods[mod_type]
	difficulty_mod = clamp(difficulty_mod, MAGICK_MAX_DIFFICULTY_BONUS, MAGICK_MAX_DIFFICULTY_PENALTY)

	if (context.debug)
		var/mods_text = ""
		for (var/mod_type as anything in context.difficulty_mods)
			mods_text += "[mod_type]: [context.difficulty_mods[mod_type]]; "
		to_chat(caster, span_warning("DEBUG: [name] difficulty_mods [mods_text]"))

	var/datum/storyteller_roll/arete/arete = new()
	arete.bumper_text = "Arete - [mage_splat.active_rote?.name || name]"
	arete.difficulty = highest_level + 3 + difficulty_mod
	var/successes = arete.st_roll(caster, caster)

	// Cap accumulated successes based on the ritual category
	var/max_successes = MAGICK_MAX_SUCCESS_SPONTANEOUS
	switch (context.ritual_category)
		if (RITUAL_BRIEF_RITE)
			max_successes = MAGICK_MAX_SUCCESS_BRIEF_RITE
		if (RITUAL_CEREMONY)
			max_successes = MAGICK_MAX_SUCCESS_CEREMONY
		if (RITUAL_GREAT_WORK)
			max_successes = MAGICK_MAX_SUCCESS_GREAT_WORK
	// If arete is somehow > cap, use arete instead
	max_successes = max(max_successes, caster.st_get_stat(STAT_ARETE))
	context.successes = min((context.successes || 0) + successes, max_successes)
	context.current_scope.successes = context.successes

	context.assign(out_act, TRUE, MAGICK_DATATYPE_TRIGGER)
