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
		var/turf/corner = get_offset_target_turf(site, -1, -1)
		var/turf/opposite_corner = get_offset_target_turf(site, 1, length(sites) ? 2 : 1)
		var/list/footprint = block(corner, opposite_corner)
		var/clear = length(footprint) == (length(sites) ? 12 : 9)
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
	for(var/offset in -1 to 1)
		var/turf/entry = get_offset_target_turf(first, offset, 0)
		var/turf/other_entry = get_offset_target_turf(second, offset, 0)
		var/turf/north_exit = get_step(other_entry, NORTH)
		var/obj/effect/map_effect/portal/stargate/aperture = locate() in entry
		if(!(north_exit in aperture?.vis_contents))
			TEST_FAIL("Aligned lane [offset] must show the north exit turf using the map portal effect")
		if(aperture?.opacity)
			TEST_FAIL("A freestanding gate must not block sight of the local room")
		var/mob/living/traveler = new(get_step(entry, SOUTH))
		step(traveler, NORTH)
		if(traveler.loc != north_exit)
			TEST_FAIL("Entering aligned lane [offset] from the south must exit north")
		step(traveler, SOUTH)
		if(traveler.loc != get_step(entry, SOUTH))
			TEST_FAIL("Entering aligned lane [offset] from the north must exit south")
		qdel(traveler)
	var/turf/beyond_exit = get_offset_target_turf(second, 0, 2)
	var/found_room_view = FALSE
	for(var/obj/effect/map_effect/portal/stargate/aperture in first.apertures)
		if(beyond_exit in aperture.vis_contents)
			found_room_view = TRUE
			break
	if(!found_room_view)
		TEST_FAIL("The map portal effect must show the destination room beyond the exit row")

	first.set_address("Unpaired [REF(src)]")
	first.set_dir(EAST)
	first.set_address(second.gate_id)
	if(length(first.apertures) != 3 || length(second.apertures) != 3)
		TEST_FAIL("Each ring must open exactly three segments")
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
	if(second.partner || length(second.apertures) || second.icon_state != "idle")
		TEST_FAIL("Deleting one ring must close the surviving aperture")
	for(var/obj/effect/map_effect/portal/stargate/segment as anything in segments)
		if(!QDELETED(segment))
			TEST_FAIL("Deleting a ring must remove every segment at both ends")
	qdel(second)
	if(GLOB.unit_tests_failures == failures_before)
		return TEST_PASS("Paired views, walking, throws and disconnection work")
	return UNIT_TEST_FAILED
