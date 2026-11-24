#define STARGATE_VIEW_DEPTH 7

/// Place the center of each three-tile ring with the same gate_id. Its cardinal dir defines the front of the ring.
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
	var/list/front_view
	var/list/back_view
	var/list/viewers

/obj/structure/stargate/Initialize(mapload, pair_id)
	. = ..()
	if(!isnull(pair_id))
		gate_id = pair_id
	return INITIALIZE_HINT_LATELOAD

/obj/structure/stargate/LateInitialize()
	find_partner()

/obj/structure/stargate/mechanics_hints(mob/user, distance, is_adjacent)
	. = ..()
	. += "Use an empty hand on the ring to set its address. Two gates with the same address can connect."

/obj/structure/stargate/attack_hand(mob/living/user)
	if(user.a_intent == I_HURT)
		return ..()
	add_fingerprint(user)
	ui_interact(user)

/obj/structure/stargate/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/stargate/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Stargate", "Stargate Controls")
		ui.open()

/obj/structure/stargate/ui_static_data(mob/user)
	var/static/list/ring_images
	if(!ring_images)
		ring_images = list()
		for(var/state in list("idle", "linked"))
			var/icon/ring = icon(initial(icon), state, SOUTH)
			ring.Crop(1, 49, 160, 112)
			ring_images[state] = icon2base64(ring)
	return list("ring_images" = ring_images, "max_length" = MAX_NAME_LEN)

/obj/structure/stargate/ui_data(mob/user)
	var/area/destination = get_area(partner)
	return list(
		"address" = gate_id,
		"linked" = !!partner,
		"destination" = destination?.name,
	)

/obj/structure/stargate/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	if(action == "set_address" && params["previous_address"] == gate_id)
		return set_address(params["address"])

/obj/structure/stargate/proc/set_address(address)
	if(!istext(address) || length_char(address) > MAX_NAME_LEN)
		return FALSE
	address = trim(address)
	var/static/regex/control_character = regex(@"[[:cntrl:]]")
	if(!length(address) || control_character.Find(address) || address == gate_id)
		return FALSE
	disconnect()
	gate_id = address
	find_partner()
	return TRUE

/// Ordered from left to right when facing out of the ring.
/obj/structure/stargate/proc/get_aperture_turfs()
	var/list/lanes = list(get_step(src, turn(dir, 90)), loc, get_step(src, turn(dir, -90)))
	for(var/turf/lane as anything in lanes)
		var/turf/front = get_step(lane, dir)
		var/turf/back = get_step(lane, REVERSE_DIR(dir))
		if(!lane || !front || !back)
			return
		if((locate(/obj/effect/map_effect/portal) in lane) || (locate(/obj/effect/map_effect/portal) in front) || (locate(/obj/effect/map_effect/portal) in back))
			return
	return lanes

/obj/structure/stargate/proc/find_partner()
	if(!isturf(loc) || !gate_id || !(dir in GLOB.cardinals))
		return
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
			if((lane in other_lanes) || (get_step(lane, dir) in other_lanes) || (get_step(lane, REVERSE_DIR(dir)) in other_lanes) || (get_step(lane, other.dir) in other_lanes) || (get_step(lane, REVERSE_DIR(other.dir)) in other_lanes))
				overlap = TRUE
				break
		if(overlap)
			continue
		unpaired_gates -= other
		partner = other
		other.partner = src
		create_apertures(lanes)
		other.create_apertures(other_lanes)
		for(var/i in 1 to length(apertures))
			var/obj/effect/map_effect/portal/stargate/near = apertures[i]
			var/obj/effect/map_effect/portal/stargate/far = other.apertures[i]
			near.counterpart = far
			far.counterpart = near
		open_views()
		other.open_views()
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
		aperture.aperture_mask = mask
		apertures += aperture
	icon_state = "linked"

/obj/structure/stargate/proc/open_views()
	front_view = project_view(REVERSE_DIR(dir), REVERSE_DIR(partner.dir))
	back_view = project_view(dir, partner.dir)
	viewers = list()
	START_PROCESSING(SSprocessing, src)
	process()

/// The view widens beyond the opening. Each image copies a live destination turf.
/obj/structure/stargate/proc/project_view(forward, remote_forward)
	var/list/projected = list()
	var/list/visible_turfs = list()
	for(var/obj/effect/map_effect/portal/stargate/aperture in apertures)
		var/turf/exit = get_step(aperture.counterpart, remote_forward)
		var/list/visible
		DVIEW(visible, STARGATE_VIEW_DEPTH, exit, INVISIBILITY_LIGHTING)
		visible_turfs |= visible
		var/image/window = make_view_tile(get_turf(aperture), exit, BELOW_OBJ_LAYER)
		window.filters = list(filter(arglist(alpha_mask_filter(icon = aperture.aperture_mask))))
		projected += window

	var/turf/local_row = get_turf(src)
	var/turf/remote_row = get_step(partner, remote_forward)
	for(var/depth in 1 to STARGATE_VIEW_DEPTH)
		local_row = get_step(local_row, forward)
		remote_row = get_step(remote_row, remote_forward)
		if(!local_row || !remote_row)
			break
		if(remote_row in visible_turfs)
			projected += make_view_tile(local_row, remote_row, ABOVE_PROJECTILE_LAYER)
		for(var/turn_angle in list(-90, 90))
			var/turf/local_tile = local_row
			var/turf/remote_tile = remote_row
			for(var/offset in 1 to depth + 1)
				local_tile = get_step(local_tile, turn(forward, turn_angle))
				remote_tile = get_step(remote_tile, turn(remote_forward, turn_angle))
				if(!local_tile || !remote_tile)
					break
				if(remote_tile in visible_turfs)
					projected += make_view_tile(local_tile, remote_tile, ABOVE_PROJECTILE_LAYER)
	return projected

/obj/structure/stargate/proc/make_view_tile(turf/position, turf/destination, image_layer)
	var/image/tile = image(loc = position, layer = image_layer)
	tile.plane = GAME_PLANE
	tile.appearance_flags = PIXEL_SCALE | KEEP_TOGETHER
	tile.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	tile.add_vis_contents(destination)
	return tile

/obj/structure/stargate/process()
	var/list/remaining = viewers.Copy()
	for(var/client/viewer in GLOB.clients)
		var/turf/eye_turf = get_turf(viewer.eye)
		if(!eye_turf || eye_turf.z != z || get_dist(src, eye_turf) > STARGATE_VIEW_DEPTH)
			continue
		var/side = get_dir(src, eye_turf)
		if(!(side & (dir | REVERSE_DIR(dir))) || !(src in view(world.view, viewer.eye)))
			continue
		var/list/projection = (side & dir) ? front_view : back_view
		remaining -= viewer
		if(viewers[viewer] == projection)
			continue
		if(viewers[viewer])
			viewer.images -= viewers[viewer]
		viewer.images += projection
		viewers[viewer] = projection
	for(var/client/viewer as anything in remaining)
		if(!QDELETED(viewer))
			viewer.images -= remaining[viewer]
		viewers -= viewer

/obj/structure/stargate/proc/close_views()
	if(viewers)
		STOP_PROCESSING(SSprocessing, src)
		for(var/client/viewer as anything in viewers)
			if(!QDELETED(viewer))
				viewer.images -= viewers[viewer]
	viewers = null
	front_view = null
	back_view = null

/obj/structure/stargate/Destroy()
	disconnect()
	return ..()

/obj/structure/stargate/proc/disconnect()
	unpaired_gates -= src
	close_views()
	QDEL_NULL_LIST(apertures)
	icon_state = "idle"
	if(partner)
		var/obj/structure/stargate/other = partner
		partner = null
		other.partner = null
		other.close_views()
		QDEL_NULL_LIST(other.apertures)
		other.icon_state = "idle"
		other.find_partner()

/// Each segment carries travelers straight through the corresponding lane.
/obj/effect/map_effect/portal/stargate
	name = "gateway aperture"
	icon_state = null
	layer = BELOW_OBJ_LAYER
	opacity = FALSE
	var/icon/aperture_mask

/obj/effect/map_effect/portal/stargate/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(!counterpart || !arrived || arrived.loc != loc)
		return
	var/exit_direction = REVERSE_DIR(counterpart.dir)
	var/turf/entry = get_turf(old_loc)
	if(entry && entry.z == z && (get_dir(src, entry) & REVERSE_DIR(dir)))
		exit_direction = counterpart.dir
	go_through_portal(arrived, get_step(counterpart, exit_direction))

/obj/effect/map_effect/portal/stargate/go_through_portal(atom/movable/traveler, turf/exit)
	if(!exit || exit.density || (locate(/obj/effect/map_effect/portal) in exit))
		return
	var/exit_direction = get_dir(counterpart, exit)
	// A throw still aims at its original coordinates after forceMove. Carry its
	// remaining distance out through the far ring, including on another z-level.
	var/datum/thrownthing/flight = traveler.throwing
	if(flight)
		flight.target_turf = get_ranged_target_turf(exit, exit_direction, get_dist(src, flight.target_turf))
		flight.initial_target = null
		flight.init_dir = exit_direction
		flight.dx = exit_direction // The throw's primary step is now along the exit axis.
	if(istype(traveler, /obj/projectile))
		var/obj/projectile/projectile = traveler
		projectile.set_angle(dir2angle(exit_direction))
	return ..(traveler, exit)

#undef STARGATE_VIEW_DEPTH
