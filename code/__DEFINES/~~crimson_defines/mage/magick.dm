/// Ritual categories (M20, pp. 538–542)

#define RITUAL_SPONTANEOUS 0
#define RITUAL_BRIEF_RITE 1
#define RITUAL_CEREMONY 2
#define RITUAL_GREAT_WORK 3

#define MAGICK_MAX_SUCCESS_SPONTANEOUS INFINITY
#define MAGICK_MAX_SUCCESS_BRIEF_RITE 5 // 1 - 5
#define MAGICK_MAX_SUCCESS_CEREMONY 10 // 5 - 10
// can exceed 10-20 but capping this to prevent server-destroying effects
#define MAGICK_MAX_SUCCESS_GREAT_WORK 20

/// Difficulties
#define DIFFICULTY_TYPE_INSTRUMENT "instrument_requirement"
#define DIFFICULTY_TYPE_INSTRUMENT_DISCARDED "discarded_instrument"
#define DIFFICULTY_TYPE_INSTRUMENT_SPHERE "instrument_matches_sphere"
#define DIFFICULTY_TYPE_FAILED_RITUAL_ROLL "failed_ritual_roll"

#define MAGICK_MAX_DIFFICULTY_BONUS -3
#define MAGICK_MAX_DIFFICULTY_PENALTY 3

#define MAGICK_FAILED_RITUAL_PENALTY 1 // failed rolls (zero successes) increases ritual difficulties by +1

#define MAGICK_COUNTER_MIN_DIFFICULTY 7 // Minimum difficulty for counterspell dice

/// Constants
#define ROTE_NOT_INTERRUPTED 0
#define ROTE_INTERRUPT_CANCEL 1
#define ROTE_INTERRUPT_DISRUPTED 2
#define ROTE_INTERRUPT_FORCE_CAST 3

// What counts as being within LoS by SS13 standards
#define MAGICK_LINE_OF_SIGHT_DISTANCE 7
