/obj/item/clothing/head/sinta_ronin
	name = "straw hat"
	desc = "A simple straw hat, completely protecting the head from harsh sun and heavy rain."
	icon = 'icons/obj/unathi_items.dmi'
	icon_state = "ronin_hat"
	item_state = "ronin_hat"
	contained_sprite = TRUE

/obj/item/clothing/head/sinta_ronin/worn_overlays(icon_file, slot)
	. = ..()
	if(slot == slot_head)
		var/mutable_appearance/M = mutable_appearance(icon_file, "[item_state]_head")
		M.appearance_flags = RESET_COLOR|RESET_ALPHA
		M.pixel_y = 2
		. += M