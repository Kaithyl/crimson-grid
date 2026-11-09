//Note: This could be switched to get_all_tool_behaviors over types

/datum/magick_focus/item/surgical_tool/
	abstract_type = /datum/magick_focus/item/surgical_tool/
	paradigms = PARADIGM_TECHNOMANCER
	icon = 'icons/obj/medical/surgery_tools.dmi'
	precast_time = 1 TURNS

// Scalpel
/datum/magick_focus/item/surgical_tool/scalpel/
	name = "Item - Scalpel"
	item_type = /obj/item/scalpel
	icon_state = "scalpel"
	start_public_sound = 'sound/items/handling/surgery/scalpel1.ogg'
	finish_public_sound = 'sound/items/handling/surgery/scalpel2.ogg'
	substitute_types = list(/obj/item/knife, /obj/item/shard)

// Retractor
/datum/magick_focus/item/surgical_tool/retractor/
	name = "Item - Retractor"
	item_type = /obj/item/retractor
	icon_state = "retractor"
	start_public_sound = 'sound/items/handling/surgery/retractor1.ogg'
	finish_public_sound = 'sound/items/handling/surgery/retractor2.ogg'
	substitute_types = list(/obj/item/screwdriver, /obj/item/wirecutters,
		/obj/item/kitchen/fork, /obj/item/kitchen/spoon, /obj/item/stack/rods)

// Hemostat
/datum/magick_focus/item/surgical_tool/hemostat/
	name = "Item - Hemostat"
	item_type = /obj/item/hemostat
	icon_state = "hemostat"
	start_public_sound = 'sound/items/handling/surgery/hemostat1.ogg'
	substitute_types = list(/obj/item/retractor/advanced, /obj/item/wirecutters, /obj/item/stack/cable_coil, /obj/item/stack/package_wrap)

// Cautery
/datum/magick_focus/item/surgical_tool/cautery/
	name = "Item - Cautery"
	item_type = /obj/item/cautery
	icon_state = "cautery"
	start_public_sound = 'sound/items/handling/surgery/cautery1.ogg'
	finish_public_sound = 'sound/items/handling/surgery/cautery2.ogg'
	substitute_types = list(/obj/item/weldingtool, /obj/item/lighter)

// Circular Saw
/datum/magick_focus/item/surgical_tool/circular_saw/
	name = "Item - Circular Saw"
	item_type = /obj/item/circular_saw
	icon_state = "saw"
	start_public_sound = 'sound/items/handling/surgery/saw.ogg'
	substitute_types = list(/obj/item/scalpel/advanced, /obj/item/knife/butcher, /obj/item/hatchet, /obj/item/fireaxe,
		/obj/item/shovel/serrated, /obj/item/melee/arm_blade)

// Surgical Drill
/datum/magick_focus/item/surgical_tool/surgicaldrill/
	name = "Item - Surgical Drill"
	item_type = /obj/item/surgicaldrill
	icon_state = "drill"
	start_public_sound = 'sound/items/tools/drill_use.ogg'
	substitute_types = list(/obj/item/cautery/advanced, /obj/item/screwdriver/power, /obj/item/pickaxe/drill)

// Blood Filter
/datum/magick_focus/item/surgical_tool/blood_filter/
	name = "Item - Blood Filter"
	item_type = /obj/item/blood_filter
	icon_state = "bloodfilter"
	start_public_sound = 'sound/machines/card_slide.ogg'

/*
	// butcher's cleaver stands in for a saw
	start_public_sounds[/obj/item/knife/butcher] = 'sound/items/handling/surgery/scalpel1.ogg'
	finish_public_sounds[/obj/item/knife/butcher] = 'sound/items/handling/surgery/scalpel2.ogg'

	// glass shard stands in for a scalpel
	start_public_sounds[/obj/item/shard] = 'sound/items/handling/surgery/scalpel1.ogg'

	// pen stands in for a scalpel
	start_public_sounds[/obj/item/pen] = 'sound/items/handling/surgery/scalpel1.ogg'

	// screwdriver stands in for a retractor / drill
	start_public_sounds[/obj/item/screwdriver] = 'sound/items/tools/screwdriver.ogg'
	finish_public_sounds[/obj/item/screwdriver] = 'sound/items/tools/screwdriver2.ogg'

	// hand drill stands in for a surgical drill
	start_public_sounds[/obj/item/screwdriver/power] = 'sound/items/tools/drill_use.ogg'

	// wirecutters stand in for a retractor / hemostat
	start_public_sounds[/obj/item/wirecutters] = 'sound/items/tools/wirecutter.ogg'
	finish_public_sounds[/obj/item/wirecutters] = 'sound/items/tools/wirecutter_cut.ogg'

	// fork stands in for a retractor
	start_public_sounds[/obj/item/kitchen/fork] = 'sound/items/handling/surgery/retractor1.ogg'
	finish_public_sounds[/obj/item/kitchen/fork] = 'sound/items/handling/surgery/retractor2.ogg'

	// spoon stands in for a retractor / drill
	start_public_sounds[/obj/item/kitchen/spoon] = 'sound/items/tools/screwdriver.ogg'
	finish_public_sounds[/obj/item/kitchen/spoon] = 'sound/items/tools/screwdriver2.ogg'

	// rods stand in for a retractor
	start_public_sounds[/obj/item/stack/rods] = 'sound/items/handling/surgery/retractor1.ogg'
	finish_public_sounds[/obj/item/stack/rods] = 'sound/items/handling/surgery/retractor2.ogg'

	// cable coil stands in for a hemostat
	start_public_sounds[/obj/item/stack/cable_coil] = 'sound/items/tools/wirecutter.ogg'
	finish_public_sounds[/obj/item/stack/cable_coil] = 'sound/items/tools/wirecutter_cut.ogg'

	// package wrap stands in for a hemostat
	start_public_sounds[/obj/item/stack/package_wrap] = 'sound/items/handling/surgery/hemostat1.ogg'

	// welding tool stands in for a cautery
	start_public_sounds[/obj/item/weldingtool] = 'sound/items/tools/welder.ogg'
	finish_public_sounds[/obj/item/weldingtool] = 'sound/items/tools/welder2.ogg'

	// lighter stands in for a cautery
	start_public_sounds[/obj/item/lighter] = 'sound/items/tools/welder.ogg'
	finish_public_sounds[/obj/item/lighter] = 'sound/items/handling/surgery/cautery2.ogg'

	// hatchet stands in for a saw
	start_public_sounds[/obj/item/hatchet] = 'sound/items/handling/surgery/scalpel1.ogg'

	// fire axe stands in for a saw
	start_public_sounds[/obj/item/fireaxe] = 'sound/items/handling/surgery/scalpel1.ogg'

	// serrated shovel stands in for a saw
	start_public_sounds[/obj/item/shovel/serrated] = 'sound/items/handling/surgery/saw.ogg'

	// arm blade stands in for a saw
	start_public_sounds[/obj/item/melee/arm_blade] = 'sound/items/handling/surgery/scalpel1.ogg'

	// mining drill stands in for a surgical drill
	start_public_sounds[/obj/item/pickaxe/drill] = 'sound/items/tools/drill_use.ogg'
*/
