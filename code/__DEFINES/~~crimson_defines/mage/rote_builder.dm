#define MAGICK_MAX_ROTES 15

#define MAGICK_MAX_NODES 20
#define MAGICK_MAX_TRAVERSAL 50
#define MAGICK_SLEEP_INTERVAL 8

#define MAGICK_FOR_LOOP_MAX_LIST 20
#define MAGICK_FOR_LOOP_MAX_BRANCHES 3

#define MAGICK_TARGET_ENABLE_TEXT(label, count) "Select the [label ? label : "next target"] for your spell. ([count] manual target selections remaining)."

#define MAGICK_DATATYPE_TRIGGER					(1<<0)
#define MAGICK_DATATYPE_NUMBER  				(1<<1)
#define MAGICK_DATATYPE_STRING  				(1<<2)
#define MAGICK_DATATYPE_TURF    				(1<<3)
#define MAGICK_DATATYPE_OBJ     				(1<<4)
#define MAGICK_DATATYPE_MOB     				(1<<5)
#define MAGICK_DATATYPE_ATOM     				(MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_MOB)

#define MAGICK_DATATYPE_FLAG_ORIGIN				(1<<21)
#define MAGICK_DATATYPE_FLAG_SINGLE				(1<<22)
#define MAGICK_DATATYPE_FLAG_LIST				(1<<23)

#define MAGICK_DATATYPES_VALID(out_flags, in_flags) (!((out_flags) & ~(in_flags)))

#define MAGICK_TAG_ROOT						(1<<0)	// For root nodes in the execution tree
#define MAGICK_TAG_DATA						(1<<1) 	// For effects that do nothing besides data processing
#define MAGICK_TAG_UTILITY					(1<<2)
#define MAGICK_TAG_DAMAGE					(1<<3)
#define MAGICK_TAG_BUFF						(1<<4)
#define MAGICK_TAG_DEBUFF					(1<<5)

GLOBAL_LIST_INIT(magick_effect_static_data, init_magick_effect_static_data())

/proc/magick_get_datatype(value)
	if(islist(value))
		. = MAGICK_DATATYPE_FLAG_LIST
		for(var/datum/magick_value/item in value)
			. |= item.type
		return

	if(isnum(value))
		return MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_FLAG_SINGLE

	if(istext(value))
		return MAGICK_DATATYPE_STRING | MAGICK_DATATYPE_FLAG_SINGLE

	if(istype(value, /turf))
		return MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_SINGLE

	if(istype(value, /obj))
		return MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_SINGLE

	if(istype(value, /mob))
		return MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_SINGLE

	return MAGICK_DATATYPE_FLAG_SINGLE
