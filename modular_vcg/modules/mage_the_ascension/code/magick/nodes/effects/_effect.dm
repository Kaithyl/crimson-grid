// Effects are nodes that actually do something when cast
/datum/rote_node/effect/
	abstract_type = /datum/rote_node/effect/

	complexity = 1

	// Cost to cast effect
	var/quintessence = 0

	// Minimum successes required for this spell to have an effect
	var/min_success_cost = 0

	// If the spell's effect can be enhanced by adding multiple successes
	var/can_add_success = FALSE
