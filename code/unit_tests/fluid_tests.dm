/datum/unit_test/fluid_transfer_conservation
	name = "FLUIDS: Transfers conserve volume and reserve destination capacity"
	groups = list("generic")

/datum/unit_test/fluid_transfer_conservation/start_test()
	var/turf/source_turf = locate(71, 155, 1)
	var/turf/target_turf = get_step(source_turf, NORTH)
	if(!source_turf || !target_turf || source_turf.fluid_effect || target_turf.fluid_effect)
		TEST_FAIL("Could not acquire two dry test turfs.")
		return 1

	var/obj/effect/liquid/source = new(source_turf)
	var/obj/effect/liquid/target = new(target_turf)
	source.volume = 1000
	target.volume = FLUID_MAX_DEPTH - 100
	var/initial_total = source.volume + target.volume

	var/queued = SSfluids.queue_transfer(source, target, 500, NORTH)
	source.apply_pending_flow()
	target.apply_pending_flow()
	var/final_total = source.volume + target.volume

	if(queued != 100)
		TEST_FAIL("Transfer queued [queued] units instead of reserving the destination's 100-unit capacity.")
	else if(final_total != initial_total)
		TEST_FAIL("Transfer changed total volume from [initial_total] to [final_total].")
	else if(target.volume != FLUID_MAX_DEPTH)
		TEST_FAIL("Destination ended at [target.volume] instead of [FLUID_MAX_DEPTH].")
	else
		TEST_PASS("Capacity was reserved and volume was conserved.")

	qdel(source)
	qdel(target)
	return 1
