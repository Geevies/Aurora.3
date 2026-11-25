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
	vis_flags = VIS_HIDE // Keep the remote ring out of its floor preview.

	var/gate_id = "stargate"
	var/static/list/unpaired_gates = list()
	var/obj/structure/stargate/partner
	var/list/apertures
	var/list/preview_images
	var/list/rear_preview_images
	var/list/side_preview_images
	/// The preview images currently shown to each client.
	var/list/preview_viewers
	/// Nearby movable eyes and the clients looking through each one.
	var/list/preview_eyes
	COOLDOWN_DECLARE(transit_sound)

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

/obj/structure/stargate/proc/can_link()
	return isturf(loc) && gate_id && (dir in GLOB.cardinals)

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
	if(partner || !can_link())
		return
	var/list/lanes = get_aperture_turfs()
	if(!lanes)
		return
	for(var/obj/structure/stargate/other in unpaired_gates)
		if(other == src || other.gate_id != gate_id || !other.can_link())
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
		on_passage_opened()
		other.on_passage_opened()
		return
	unpaired_gates |= src

/obj/structure/stargate/proc/create_apertures(list/lanes)
	apertures = list()
	for(var/turf/lane in lanes)
		var/obj/effect/map_effect/portal/stargate/aperture = new(lane)
		aperture.gate = src
		aperture.set_dir(dir)
		aperture.rear_preview = new /obj/effect/map_effect/portal/stargate_preview(lane)
		aperture.side_preview = new /obj/effect/map_effect/portal/stargate_preview(lane)
		apertures += aperture
	icon_state = "linked"

/obj/structure/stargate/proc/show_destination()
	preview_images = list()
	rear_preview_images = list()
	side_preview_images = list()
	preview_viewers = list()
	var/list/front_observed_turfs = list()
	var/list/rear_observed_turfs = list()
	var/list/front_projected_turfs = list()
	var/list/rear_projected_turfs = list()
	var/list/side_projected_turfs = list()
	for(var/obj/effect/map_effect/portal/stargate/aperture in apertures)
		var/turf/remote_aperture = get_turf(aperture.counterpart)
		preview_images += make_preview(aperture, aperture.get_exit_turf(dir), dir, front_observed_turfs, front_projected_turfs, remote_aperture)
		var/rear = REVERSE_DIR(dir)
		rear_preview_images += make_preview(aperture.rear_preview, aperture.get_exit_turf(rear), rear, rear_observed_turfs, rear_projected_turfs, remote_aperture)
		side_preview_images += make_preview(aperture.side_preview, remote_aperture, NONE, null, side_projected_turfs)
	if(dir != partner.dir)
		// Turned views draw the aperture and the exit as separate rows.
		preview_images += side_preview_images
		rear_preview_images += side_preview_images
		front_projected_turfs |= side_projected_turfs
		rear_projected_turfs |= side_projected_turfs
	preview_images += make_preview_outline(front_projected_turfs)
	rear_preview_images += make_preview_outline(rear_projected_turfs)
	side_preview_images += make_preview_outline(side_projected_turfs)
	var/image/rim = image(icon, loc = get_turf(src), icon_state = "linked", dir = dir, layer = ABOVE_OBJ_LAYER + 0.03)
	rim.pixel_x = pixel_x
	rim.pixel_y = pixel_y
	rim.plane = ABOVE_LIGHTING_PLANE
	rim.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	rim.appearance_flags = PIXEL_SCALE | KEEP_APART
	preview_images += rim
	rear_preview_images += rim
	side_preview_images += rim
	START_PROCESSING(SSprocessing, src)
	process()

/obj/structure/stargate/proc/make_preview(obj/effect/map_effect/portal/rendered_scene, turf/focus, approach_side, list/observed_turfs, list/projected_turfs, turf/remote_aperture = focus)
	// The copied scene is shaded again at the viewer's end. Apply gain to the
	// preview without changing the renderer or lighting of either room.
	var/static/list/preview_exposure = list(
		2.5, 0, 0,
		0, 2.5, 0,
		0, 0, 2.5,
		0, 0, 0,
	)
	// Aligned rings keep the remote aperture and its floor aligned with the local ring.
	var/projection_direction = (dir == partner.dir) ? approach_side : NONE
	var/turf/alignment_turf = projection_direction ? remote_aperture : focus
	var/turf/local_anchor = get_turf(rendered_scene)
	if(approach_side && !projection_direction)
		local_anchor = get_step(local_anchor, REVERSE_DIR(approach_side))
	rendered_scene.render_destination(focus, projection_direction, observed_turfs, limit_to_aperture = TRUE, alignment_turf = alignment_turf)
	for(var/turf/remote_turf in rendered_scene.vis_contents)
		var/turf/projected = locate(local_anchor.x + remote_turf.x - alignment_turf.x, local_anchor.y + remote_turf.y - alignment_turf.y, z)
		if(projected)
			projected_turfs |= projected
	// Keep the grouped scene off-screen until a viewer is on this side.
	rendered_scene.icon_state = "blank"
	rendered_scene.render_target = "*stargate-[REF(rendered_scene)]"
	var/image/preview = image(rendered_scene.icon, loc = get_turf(rendered_scene), icon_state = rendered_scene.icon_state, layer = ABOVE_OBJ_LAYER)
	preview.render_source = rendered_scene.render_target
	// A wall on this end must not mask the projected room with local blackness.
	preview.plane = ABOVE_LIGHTING_PLANE
	preview.color = preview_exposure
	preview.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	preview.appearance_flags = PIXEL_SCALE | KEEP_APART
	preview.pixel_x = rendered_scene.pixel_x + WORLD_ICON_SIZE * (local_anchor.x - rendered_scene.x)
	preview.pixel_y = rendered_scene.pixel_y + WORLD_ICON_SIZE * (local_anchor.y - rendered_scene.y)
	// Keep the wave in phase across lane images and move along the joins.
	var/horizontal_aperture = dir & (NORTH | SOUTH)
	var/wavelength = 3 * WORLD_ICON_SIZE
	var/scene_center = horizontal_aperture ? ((rendered_scene.x - x + rendered_scene.total_width / 2) * WORLD_ICON_SIZE + preview.pixel_x) : ((rendered_scene.y - y + rendered_scene.total_height / 2) * WORLD_ICON_SIZE + preview.pixel_y)
	var/phase = -scene_center / wavelength
	preview.filters = filter(type = "wave", x = horizontal_aperture ? wavelength : 0, y = horizontal_aperture ? 0 : wavelength, size = 0.45, offset = phase, flags = WAVE_SIDEWAYS | WAVE_BOUNDED)
	animate(preview.filters[1], offset = phase, time = 0, loop = -1)
	animate(offset = phase - 1, time = 5 SECONDS)
	rendered_scene.pixel_x = 0
	rendered_scene.pixel_y = 0
	return preview

/// Outline only the exposed sides of the combined projection so lanes join without seams.
/obj/structure/stargate/proc/make_preview_outline(list/projected_turfs)
	var/static/list/outline_icons
	if(!outline_icons)
		var/icon/south_edge = icon('icons/mob/base_32.dmi', "blank")
		var/list/glow_colors = list("#D8FFFFF8", "#64F7FFE0", "#22D9FFAC", "#24B5FF70", "#428CFF48", "#617CFF26", "#617CFF12")
		for(var/distance in 1 to length(glow_colors))
			south_edge.DrawBox(glow_colors[distance], 1, distance, WORLD_ICON_SIZE, distance)
		south_edge.DrawBox("#AAFDFFE8", 7, 3, 13, 3)
		south_edge.DrawBox("#A2D6FFA0", 8, 4, 12, 4)
		south_edge.DrawBox("#D2C0FFD0", 22, 3, 26, 3)
		south_edge.DrawBox("#8B9DFFA0", 23, 4, 25, 4)
		outline_icons = list()
		for(var/direction in GLOB.cardinals)
			var/icon/edge = icon(south_edge)
			edge.Turn(dir2angle(direction) - dir2angle(SOUTH))
			outline_icons["[direction]"] = edge

	var/list/outline = list()
	for(var/turf/projected as anything in projected_turfs)
		for(var/direction in GLOB.cardinals)
			if(get_step(projected, direction) in projected_turfs)
				continue
			var/image/glow = image(outline_icons["[direction]"], loc = get_turf(src), layer = ABOVE_OBJ_LAYER + 0.02)
			glow.pixel_x = (projected.x - x) * WORLD_ICON_SIZE
			glow.pixel_y = (projected.y - y) * WORLD_ICON_SIZE
			glow.plane = ABOVE_LIGHTING_PLANE
			glow.blend_mode = BLEND_ADD
			glow.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
			glow.appearance_flags = PIXEL_SCALE | KEEP_APART
			outline += glow
	return outline

/obj/structure/stargate/process()
	for(var/client/viewer as anything in preview_viewers - GLOB.clients)
		preview_viewers -= viewer
	var/list/view_size = getviewsize(world.view)
	// Start listening before an approaching viewer can see the ring.
	var/watch_range = ceil(max(view_size[1], view_size[2]) / 2) + 4
	var/list/nearby_eyes = list()
	for(var/client/viewer as anything in GLOB.clients)
		var/atom/eye = viewer.eye
		var/turf/eye_turf = get_turf(eye)
		var/nearby = eye_turf && eye_turf.z == z && get_dist(src, eye_turf) <= watch_range
		if(nearby || (viewer in preview_viewers))
			update_preview(viewer)
		if(!nearby || !ismovable(eye) || eye == src)
			continue
		if(!nearby_eyes[eye])
			nearby_eyes[eye] = list()
			if(!(eye in preview_eyes))
				RegisterSignal(eye, COMSIG_MOVABLE_MOVED, PROC_REF(on_preview_eye_moved))
		nearby_eyes[eye] += viewer
	if(preview_eyes)
		for(var/atom/movable/old_eye as anything in preview_eyes - nearby_eyes)
			if(!QDELETED(old_eye))
				UnregisterSignal(old_eye, COMSIG_MOVABLE_MOVED)
	preview_eyes = nearby_eyes

/obj/structure/stargate/proc/on_preview_eye_moved(atom/movable/eye)
	SIGNAL_HANDLER
	for(var/client/viewer as anything in preview_eyes?[eye])
		if(!QDELETED(viewer) && viewer.eye == eye)
			update_preview(viewer)

/obj/structure/stargate/proc/get_preview_images(turf/eye_turf)
	if(!eye_turf || eye_turf.z != z)
		return
	var/eye_direction = get_dir(src, eye_turf)
	if(eye_direction & dir)
		return preview_images
	if(eye_direction & REVERSE_DIR(dir))
		return rear_preview_images
	if(eye_direction)
		return side_preview_images

/obj/structure/stargate/proc/update_preview(client/viewer)
	if(!preview_images || !viewer)
		return
	var/list/next_images = get_preview_images(get_turf(viewer.eye))
	if(next_images && !(src in view(world.view, viewer.eye)))
		next_images = null
	var/list/previous_images = preview_viewers[viewer]
	if(next_images == previous_images)
		return
	if(previous_images)
		viewer.images -= previous_images
	if(next_images)
		viewer.images += next_images
		preview_viewers[viewer] = next_images
	else
		preview_viewers -= viewer

/obj/structure/stargate/proc/clear_preview()
	if(!preview_images)
		return
	STOP_PROCESSING(SSprocessing, src)
	for(var/client/viewer as anything in preview_viewers)
		if(!QDELETED(viewer))
			viewer.images -= preview_viewers[viewer]
	for(var/atom/movable/eye as anything in preview_eyes)
		if(!QDELETED(eye))
			UnregisterSignal(eye, COMSIG_MOVABLE_MOVED)
	preview_images = null
	rear_preview_images = null
	side_preview_images = null
	preview_viewers = null
	preview_eyes = null

/obj/structure/stargate/Destroy()
	disconnect()
	return ..()

/obj/structure/stargate/proc/disconnect()
	unpaired_gates -= src
	var/obj/structure/stargate/other = partner
	partner = null
	close_apertures()
	if(other)
		other.partner = null
		other.close_apertures()
		other.find_partner()

/obj/structure/stargate/proc/close_apertures()
	if(!apertures)
		return
	clear_preview()
	QDEL_NULL_LIST(apertures)
	icon_state = "idle"
	playsound(get_turf(src), 'sound/magic/Teleport_diss.ogg', 35, FALSE)
	return TRUE

/obj/structure/stargate/proc/on_passage_opened()
	playsound(get_turf(src), 'sound/effects/phasein.ogg', 45, FALSE)

/obj/structure/stargate/proc/play_transit_sound()
	if(COOLDOWN_FINISHED(src, transit_sound))
		COOLDOWN_START(src, transit_sound, 1 SECOND)
		playsound(get_turf(src), 'sound/effects/teleport.ogg', 25, TRUE)

/// The center row and the three approach tiles on each side must stay accessible.
/proc/stargate_site_is_clear(turf/site, obj/structure/stargate/existing_gate)
	if(!isfloor(site))
		return FALSE
	for(var/obj/structure/stargate/other in range(2, site))
		if(other != existing_gate)
			return FALSE
	var/turf/first = get_offset_target_turf(site, -1, -1)
	var/turf/last = get_offset_target_turf(site, 1, 1)
	if(!first || !last)
		return FALSE
	var/list/footprint = block(first, last)
	var/static/list/link_directions = list(NORTH, EAST)
	for(var/turf/tile in footprint)
		if(!isfloor(tile) || tile.density || (locate(/obj/effect/map_effect/portal) in tile))
			return FALSE
		for(var/obj/obstacle in tile)
			if(obstacle.density && !(obstacle.atom_flags & ATOM_FLAG_CHECKS_BORDER))
				return FALSE
		for(var/check_dir in link_directions)
			var/turf/neighbour = get_step(tile, check_dir)
			if((neighbour in footprint) && turf_link_blocks_placement(tile, neighbour))
				return FALSE
	return TRUE

/obj/structure/stargate/deployable
	desc = "A collapsible transit ring. It must be bolted to the floor and connected to local equipment power before it can open a passage."
	anchored = FALSE
	gate_id = null
	var/enabled = FALSE
	var/area/power_area

/obj/structure/stargate/deployable/Initialize(mapload, pair_id)
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_gate_moved))

/obj/structure/stargate/deployable/set_dir(new_dir)
	if(new_dir in GLOB.diagonals)
		new_dir &= NORTH | SOUTH
	return ..(new_dir)

/obj/structure/stargate/deployable/Destroy()
	if(power_area)
		UnregisterSignal(power_area, COMSIG_AREA_POWER_CHANGE)
		power_area = null
	return ..()

/obj/structure/stargate/deployable/mechanics_hints(mob/user, distance, is_adjacent)
	. = ..()
	. += "Wrench the ring into place on a clear three-by-three area. Match both addresses and enable each ring from its controls."
	. += "Unbolt the ring, then use a crowbar to fold it back into a flatpak."

/obj/structure/stargate/deployable/can_link()
	return anchored && enabled && equipment_powered() && ..()

/obj/structure/stargate/deployable/proc/equipment_powered()
	return !!power_area?.powered(AREA_USAGE_EQUIP)

/obj/structure/stargate/deployable/proc/set_gate_anchored(new_anchored)
	if(anchored == new_anchored)
		return
	anchored = new_anchored
	if(anchored)
		power_area = get_area(src)
		if(power_area)
			RegisterSignal(power_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(on_equipment_power_change))
	else
		enabled = FALSE
		if(power_area)
			UnregisterSignal(power_area, COMSIG_AREA_POWER_CHANGE)
			power_area = null
		disconnect()
	SStgui.update_uis(src)

/obj/structure/stargate/deployable/proc/on_gate_moved()
	SIGNAL_HANDLER
	if(anchored)
		set_gate_anchored(FALSE)

/obj/structure/stargate/deployable/proc/on_equipment_power_change()
	SIGNAL_HANDLER
	if(equipment_powered())
		find_partner()
	else
		disconnect()
	SStgui.update_uis(src)

/obj/structure/stargate/deployable/on_passage_opened()
	..()
	power_area?.use_power_oneoff(2500, AREA_USAGE_EQUIP)
	SStgui.update_uis(src)

/obj/structure/stargate/deployable/close_apertures()
	. = ..()
	if(.)
		SStgui.update_uis(src)

/obj/structure/stargate/deployable/attackby(obj/item/attacking_item, mob/living/user, params)
	if(user.a_intent == I_HURT)
		return ..()
	if(attacking_item.tool_behaviour == TOOL_WRENCH)
		var/was_anchored = anchored
		if(!attacking_item.use_tool(src, user, 2 SECONDS, volume = 40) || QDELETED(src) || anchored != was_anchored)
			return
		if(!was_anchored && !stargate_site_is_clear(get_turf(src), src))
			to_chat(user, SPAN_WARNING("The ring needs a clear three-by-three area of floor before you can secure it."))
			return
		set_gate_anchored(!was_anchored)
		to_chat(user, SPAN_NOTICE("You [anchored ? "bolt [src] to the floor" : "unbolt [src] from the floor"]."))
		add_fingerprint(user)
		return
	if(attacking_item.tool_behaviour == TOOL_CROWBAR)
		if(anchored)
			to_chat(user, SPAN_WARNING("Unbolt the ring before folding it away."))
			return
		if(!attacking_item.use_tool(src, user, 4 SECONDS, volume = 40) || QDELETED(src) || anchored)
			return
		var/obj/item/flatpak/stargate/flatpak = new(get_turf(src))
		flatpak.add_fingerprint(user)
		user.visible_message(SPAN_NOTICE("[user] folds \the [src] into a flatpak."), SPAN_NOTICE("You fold \the [src] into a flatpak."))
		qdel(src)
		return
	return ..()

/obj/structure/stargate/deployable/ui_data(mob/user)
	. = ..()
	.["deployable"] = TRUE
	.["anchored"] = anchored
	.["powered"] = equipment_powered()
	.["enabled"] = enabled

/obj/structure/stargate/deployable/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	if(action != "set_enabled")
		return FALSE
	var/should_enable = !!params["enabled"]
	if(should_enable == enabled)
		return FALSE
	if(should_enable)
		if(!anchored || !equipment_powered() || !gate_id)
			return FALSE
		if(!stargate_site_is_clear(get_turf(src), src))
			to_chat(usr, SPAN_WARNING("Clear the floor around the ring before enabling it."))
			return FALSE
		enabled = TRUE
		find_partner()
	else
		enabled = FALSE
		disconnect()
	return TRUE

/obj/item/circuitboard/stargate
	name = T_BOARD("stargate controller")
	build_path = /obj/structure/stargate/deployable
	board_type = BOARD_MACHINE

/obj/item/flatpak/stargate
	circuit_type = /obj/item/circuitboard/stargate

/obj/item/flatpak/stargate/Initialize(mapload, new_circuit_type, list/material_cost)
	return ..(mapload, circuit_type, material_cost)

/obj/item/flatpak/stargate/can_deploy_at(turf/deployment_turf)
	return stargate_site_is_clear(deployment_turf)

/obj/item/flatpak/stargate/mechanics_hints(mob/user, distance, is_adjacent)
	. = ..()
	. += "The ring faces the way you face during assembly. Leave three tiles clear across the ring and on both sides."

/// Each segment carries travelers straight through the corresponding lane.
/obj/effect/map_effect/portal/stargate
	name = "gateway aperture"
	icon = 'icons/mob/base_32.dmi'
	icon_state = "blank"
	opacity = FALSE
	blocks_emissive = EMISSIVE_BLOCK_NONE
	vis_flags = VIS_HIDE // Keep nearby rings from recursively rendering each other.
	var/obj/structure/stargate/gate
	var/obj/effect/map_effect/portal/stargate_preview/rear_preview
	var/obj/effect/map_effect/portal/stargate_preview/side_preview

/obj/effect/map_effect/portal/stargate/Destroy()
	QDEL_NULL(rear_preview)
	QDEL_NULL(side_preview)
	return ..()

/obj/effect/map_effect/portal/stargate/proc/get_exit_turf(approach_side)
	var/exit_direction = (approach_side == dir) ? REVERSE_DIR(counterpart.dir) : counterpart.dir
	return get_step(counterpart, exit_direction)

/obj/effect/map_effect/portal/stargate/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(!counterpart || !arrived || arrived.loc != loc)
		return
	var/approach_side = dir
	var/turf/entry = get_turf(old_loc)
	if(entry && entry.z == z && (get_dir(src, entry) & REVERSE_DIR(dir)))
		approach_side = REVERSE_DIR(dir)
	go_through_portal(arrived, get_exit_turf(approach_side))

/obj/effect/map_effect/portal/stargate/go_through_portal(atom/movable/traveler, turf/exit)
	if(!exit || exit.density || (locate(/obj/effect/map_effect/portal) in exit))
		return
	var/turf/exit_aperture = get_turf(counterpart)
	var/exit_direction = get_dir(exit_aperture, exit)
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
	if(isliving(traveler) && traveler.loc == exit)
		gate?.play_transit_sound()
		gate?.partner?.play_transit_sound()
		var/mob/living/arrived = traveler
		if(!flight)
			play_exit_glide(arrived, exit_aperture, exit)
		if(arrived.client)
			gate?.update_preview(arrived.client)
			gate?.partner?.update_preview(arrived.client)

/// Finish the visible step from the receiving ring after movement has resolved.
/obj/effect/map_effect/portal/stargate/proc/play_exit_glide(mob/living/traveler, turf/aperture_turf, turf/exit)
	var/delta_x = (aperture_turf.x - exit.x) * WORLD_ICON_SIZE
	var/delta_y = (aperture_turf.y - exit.y) * WORLD_ICON_SIZE
	var/duration = 0.15 SECONDS
	var/rest_x = traveler.pixel_x
	var/rest_y = traveler.pixel_y
	animate(traveler, pixel_x = rest_x + delta_x, pixel_y = rest_y + delta_y, time = 0, tag = "stargate exit")
	animate(pixel_x = rest_x, pixel_y = rest_y, time = duration, easing = SINE_EASING | EASE_OUT)

	var/client/viewer = traveler.client
	if(viewer?.eye == traveler)
		var/camera_x = viewer.pixel_x
		var/camera_y = viewer.pixel_y
		animate(viewer, pixel_x = camera_x + delta_x, pixel_y = camera_y + delta_y, time = 0, tag = "stargate exit")
		animate(pixel_x = camera_x, pixel_y = camera_y, time = duration, easing = SINE_EASING | EASE_OUT)

/// An alternate render target on a lane for the rear or side view.
/obj/effect/map_effect/portal/stargate_preview
	icon = 'icons/mob/base_32.dmi'
	icon_state = "blank"
	opacity = FALSE
	blocks_emissive = EMISSIVE_BLOCK_NONE
	vis_flags = VIS_HIDE
