// Search tags for the rote builder
#define MAGICK_TAG_ROOT							(1<<0)	// For root nodes in the execution tree
#define MAGICK_TAG_DATA							(1<<1) 	// For effects that do nothing besides data processing
#define MAGICK_TAG_UTILITY						(1<<2)
#define MAGICK_TAG_DAMAGE						(1<<3)
#define MAGICK_TAG_BUFF							(1<<4)
#define MAGICK_TAG_DEBUFF						(1<<5)

// These limits are for safety/performance reasons
#define MAGICK_MAX_NODES 20
#define MAGICK_MAX_TRAVERSAL 50
#define MAGICK_SLEEP_INTERVAL 8
#define MAGICK_FOR_LOOP_MAX_LIST 20
#define MAGICK_FOR_LOOP_MAX_BRANCHES 10
