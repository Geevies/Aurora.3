/// Place the center of each three-tile ring with the same gate_id. Its cardinal dir defines the front of the ring.
/obj/structure/stargate
	name = "stargate"
	desc = "A metal ring lined with crystalline chevrons. A matching ring can open a passage through its center."
	icon = 'icons/obj/machinery/stargate.dmi'
	icon_state = "idle"
	layer = SINGULARITY_LAYER
	pixel_x = -64
	pixel_y = -64
	anchored = TRUE
	density = FALSE
	pass_flags_self = PASSSTRUCTURE | LETPASSTHROW

	var/gate_id = "stargate"
	var/static/list/unpaired_gates = list()
	var/obj/structure/stargate/partner
	var/list/apertures
	var/list/preview_images
	var/list/preview_viewers

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
		show_destination()
		other.show_destination()
		return
	unpaired_gates |= src

/obj/structure/stargate/proc/create_apertures(list/lanes)
	apertures = list()
	for(var/turf/lane in lanes)
		var/obj/effect/map_effect/portal/stargate/aperture = new(lane)
		aperture.gate = src
		aperture.set_dir(dir)
		apertures += aperture
	icon_state = "linked"

/obj/structure/stargate/proc/show_destination()
	preview_images = list()
	preview_viewers = list()
	var/list/observed_turfs = list()
	// The map portal renderer projects in world coordinates. Show the exit row when the rings turn the route.
	var/approach_direction = (dir == partner.dir) ? dir : NONE
	for(var/obj/effect/map_effect/portal/stargate/aperture in apertures)
		var/turf/exit = get_step(aperture.counterpart, REVERSE_DIR(partner.dir))
		aperture.render_destination(exit, approach_direction, observed_turfs, limit_to_aperture = TRUE)
		// Keep the map portal's grouped scene off-screen until a viewer is facing its approach.
		aperture.icon_state = "blank"
		aperture.render_target = "*stargate-[REF(aperture)]"
		var/image/preview = image(aperture.icon, loc = get_turf(aperture), icon_state = aperture.icon_state, layer = ABOVE_OBJ_LAYER)
		preview.render_source = aperture.render_target
		preview.plane = GAME_PLANE
		preview.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		preview.appearance_flags = PIXEL_SCALE | KEEP_APART
		preview.pixel_x = aperture.pixel_x
		preview.pixel_y = aperture.pixel_y
		aperture.pixel_x = 0
		aperture.pixel_y = 0
		preview_images += preview
	START_PROCESSING(SSprocessing, src)
	process()

/obj/structure/stargate/process()
	for(var/client/viewer as anything in preview_viewers - GLOB.clients)
		preview_viewers -= viewer
	for(var/client/viewer as anything in GLOB.clients)
		update_preview(viewer)

/obj/structure/stargate/proc/is_approach_side(turf/eye_turf)
	return eye_turf && eye_turf.z == z && (get_dir(src, eye_turf) & dir)

/obj/structure/stargate/proc/update_preview(client/viewer)
	if(!preview_images || !viewer)
		return
	var/turf/eye_turf = get_turf(viewer.eye)
	var/show_preview = is_approach_side(eye_turf) && (src in view(world.view, viewer.eye))
	var/has_preview = (viewer in preview_viewers)
	if(show_preview && !has_preview)
		viewer.images += preview_images
		preview_viewers += viewer
	else if(!show_preview && has_preview)
		viewer.images -= preview_images
		preview_viewers -= viewer

/obj/structure/stargate/proc/clear_preview()
	if(!preview_images)
		return
	STOP_PROCESSING(SSprocessing, src)
	for(var/client/viewer as anything in preview_viewers)
		if(!QDELETED(viewer))
			viewer.images -= preview_images
	preview_images = null
	preview_viewers = null

/obj/structure/stargate/Destroy()
	disconnect()
	return ..()

/obj/structure/stargate/proc/disconnect()
	unpaired_gates -= src
	clear_preview()
	QDEL_NULL_LIST(apertures)
	icon_state = "idle"
	if(partner)
		var/obj/structure/stargate/other = partner
		partner = null
		other.partner = null
		other.clear_preview()
		QDEL_NULL_LIST(other.apertures)
		other.icon_state = "idle"
		other.find_partner()

/// Each segment carries travelers straight through the corresponding lane.
/obj/effect/map_effect/portal/stargate
	name = "gateway aperture"
	icon = 'icons/mob/base_32.dmi'
	icon_state = "blank"
	opacity = FALSE
	blocks_emissive = EMISSIVE_BLOCK_NONE
	vis_flags = VIS_HIDE // Keep nearby rings from recursively rendering each other.
	var/obj/structure/stargate/gate

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
	. = ..(traveler, exit)
	if(ismob(traveler))
		var/mob/arrived = traveler
		if(arrived.client)
			gate?.update_preview(arrived.client)
			gate?.partner?.update_preview(arrived.client)
