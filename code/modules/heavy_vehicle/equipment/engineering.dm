/obj/item/mecha_equipment/mounted_system/rfd
	name = "mounted rfd"
	icon_state = "mecha_rfd"
	holding_type = /obj/item/rfd/construction/mounted/exosuit
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_ENGINEERING)

/obj/item/mecha_equipment/mounted_system/rfd/CtrlClick(mob/user)
	if(owner && istype(holding, /obj/item/rfd/construction/mounted/exosuit))
		var/obj/item/rfd/construction/mounted/exosuit/R = holding
		var/current_mode = show_radial_menu(user, owner, R.radial_modes, radius = 42, require_near = FALSE , tooltips = TRUE)
		switch(current_mode)
			if("Floors and Walls")
				R.mode = RFD_FLOORS_AND_WALL
			if("Windows and Grille")
				R.mode = RFD_WINDOW_AND_FRAME
			if("Airlock")
				R.mode = RFD_AIRLOCK
			if("Deconstruct")
				R.mode = RFD_DECONSTRUCT
			else
				R.mode = RFD_FLOORS_AND_WALL
		if(current_mode)
			to_chat(user, SPAN_NOTICE("You set the device to <i>\"[current_mode]\"</i>."))
			if(R.mode == 3)
				playsound(get_turf(src), 'sound/weapons/laser_safetyoff.ogg', 50, FALSE)
			else
				playsound(get_turf(src), 'sound/weapons/laser_safetyon.ogg', 50, FALSE)
	else
		return

/obj/item/rfd/construction/mounted/exosuit/attack_self(mob/user) //we don't want this attack_self, as it would target the pilot not the exosuit.
	return

/obj/item/rfd/construction/mounted/exosuit/get_hardpoint_maptext()
	var/obj/item/mecha_equipment/mounted_system/MS = loc
	if(istype(MS) && MS.owner)
		var/obj/item/cell/C = MS.owner.get_cell()
		if(istype(C))
			return "[round(C.charge)]/[round(C.maxcharge)]"
	return null

/obj/item/rfd/construction/mounted/exosuit/get_hardpoint_status_value()
	var/obj/item/mecha_equipment/mounted_system/MS = loc
	if(istype(MS) && MS.owner)
		var/obj/item/cell/C = MS.owner.get_cell()
		if(istype(C))
			return C.charge/C.maxcharge
	return null

/obj/item/extinguisher/mech
	name = "mounted fire extinguisher"
	max_water = 4000 //Good is gooder
	icon = 'icons/mecha/mech_equipment.dmi'
	icon_state = "mecha_exting"
	safety = FALSE

/obj/item/extinguisher/mech/New()
	reagents = new/datum/reagents(max_water)
	reagents.my_atom = src
	reagents.add_reagent(/decl/reagent/toxin/fertilizer/monoammoniumphosphate, max_water)
	..()

/obj/item/extinguisher/mech/get_hardpoint_maptext()
	return "[reagents.total_volume]/[max_water]"

/obj/item/extinguisher/mech/get_hardpoint_status_value()
	return reagents.total_volume/max_water

/obj/item/mecha_equipment/mounted_system/extinguisher
	name = "mounted extinguisher"
	icon_state = "mecha_exting"
	holding_type = /obj/item/extinguisher/mech
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_ENGINEERING)

// A shoulder mounted emitter, it isn't a mounted system so mechs are forced to fire in cardinal directions like normal emitters
/obj/item/mecha_equipment/emitter
	name = "shoulder-mounted exosuit emitter"
	desc = "An exosuit-mounted emitter."
	icon_state = "mech_floodlight"
	restricted_hardpoints = list(HARDPOINT_LEFT_SHOULDER, HARDPOINT_RIGHT_SHOULDER)
	restricted_software = list(MECH_SOFTWARE_ENGINEERING)
	origin_tech = list(TECH_POWER = 5, TECH_ENGINEERING = 4)

	active_power_use = 30 KILOWATTS

	var/is_active = FALSE

	var/fire_delay = 100
	var/max_burst_delay = 100
	var/min_burst_delay = 20
	var/burst_shots = 3
	var/last_shot = 0
	var/shot_number = 0

/obj/item/mecha_equipment/emitter/update_icon()
	// if(is_active)
	// 	icon_state = "[initial(icon_state)]-on"
	// 	set_light(brightness_on, 1)
	// else
	// 	icon_state = "[initial(icon_state)]"
	// 	set_light(0)

/obj/item/mecha_equipment/emitter/attack_self(var/mob/user)
	. = ..()
	if(.)
		set_state(!is_active)
		to_chat(user, "You switch \the [src] [is_active ? "on" : "off"].")

/obj/item/mecha_equipment/emitter/proc/set_state(var/set_active)
	is_active = set_active
	update_icon()
	owner.update_icon()
	if(is_active)
		START_PROCESSING(SSprocessing, src)
	else
		STOP_PROCESSING(SSprocessing, src)

/obj/item/mecha_equipment/emitter/process()
	if(last_shot + fire_delay > world.time)
		return

	var/obj/item/cell/cell = owner.get_cell()
	var/charge_usage = active_power_use * CELLRATE
	if(!(cell?.check_charge(charge_usage)))
		set_state(FALSE)
		return

	last_shot = world.time
	if(shot_number < burst_shots)
		fire_delay = 2
		shot_number++
	else
		fire_delay = rand(min_burst_delay, max_burst_delay)
		shot_number = 0

	var/burst_time = (min_burst_delay + max_burst_delay) / 2 + 2 * (burst_shots - 1)
	var/power_per_shot = active_power_use * (burst_time / 10) / burst_shots

	var/turf/our_turf = get_turf(src)

	playsound(our_turf, 'sound/weapons/emitter.ogg', 15, TRUE, 2, 0.5, TRUE)
	if(prob(35))
		spark(our_turf, 3)

	var/obj/item/projectile/beam/emitter/A = new /obj/item/projectile/beam/emitter(our_turf)
	A.damage = round(power_per_shot / EMITTER_DAMAGE_POWER_TRANSFER)
	A.launch_projectile(get_step(owner, owner.dir))

	cell.use(charge_usage)


/obj/item/mecha_equipment/emitter/deactivate()
	if(is_active)
		set_state(FALSE)
	return ..()

/obj/item/mecha_equipment/emitter/uninstalled()
	if(is_active)
		set_state(FALSE)
	return ..()
