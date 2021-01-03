/obj/item/mecha_equipment/mounted_system/rfd
	name = "mounted rfd"
	icon_state = "mecha_rfd"
	holding_type = /obj/item/rfd/construction/mounted
	restricted_hardpoints = list(HARDPOINT_LEFT_HAND, HARDPOINT_RIGHT_HAND)
	restricted_software = list(MECH_SOFTWARE_ENGINEERING)

/obj/item/rfd/construction/mounted/get_hardpoint_maptext()
	var/obj/item/mecha_equipment/mounted_system/MS = loc
	if(istype(MS) && MS.owner)
		var/obj/item/cell/C = MS.owner.get_cell()
		if(istype(C))
			return "[round(C.charge)]/[round(C.maxcharge)]"
	return null

/obj/item/rfd/construction/mounted/get_hardpoint_status_value()
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
	reagents.add_reagent(/datum/reagent/toxin/fertilizer/monoammoniumphosphate, max_water)
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

/obj/item/mecha_equipment/shield_generator
	name = "emergency shield projector"
	desc = "A large, heavy emergency shield projector. It's been modified to be able to fit into the shoulder hardpoint of most modular exosuits."
	icon_state = "med_droid"
	restricted_hardpoints = list(HARDPOINT_LEFT_SHOULDER)
	restricted_software = list(MECH_SOFTWARE_ENGINEERING)
	origin_tech = list(TECH_MATERIAL = 2, TECH_ENGINEERING = 2)
	var/obj/machinery/shieldgen/mounted/shield

/obj/item/mecha_equipment/shield_generator/Initialize()
	. = ..()
	shield = new /obj/machinery/shieldgen/mounted(src)

/obj/item/mecha_equipment/shield_generator/attack_self(mob/user)
	. = ..()
	if(.)
		shield.attack_hand(user)