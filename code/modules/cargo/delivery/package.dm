/obj/item/cargo_package
	name = "cargo package"
	desc = "An Orion Express cargo package, these packages generally find their way to researchers bunkered up on exoplanets. Always pays an extra 2% tip to the courier."
	desc_info = "You can deliver this package to a delivery site on an exoplanet to get additional funds for the cargo department's account. An additional 2% is added to your account on delivery. Can be loaded into a cargo pack."
	icon = 'icons/obj/orion_delivery.dmi'
	icon_state = "express_package"
	item_state = "express_package"
	contained_sprite = TRUE
	w_class = ITEMSIZE_HUGE
	force = 10

	slowdown = 1

	var/delivery_point_id = ""
	var/delivery_point_sector = ""
	var/delivery_point_coordinates = ""

	var/datum/weakref/associated_delivery_point
	var/pay_amount = 69420

/obj/item/cargo_package/Initialize(mapload, obj/structure/cargo_receptacle/delivery_point)
	. = ..()
	pay_amount = rand(4, 7) * 1000
	if(prob(3))
		pay_amount = rand(12, 17) * 1000
	if(delivery_point)
		associated_delivery_point = WEAKREF(delivery_point)
		delivery_point_id = delivery_point.delivery_id
		delivery_point_sector = delivery_point.delivery_sector
		delivery_point_coordinates = "[delivery_point.x]-[delivery_point.y]"

/obj/item/cargo_package/examine(mob/user, distance)
	. = ..()
	to_chat(user, SPAN_NOTICE("The label on the package reads: SITE: <b>[delivery_point_sector]</b> | COORD: <b>[delivery_point_coordinates]</b> | ID: <b>[delivery_point_id]</b>"))
	to_chat(user, SPAN_NOTICE("The price tag on the package reads: <b>[pay_amount]电</b>"))

/obj/item/cargo_package/do_additional_pickup_checks(var/mob/living/carbon/human/user)
	if(!ishuman(user))
		return FALSE

	if(user.species.mob_size < 12)
		var/obj/A = user.get_inactive_hand()
		if(A)
			to_chat(user, SPAN_WARNING("Your other hand is occupied!"))
			return

	user.visible_message("<b>[user]</b> tightens their grip on \the [src] and starts heaving...", SPAN_NOTICE("You tighten your grip on \the [src] and start heaving..."))
	if(do_after(user, 1 SECONDS, src, DO_UNIQUE))
		user.visible_message("<b>[user]</b> heaves \the [src] up!", SPAN_NOTICE("You heave \the [src] up!"))
		// larger mobs, such as industrials, can hold two pieces of cargo
		if(user.species.mob_size < 12)
			wield(user)
			slowdown = 2
		else
			slowdown = 0
		return TRUE
	return FALSE

/obj/item/cargo_package/proc/wield(var/mob/living/carbon/human/user)
	var/obj/A = user.get_inactive_hand()
	if(A)
		to_chat(user, SPAN_WARNING("Your other hand is occupied!"))
		return
	item_state += "_wielded"
	var/obj/item/offhand/O = new(user)
	O.name = "[initial(name)] - offhand"
	O.desc = "Your second grip on \the [initial(name)]."
	user.put_in_inactive_hand(O)

/obj/item/cargo_package/dropped(var/mob/living/user)
	..()
	item_state = initial(item_state)
	if(user)
		var/obj/item/offhand/O = user.get_inactive_hand()
		if(istype(O))
			O.unwield()

/obj/item/cargo_package/can_swap_hands(var/mob/user)
	var/obj/item/offhand/O = user.get_inactive_hand()
	if(istype(O))
		return FALSE
	return TRUE

/obj/item/cargo_package/too_heavy_to_throw()
	return TRUE
