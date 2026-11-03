/datum/magick_focus/item/engineering_tool/
	abstract_type = /datum/magick_focus/item/engineering_tool/
	paradigms = PARADIGM_TECHNOMANCER
	icon = 'icons/obj/tools.dmi'
	precast_time = 1 TURNS

// Screwdriver
/datum/magick_focus/item/engineering_tool/screwdriver/
	name = "Item - Screwdriver"
	item_type = /obj/item/screwdriver
	icon_state = "screwdriver_brass"
	//icon_state = "screwdriver" // this is temp, the handle and tip icons are separated
	start_public_sound = 'sound/items/tools/screwdriver.ogg'
	finish_public_sound = 'sound/items/tools/screwdriver2.ogg'

// Wrench
/datum/magick_focus/item/engineering_tool/wrench/
	name = "Item - Wrench"
	item_type = /obj/item/wrench
	icon_state = "wrench"
	start_public_sound = 'sound/items/tools/ratchet.ogg'
	finish_public_sound = 'sound/items/tools/ratchet_slow.ogg'
	substitute_types = list(/obj/item/screwdriver/power)

// Welding Tool
/datum/magick_focus/item/engineering_tool/weldingtool/
	name = "Item - Welding Tool"
	item_type = /obj/item/weldingtool
	icon_state = "welder"
	start_public_sound = 'sound/items/tools/welder.ogg'
	finish_public_sound = 'sound/items/tools/welder2.ogg'

// Crowbar
/datum/magick_focus/item/engineering_tool/crowbar/
	name = "Item - Crowbar"
	item_type = /obj/item/crowbar
	icon_state = "crowbar"
	start_public_sound = 'sound/items/tools/crowbar.ogg'
	finish_public_sound = 'sound/items/tools/crowbar_prying.ogg'

// Wirecutters
/datum/magick_focus/item/engineering_tool/wirecutters/
	name = "Item - Wirecutters"
	item_type = /obj/item/wirecutters
	icon_state = "cutters"
	start_public_sound = 'sound/items/tools/wirecutter.ogg'
	finish_public_sound = 'sound/items/tools/wirecutter_cut.ogg'
	substitute_types = list(/obj/item/crowbar/power)

// Multitool
/datum/magick_focus/item/engineering_tool/multitool/
	name = "Item - Multitool"
	item_type = /obj/item/multitool
	icon = 'icons/obj/devices/tool.dmi'
	icon_state = "multitool"
	start_public_sound = 'sound/items/tools/screwdriver.ogg'
	finish_public_sound = 'sound/items/tools/screwdriver2.ogg'
