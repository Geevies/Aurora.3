/obj/effect/map_effect/door_helper
	layer = DOOR_CLOSED_LAYER + 0.1

/obj/effect/map_effect/door_helper/unres
	icon_state = "unres_door"

/obj/effect/map_effect/door_helper/unres/Initialize(mapload, ...)
	. = ..()
	var/obj/machinery/door/D = locate() in loc
	if(D)
		D.unres_dir ^= dir