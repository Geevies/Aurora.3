/**
 * Tests whether or not all mapped in machinery appear in the SSmachinery.machinery
 * list after round start.
 *
 * It's not exactly the most robust, but it'll catch basic faults in new machinery
 * design.
 */
/datum/unit_test/machinery_global_test
	name = "OBJECTS: Machinery Global List Test"
	groups = list("map")

/datum/unit_test/machinery_global_test/start_test()
	var/list/all_types = list()
	var/list/unfound_types = list()

	for (var/obj/structure/machinery/M in world)
		if (!LAZYISIN(SSmachinery.machinery, M) && !QDELETED(M))
			if (!unfound_types[M.type])
				unfound_types[M.type] = 1
			else
				unfound_types[M.type]++

		if (!all_types[M.type])
			all_types[M.type] = 1

	if (unfound_types.len)
		for (var/t in unfound_types)
			TEST_FAIL("[unfound_types[t]] instances of [t] not found in SSmachinery.machinery.")

		TEST_FAIL("\[[unfound_types.len] / [all_types.len]\] mapped in machinery types were not found in SSmachinery.machinery.")
	else
		TEST_PASS("All \[[all_types.len]\] mapped in machinery types were found in SSmachinery.machinery.")

	return 1

/**
 * Tests whether all floor tiles have a unique or null build type. Else constructing them may result in the wrong turf.
 */
/datum/unit_test/flooring_build_type_conflicts
	name = "OBJECTS: All flooring shall have a unique build type"
	groups = list("map")

/datum/unit_test/flooring_build_type_conflicts/start_test()
	var/list/known_types = list()
	var/list/decls = GET_SINGLETON_SUBTYPE_MAP(/singleton/flooring)
	for(var/flooring_type in decls)
		var/singleton/flooring/F = decls[flooring_type]
		if(!isnull(F.build_type))
			known_types += F.build_type

	if(known_types.len == length(uniquelist(known_types)))
		TEST_PASS("All flooring types had a unique or null build type.")
	else
		for(var/type in known_types)
			var/i = 0
			for(var/flooring_type in known_types)
				if(flooring_type == type)
					i++
			if(i != 1)
				TEST_FAIL("Flooring build_type [type] is non-unique; exists [i] times.")
		TEST_FAIL("Found non-unique build_types in flooring decl.")

	return TRUE

/datum/unit_test/stargate
	name = "OBJECTS: Stargate traversal"
	groups = list("generic")

/datum/unit_test/stargate/start_test()
	var/list/sites = list()
	for(var/turf/simulated/floor/site in world)
		if(length(sites) && get_dist(sites[1], site) < 5)
			continue
		var/turf/corner = get_offset_target_turf(site, -1, length(sites) ? -2 : -1)
		var/turf/opposite_corner = get_offset_target_turf(site, 1, length(sites) ? 2 : 1)
		var/list/footprint = block(corner, opposite_corner)
		var/clear = length(footprint) == (length(sites) ? 15 : 9)
		for(var/turf/tile in footprint)
			if(!istype(tile, /turf/simulated/floor) || tile.contains_dense_objects())
				clear = FALSE
				break
		if(!clear)
			continue
		sites += site
		if(length(sites) == 2)
			break
	TEST_ASSERT(length(sites) == 2, "Two clear gate sites are required")

	var/obj/structure/stargate/first = new(sites[1], REF(src))
	var/obj/structure/stargate/second = new(sites[2], REF(src))
	var/failures_before = GLOB.unit_tests_failures
	if(length(first.preview_images) <= 4 || length(first.rear_preview_images) <= 4 || length(first.side_preview_images) <= 4)
		TEST_FAIL("Each view must show the three lanes and their outline")
	var/image/front_scene = first.preview_images?[1]
	var/image/rear_scene = first.rear_preview_images?[1]
	var/image/side_scene = first.side_preview_images?[1]
	var/obj/effect/map_effect/portal/stargate/first_lane = first.apertures?[1]
	if(front_scene?.pixel_y != 0 || rear_scene?.pixel_y != (1 - first_lane?.rear_preview?.total_height) * WORLD_ICON_SIZE)
		TEST_FAIL("The far aperture row must line up with the near ring from both approaches")
	if(front_scene?.plane <= BLACKNESS_PLANE || rear_scene?.plane <= BLACKNESS_PLANE || side_scene?.plane <= BLACKNESS_PLANE)
		TEST_FAIL("Every destination preview must draw above the local blackness mask")
	var/list/adjacent_tiles = list(get_turf(first), get_step(first, EAST))
	var/list/adjacent_outline = first.make_preview_outline(adjacent_tiles)
	if(length(adjacent_outline) != 2)
		TEST_FAIL("The outline must use one image per perimeter tile")
	else
		var/image/west_edge = adjacent_outline[1]
		var/image/east_edge = adjacent_outline[2]
		var/icon/west_pattern = icon(west_edge.icon)
		var/icon/east_pattern = icon(east_edge.icon)
		var/middle = WORLD_ICON_SIZE / 2
		if(west_pattern.GetPixel(WORLD_ICON_SIZE, middle) || east_pattern.GetPixel(1, middle))
			TEST_FAIL("The outline must omit the seam between adjacent projected tiles")
		if(!west_pattern.GetPixel(1, middle) || !east_pattern.GetPixel(WORLD_ICON_SIZE, middle))
			TEST_FAIL("The outline must draw both exposed edges")
		if(!west_pattern.GetPixel(5, middle) || west_pattern.GetPixel(6, middle))
			TEST_FAIL("The outline must fade inward over five pixels")
		if(west_pattern.GetPixel(1, 1) != west_pattern.GetPixel(1, middle))
			TEST_FAIL("The outer stroke must stay continuous at corners")
	if(first.get_preview_images(get_step(first, SOUTH)) != first.preview_images || first.get_preview_images(get_step(first, NORTH)) != first.rear_preview_images)
		TEST_FAIL("Viewers must get the preview for their side of the ring")
	if(first.get_preview_images(get_step(first, EAST)) != first.side_preview_images || first.get_preview_images(get_step(first, WEST)) != first.side_preview_images)
		TEST_FAIL("Both lateral approaches must show the destination aperture")
	var/turf/west_approach = get_step(first, SOUTHWEST)
	var/list/from_west = first.get_preview_images(west_approach)
	var/list/from_east = first.get_preview_images(get_step(first, SOUTHEAST))
	if(!from_west || !from_east || from_west == from_east || from_west == first.preview_images || from_east == first.preview_images || from_west != first.get_preview_images(west_approach))
		TEST_FAIL("Angled approaches must get distinct, reusable previews")
	var/obj/effect/stargate_image_anchor/old_anchor = first.preview_anchor
	if(!(old_anchor?.vis_flags & VIS_HIDE))
		TEST_FAIL("The preview anchor must stay out of copied turf appearances")
	for(var/image/preview as anything in first.preview_images + first.rear_preview_images + first.side_preview_images + from_west + from_east)
		if(preview.loc != old_anchor)
			TEST_FAIL("Every preview image must be attached to the isolated anchor")
			break

	var/turf/focus = get_step(second, NORTH)
	var/turf/far_right = get_step(focus, NORTHEAST)
	var/turf/far_left = get_step(focus, NORTHWEST)
	var/obj/effect/map_effect/portal/stargate_preview/angled_scene = new
	angled_scene.render_destination(focus, SOUTH, list(), limit_to_aperture = TRUE, view_slope = 2)
	if(!(far_right in angled_scene.vis_contents) || (far_left in angled_scene.vis_contents))
		TEST_FAIL("Looking through from the west must shift the destination view east")
	qdel(angled_scene)
	for(var/offset in -1 to 1)
		var/turf/entry = get_offset_target_turf(first, offset, 0)
		var/turf/other_entry = get_offset_target_turf(second, offset, 0)
		var/turf/north_exit = get_step(other_entry, NORTH)
		var/turf/south_exit = get_step(other_entry, SOUTH)
		var/obj/effect/map_effect/portal/stargate/aperture = locate() in entry
		if(!(north_exit in aperture?.vis_contents))
			TEST_FAIL("Aligned lane [offset] must show the north exit turf using the map portal effect")
		if(!(south_exit in aperture?.rear_preview?.vis_contents))
			TEST_FAIL("Aligned lane [offset] must show the south exit turf from the north")
		if(!(other_entry in aperture?.vis_contents) || !(other_entry in aperture?.rear_preview?.vis_contents))
			TEST_FAIL("Aligned lane [offset] must include the floor beneath the far ring")
		if(length(aperture?.side_preview?.vis_contents) != 1 || !(other_entry in aperture.side_preview.vis_contents))
			TEST_FAIL("Side-on lane [offset] must show only the remote aperture turf")
		if(aperture?.opacity || aperture?.rear_preview?.opacity || aperture?.side_preview?.opacity)
			TEST_FAIL("The aperture and its preview must leave normal room visibility intact")
		var/mob/living/traveler = new(get_step(entry, SOUTH))
		step(traveler, NORTH)
		if(traveler.loc != north_exit)
			TEST_FAIL("Entering aligned lane [offset] from the south must exit north")
		step(traveler, SOUTH)
		if(traveler.loc != get_step(entry, SOUTH))
			TEST_FAIL("Entering aligned lane [offset] from the north must exit south")
		qdel(traveler)
	var/turf/beyond_north_exit = get_offset_target_turf(second, 0, 2)
	var/turf/beyond_south_exit = get_offset_target_turf(second, 0, -2)
	var/found_north_room = FALSE
	var/found_south_room = FALSE
	for(var/obj/effect/map_effect/portal/stargate/aperture in first.apertures)
		found_north_room ||= (beyond_north_exit in aperture.vis_contents)
		found_south_room ||= (beyond_south_exit in aperture.rear_preview.vis_contents)
	if(!found_north_room || !found_south_room)
		TEST_FAIL("The map portal effect must show the destination room beyond both exit rows")

	var/obj/effect/map_effect/portal/stargate/aim_lane = first.apertures[2]
	var/turf/aim_origin = get_step(aim_lane, SOUTH)
	var/turf/aim_destination = get_offset_target_turf(second, 1, 2)
	var/datum/stargate_aim/aim = new
	aim.lane = aim_lane
	aim.receiving_lane = aim_lane.counterpart
	aim.approach = SOUTH
	aim.destination = aim_destination
	aim.target = aim_destination
	var/turf/aim_projection = get_offset_target_turf(first, 1, 2)
	var/list/aim_targets = first.preview_targets[REF(first.preview_images)]
	if(aim_targets[aim_projection] != aim_destination)
		TEST_FAIL("The projected floor must map back to its remote turf")

	var/obj/projectile/aimed_shot = new(aim_origin)
	aimed_shot.preparePixelProjectile(aim_destination, aim_origin, list("stargate_aim" = aim))
	aimed_shot.fire()
	for(var/i in 1 to 45)
		if(QDELETED(aimed_shot) || aimed_shot.loc == aim_destination)
			break
		aimed_shot.pixel_move(1)
	if(QDELETED(aimed_shot) || aimed_shot.loc != aim_destination)
		TEST_FAIL("A projectile aimed through a lane must reach the off-axis destination")
	qdel(aimed_shot)

	var/obj/item/aimed_throw = new(aim_origin)
	aimed_throw.throw_at(aim_destination, 4, 2, null, FALSE, FALSE, null, MOVE_FORCE_STRONG, FALSE, FALSE, aim)
	for(var/i in 1 to 6)
		if(!aimed_throw.throwing)
			break
		aimed_throw.throwing.start_time -= 1
		aimed_throw.throwing.tick()
	if(aimed_throw.loc != aim_destination)
		TEST_FAIL("A throw aimed through a lane must continue to the off-axis destination")
	qdel(aimed_throw)

	var/list/old_angled_scenes = first.angled_preview_scenes?.Copy()
	first.set_address("Unpaired [REF(src)]")
	if(!QDELETED(old_anchor))
		TEST_FAIL("Unlinking must remove the preview anchor")
	for(var/obj/effect/map_effect/portal/stargate_preview/old_scene as anything in old_angled_scenes)
		if(!QDELETED(old_scene))
			TEST_FAIL("Unlinking must remove the cached angle render targets")
	first.set_dir(EAST)
	first.set_address(second.gate_id)
	if(length(first.apertures) != 3 || length(second.apertures) != 3)
		TEST_FAIL("Each ring must open exactly three segments")
	front_scene = first.preview_images?[1]
	rear_scene = first.rear_preview_images?[1]
	side_scene = first.side_preview_images?[1]
	if(front_scene?.pixel_x != -WORLD_ICON_SIZE || rear_scene?.pixel_x != WORLD_ICON_SIZE || !(side_scene in first.preview_images) || !(side_scene in first.rear_preview_images))
		TEST_FAIL("A turned view must keep the aperture row and show the exit one tile beyond it")
	for(var/offset in -1 to 1)
		var/turf/entry = get_offset_target_turf(first, 0, offset)
		var/turf/other_entry = get_offset_target_turf(second, offset, 0)
		var/turf/north_exit = get_step(other_entry, NORTH)
		var/turf/south_exit = get_step(other_entry, SOUTH)
		var/turf/east_exit = get_step(entry, EAST)
		var/turf/west_exit = get_step(entry, WEST)
		var/obj/effect/map_effect/portal/stargate/aperture = locate() in entry
		if(!(north_exit in aperture?.vis_contents))
			TEST_FAIL("Turned lane [offset] must show its exit turf")
		if(!(south_exit in aperture?.rear_preview?.vis_contents))
			TEST_FAIL("Turned lane [offset] must show the opposite exit turf from the rear")

		var/mob/living/traveler = new(east_exit)
		step(traveler, WEST)
		if(traveler.loc != north_exit)
			TEST_FAIL("Entering the front of segment [offset] must exit at the back")
		traveler.throw_at(other_entry, 1, 1)
		if(traveler.loc != east_exit)
			TEST_FAIL("Entering the back of segment [offset] must exit at the front")
		traveler.forceMove(west_exit)
		step(traveler, EAST)
		if(traveler.loc != south_exit)
			TEST_FAIL("Walking into the back of segment [offset] must exit at the front")
		qdel(traveler)

	var/turf/first_edge = get_step(first, NORTH)
	var/turf/first_exit = get_step(first_edge, EAST)
	var/turf/second_exit = get_step(get_step(second, EAST), NORTH)
	var/obj/item/cargo = new(first_exit)
	cargo.throw_at(get_step(first_edge, WEST), 2, 4)
	if(cargo.throwing)
		cargo.throwing.start_time -= 2
		cargo.throwing.tick()
	if(cargo.loc != get_step(second_exit, NORTH))
		TEST_FAIL("A thrown item must continue out of the receiving ring")
	qdel(cargo)

	var/obj/projectile/shot = new(first_exit)
	shot.fire(dir2angle(WEST))
	for(var/i in 1 to 8)
		if(QDELETED(shot) || shot.loc == get_step(second_exit, NORTH))
			break
		shot.pixel_move(1)
	if(QDELETED(shot) || shot.loc != get_step(second_exit, NORTH))
		TEST_FAIL("A projectile must continue out of the receiving ring")
	qdel(shot)

	var/datum/tgui/controls = new(null, first, "Stargate")
	controls.status = UI_INTERACTIVE
	var/original_address = first.gate_id
	var/new_address = "Outpost [REF(src)]"
	first.ui_act("set_address", list("address" = "  ", "previous_address" = original_address), controls)
	if(first.partner != second || first.gate_id != original_address)
		TEST_FAIL("A blank address must leave the current passage open")

	first.ui_act("set_address", list("address" = "  [new_address]  ", "previous_address" = original_address), controls)
	var/list/status = first.ui_data()
	if(status["address"] != new_address || status["linked"] || length(first.apertures) || length(second.apertures))
		TEST_FAIL("Applying a new address must close both ends and show the saved address")
	first.ui_act("set_address", list("address" = original_address, "previous_address" = original_address), controls)
	if(first.gate_id != new_address)
		TEST_FAIL("A stale editor must not overwrite a newer address")
	second.set_address(new_address)
	status = first.ui_data()
	if(first.partner != second || !status["linked"] || length(first.apertures) != 3 || length(second.apertures) != 3)
		TEST_FAIL("Setting matching addresses must reopen the full passage")
	qdel(controls)

	var/list/segments = first.apertures + second.apertures
	qdel(first)
	if(second.partner || length(second.apertures) || length(second.preview_images) || length(second.rear_preview_images) || length(second.side_preview_images) || second.icon_state != "idle")
		TEST_FAIL("Deleting one ring must close the surviving aperture")
	for(var/obj/effect/map_effect/portal/stargate/segment as anything in segments)
		if(!QDELETED(segment))
			TEST_FAIL("Deleting a ring must remove every segment at both ends")
	qdel(second)

	var/obj/item/flatpak/stargate/flatpak = new(sites[1])
	if(flatpak.machine_type != /obj/structure/stargate/deployable || !flatpak.can_deploy_at(sites[1]))
		TEST_FAIL("A cargo flatpak must contain a deployable stargate and accept a clear site")
	var/obj/structure/obstacle = new(get_step(sites[1], SOUTHWEST))
	obstacle.density = TRUE
	if(flatpak.can_deploy_at(sites[1]))
		TEST_FAIL("The site check must account for side lanes and their approaches")
	qdel(obstacle)
	qdel(flatpak)

	var/obj/structure/stargate/deployable/installed = new(sites[1])
	var/obj/structure/stargate/deployable/remote = new(sites[2])
	var/area/local_area = get_area(installed)
	var/area/remote_area = get_area(remote)
	var/local_required_power = local_area.requires_power
	var/remote_required_power = remote_area.requires_power
	var/was_always_unpowered = local_area.always_unpowered
	local_area.requires_power = FALSE
	remote_area.requires_power = FALSE
	installed.set_address(new_address)
	remote.set_address(new_address)
	controls = new(null, installed, "Stargate")
	controls.status = UI_INTERACTIVE
	installed.ui_act("set_enabled", list("enabled" = TRUE), controls)
	if(installed.enabled || installed.partner)
		TEST_FAIL("An unbolted gate must reject activation")
	installed.set_gate_anchored(TRUE)
	remote.set_gate_anchored(TRUE)
	installed.ui_act("set_enabled", list("enabled" = TRUE), controls)
	if(!installed.enabled || installed.partner)
		TEST_FAIL("An enabled gate must wait until its partner is enabled")
	var/datum/tgui/remote_controls = new(null, remote, "Stargate")
	remote_controls.status = UI_INTERACTIVE
	remote.ui_act("set_enabled", list("enabled" = TRUE), remote_controls)
	if(installed.partner != remote || length(installed.apertures) != 3)
		TEST_FAIL("Two powered and enabled gates must open a three-tile passage")

	local_area.requires_power = TRUE
	local_area.always_unpowered = TRUE
	local_area.power_change()
	if(installed.partner || remote.partner || installed.apertures || remote.apertures)
		TEST_FAIL("Losing equipment power must remove both apertures")
	local_area.requires_power = FALSE
	local_area.power_change()
	if(installed.partner != remote)
		TEST_FAIL("Restoring equipment power must reconnect gates that are still enabled")
	remote.set_gate_anchored(FALSE)
	if(installed.partner || remote.enabled || remote.power_area)
		TEST_FAIL("Unbolting a gate must close the passage and detach it from power")
	qdel(controls)
	qdel(remote_controls)
	qdel(installed)
	qdel(remote)
	local_area.requires_power = local_required_power
	local_area.always_unpowered = was_always_unpowered
	remote_area.requires_power = remote_required_power
	local_area.power_change()
	if(remote_area != local_area)
		remote_area.power_change()
	if(GLOB.unit_tests_failures == failures_before)
		return TEST_PASS("Paired views, traversal, flatpak placement, and powered operation work")
	return UNIT_TEST_FAILED
