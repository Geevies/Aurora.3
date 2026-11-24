/// Place two rings with the same gate_id. Each ring's dir points at its exit tile.
/obj/structure/stargate
	name = "stargate"
	desc = "A metal ring lined with crystalline chevrons. A matching ring can open a passage through its center."
	icon = 'icons/obj/machinery/stargate.dmi'
	icon_state = "idle"
	pixel_x = -8
	pixel_y = -8
	anchored = TRUE
	density = FALSE
	pass_flags_self = PASSSTRUCTURE | LETPASSTHROW

	var/gate_id = "stargate"
	var/static/list/unpaired_gates = list()
	var/obj/structure/stargate/partner
	var/obj/effect/map_effect/portal/stargate/aperture

/obj/structure/stargate/Initialize(mapload, pair_id)
	. = ..()
	if(!isnull(pair_id))
		gate_id = pair_id
	return INITIALIZE_HINT_LATELOAD

/obj/structure/stargate/LateInitialize()
	if(isturf(loc) && gate_id && get_step(src, dir))
		find_partner()

/obj/structure/stargate/proc/find_partner()
	for(var/obj/structure/stargate/other in unpaired_gates)
		if(other.gate_id != gate_id || other.loc == loc)
			continue
		if(get_step(other, other.dir) == loc || get_step(src, dir) == other.loc)
			continue
		unpaired_gates -= other
		partner = other
		other.partner = src
		aperture = new(loc)
		other.aperture = new(other.loc)
		aperture.set_dir(dir)
		other.aperture.set_dir(other.dir)
		aperture.open(other.aperture)
		other.aperture.open(aperture)
		icon_state = "linked"
		other.icon_state = "linked"
		return
	unpaired_gates |= src

/obj/structure/stargate/Destroy()
	unpaired_gates -= src
	QDEL_NULL(aperture)
	if(partner)
		var/obj/structure/stargate/other = partner
		partner = null
		other.partner = null
		QDEL_NULL(other.aperture)
		other.icon_state = "idle"
		other.find_partner()
	return ..()

/// The ring frames a live view of the tile a traveler will arrive on.
/obj/effect/map_effect/portal/stargate
	name = "gateway aperture"
	icon_state = null
	layer = BELOW_OBJ_LAYER
	opacity = FALSE

/obj/effect/map_effect/portal/stargate/proc/open(obj/effect/map_effect/portal/stargate/other)
	counterpart = other
	add_vis_contents(other.get_focused_turf())
	var/static/icon/aperture_mask = icon('icons/obj/machinery/stargate.dmi', "aperture")
	add_filter("aperture", 1, alpha_mask_filter(icon = aperture_mask))

/obj/effect/map_effect/portal/stargate/go_through_portal(atom/movable/traveler)
	var/turf/exit = counterpart.get_focused_turf()
	if(!exit || exit.density || (locate(/obj/effect/map_effect/portal) in exit))
		return
	// A throw still aims at its original coordinates after forceMove. Carry its
	// remaining distance out through the far ring, including on another z-level.
	var/datum/thrownthing/flight = traveler.throwing
	if(flight)
		flight.target_turf = get_ranged_target_turf(exit, counterpart.dir, get_dist(src, flight.target_turf))
		flight.initial_target = null
		flight.init_dir = counterpart.dir
		flight.dx = counterpart.dir // The throw's primary step is now along the exit axis.
	if(istype(traveler, /obj/projectile))
		var/obj/projectile/projectile = traveler
		projectile.set_angle(dir2angle(counterpart.dir))
	return ..()
