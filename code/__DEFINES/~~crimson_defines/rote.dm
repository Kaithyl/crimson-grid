#define MAGICK_BASE_DIFFICULTY 6

#define MAGICK_DATA_TRIGGER				(1<<0)
#define MAGICK_DATA_BOOL  				(1<<1)
#define MAGICK_DATA_NUMBER  			(1<<2)
#define MAGICK_DATA_STRING  			(1<<3)
#define MAGICK_DATA_TURF    			(1<<4)
#define MAGICK_DATA_OBJ     			(1<<5)
#define MAGICK_DATA_MOB     			(1<<6)
#define MAGICK_DATA_ANY     			(MAGICK_DATA_TURF | MAGICK_DATA_OBJ | MAGICK_DATA_MOB)
#define MAGICK_DATA_COUNT_ONE			(1<<21)
#define MAGICK_DATA_COUNT_LIST			(1<<22)
#define MAGICK_DATA_COUNT_ANY   		(1<<23)

#define MAGICK_DATA_LINK_VALID(out_flags, in_flags) (!((out_flags) & ~(in_flags)))

#define MAGICK_PORT_ACTIVATE 		new/datum/magick_port("Activate", MAGICK_DATA_TRIGGER)
#define MAGICK_PORT_NUMBER			new/datum/magick_port("Number", MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)
#define MAGICK_PORT_TARGET			new/datum/magick_port("Target", MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ONE)
#define MAGICK_PORT_TARGET_S		new/datum/magick_port("Target(s)", MAGICK_DATA_ANY | MAGICK_DATA_COUNT_ANY)

#define MAGICK_PORT_NUMBER_(name)	new/datum/magick_port(name, MAGICK_DATA_NUMBER | MAGICK_DATA_COUNT_ONE)

#define MAGICK_VULGAR_FIRE 				(1<<0)
#define MAGICK_VULGAR_EXPLOSION 		(1<<1)
#define MAGICK_VULGAR_ELECTRIC			(1<<2)
#define MAGICK_VULGAR_KINETIC			(1<<3)
#define MAGICK_VULGAR_GAS 				(1<<4)
#define MAGICK_VULGAR_ACID 				(1<<5)
#define MAGICK_VULGAR_BASIC_BIO 		(1<<6)
#define MAGICK_VULGAR_COMPLEX_BIO 		(1<<7)

#define MAGICK_TAG_DATA					(1<<0) // For effects that do nothing besides data processing
#define MAGICK_TAG_UTILITY				(1<<1)
#define MAGICK_TAG_DAMAGE				(1<<2)
#define MAGICK_TAG_BUFF					(1<<3)
#define MAGICK_TAG_DEBUFF				(1<<4)

GLOBAL_LIST_INIT(magick_effect_static_data, init_magick_effect_static_data())
