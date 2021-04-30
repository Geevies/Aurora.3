/obj/item/clothing/suit/unathi
	name = "abstract suit"
	icon = 'icons/obj/unathi_items.dmi'
	contained_sprite = TRUE

/obj/item/clothing/suit/unathi/himation
	name = "himation cloak"
	desc = "The himation is a staple of unathi fashion. Whether a commoner in practical clothes to a noble looking for leisure wear, the himation has remained stylish for centuries."
	desc_fluff = "The himation while unwrapped is usually a three meter around cloth. Unathi start by putting the front around their waist, bring it over their right shoulder, and then form a sash-like loop by bringing it over their right again. A belt ties it off and drapes a skirt down over their thighs to complete the look. Fashionable for simple noble wear (the cloth can be embroidered), and practical for labor!"
	icon_state = "himation"
	item_state = "himation"
	var/additional_color = COLOR_GRAY // default

/obj/item/clothing/suit/unathi/himation/worn_overlays(icon_file, contained_flag)
	. = ..()
	if(contained_flag == WORN_SUIT)
		var/image/skirt = image(icon_file, null, "himation_su_skirt")
		skirt.appearance_flags = RESET_COLOR
		skirt.color = additional_color
		. += skirt
		var/image/belt = image(icon_file, null, "himation_su_belt")
		belt.appearance_flags = RESET_COLOR
		. += belt