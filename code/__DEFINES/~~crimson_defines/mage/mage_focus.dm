/// Paradigms

#define PARADIGM_MYSTIC				(1<<0)
#define PARADIGM_TECHNOMANCER		(1<<1)
#define PARADIGM_ANIMIST			(1<<2)

/// Instruments

// Difficulty reduction from using a discarded instrument
#define MAGICK_DIFF_DISCARDED_INSTRUMENT -1

// Difficulty reduction from matching a unique instrument with its sphere
#define MAGICK_DIFF_UNIQUE_INSTRUMENT -1

// Difficulty reduction from matching a personal instrument with its sphere
#define MAGICK_DIFF_PERSONAL_INSTRUMENT -1

// Difficutly penalty for using an in-paradigm but not personal instrument
#define MAGICK_DIFF_NONPERSONAL_PARADIGM_INSTRUMENT 1

// Difficutly penalty for using an instrument out of paradigm
#define MAGICK_DIFF_NONPERSONAL_INSTRUMENT 2

// Difficulty penalty for technomancers/mystics using each others instruments
#define MAGICK_DIFF_CROSS_MAGI_TECH_INSTRUMENT 3

// Difficulty penalty for casting without an instrument
#define MAGICK_DIFF_NO_INSTRUMENT 3

// Willpower cost without an instrument
#define MAGICK_WILLPOWER_NO_INSTRUMENT 1

#define MAGE_PARADIGM_PENALTY(focus_paradigms, mage_paradigm) \
	(((focus_paradigms) & (mage_paradigm) & ~(PARADIGM_MYSTIC | PARADIGM_TECHNOMANCER)) ? MAGICK_DIFF_NONPERSONAL_PARADIGM_INSTRUMENT : \
	(((focus_paradigms) & (mage_paradigm) & (PARADIGM_MYSTIC | PARADIGM_TECHNOMANCER)) ? MAGICK_DIFF_NONPERSONAL_INSTRUMENT : \
	MAGICK_DIFF_CROSS_MAGI_TECH_INSTRUMENT))

// Maximum difficulty penalty from instruments
#define MAGICK_DIFF_INSTRUMENT_PENALTY_MAX 3
#define MAGICK_APPLY_INSTRUMENT_PENALTY(context, penalty) \
	do { \
		var/__magick_penalty = min((penalty), MAGICK_DIFF_INSTRUMENT_PENALTY_MAX); \
		if (__magick_penalty > (context).instrument_penalty) { \
			(context).difficulty_mod += __magick_penalty - (context).instrument_penalty; \
			(context).instrument_penalty = __magick_penalty; \
		} \
	} while (FALSE)

#define MAGE_GET_INSTRUMENTS(caster) ((caster)?.client?.prefs?.focus_instruments || list())

#define MAGE_GET_DISCARDED_INSTRUMENTS(caster) ((caster)?.client?.prefs?.discarded_instruments || list())
