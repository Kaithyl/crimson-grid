// These limits are for safety/performance reasons
#define ROTE_MAX_NODES 20
#define ROTE_MAX_TRAVERSAL 50
#define ROTE_SLEEP_INTERVAL 8
#define ROTE_FOR_LOOP_MAX_LIST 20
#define ROTE_FOR_LOOP_MAX_BRANCHES 10

#define ROTE_NODE_MAX_LIST_SIZE 20

#define ROTE_EXECUTION_DATA(node_id, scope, successes) alist("id" = node_id, "scope" = scope, "success" = successes)

#define MAGICK_TARGET_ENABLE_TEXT(label, count) "Select the [label ? label : "next target"] for your spell. ([count] manual target selections remaining)."
