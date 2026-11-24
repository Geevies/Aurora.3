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
		var/turf/front = get_step(site, SOUTH)
		var/turf/beyond = get_step(front, SOUTH)
		if(!istype(front, /turf/simulated/floor) || !istype(beyond, /turf/simulated/floor))
			continue
		if(site.contains_dense_objects() || front.contains_dense_objects() || beyond.contains_dense_objects())
			continue
		if(length(sites) && get_dist(sites[1], site) < 5)
			continue
		sites += site
		if(length(sites) == 2)
			break
	TEST_ASSERT(length(sites) == 2, "Two clear gate sites are required")

	var/obj/structure/stargate/first = new(sites[1], REF(src))
	var/obj/structure/stargate/second = new(sites[2], REF(src))
	var/turf/first_exit = get_step(first, SOUTH)
	var/turf/second_exit = get_step(second, SOUTH)
	var/failures_before = GLOB.unit_tests_failures
	if(!(second_exit in first.aperture?.vis_contents) || !(first_exit in second.aperture?.vis_contents))
		TEST_FAIL("Both apertures must show their partner's exit turf")

	var/mob/living/traveler = new(first_exit)
	step(traveler, NORTH)
	if(traveler.loc != second_exit)
		TEST_FAIL("Walking into the first ring must reach the second exit")
	traveler.throw_at(second, 1, 1)
	if(traveler.loc != first_exit)
		TEST_FAIL("A mob thrown into the second ring must return through the first")
	qdel(traveler)

	var/obj/item/cargo = new(first_exit)
	cargo.throw_at(get_step(first, NORTH), 2, 4)
	if(cargo.throwing)
		cargo.throwing.start_time -= 2
		cargo.throwing.tick()
	if(cargo.loc != get_step(second_exit, SOUTH))
		TEST_FAIL("A thrown item must continue out of the receiving ring")
	qdel(cargo)

	var/obj/projectile/shot = new(first_exit)
	shot.fire(dir2angle(NORTH))
	for(var/i in 1 to 8)
		if(QDELETED(shot) || shot.loc == get_step(second_exit, SOUTH))
			break
		shot.pixel_move(1)
	if(QDELETED(shot) || shot.loc != get_step(second_exit, SOUTH))
		TEST_FAIL("A projectile must continue out of the receiving ring")
	qdel(shot)

	qdel(first)
	if(second.partner || second.aperture || second.icon_state != "idle")
		TEST_FAIL("Deleting one ring must close the surviving aperture")
	qdel(second)
	if(GLOB.unit_tests_failures == failures_before)
		return TEST_PASS("Paired views, walking, throws and disconnection work")
	return UNIT_TEST_FAILED
