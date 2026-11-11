// Any changes should be updated in RoteBuilder\lib\constants.ts

// Search tags for the rote builder
#define MAGICK_TAG_CAST							(1<<0)
#define MAGICK_TAG_FOCI							(1<<1)
#define MAGICK_TAG_DATA							(1<<2) 	// For effects that do nothing besides data processing
#define MAGICK_TAG_UTILITY						(1<<3)
#define MAGICK_TAG_DAMAGE						(1<<4)
#define MAGICK_TAG_BUFF							(1<<5)
#define MAGICK_TAG_DEBUFF						(1<<6)

// These limits are for safety/performance reasons
#define ROTE_MAX_NODES 20
#define ROTE_MAX_TRAVERSAL 50
#define ROTE_SLEEP_INTERVAL 8
#define ROTE_FOR_LOOP_MAX_LIST 20
#define ROTE_FOR_LOOP_MAX_BRANCHES 10

#define ROTE_NODE_MAX_LIST_SIZE 20

// Helper defines for casting
#define ROTE_NODE_VISITED(context, node_id) ((node_id) in (context)?.visited_nodes)
#define ROTE_NODE_TYPE_VISITED(context, node_type) ((node_type) in (context)?.visited_node_types)

#define ROTE_IS_CASTING(rote) (!isnull((rote)?.active_context))

#define ROTE_SPHERES_VALID(user, option, result) \
	result = TRUE; \
	for(var/_sphere_key in (option)) { \
		if((user).st_get_stat(ALL_SPHERES[_sphere_key]) < (option)[_sphere_key]) { \
			result = FALSE; \
			break; \
		} \
	}
