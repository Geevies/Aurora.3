/obj/item/cargo_backpack
	name = "cargo pack"
	desc = "A robust set of rigs and buckles that allows the wearer to carry two additional Orion Express delivery packages on their back."
	desc_info = "To load packages onto your back, equip this item on the back slot, then click on it with a package in-hand. To unload a package, click on this item with an empty hand."
	icon = 'icons/obj/orion_delivery.dmi'
	icon_state = "package_pack"
	item_state = "package_pack"
	contained_sprite = TRUE
	w_class = ITEMSIZE_HUGE
	slot_flags = SLOT_BACK
	var/species_restricted = list("exclude",BODYTYPE_VAURCA_BREEDER,BODYTYPE_VAURCA_WARFORM)
	drop_sound = 'sound/items/drop/backpack.ogg'
	pickup_sound = 'sound/items/pickup/backpack.ogg'

	var/list/contained_packages

/obj/item/cargo_backpack/Destroy()
	QDEL_NULL(contained_packages)
	return ..()

/obj/item/cargo_backpack/examine(mob/user, distance)
	. = ..()
	if(length(contained_packages))
		for(var/obj/item/cargo_package/package in contained_packages)
			to_chat(user, SPAN_NOTICE(" - SITE: <b>[package.delivery_point_sector]</b> | COORD: <b>[package.delivery_point_coordinates]</b> | ID: <b>[package.delivery_point_id]</b>"))

/obj/item/cargo_backpack/proc/update_state()
	if(LAZYLEN(contained_packages))
		slowdown = 1
	else
		slowdown = 0
	update_icon()

/obj/item/cargo_backpack/update_icon()
	if(LAZYLEN(contained_packages))
		item_state = "[initial(item_state)]_[length(contained_packages)]"
	else
		item_state = initial(item_state)
	if(ishuman(loc))
		var/mob/living/carbon/human/courier = loc
		courier.update_inv_back()

/obj/item/cargo_backpack/get_mob_overlay(var/mob/living/carbon/human/courier, var/mob_icon, var/mob_state, var/slot)
	var/image/mob_overlay = ..()
	mob_overlay.layer = courier.layer + 0.01 // we want the tall backpack to render over hair and helmets
	mob_overlay.appearance_flags |= KEEP_APART
	return mob_overlay

/obj/item/cargo_backpack/attack_hand(mob/living/carbon/human/user)
	if(!ishuman(user))
		return ..()
	if(!LAZYLEN(contained_packages))
		return ..()

	if(user.species.mob_size < 12)
		var/obj/A = user.get_inactive_hand()
		if(A)
			to_chat(user, SPAN_WARNING("Your other hand is occupied!"))
			return

	user.visible_message("<b>[user]</b> starts unloading a package from \the [src]...", SPAN_NOTICE("You start unloading a package from \the [src]..."))
	if(do_after(user, 1 SECONDS, src, DO_UNIQUE))
		if(user.species.mob_size < 12)
			var/obj/A = user.get_inactive_hand()
			if(A)
				to_chat(user, SPAN_WARNING("Your other hand is occupied!"))
				return
		user.visible_message("<b>[user]</b> unloads a package from \the [src]!", SPAN_NOTICE("You unload a package from \the [src]!"))
		var/obj/item/cargo_package/package = contained_packages[1]
		user.put_in_hands(package)
		if(user.species.mob_size < 12)
			package.wield(user)
		LAZYREMOVE(contained_packages, package)
		update_state()

/obj/item/cargo_backpack/attackby(obj/item/item, mob/living/carbon/human/user)
	if(!ishuman(user))
		return ..()
	if(user.back != src)
		if(istype(item, /obj/item/cargo_package))
			to_chat(user, SPAN_WARNING("Put \the [src] on your back before you load packages onto it!"))
			return
		return ..()
	if(!istype(item, /obj/item/cargo_package))
		return ..()

	if(LAZYLEN(contained_packages) >= 2)
		to_chat(user, SPAN_WARNING("\The [src] is already fully loaded!"))
		return

	user.visible_message("<b>[user]</b> starts loading \the [item] onto \the [src]...", SPAN_NOTICE("You start loading \the [item] onto \the [src]..."))
	if(do_after(user, 1 SECONDS, src, DO_UNIQUE))
		user.visible_message("<b>[user]</b> loads \the [item] onto \the [src]!", SPAN_NOTICE("You load \the [item] onto \the [src]!"))
		user.drop_from_inventory(item, src)
		LAZYADD(contained_packages, item)
		update_state()
