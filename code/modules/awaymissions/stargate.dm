GLOBAL_LIST_EMPTY(open_stargates)

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
	var/obj/structure/machinery/computer/stargate/control_terminal
	/// Mapped rings open immediately unless their partner is a deployable ring.
	var/charge_duration = 0
	var/charge_timer
	var/obj/effect/stargate_charge/charge_effect
	var/list/apertures
	var/list/preview_images
	var/list/rear_preview_images
	var/list/side_preview_images
	var/list/angled_preview_images
	var/list/angled_preview_scenes
	var/image/preview_rim
	var/obj/effect/stargate_image_anchor/preview_anchor
	var/list/preview_targets
	/// The preview images currently shown to each client.
	var/list/preview_viewers
	/// Nearby movable eyes and the clients looking through each one.
	var/list/preview_eyes
	COOLDOWN_DECLARE(transit_effects)

/obj/structure/stargate/Initialize(mapload, pair_id)
	. = ..()
	if(!isnull(pair_id))
		gate_id = pair_id
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_terminal_position_changed))
	return INITIALIZE_HINT_LATELOAD

/obj/structure/stargate/LateInitialize()
	find_partner()

/obj/structure/stargate/mechanics_hints(mob/user, distance, is_adjacent)
	. = ..()
	. += "Use a multitool on the ring to store its connection, then apply the tool to a stargate control computer."

/obj/structure/stargate/proc/on_terminal_position_changed()
	SIGNAL_HANDLER
	if(control_terminal && (!isturf(loc) || z != control_terminal.z))
		control_terminal.link_gate(null)

/obj/structure/stargate/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/multitool) && user.a_intent != I_HURT)
		var/obj/item/multitool/tool = attacking_item
		tool.set_buffer(src)
		to_chat(user, SPAN_NOTICE("You store the ring's connection in [tool]. Apply it to a powered stargate control computer."))
		return TRUE
	return ..()

/obj/structure/stargate/proc/control_data()
	var/area/destination = get_area(partner)
	return list(
		"address" = gate_id,
		"linked" = !!length(apertures),
		"charging" = !!partner && !length(apertures),
		"destination" = destination?.name,
	)

/obj/structure/stargate/proc/can_link()
	return isturf(loc) && gate_id && (dir in GLOB.cardinals)

/obj/structure/stargate/proc/update_terminal()
	if(control_terminal)
		SStgui.update_uis(control_terminal)

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
	update_terminal()
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
		var/duration = max(charge_duration, other.charge_duration)
		if(duration)
			charge_timer = addtimer(CALLBACK(src, PROC_REF(finish_charge)), duration, TIMER_STOPPABLE)
			begin_charge(duration)
			other.begin_charge(duration)
		else
			open_passage(lanes, other_lanes)
		return
	unpaired_gates |= src

/obj/structure/stargate/proc/begin_charge(duration)
	charge_effect = new(get_turf(src), dir, duration)
	playsound(get_turf(src), 'sound/magic/Charge.ogg', 60, FALSE, ignore_walls = FALSE)
	update_terminal()

/obj/structure/stargate/proc/finish_charge()
	charge_timer = null
	if(!partner)
		return
	if(!can_link() || !partner.can_link())
		disconnect()
		return
	var/list/lanes = get_aperture_turfs()
	var/list/other_lanes = partner.get_aperture_turfs()
	if(!lanes || !other_lanes)
		disconnect()
		return
	QDEL_NULL(charge_effect)
	QDEL_NULL(partner.charge_effect)
	open_passage(lanes, other_lanes, TRUE)

/obj/structure/stargate/proc/open_passage(list/lanes, list/other_lanes, charged = FALSE)
	create_apertures(lanes)
	partner.create_apertures(other_lanes)
	for(var/i in 1 to length(apertures))
		var/obj/effect/map_effect/portal/stargate/near = apertures[i]
		var/obj/effect/map_effect/portal/stargate/far = partner.apertures[i]
		near.counterpart = far
		far.counterpart = near
	show_destination()
	partner.show_destination()
	on_passage_opened(charged)
	partner.on_passage_opened(charged)

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
	LAZYINITLIST(GLOB.open_stargates)
	GLOB.open_stargates |= src
	preview_anchor = new(get_turf(src))
	preview_targets = list()
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
	preview_rim = image(icon, loc = preview_anchor, icon_state = "linked", dir = dir, layer = ABOVE_OBJ_LAYER + 0.03)
	preview_rim.pixel_x = pixel_x
	preview_rim.pixel_y = pixel_y
	preview_rim.plane = ABOVE_LIGHTING_PLANE
	preview_rim.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	preview_rim.appearance_flags = PIXEL_SCALE | KEEP_APART
	preview_images += preview_rim
	rear_preview_images += preview_rim
	side_preview_images += preview_rim
	preview_targets[REF(preview_images)] = front_projected_turfs
	preview_targets[REF(rear_preview_images)] = rear_projected_turfs
	START_PROCESSING(SSprocessing, src)
	process()

/obj/structure/stargate/proc/make_preview(obj/effect/map_effect/portal/rendered_scene, turf/focus, approach_side, list/observed_turfs, list/projected_turfs, turf/remote_aperture = focus, view_slope = 0)
	// Aligned rings keep the remote aperture and its floor aligned with the local ring.
	var/projection_direction = (dir == partner.dir) ? approach_side : NONE
	var/turf/alignment_turf = projection_direction ? remote_aperture : focus
	var/turf/local_anchor = get_turf(rendered_scene)
	if(approach_side && !projection_direction)
		local_anchor = get_step(local_anchor, REVERSE_DIR(approach_side))
	rendered_scene.render_destination(focus, projection_direction, observed_turfs, limit_to_aperture = TRUE, alignment_turf = alignment_turf, view_slope = view_slope)
	for(var/turf/remote_turf in rendered_scene.vis_contents)
		var/turf/projected = locate(local_anchor.x + remote_turf.x - alignment_turf.x, local_anchor.y + remote_turf.y - alignment_turf.y, z)
		if(projected)
			projected_turfs[projected] = remote_turf
	// Keep the grouped scene off-screen until a viewer is on this side.
	rendered_scene.icon_state = "blank"
	rendered_scene.render_target = "*stargate-[REF(rendered_scene)]"
	var/image/preview = image(rendered_scene.icon, loc = preview_anchor, icon_state = rendered_scene.icon_state, layer = ABOVE_OBJ_LAYER)
	preview.render_source = rendered_scene.render_target
	// A wall on this end must not mask the projected room with local blackness.
	preview.plane = ABOVE_LIGHTING_PLANE
	preview.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	preview.appearance_flags = PIXEL_SCALE | KEEP_APART
	preview.pixel_x = rendered_scene.pixel_x + WORLD_ICON_SIZE * (local_anchor.x - preview_anchor.x)
	preview.pixel_y = rendered_scene.pixel_y + WORLD_ICON_SIZE * (local_anchor.y - preview_anchor.y)
	// Keep the wave in phase across lane images and move along the joins.
	var/horizontal_aperture = dir & (NORTH | SOUTH)
	var/wavelength = 3 * WORLD_ICON_SIZE
	var/scene_center = horizontal_aperture ? (rendered_scene.total_width * WORLD_ICON_SIZE / 2 + preview.pixel_x) : (rendered_scene.total_height * WORLD_ICON_SIZE / 2 + preview.pixel_y)
	var/phase = -scene_center / wavelength
	preview.filters = filter(type = "wave", x = horizontal_aperture ? wavelength : 0, y = horizontal_aperture ? 0 : wavelength, size = 0.45, offset = phase, flags = WAVE_SIDEWAYS | WAVE_BOUNDED)
	animate(preview.filters[1], offset = phase, time = 0, loop = -1)
	animate(offset = phase - 1, time = 5 SECONDS)
	rendered_scene.pixel_x = 0
	rendered_scene.pixel_y = 0
	return preview

/// Trace the perimeter of the combined projection so adjacent lanes join without seams.
/obj/structure/stargate/proc/make_preview_outline(list/projected_turfs)
	var/list/outline = list()
	for(var/turf/projected as anything in projected_turfs)
		var/exposed_edges = NONE
		for(var/direction in GLOB.cardinals)
			if(!(get_step(projected, direction) in projected_turfs))
				exposed_edges |= direction
		var/list/inside_corners = list()
		for(var/direction in GLOB.diagonals)
			if(!(exposed_edges & direction) && !(get_step(projected, direction) in projected_turfs))
				inside_corners += direction
		if(!exposed_edges && !length(inside_corners))
			continue
		var/image/edge = image(get_preview_outline_icon(exposed_edges, inside_corners), loc = preview_anchor, layer = ABOVE_OBJ_LAYER + 0.02)
		edge.pixel_x = (projected.x - x) * WORLD_ICON_SIZE
		edge.pixel_y = (projected.y - y) * WORLD_ICON_SIZE
		edge.plane = ABOVE_LIGHTING_PLANE
		edge.alpha = 128
		edge.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		edge.appearance_flags = PIXEL_SCALE | KEEP_APART
		outline += edge
	return outline

/obj/structure/stargate/proc/get_preview_outline_icon(exposed_edges, list/inside_corners)
	var/static/list/outline_patterns
	LAZYINITLIST(outline_patterns)
	var/pattern_key = "[exposed_edges]:[jointext(inside_corners, ",")]"
	if(outline_patterns[pattern_key])
		return outline_patterns[pattern_key]
	var/icon/pattern = icon('icons/mob/base_32.dmi', "blank")
	var/list/band_colors = list("#6AAEB9", "#5C9AA8DD", "#477C8BA8", "#33596768", "#203D4A30")
	var/band_count = length(band_colors)
	// Wrap the fade around each missing diagonal tile so the neighboring strokes meet.
	for(var/direction in inside_corners)
		for(var/horizontal in 1 to band_count)
			for(var/vertical in 1 to band_count)
				var/band = ceil(sqrt((horizontal - 0.5) ** 2 + (vertical - 0.5) ** 2))
				if(band > band_count)
					continue
				var/pixel_column = (direction & EAST) ? WORLD_ICON_SIZE + 1 - horizontal : horizontal
				var/pixel_row = (direction & NORTH) ? WORLD_ICON_SIZE + 1 - vertical : vertical
				pattern.DrawBox(band_colors[band], pixel_column, pixel_row, pixel_column, pixel_row)
	// Paint from the inner falloff to the outer stroke for an even width around turns.
	for(var/band = band_count, band >= 1, band--)
		var/band_color = band_colors[band]
		var/opposite = WORLD_ICON_SIZE + 1 - band
		if(exposed_edges & NORTH)
			pattern.DrawBox(band_color, 1, opposite, WORLD_ICON_SIZE, opposite)
		if(exposed_edges & SOUTH)
			pattern.DrawBox(band_color, 1, band, WORLD_ICON_SIZE, band)
		if(exposed_edges & EAST)
			pattern.DrawBox(band_color, opposite, 1, opposite, WORLD_ICON_SIZE)
		if(exposed_edges & WEST)
			pattern.DrawBox(band_color, band, 1, band, WORLD_ICON_SIZE)
	// Soften the tip of each outside corner while keeping the edge continuous.
	for(var/direction in GLOB.diagonals)
		if((exposed_edges & direction) != direction)
			continue
		var/corner_column = (direction & EAST) ? WORLD_ICON_SIZE : 1
		var/corner_row = (direction & NORTH) ? WORLD_ICON_SIZE : 1
		pattern.DrawBox(band_colors[2], corner_column, corner_row, corner_column, corner_row)
	outline_patterns[pattern_key] = pattern
	return pattern

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
	if(!partner || !eye_turf || eye_turf.z != z)
		return
	var/eye_direction = get_dir(src, eye_turf)
	if(!eye_direction)
		return
	var/approach_side = eye_direction & (dir | REVERSE_DIR(dir))
	if(!approach_side)
		return side_preview_images
	if(dir == partner.dir && preview_rim)
		var/north_south = dir & (NORTH | SOUTH)
		var/depth = abs(north_south ? eye_turf.y - y : eye_turf.x - x)
		var/across = north_south ? x - eye_turf.x : y - eye_turf.y
		// Quantize the sight line so nearby viewpoints can share render targets.
		var/view_slope = clamp(round(across / depth, 0.5), -2, 2)
		if(view_slope)
			return get_angled_preview(approach_side, view_slope)
	return (approach_side == dir) ? preview_images : rear_preview_images

/obj/structure/stargate/proc/get_angled_preview(approach_side, view_slope)
	LAZYINITLIST(angled_preview_images)
	var/key = "[approach_side],[view_slope]"
	var/list/images = angled_preview_images[key]
	if(images)
		return images
	images = list()
	var/list/observed_turfs = list()
	var/list/projected_turfs = list()
	for(var/obj/effect/map_effect/portal/stargate/aperture in apertures)
		var/obj/effect/map_effect/portal/stargate_preview/scene = new(get_turf(aperture))
		LAZYADD(angled_preview_scenes, scene)
		images += make_preview(scene, aperture.get_exit_turf(approach_side), approach_side, observed_turfs, projected_turfs, get_turf(aperture.counterpart), view_slope)
	images += make_preview_outline(projected_turfs)
	images += preview_rim
	angled_preview_images[key] = images
	LAZYINITLIST(preview_targets)
	preview_targets[REF(images)] = projected_turfs
	return images

/obj/structure/stargate/proc/update_preview(client/viewer)
	if(!preview_anchor || !preview_images || !viewer)
		return
	var/turf/eye_turf = get_turf(viewer.eye)
	var/list/next_images
	if(eye_turf?.z == z && (src in view(world.view, viewer.eye)))
		next_images = get_preview_images(eye_turf)
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
	if(GLOB.open_stargates)
		GLOB.open_stargates -= src
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
	angled_preview_images = null
	QDEL_NULL_LIST(angled_preview_scenes)
	preview_rim = null
	QDEL_NULL(preview_anchor)
	preview_targets = null
	preview_viewers = null
	preview_eyes = null

/// A validated route for one ranged action. The near lane is traversed by normal projectile movement.
/datum/stargate_aim
	var/obj/effect/map_effect/portal/stargate/lane
	var/obj/effect/map_effect/portal/stargate/receiving_lane
	var/turf/destination
	var/atom/target
	var/approach
	var/target_pixel_x = WORLD_ICON_SIZE / 2
	var/target_pixel_y = WORLD_ICON_SIZE / 2

/datum/stargate_aim/proc/can_launch_from(atom/source)
	var/turf/origin = get_turf(source)
	return receiving_lane && lane?.counterpart == receiving_lane && origin && origin.z == lane.z && (get_dir(lane.gate, origin) & approach) && (lane.loc in view(world.view, origin))

/datum/stargate_aim/proc/routes_through(obj/structure/stargate/gate)
	return gate && lane?.gate == gate && receiving_lane?.gate == gate.partner

/mob/proc/find_stargate_aim(turf/clicked_turf, atom/remote_target)
	if(!length(GLOB.open_stargates) || !isliving(src) || !client || client.eye != src || !isturf(loc))
		return
	var/turf/remote_turf = get_turf(remote_target)
	if(!clicked_turf && !remote_turf)
		return
	var/list/visible = view(world.view, src)
	for(var/obj/structure/stargate/gate as anything in GLOB.open_stargates)
		if(!gate.partner || gate.z != z || !(gate in visible))
			continue
		var/list/images = gate.preview_viewers?[client]
		var/list/targets = gate.preview_targets?[REF(images)]
		if(!length(targets))
			continue
		var/turf/projected = clicked_turf
		if(remote_turf)
			for(var/turf/shown as anything in targets)
				if(targets[shown] == remote_turf)
					projected = shown
					break
		var/turf/destination = targets[projected]
		if(!destination)
			continue
		var/approach = get_dir(gate, src) & (gate.dir | REVERSE_DIR(gate.dir))
		if(!approach || !(get_dir(gate, projected) & REVERSE_DIR(approach)))
			continue
		var/list/path = get_line(src, projected)
		var/obj/effect/map_effect/portal/stargate/chosen
		for(var/obj/effect/map_effect/portal/stargate/lane in gate.apertures)
			if(lane.loc in path)
				chosen = lane
				break
			if(!chosen || get_dist(lane, projected) < get_dist(chosen, projected))
				chosen = lane
		if(!chosen?.counterpart || !(chosen.loc in visible))
			continue
		var/turf/exit = chosen.get_exit_turf(approach)
		if(destination == get_turf(chosen.counterpart) || !(get_dir(chosen.counterpart, destination) & get_dir(chosen.counterpart, exit)))
			continue
		var/datum/stargate_aim/aim = new
		aim.lane = chosen
		aim.receiving_lane = chosen.counterpart
		aim.destination = destination
		aim.target = remote_target || destination
		aim.approach = approach
		return aim

/obj/structure/stargate/Destroy()
	control_terminal?.link_gate(null)
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
	var/was_charging = !!charge_effect
	if(charge_timer)
		deltimer(charge_timer)
		charge_timer = null
	QDEL_NULL(charge_effect)
	if(!apertures)
		if(was_charging)
			update_terminal()
		return FALSE
	clear_preview()
	QDEL_NULL_LIST(apertures)
	icon_state = "idle"
	playsound(get_turf(src), 'sound/magic/Teleport_diss.ogg', 35, FALSE)
	update_terminal()
	return TRUE

/obj/structure/stargate/proc/on_passage_opened(charged)
	var/turf/center = get_turf(src)
	playsound(center, 'sound/effects/phasein.ogg', charged ? 80 : 45, FALSE)
	if(charged)
		new /obj/effect/stargate_transit(center, dir, TRUE)
		new /obj/effect/shockwave/stargate(center, 7, 3, SINE_EASING | EASE_OUT)
		playsound(center, 'sound/effects/EMPulse.ogg', 65, FALSE, frequency = 32000, ignore_walls = FALSE)
	update_terminal()

/obj/structure/stargate/proc/play_transit_effects()
	if(!COOLDOWN_FINISHED(src, transit_effects))
		return
	COOLDOWN_START(src, transit_effects, 0.65 SECONDS)
	var/turf/center = get_turf(src)
	new /obj/effect/stargate_transit(center, dir)
	new /obj/effect/shockwave/stargate(center, 3, 2.5, SINE_EASING | EASE_OUT)
	playsound(center, 'sound/effects/teleport.ogg', 35, TRUE, extrarange = -6, frequency = 38000, ignore_walls = FALSE)
	playsound(center, 'sound/effects/EMPulse.ogg', 24, TRUE, extrarange = -8, frequency = 30000, ignore_walls = FALSE)

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
	charge_duration = 2 SECONDS
	var/enabled = FALSE
	var/area/power_area

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
	. += "Bolt the ring to a clear three-by-three floor with a wrench. Use the linked computers to set matching addresses and activate both rings."
	. += "Unbolt the ring, then use a crowbar to fold it back into a flatpak."

/obj/structure/stargate/deployable/can_link()
	return anchored && enabled && equipment_powered() && control_terminal?.can_operate_gate() && ..()

/obj/structure/stargate/deployable/get_aperture_turfs()
	if(stargate_site_is_clear(get_turf(src), src))
		return ..()

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
	update_terminal()

/obj/structure/stargate/deployable/on_terminal_position_changed()
	SIGNAL_HANDLER
	if(anchored)
		set_gate_anchored(FALSE)
	return ..()

/obj/structure/stargate/deployable/proc/on_equipment_power_change()
	SIGNAL_HANDLER
	if(equipment_powered())
		find_partner()
	else
		disconnect()
	update_terminal()

/obj/structure/stargate/deployable/on_passage_opened(charged)
	power_area?.use_power_oneoff(2500, AREA_USAGE_EQUIP)
	return ..()

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

/obj/structure/stargate/deployable/control_data()
	. = ..()
	.["deployable"] = TRUE
	.["anchored"] = anchored
	.["powered"] = equipment_powered()
	.["enabled"] = enabled

/obj/structure/stargate/deployable/proc/set_activation(should_enable, mob/user)
	if(should_enable == enabled)
		return FALSE
	if(should_enable)
		if(!anchored || !equipment_powered() || !gate_id || !control_terminal?.can_operate_gate())
			if(user)
				to_chat(user, SPAN_WARNING("Secure and power the ring, link a powered control computer, and set an address before activating it."))
			return FALSE
		if(!stargate_site_is_clear(get_turf(src), src))
			if(user)
				to_chat(user, SPAN_WARNING("Clear the floor around the ring before activating it."))
			return FALSE
	enabled = should_enable
	if(user)
		playsound(get_turf(src), 'sound/arcade/sloto_lever.ogg', 35, FALSE, extrarange = -5)
	if(enabled)
		find_partner()
	else
		disconnect()
	update_terminal()
	return TRUE

/obj/structure/machinery/computer/stargate
	name = "stargate control computer"
	desc = "A hard-shell terminal used to program and activate a stargate. It has a port for the linkage stored in a multitool."
	icon = 'icons/obj/primitive_computer.dmi'
	icon_screen = "engi"
	is_holographic = FALSE
	can_pass_under = FALSE
	circuit = /obj/item/circuitboard/stargate_terminal
	var/obj/structure/stargate/linked_gate

/obj/structure/machinery/computer/stargate/mechanics_hints(mob/user, distance, is_adjacent)
	. = ..()
	. += "Use a multitool on a stargate on this level, then use it on this powered computer to link them."

/obj/structure/machinery/computer/stargate/attackby(obj/item/attacking_item, mob/user)
	if(!istype(attacking_item, /obj/item/multitool) || user.a_intent == I_HURT)
		return ..()
	var/obj/item/multitool/tool = attacking_item
	var/obj/structure/stargate/buffered_gate = tool.get_buffer(/obj/structure/stargate)
	if(!operable(MAINT) || !powered())
		to_chat(user, SPAN_WARNING("The control computer must be operational to accept a link."))
	else if(!buffered_gate)
		to_chat(user, SPAN_WARNING("Use the multitool on a stargate first."))
	else if(buffered_gate == linked_gate)
		to_chat(user, SPAN_NOTICE("This computer already controls that ring."))
	else if(!link_gate(buffered_gate))
		to_chat(user, SPAN_WARNING("The ring must be on this level and available for a new computer connection."))
	else
		add_fingerprint(user)
		tool.set_buffer(null)
		to_chat(user, SPAN_NOTICE("You link [src] to [buffered_gate]."))
	return TRUE

/obj/structure/machinery/computer/stargate/attack_hand(mob/user)
	if(..())
		return TRUE
	ui_interact(user)
	return TRUE

/obj/structure/machinery/computer/stargate/Destroy()
	link_gate(null)
	return ..()

/obj/structure/machinery/computer/stargate/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(linked_gate && (!isturf(loc) || linked_gate.z != z))
		link_gate(null)
	else if(!can_operate_gate())
		reset_activation()

/obj/structure/machinery/computer/stargate/power_change()
	. = ..()
	if(linked_gate && !can_operate_gate())
		reset_activation()
	SStgui.update_uis(src)

/obj/structure/machinery/computer/stargate/set_broken()
	. = ..()
	reset_activation()
	SStgui.update_uis(src)

/obj/structure/machinery/computer/stargate/proc/link_gate(obj/structure/stargate/new_gate)
	if(new_gate == linked_gate)
		return FALSE
	if(new_gate && (QDELETED(new_gate) || !isturf(new_gate.loc) || new_gate.z != z || new_gate.control_terminal))
		return FALSE
	reset_activation()
	if(linked_gate?.control_terminal == src)
		linked_gate.control_terminal = null
	linked_gate = new_gate
	if(new_gate)
		new_gate.control_terminal = src
	SStgui.update_uis(src)
	return TRUE

/obj/structure/machinery/computer/stargate/proc/reset_activation()
	var/obj/structure/stargate/deployable/deployed_gate = linked_gate
	if(istype(deployed_gate) && !QDELETED(deployed_gate))
		deployed_gate.set_activation(FALSE)

/obj/structure/machinery/computer/stargate/proc/can_operate_gate()
	return !QDELETED(linked_gate) && isturf(loc) && anchored && linked_gate.z == z && operable(MAINT) && powered()

/obj/structure/machinery/computer/stargate/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/machinery/computer/stargate/ui_interact(mob/user, datum/tgui/ui)
	if(!operable(MAINT) || !powered())
		ui?.close()
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Stargate", "Stargate Control Computer")
		ui.open()

/obj/structure/machinery/computer/stargate/ui_static_data(mob/user)
	var/static/list/ring_images
	if(!ring_images)
		ring_images = list()
		for(var/state in list("idle", "linked"))
			var/icon/ring = icon('icons/obj/machinery/stargate.dmi', state, SOUTH)
			ring.Crop(1, 49, 160, 112)
			ring_images[state] = icon2base64(ring)
	return list("ring_images" = ring_images, "max_length" = MAX_NAME_LEN)

/obj/structure/machinery/computer/stargate/ui_data(mob/user)
	. = linked_gate ? linked_gate.control_data() : list()
	.["has_ring"] = !!linked_gate

/obj/structure/machinery/computer/stargate/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	if(!can_operate_gate())
		return FALSE
	if(action == "set_address" && params["previous_address"] == linked_gate.gate_id)
		return linked_gate.set_address(params["address"])
	if(action == "unlink_ring")
		return link_gate(null)
	var/obj/structure/stargate/deployable/deployed_gate = linked_gate
	if(action == "set_activation" && istype(deployed_gate))
		return deployed_gate.set_activation(!!params["enabled"], usr)

/obj/item/circuitboard/stargate
	name = T_BOARD("stargate controller")
	build_path = /obj/structure/stargate/deployable
	board_type = BOARD_MACHINE

/obj/item/circuitboard/stargate_terminal
	name = T_BOARD("stargate control computer")
	build_path = /obj/structure/machinery/computer/stargate
	board_type = BOARD_COMPUTER

/obj/item/flatpak/stargate_terminal
	circuit_type = /obj/item/circuitboard/stargate_terminal

/obj/item/flatpak/stargate_terminal/Initialize(mapload, new_circuit_type, list/material_cost)
	return ..(mapload, circuit_type, material_cost)

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
	if(istype(arrived, /obj/effect/stargate_image_anchor) || istype(arrived, /obj/effect/map_effect/portal/stargate_preview) || istype(arrived, /obj/effect/stargate_transit) || istype(arrived, /obj/effect/shockwave/stargate))
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
		var/datum/stargate_aim/aim = flight.stargate_aim
		flight.stargate_aim = null
		if(aim?.routes_through(gate))
			flight.target_turf = aim.destination
			flight.initial_target = ismovable(aim.target) && get_turf(aim.target) == aim.destination ? WEAKREF(aim.target) : null
			flight.set_throw_heading(exit, aim.destination)
			flight.trajectory_start_distance = flight.dist_travelled + 1
		else
			flight.target_turf = get_ranged_target_turf(exit, exit_direction, get_dist(src, flight.target_turf))
			flight.initial_target = null
			flight.init_dir = exit_direction
			flight.dx = exit_direction // The throw's primary step is now along the exit axis.
	if(istype(traveler, /obj/projectile))
		var/obj/projectile/projectile = traveler
		var/datum/stargate_aim/aim = projectile.stargate_aim
		projectile.stargate_aim = null
		if(aim?.routes_through(gate) && aim.destination != exit)
			var/list/heading = calculate_projectile_angle_and_pixel_offsets(exit, aim.destination, list(ICON_X = aim.target_pixel_x, ICON_Y = aim.target_pixel_y))
			projectile.set_angle(heading[1] + closer_angle_difference(projectile.stargate_entry_angle, projectile.Angle))
		else
			projectile.set_angle(dir2angle(exit_direction))
	. = ..(traveler, exit)
	if(isliving(traveler) && traveler.loc == exit)
		gate?.play_transit_effects()
		gate?.partner?.play_transit_effects()
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

/// Keeps player-specific projection images out of copies of the surrounding turf.
/obj/effect/stargate_image_anchor
	icon = 'icons/mob/base_32.dmi'
	icon_state = "blank"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_HIDE
	z_flags = ZMM_IGNORE

/// The opening emits a short energy burst as a traveler crosses.
/obj/effect/stargate_transit
	name = "gateway transit burst"
	icon = 'icons/effects/effects.dmi'
	icon_state = "emppulse"
	color = "#73E8FF"
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_OBJ_LAYER + 0.04
	blend_mode = BLEND_ADD
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_HIDE
	z_flags = ZMM_IGNORE

/obj/effect/stargate_transit/Initialize(mapload, gate_direction, opening = FALSE)
	. = ..()
	var/static/icon/burst = icon('icons/effects/effects.dmi', "emppulse", frame = 5)
	icon = burst
	icon_state = ""
	var/angle = (gate_direction & (EAST | WEST)) ? 90 : 0
	var/duration = opening ? 0.9 SECONDS : 0.5 SECONDS
	transform = matrix().Scale(3.8, opening ? 1.6 : 1.1).Turn(angle)
	var/matrix/expanded = opening ? matrix().Scale(9, 4.2) : matrix().Scale(5.6, 2.4)
	animate(src, transform = expanded.Turn(angle), alpha = 0, time = duration, easing = SINE_EASING | EASE_OUT)
	AddElement(/datum/element/temporary, duration)

/obj/effect/stargate_charge
	name = "gathering energy"
	icon = 'icons/effects/effects.dmi'
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_OBJ_LAYER + 0.04
	blend_mode = BLEND_ADD
	appearance_flags = PIXEL_SCALE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_HIDE
	z_flags = ZMM_IGNORE
	alpha = 0

/obj/effect/stargate_charge/Initialize(mapload, gate_direction, duration)
	. = ..()
	var/static/icon/pulse = icon('icons/effects/effects.dmi', "emppulse", frame = 5)
	icon = pulse
	var/angle = (gate_direction & (EAST | WEST)) ? 90 : 0
	transform = matrix().Scale(6, 3.1).Turn(angle)
	animate(src, transform = matrix().Scale(5.6, 2.8).Turn(angle), alpha = 95, time = duration * 0.25, easing = SINE_EASING)
	animate(transform = matrix().Scale(4.7, 2.2).Turn(angle), alpha = 60, time = duration * 0.2, easing = SINE_EASING)
	animate(transform = matrix().Scale(3.6, 0.95).Turn(angle), alpha = 230, time = duration * 0.55, easing = SINE_EASING | EASE_IN)

/obj/effect/shockwave/stargate
	vis_flags = VIS_HIDE
	z_flags = ZMM_IGNORE
