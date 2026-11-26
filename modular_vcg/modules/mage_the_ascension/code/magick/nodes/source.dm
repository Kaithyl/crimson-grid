// These are root nodes that should execute with player-input values upon casting

/datum/rote_node/source/
	abstract_type = /datum/rote_node/source/
	tags = MAGICK_TAG_DATA

	complexity = 1

	var/out_value = "out_value"

	// Optional ports used to preview the tiles affected by this source while targeting
	var/in_pattern = "in_pattern"
	var/in_dir = "in_dir"

	outputs = new(
		out_value = alist("name" = "Target", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

// Resolves the target when execution reaches this node, or suspends the cast until the caster picks one
/datum/rote_node/source/execute(datum/magick_context/context)
	var/node_id = context.current_node_id
	if (!isnull(context.read(node_id, out_value)))
		return
	if (requires_crosshair(context, node_id))
		// Re-queue this node at the front and suspend, it is resumed once a target is pushed
		context.push_stack(node_id, context.current_scope.successes)
		context.status = ROTE_AWAITING_TARGET
		return
	var/target = resolve_target(context.caster)
	if (target)
		push_target(context, node_id, target)

/datum/rote_node/source/proc/resolve_target(mob/caster)
	return null

// Whether the caster must use a crosshair before this node can resolve
/datum/rote_node/source/proc/requires_crosshair(datum/magick_context/context, node_id)
	return needs_crosshair

/datum/rote_node/source/proc/is_valid_target(atom/clicked_on, mob/caster)
	return TRUE

// Converts the clicked atom into the target this node outputs
/datum/rote_node/source/proc/get_clicked_target(atom/clicked_on, mob/caster)
	return clicked_on

// Pushes this source node's resolved target into the correct port of the running context
/datum/rote_node/source/proc/push_target(datum/magick_context/context, node_id, atom/target)
	var/previous_node_id = context.current_node_id
	context.current_node_id = node_id
	context.assign(out_value, target, outputs?[out_value]?["type"])
	context.current_node_id = previous_node_id

// If preview mechanic is used, show turfs targeted
/datum/rote_node/source/proc/get_preview_turfs(datum/magick_context/context, node_id, atom/origin)
	var/datum/magick_value/pattern_value = context.read(node_id, in_pattern)
	var/list/pattern = pattern_value?.value
	if (!islist(pattern) || !length(pattern))
		return null
	var/turf/origin_turf = get_turf(origin)
	if (!origin_turf)
		return null
	var/datum/magick_value/dir_value = context.read(node_id, in_dir)
	var/direction = dir_value?.value
	if (!direction || direction == MAGICK_DIRECTION_CASTER)
		direction = context.caster?.dir || NORTH
	var/list/turfs = list()
	for (var/list/offset in rotate_pattern(pattern, direction))
		var/turf/selected = locate(origin_turf.x + offset[1], origin_turf.y + offset[2], origin_turf.z)
		if (selected)
			turfs += selected
	return turfs

/datum/rote_node/source/proc/get_preview_origin(mob/caster, turf/mouse_turf, atom/hovered_atom)
	return caster

// Generates the actual images used for the preview
/datum/rote_node/source/proc/show_target_preview(datum/magick_rote/rote, datum/magick_context/context, node_id, mob/caster, atom/origin)
	var/list/turfs = get_preview_turfs(context, node_id, origin)
	if (!length(turfs) || !caster?.client)
		return
	var/list/tile_images = list()
	for (var/turf/selected as anything in turfs)
		// if anything goes wrong reference bm_mode.dm (highlight_region)
		// TODO: Allow color to be set
		var/image/tile_image = image('icons/turf/overlays.dmi', selected, "greyOverlay", ABOVE_ALL_MOB_LAYER)
		SET_PLANE(tile_image, ABOVE_LIGHTING_PLANE, selected)
		tile_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		tile_image.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
		//tile_image.color = "#ffffff"
		tile_image.alpha = 50
		tile_images += tile_image
	caster.client.images += tile_images
	if (!rote.preview_images)
		rote.preview_images = list()
	rote.preview_images += tile_images

// Target (Self)

/datum/rote_node/source/target_self
	name = "Target (Self)"

	inputs = new(
		in_pattern = MAGICK_PORT_PATTERN(FALSE, 3, FALSE),
		in_dir = MAGICK_PORT_DIRECTION(TRUE, TRUE),
	)

/datum/rote_node/source/target_self/resolve_target(mob/caster)
	return caster

// Enter crosshair mode when a pattern is set so the caster can see the preview tiles
/datum/rote_node/source/target_self/requires_crosshair(datum/magick_context/context, node_id)
	var/datum/magick_value/pattern_value = context.read(node_id, in_pattern)
	var/list/pattern = pattern_value?.value
	return islist(pattern) && length(pattern)

// Clicking anywhere confirms, the target is always the caster
/datum/rote_node/source/target_self/get_clicked_target(atom/clicked_on, mob/caster)
	return caster

// Target (Item)

/datum/rote_node/source/target_item_hands
	name = "Target (Item)"

/datum/rote_node/source/target_item_hands/resolve_target(mob/caster)
	for (var/obj/item/held_item in caster.held_items)
		if (held_item)
			return held_item
	return null

// Target (Melee)

/datum/rote_node/source/target_melee
	//abstract_type = /datum/rote_node/source/target_melee
	name = "Target (Melee)"
	needs_crosshair = TRUE
	var/melee_target_type = /atom/movable

/datum/rote_node/source/target_melee/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, melee_target_type) && (get_dist(caster, clicked_on) <= 1)

/datum/rote_node/source/target_melee/_turf
	name = "Target (Melee Turf)"
	melee_target_type = /turf
	outputs = new(
		out_value = alist("name" = "Target", "type" = MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_melee/_mob
	name = "Target (Melee Mob)"
	melee_target_type = /mob/living
	outputs = new(
		out_value = alist("name" = "Target", "type" = MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_melee/_obj
	name = "Target (Melee Obj)"
	melee_target_type = /obj
	outputs = new(
		out_value = alist("name" = "Target", "type" = MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_ORIGIN | MAGICK_DATATYPE_FLAG_SINGLE),
	)

// Target (Clicked)

/datum/rote_node/source/target_clicked
	//abstract_type = /datum/rote_node/source/target_clicked
	name = "Target (Clicked)"
	needs_crosshair = TRUE
	var/clicked_target_type = /atom
	outputs = new(
		out_value = alist("name" = "Target", "type" = MAGICK_DATATYPE_ATOM | MAGICK_DATATYPE_FLAG_SINGLE),
	)

	inputs = new(
		in_pattern = MAGICK_PORT_PATTERN(FALSE, 3, TRUE),
		in_dir = MAGICK_PORT_DIRECTION(TRUE, TRUE),
	)

// Only preview while the cursor is over a valid target
/datum/rote_node/source/target_clicked/get_preview_origin(mob/caster, turf/mouse_turf, atom/hovered_atom)
	if (!is_valid_target(hovered_atom, caster))
		return null
	return mouse_turf

/datum/rote_node/source/target_clicked/is_valid_target(atom/clicked_on, mob/caster)
	return istype(clicked_on, clicked_target_type)

/datum/rote_node/source/target_clicked/_turf
	name = "Target (Clicked Turf)"
	clicked_target_type = /turf
	outputs = new(
		out_value = alist("name" = "Target (Turf)", "type" = MAGICK_DATATYPE_TURF | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_clicked/_mob
	name = "Target (Clicked Mob)"
	clicked_target_type = /mob
	outputs = new(
		out_value = alist("name" = "Target (Mob)", "type" = MAGICK_DATATYPE_MOB | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/target_clicked/_obj
	name = "Target (Clicked Obj)"
	clicked_target_type = /obj
	outputs = new(
		out_value = alist("name" = "Target (Obj)", "type" = MAGICK_DATATYPE_OBJ | MAGICK_DATATYPE_FLAG_SINGLE),
	)

/datum/rote_node/source/primitive/
	abstract_type = /datum/rote_node/source/primitive/

/datum/rote_node/source/primitive/direction
	name = "Direction"
	outputs = new(
		out_value = MAGICK_PORT_DIRECTION(TRUE, FALSE)
	)

/datum/rote_node/source/primitive/string
	name = "Text"
	outputs = new(
		out_value = MAGICK_PORT_STRING("Text", null, TRUE),
	)

/datum/rote_node/source/primitive/integer
	name = "Number"
	outputs = new(
		out_value = MAGICK_PORT_NUMBER_("Number", 0, TRUE),
	)

/datum/rote_node/source/primitive/pattern_small
	name = "Pattern (Small)"
	outputs = new(
		out_value = MAGICK_PORT_PATTERN(TRUE, 3, FALSE),
	)

/datum/rote_node/source/primitive/pattern_medium
	name = "Pattern (Medium)"
	complexity = 2
	outputs = new(
		out_value = MAGICK_PORT_PATTERN(TRUE, 5, FALSE),
	)

/datum/rote_node/source/primitive/pattern_large
	name = "Pattern (Large)"
	complexity = 3
	outputs = new(
		out_value = MAGICK_PORT_PATTERN(TRUE, 7, FALSE),
	)
