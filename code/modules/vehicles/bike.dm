/obj/vehicle/bike
	name = "space-bike"
	desc = "Space wheelies! Woo! "
	icon = 'icons/obj/bike.dmi'
	icon_state = "bike_off"
	dir = SOUTH

	load_item_visible = 1
	mob_offset_y = 5
	health = 100
	maxhealth = 100

	can_pull = TRUE

	fire_dam_coeff = 0.6
	brute_dam_coeff = 0.5
	var/protection_percent = 60

	var/land_speed = 10 //if 0 it can't go on turf
	var/space_speed = 1
	var/bike_icon = "bike"

	var/datum/effect_system/ion_trail/ion
	var/kickstand = TRUE

/obj/vehicle/bike/Initialize()
	. = ..()
	ion = new /datum/effect_system/ion_trail(src)
	turn_off()
	add_overlay(image('icons/obj/bike.dmi', "[icon_state]_off_overlay", MOB_LAYER + 1))
	icon_state = "[bike_icon]_off"

/obj/vehicle/bike/examine(mob/user)
	. = ..()
	if(kickstand)
		to_chat(user, span("notice", "It has its kickstand deployed."))

/obj/vehicle/bike/verb/toggle()
	set name = "Toggle Engine"
	set category = "Vehicle"
	set src in view(0)

	if(usr.incapacitated())
		return

	if(!on)
		turn_on()
		visible_message(span("notice", "\The [src] rumbles to life."), span("notice", "You hear something rumble deeply."))
		playsound(src, 'sound/misc/bike_start.ogg', 100, TRUE)
	else
		turn_off()
		visible_message(span("notice", "\The [src] putters before turning off."), span("notice", "You hear something putter slowly."))

/obj/vehicle/bike/verb/kickstand()
	set name = "Toggle Kickstand"
	set category = "Vehicle"
	set src in view(0)

	if(usr.incapacitated())
		return

	if(kickstand)
		usr.visible_message(span("notice", "\The [usr] puts up \the [src]'s kickstand."), span("notice", "You put up \the [src]'s kickstand."), span("notice", "You hear a thunk."))
		playsound(src, 'sound/misc/bike_stand_up.ogg', 50, TRUE)
	else
		if(isturf(loc))
			var/turf/T = loc
			if(T.is_hole)
				to_chat(usr, span("warning", "You don't think kickstands work here."))
				return
		usr.visible_message(span("notice", "\The [usr] puts down \the [src]'s kickstand."), span("notice", "You put down \the [src]'s kickstand."), span("notice", "You hear a thunk."))
		playsound(src, 'sound/misc/bike_stand_down.ogg', 50, TRUE)
		if(pulledby)
			pulledby.stop_pulling()

	kickstand = !kickstand
	can_pull = kickstand

/obj/vehicle/bike/load(atom/movable/C)
	var/mob/living/M = C
	if(!istype(C))
		return FALSE
	if(M.buckled || M.restrained() || !Adjacent(M) || !M.Adjacent(src))
		return FALSE
	return ..(M)

/obj/vehicle/bike/MouseDrop_T(atom/movable/C, mob/user)
	if(!load(C))
		to_chat(user, span("warning", "You were unable to load \the [C] onto \the [src]."))
		return

/obj/vehicle/bike/attack_hand(mob/user)
	if(user == load)
		unload(load)
		to_chat(user, span("notice", "You unbuckle yourself from \the [src]."))
	else if(user != load && load)
		user.visible_message(span("notice", "\The [user] starts to unbuckle \the [load] from \the [src]!"))
		if(do_after(user, 8 SECONDS, act_target = src))
			unload(load)
			to_chat(user, span("notice", "You unbuckle \the [load] from \the [src]."))
			to_chat(load, span("notice", "You were unbuckled from \the [src] by \the [user]."))

/obj/vehicle/bike/relaymove(mob/user, direction)
	if(user != load || !on || user.incapacitated())
		return
	if(kickstand)
		to_chat(user, span("warning", "You cannot move while the kickstand is deployed."))
		return
	return Move(get_step(src, direction))

/obj/vehicle/bike/Move(turf/destination)
	//these things like space, not turf. Dragging shouldn't weigh you down.
	var/static/list/types = typecacheof(list(/turf/space, /turf/simulated/open, /turf/unsimulated/floor/asteroid))
	if(is_type_in_typecache(destination,types) || pulledby)
		if(!space_speed)
			return FALSE
		move_delay = space_speed
	else
		if(!land_speed)
			return FALSE
		move_delay = land_speed
	return ..()

/obj/vehicle/bike/turn_on()
	ion.start()
	can_pull = FALSE

	update_icon()

	if(pulledby)
		pulledby.stop_pulling()
	..()

/obj/vehicle/bike/turn_off()
	ion.stop()
	can_pull = kickstand

	update_icon()

	..()

/obj/vehicle/bike/bullet_act(obj/item/projectile/Proj)
	if(buckled_mob && prob(protection_percent))
		buckled_mob.bullet_act(Proj)
		return
	..()

/obj/vehicle/bike/update_icon()
	cut_overlays()

	if(on)
		add_overlay(image('icons/obj/bike.dmi', "[bike_icon]_on_overlay", MOB_LAYER + 1))
		icon_state = "[bike_icon]_on"
	else
		add_overlay(image('icons/obj/bike.dmi', "[bike_icon]_off_overlay", MOB_LAYER + 1))
		icon_state = "[bike_icon]_off"
	..()


/obj/vehicle/bike/Destroy()
	QDEL_NULL(ion)
	return ..()

/obj/vehicle/bike/speeder
	name = "retrofitted speeder"
	desc = "A short bike that seems to consist mostly of an engine, a hover repulsor, vents and a steering shaft."
	icon_state = "speeder_on"

	health = 150
	maxhealth = 150

	fire_dam_coeff = 0.5
	brute_dam_coeff = 0.4

	bike_icon = "speeder"