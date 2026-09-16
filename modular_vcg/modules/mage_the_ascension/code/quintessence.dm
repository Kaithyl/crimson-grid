/datum/splat/mage/proc/adjust_quintessence(amount, sound = TRUE)
	if (amount > 0)
		// Character capacity for quint is determined by avatar rating
		// unless the mage has prime in which its capped by paradox
		// TODO: switch to toggle for prime 1 taking in more than cap
		var/total_dox = permanent_paradox + paradox
		var/prime = owner.st_get_stat(STAT_SPHERE_PRIME)
		var/avatar = owner.st_get_stat(STAT_AVATAR)
		var/max_quint = (prime > 0) ? MAX_QUINTESSENCE_AND_PARADOX - total_dox : avatar
		var/new_quint = min(quintessence + amount, max_quint)
		//if (quintessence == new_quint)
		//	return FALSE

		quintessence = new_quint
		//if(sound)
			// send sound
		//send message
	else if (amount < 0)
		if (quintessence < amount)
			return FALSE

		quintessence += amount
		//if(sound)
			//send sound
		//send message

	owner.update_mage_hud()
	return TRUE

/datum/splat/mage/proc/regain_quint_process(seconds_per_tick)
	/*
	if(!COOLDOWN_FINISHED(src, gnosis_regain_cd))
		return
	for(var/obj/structure/werewolf_totem/totem in GLOB.totems)
		if(totem.broken)
			continue
		if(!totem.is_friend_of_totem(owner))
			continue
		if(get_area(totem) != get_area(owner))
			continue
		adjust_gnosis(1, TRUE)
		COOLDOWN_START(src, gnosis_regain_cd, 1 SCENES)*/
