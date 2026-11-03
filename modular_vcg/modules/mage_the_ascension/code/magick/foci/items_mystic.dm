/datum/magick_focus/item/mystic_tool/
	abstract_type = /datum/magick_focus/item/mystic_tool/
	paradigms = PARADIGM_MYSTIC
	precast_time = 1 TURNS

/datum/magick_focus/item/mystic_tool/wand
	name = "Item - Wand"
	item_type = /obj/item/staff
	icon = 'icons/obj/weapons/guns/magic.dmi'
	icon_state = "staff"

/datum/magick_focus/item/mystic_tool/spellbook
	name = "Item - Inscribed Book"
	// TEMP - TODO: Should work for generic books too
	item_type = /obj/item/path_spellbook
	icon = 'modular_darkpack/modules/paths/icons/paths.dmi'
	icon_state = "spellbook_unfinished"

/datum/magick_focus/item/mystic_tool/chalice
	name = "Item - Chalice"
	// TODO: Add item_types and this works with gold cups as well
	item_type = /obj/item/reagent_containers/cup/glass/trophy/silver_cup
	icon = 'icons/obj/drinks/bottles.dmi'
	icon_state = "silver_cup"

// TODO - Split this with Athame with different names between wiccans, hermetics and dreamspeakers
/datum/magick_focus/item/mystic_tool/dagger
	name = "Item - Dagger"
	// TODO: Add multiple item_types
	item_type = /obj/item/occult_artifact/werewolf/klaive
	icon = 'modular_darkpack/modules/werewolf_the_apocalypse/icons/weapons/weapons.dmi'
	icon_state = "klaive"
