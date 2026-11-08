#define MAGICK_DATATYPE_TRIGGER					(1<<0)
#define MAGICK_DATATYPE_NUMBER  				(1<<1)
#define MAGICK_DATATYPE_STRING  				(1<<2)
#define MAGICK_DATATYPE_STRING_OR_NUMBER		(MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_STRING)
#define MAGICK_DATATYPE_TURF    				(1<<3)
#define MAGICK_DATATYPE_OBJ     				(1<<4)
#define MAGICK_DATATYPE_MOB     				(1<<5)
#define MAGICK_DATATYPE_ATOM     				(MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_MOB)

#define MAGICK_DATATYPE_FLAG_ORIGIN				(1<<21)
#define MAGICK_DATATYPE_FLAG_SINGLE				(1<<22)
#define MAGICK_DATATYPE_FLAG_LIST				(1<<23)

// Any changes to this function should be reflected in
// tgui\packages\tgui\interfaces\RoteBuilder\lib\ports.ts\validLink()
#define MAGICK_DATATYPES_VALID(out_flags, in_flags) ( \
	(((out_flags) & MAGICK_DATATYPE_TRIGGER) || ((in_flags) & MAGICK_DATATYPE_TRIGGER)) \
		? ((((out_flags) & MAGICK_DATATYPE_TRIGGER) == ((in_flags) & MAGICK_DATATYPE_TRIGGER))) \
		: ( \
			((((out_flags) & ~(in_flags) & MAGICK_DATATYPE_ATOM) == 0)) \
			&& ((((out_flags) & ~(in_flags) & ~MAGICK_DATATYPE_ATOM & ~MAGICK_DATATYPE_FLAG_ORIGIN) == 0)) \
			&& (!((in_flags) & MAGICK_DATATYPE_FLAG_ORIGIN) || ((out_flags) & MAGICK_DATATYPE_FLAG_ORIGIN)) \
		) \
)

/proc/magick_get_datatype(value)
	if(islist(value))
		. = MAGICK_DATATYPE_FLAG_LIST
		// TODO: Probably needs a more robust system for enforcing or checking monotypes
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
