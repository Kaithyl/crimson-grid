/datum/splat/mage/proc/adjust_paradox(amount, sound = TRUE)
	if (amount > 0)
		paradox += amount
		var/total_dox = permanent_paradox + paradox

		//___callbackvarsetif (MAX_QUINTESSENCE_AND_PARADOX - total_dox < quintessence)
			// TODO: handle paradox canceling out quint

		// Use temp willpower to push backlash back by 1 SCENE
		// Rework delay backlash into giving chance to avoid it entirely dependent on dox size
		// Should allow dox to actually build up instead of instantly backlashing at 6
		// Trigger automatic backlash at 21+ paradox no willpower can be used to delay
		//if (paradox >= PARADOX_BACKLASH_THRESHOLD)
			// TODO: handle paradox backlash
			// if (delay_backlash_action.active)

		//if(sound)
			//send sound
		//send message
	if (amount < 0)
		// Might instead return FALSE if paradox is already at 0?
		if (paradox < 1)
			return FALSE

		paradox = max(0, paradox + amount)

		//if(sound)
			//send sound
		//send message
	owner.update_mage_hud()
	return TRUE

/datum/splat/mage/proc/adjust_permanent_paradox(amount, sound = TRUE)
	if (amount > 0)
		permanent_paradox += amount
		var/total_dox = permanent_paradox + paradox

		//if (MAX_QUINTESSENCE_AND_PARADOX - total_dox < quintessence)
			// TODO: handle paradox canceling out quint

		//if(sound)
			//send sound
		//send message
	if (amount < 0)
		if (permanent_paradox < 1)
			return FALSE

		permanent_paradox = max(0, permanent_paradox + amount)

		//if(sound)
			//send sound
		//send message
	owner.update_mage_hud()
	return TRUE

/datum/splat/mage/proc/bleed_dox_process(seconds_per_tick)
	// Reduce when dox < 10 and mage has not casted spell for 1 scene

/datum/splat/mage/proc/trigger_paradox_backlash()
	var/datum/storyteller_roll/paradox_backlash/roll = new()
	var/successes = roll.st_roll(owner, owner)

	// On botch, all paradox discharges harmlessly
	if (successes < 0)
		// TODO: Custom message?
		adjust_paradox(-paradox)
		return

	// TODO: check spheres used on spell to make backlash more poetic?

	// On 0 successes nothing happens
	// Discharge paradox equal to the number of successes
	// determine paradox flaws if any
	switch (successes)
		if (0)
			return .
		if (1 to 5)
			owner.adjust_brute_loss(successes TTRPG_DAMAGE)
			// trivial paradox flaw
		if (6 to 10)
			owner.adjust_brute_loss(successes TTRPG_DAMAGE)
			// minor paradox flaw
		if (11 to 15)
			owner.adjust_brute_loss(successes LETHAL_TTRPG_DAMAGE)
			// significant paradox flaw, paradox spirit, or mild quiet
		if (16 to 20)
			owner.adjust_agg_loss(successes TTRPG_DAMAGE)
			adjust_permanent_paradox(1)
			// two effects: severe paradox flaw, paradox spirit, moderate quiet, or paradox realm.
		else // if (21+)
			owner.adjust_agg_loss(successes TTRPG_DAMAGE)
			adjust_permanent_paradox(2)
			// one effect: drastic paradox flaw, paradox spirit, severe quiet, or paradox realm.

	adjust_paradox(-successes)

/datum/storyteller_roll/paradox_backlash
	bumper_text = "paradox backlash"
	numerical = TRUE
	// Uses standard difficulty and successes
	roll_output_type = ROLL_PRIVATE

/datum/storyteller_roll/paradox_backlash/calculate_used_dice(mob/living/roller, bonus = 0)
	var/datum/splat/mage/our_splat = get_mage_splat(roller)
	if (our_splat)
		return our_splat.permanent_paradox + our_splat.paradox
	return 0
