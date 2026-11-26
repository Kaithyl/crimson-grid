// Any changes should be updated in RoteBuilder\lib\constants.ts and ports.ts

// TODO: Consider major cleanup, like give ATOM its own flag and have all atoms, ie TURF = ATOM | (1<<TURF bitflag)
// So checking for inheritence only needs to look at the ATOM bitflag
// Also move ORIGIN, SINGLE and LIST into their own extra_flags var

#define MAGICK_DATATYPE_ANY						(MAGICK_DATATYPE_STRING_OR_NUMBER | MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_PATTERN)
#define MAGICK_DATATYPE_TRIGGER					(1<<0)
#define MAGICK_DATATYPE_NUMBER  				(1<<1)
#define MAGICK_DATATYPE_STRING  				(1<<2)
#define MAGICK_DATATYPE_STRING_OR_NUMBER		(MAGICK_DATATYPE_NUMBER | MAGICK_DATATYPE_STRING)
#define MAGICK_DATATYPE_TURF    				(1<<3)
#define MAGICK_DATATYPE_OBJ     				(1<<4)
#define MAGICK_DATATYPE_MOB     				(1<<5)
#define MAGICK_DATATYPE_ATOM     				(MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_MOB)
#define MAGICK_DATATYPE_PATTERN					(1<<6)

#define MAGICK_DATATYPE_FLAG_DIRECTION			(1<<20)
#define MAGICK_DATATYPE_FLAG_ORIGIN				(1<<21)
#define MAGICK_DATATYPE_FLAG_SINGLE				(1<<22)
#define MAGICK_DATATYPE_FLAG_LIST				(1<<23)

// Any changes to this function should be reflected in
// tgui\packages\tgui\interfaces\RoteBuilder\lib\ports.ts\validLink()
#define MAGICK_DATATYPES_VALID(out_flags, in_flags) ( \
	(((out_flags) & MAGICK_DATATYPE_TRIGGER) || ((in_flags) & MAGICK_DATATYPE_TRIGGER)) \
		? ((((out_flags) & MAGICK_DATATYPE_TRIGGER) == ((in_flags) & MAGICK_DATATYPE_TRIGGER))) \
		: ( \
			(((out_flags) & MAGICK_DATATYPE_FLAG_LIST) == ((in_flags) & MAGICK_DATATYPE_FLAG_LIST)) \
			&& ( \
				((in_flags) & MAGICK_DATATYPE_STRING) \
				|| ( \
					((((out_flags) & ~(in_flags) & MAGICK_DATATYPE_ATOM) == 0)) \
					&& ((((out_flags) & ~(in_flags) & ~MAGICK_DATATYPE_ATOM & ~MAGICK_DATATYPE_FLAG_ORIGIN) == 0)) \
					&& (!((in_flags) & MAGICK_DATATYPE_FLAG_ORIGIN) || ((out_flags) & MAGICK_DATATYPE_FLAG_ORIGIN)) \
				) \
			) \
		) \
)
