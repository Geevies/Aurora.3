/// Place the center of each three-tile ring with the same gate_id. Its cardinal dir points toward its exit row.
/obj/structure/stargate
	name = "stargate"
	desc = "A metal ring lined with crystalline chevrons. A matching ring can open a passage through its center."
	icon = 'icons/obj/machinery/stargate.dmi'
	icon_state = "idle"
	pixel_x = -64
	pixel_y = -64
	anchored = TRUE
	density = FALSE
	pass_flags_self = PASSSTRUCTURE | LETPASSTHROW

	var/gate_id = "stargate"
	var/static/list/unpaired_gates = list()
	var/obj/structure/stargate/partner
	var/list/apertures

/obj/structure/stargate/Initialize(mapload, pair_id)
	. = ..()
	if(!isnull(pair_id))
		gate_id = pair_id
	return INITIALIZE_HINT_LATELOAD

/obj/structure/stargate/LateInitialize()
	if(isturf(loc) && gate_id && (dir in GLOB.cardinals))
		find_partner()

/// Ordered from left to right when facing out of the ring.
/obj/structure/stargate/proc/get_aperture_turfs()
	var/list/lanes = list(get_step(src, turn(dir, 90)), loc, get_step(src, turn(dir, -90)))
	for(var/turf/lane as anything in lanes)
		var/turf/exit = get_step(lane, dir)
		if(!lane || !exit || (locate(/obj/effect/map_effect/portal) in lane) || (locate(/obj/effect/map_effect/portal) in exit))
			return
	return lanes

/obj/structure/stargate/proc/find_partner()
	var/list/lanes = get_aperture_turfs()
	if(!lanes)
		return
	for(var/obj/structure/stargate/other in unpaired_gates)
		if(other.gate_id != gate_id)
			continue
		var/list/other_lanes = other.get_aperture_turfs()
		if(!other_lanes)
			continue
		var/overlap = FALSE
		for(var/turf/lane in lanes)
			if((lane in other_lanes) || (get_step(lane, dir) in other_lanes) || (get_step(lane, REVERSE_DIR(other.dir)) in other_lanes))
				overlap = TRUE
				break
		if(overlap)
			continue
		unpaired_gates -= other
		partner = other
		other.partner = src
		create_apertures(lanes)
		other.create_apertures(other_lanes)
		for(var/i in 1 to length(lanes))
			// Entering one ring and exiting the other reverses their facing-relative order.
			var/obj/effect/map_effect/portal/stargate/near = apertures[i]
			var/obj/effect/map_effect/portal/stargate/far = other.apertures[length(lanes) + 1 - i]
			near.open(far)
			far.open(near)
		return
	unpaired_gates |= src

/obj/structure/stargate/proc/create_apertures(list/lanes)
	apertures = list()
	for(var/turf/lane in lanes)
		var/obj/effect/map_effect/portal/stargate/aperture = new(lane)
		aperture.set_dir(dir)
		var/icon/mask = icon(icon, "aperture", dir)
		var/mask_x = 1 - pixel_x + (lane.x - x) * WORLD_ICON_SIZE
		var/mask_y = 1 - pixel_y + (lane.y - y) * WORLD_ICON_SIZE
		mask.Crop(mask_x, mask_y, mask_x + WORLD_ICON_SIZE - 1, mask_y + WORLD_ICON_SIZE - 1)
		aperture.add_filter("aperture", 1, alpha_mask_filter(icon = mask))
		apertures += aperture
	icon_state = "linked"

/obj/structure/stargate/Destroy()
	unpaired_gates -= src
	QDEL_NULL_LIST(apertures)
	if(partner)
		var/obj/structure/stargate/other = partner
		partner = null
		other.partner = null
		QDEL_NULL_LIST(other.apertures)
		other.icon_state = "idle"
		other.find_partner()
	return ..()

/// Each segment shows the exact exit tile for travelers crossing that part of the ring.
/obj/effect/map_effect/portal/stargate
	name = "gateway aperture"
	icon_state = null
	layer = BELOW_OBJ_LAYER
	opacity = FALSE

/obj/effect/map_effect/portal/stargate/proc/open(obj/effect/map_effect/portal/stargate/other)
	counterpart = other
	add_vis_contents(other.get_focused_turf())

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
