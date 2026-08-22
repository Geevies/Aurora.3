/// One lightweight visual/state object exists for each wet turf.
/obj/effect/liquid
	name = "liquid"
	icon = 'icons/effects/liquid.dmi'
	icon_state = "1"
	anchored = TRUE
	simulated = FALSE
	density = FALSE
	opacity = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = SHALLOW_FLUID_LAYER

	var/volume = 0
	var/temperature = T20C
	var/pending_volume = 0
	var/pending_thermal_energy = 0
	var/flow_amount = 0
	var/flow_direction = NONE
	var/permanent_source = FALSE
	var/turf/start_loc
	var/appearance_band = -1
	/// Silhouette consumed by the clientside fluid blur mask plane.
	var/mutable_appearance/fluid_blur_mask
	/// Lightweight surface marker shown on the open turf above a full column.
	var/turf/surface_hint_turf
	var/mutable_appearance/surface_hint

/obj/effect/liquid/Initialize(mapload)
	. = ..()
	start_loc = get_turf(src)
	if(!start_loc || start_loc.fluid_effect)
		return INITIALIZE_HINT_QDEL
	start_loc.fluid_effect = src
	RegisterSignal(start_loc, COMSIG_ATOM_ENTERED, PROC_REF(on_turf_entered))
	RegisterSignal(start_loc, COMSIG_ATOM_EXITED, PROC_REF(on_turf_exited))
	SSfluids.all_fluids[src] = TRUE
	update_fluid_appearance()
	var/turf/below = GET_TURF_BELOW(start_loc)
	below?.fluid_effect?.update_surface_hint()

/obj/effect/liquid/Destroy()
	clear_surface_hint()
	if(fluid_blur_mask)
		CutOverlays(fluid_blur_mask)
		fluid_blur_mask = null
	SSfluids.active_fluids -= src
	SSfluids.apply_queue -= src
	SSfluids.all_fluids -= src
	if(start_loc)
		UnregisterSignal(start_loc, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
		update_occupant_render_planes(0)
		if(start_loc.fluid_effect == src)
			start_loc.fluid_effect = null
		var/turf/old_turf = start_loc
		start_loc = null
		old_turf.activate_neighboring_fluids()
		var/turf/below = GET_TURF_BELOW(old_turf)
		below?.fluid_effect?.update_surface_hint()
	return ..()

/obj/effect/liquid/Move()
	return FALSE

/obj/effect/liquid/ex_act()
	return

/obj/effect/liquid/proc/on_turf_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(isliving(arrived))
		var/mob/living/living_mob = arrived
		living_mob.update_fluid_render_plane(volume)
	if(!QDELETED(arrived) && !arrived.waterproof && volume >= FLUID_WET_DEPTH)
		arrived.water_act(volume)

/obj/effect/liquid/proc/on_turf_exited(turf/source, atom/movable/departed)
	SIGNAL_HANDLER
	if(isliving(departed))
		var/mob/living/living_mob = departed
		living_mob.update_fluid_render_plane(0)

/obj/effect/liquid/proc/add_volume(amount, new_temperature)
	if(amount <= 0)
		return
	var/old_volume = volume
	if(isnull(new_temperature))
		new_temperature = temperature
	var/new_volume = min(FLUID_MAX_DEPTH, old_volume + amount)
	if(new_volume > 0)
		temperature = ((old_volume * temperature) + ((new_volume - old_volume) * new_temperature)) / new_volume
	volume = new_volume
	update_fluid_appearance()
	if((old_volume < FLUID_MINIMUM_VOLUME) != (volume < FLUID_MINIMUM_VOLUME) || (old_volume < FLUID_MOB_HEAD_DEPTH) != (volume < FLUID_MOB_HEAD_DEPTH))
		update_occupant_render_planes(volume)
	SSfluids.activate(src)
	start_loc.activate_neighboring_fluids()
	if(old_volume < FLUID_WET_DEPTH && volume >= FLUID_WET_DEPTH)
		start_loc.fluid_depth_crossed(old_volume, volume)

/obj/effect/liquid/proc/remove_volume(amount)
	if(amount <= 0 || permanent_source)
		return 0
	var/old_volume = volume
	var/removed = min(amount, volume)
	volume -= removed
	if(volume < FLUID_MINIMUM_VOLUME)
		qdel(src)
	else
		update_fluid_appearance()
		if((old_volume < FLUID_MOB_HEAD_DEPTH) != (volume < FLUID_MOB_HEAD_DEPTH))
			update_occupant_render_planes(volume)
		SSfluids.activate(src)
		start_loc.activate_neighboring_fluids()
	return removed

/obj/effect/liquid/proc/calculate_flow()
	if(!start_loc || loc != start_loc || start_loc.density)
		qdel(src)
		return

	flow_amount = 0
	flow_direction = NONE

	var/available_volume = permanent_source ? FLUID_MAX_DEPTH : max(0, volume - FLUID_MINIMUM_VOLUME)
	if(available_volume <= 0)
		return

	// Open turfs drain downward before attempting lateral equalization.
	if(isopenturf(start_loc))
		var/turf/below = GET_TURF_BELOW(start_loc)
		if(below && start_loc.can_fluid_cross_to(below, DOWN))
			if(below.is_fluid_sink())
				if(!permanent_source)
					SSfluids.queue_drain(src, available_volume, DOWN)
				return
			var/obj/effect/liquid/lower_fluid = below.get_or_create_fluid()
			if(lower_fluid && !lower_fluid.permanent_source)
				var/down_amount = min(available_volume, FLUID_MAX_DEPTH - lower_fluid.volume)
				if(down_amount > FLUID_SETTLE_THRESHOLD)
					var/queued_amount = SSfluids.queue_transfer(src, lower_fluid, down_amount, DOWN)
					available_volume -= queued_amount
					if(available_volume <= FLUID_MINIMUM_VOLUME)
						return

	var/total_difference = 0
	for(var/spread_direction in GLOB.cardinals)
		var/turf/neighbor = get_step(start_loc, spread_direction)
		if(!start_loc.can_fluid_cross_to(neighbor, spread_direction))
			continue
		var/neighbor_volume = neighbor.is_fluid_sink() ? 0 : neighbor.get_fluid_depth()
		var/difference = volume - neighbor_volume
		if(difference > FLUID_SETTLE_THRESHOLD)
			total_difference += difference

	if(total_difference <= FLUID_SETTLE_THRESHOLD)
		return

	// A fixed, stable diffusion coefficient prevents a fresh tile from emptying
	// itself into all four neighbors. That failure mode produces checkerboard or
	// diagonal-looking rings instead of a contiguous puddle.
	var/transfer_scale = min(FLUID_FLOW_FRACTION, available_volume / total_difference)
	var/transferred = FALSE
	for(var/spread_direction in GLOB.cardinals)
		var/turf/neighbor = get_step(start_loc, spread_direction)
		if(!start_loc.can_fluid_cross_to(neighbor, spread_direction))
			continue
		var/neighbor_volume = neighbor.is_fluid_sink() ? 0 : neighbor.get_fluid_depth()
		var/difference = volume - neighbor_volume
		if(difference <= FLUID_SETTLE_THRESHOLD)
			continue
		var/transfer_amount = difference * transfer_scale
		if(transfer_amount <= FLUID_MINIMUM_VOLUME)
			continue
		if(neighbor.is_fluid_sink())
			if(!permanent_source)
				transferred = SSfluids.queue_drain(src, transfer_amount, spread_direction) || transferred
		else
			// Do not fan tiny, invisible films out into thousands of objects. Existing
			// wet tiles can still exchange fractional amounts and reach equilibrium.
			if(!neighbor.fluid_effect && transfer_amount < FLUID_WET_DEPTH)
				continue
			var/obj/effect/liquid/neighbor_fluid = neighbor.get_or_create_fluid()
			if(neighbor_fluid && !neighbor_fluid.permanent_source)
				transferred = SSfluids.queue_transfer(src, neighbor_fluid, transfer_amount, spread_direction) || transferred

	if(transferred && permanent_source)
		SSfluids.activate(src)

/obj/effect/liquid/proc/apply_pending_flow()
	if(!start_loc)
		return

	var/old_volume = volume
	if(permanent_source)
		volume = FLUID_MAX_DEPTH
	else
		var/new_volume = max(0, min(FLUID_MAX_DEPTH, volume + pending_volume))
		var/new_thermal_energy = (volume * temperature) + pending_thermal_energy
		volume = new_volume
		if(volume > 0)
			temperature = new_thermal_energy / volume

	pending_volume = 0
	pending_thermal_energy = 0

	if(volume < FLUID_MINIMUM_VOLUME && !permanent_source)
		qdel(src)
		return

	update_fluid_appearance()
	if((old_volume < FLUID_MINIMUM_VOLUME) != (volume < FLUID_MINIMUM_VOLUME) || (old_volume < FLUID_MOB_HEAD_DEPTH) != (volume < FLUID_MOB_HEAD_DEPTH))
		update_occupant_render_planes(volume)
	if(abs(volume - old_volume) > FLUID_SETTLE_THRESHOLD)
		SSfluids.activate(src)
		start_loc.activate_neighboring_fluids()

	if((old_volume < FLUID_WET_DEPTH && volume >= FLUID_WET_DEPTH) || (old_volume < FLUID_DEEP_DEPTH && volume >= FLUID_DEEP_DEPTH))
		start_loc.fluid_depth_crossed(old_volume, volume)

	if(flow_amount >= FLUID_PUSH_THRESHOLD && flow_direction)
		for(var/atom/movable/movable_atom as anything in start_loc)
			if(!SSfluids.pushed_atoms[movable_atom] && movable_atom.is_fluid_pushable(flow_amount))
				SSfluids.pushed_atoms[movable_atom] = TRUE
				step(movable_atom, flow_direction)

/obj/effect/liquid/proc/update_fluid_appearance()
	var/new_band
	switch(volume)
		if(0 to FLUID_WET_DEPTH)
			new_band = 1
		if(FLUID_WET_DEPTH to 50)
			new_band = 2
		if(50 to FLUID_SHALLOW_DEPTH)
			new_band = 3
		if(FLUID_SHALLOW_DEPTH to 400)
			new_band = 4
		if(400 to FLUID_DEEP_DEPTH)
			new_band = 5
		if(FLUID_DEEP_DEPTH to 1600)
			new_band = 6
		if(1600 to INFINITY)
			new_band = 7

	update_surface_hint()
	if(new_band == appearance_band)
		return
	appearance_band = new_band
	icon_state = "[new_band]"
	layer = volume >= FLUID_MOB_HEAD_DEPTH ? DEEP_FLUID_LAYER : SHALLOW_FLUID_LAYER
	alpha = clamp(45 + round((min(volume, FLUID_DEEP_DEPTH) / FLUID_DEEP_DEPTH) * 115), 45, 160)

	if(fluid_blur_mask)
		CutOverlays(fluid_blur_mask)
	// RESET_ALPHA prevents the liquid's own transparency from attenuating the
	// mask a second time before the blurred game-plane copy is composited.
	var/mask_alpha = clamp(96 + round((min(volume, FLUID_DEEP_DEPTH) / FLUID_DEEP_DEPTH) * 64), 96, 160)
	fluid_blur_mask = mutable_appearance('icons/effects/effects.dmi', "white", plane = FLUID_MASK_PLANE, alpha = mask_alpha, appearance_flags = RESET_ALPHA)
	AddOverlays(fluid_blur_mask)
	update_fluid_mimic()

/obj/effect/liquid/proc/update_fluid_mimic()
	if(bound_overlay)
		update_above()
	else
		start_loc?.update_above()

/obj/effect/liquid/proc/update_occupant_render_planes(depth)
	if(!start_loc)
		return
	for(var/mob/living/living_mob as anything in start_loc)
		living_mob.update_fluid_render_plane(depth)

/obj/effect/liquid/proc/clear_surface_hint()
	if(surface_hint_turf && !QDELETED(surface_hint_turf) && surface_hint)
		surface_hint_turf.CutOverlays(surface_hint)
		surface_hint_turf.update_above()
	surface_hint_turf = null
	surface_hint = null

/obj/effect/liquid/proc/update_surface_hint()
	var/turf/above = start_loc ? GET_TURF_ABOVE(start_loc) : null
	var/should_show = volume >= FLUID_MAX_DEPTH && isopenturf(above) && !above.fluid_effect
	if(should_show && surface_hint_turf == above && surface_hint)
		return
	clear_surface_hint()
	if(!should_show)
		return
	surface_hint_turf = above
	surface_hint = mutable_appearance('icons/effects/liquid.dmi', "1", layer = SHALLOW_FLUID_LAYER, plane = GAME_PLANE, alpha = 70, appearance_flags = RESET_ALPHA)
	surface_hint_turf.AddOverlays(surface_hint)
	surface_hint_turf.update_above()

/atom/proc/water_act(depth)
	clean_blood()

/atom/proc/CanFluidPass(coming_from)
	return TRUE

/atom/proc/return_fluid()
	return null

/atom/proc/get_fluid_depth()
	return 0

/atom/proc/check_fluid_depth(minimum)
	return get_fluid_depth() >= minimum

/atom/proc/is_flooded(lying_mob, absolute)
	return FALSE

/atom/proc/submerged(depth)
	if(isnull(depth))
		var/turf/current_turf = get_turf(src)
		if(!current_turf)
			return FALSE
		depth = current_turf.get_fluid_depth()
	if(ismob(loc))
		return depth >= FLUID_SHALLOW_DEPTH
	if(isturf(loc))
		return depth >= FLUID_WET_DEPTH
	return depth >= FLUID_MOB_HEAD_DEPTH

/atom/proc/fluid_update()
	var/turf/current_turf = get_turf(src)
	if(current_turf)
		current_turf.fluid_update()

/atom/movable/var/waterproof = TRUE

/mob/living
	waterproof = FALSE

/mob/living/proc/update_fluid_render_plane(depth)
	// Only lift a mob out of the blurred game-world source while it is visibly
	// above shallow water. Dry and submerged mobs retain normal GAME_PLANE
	// ordering, including their relationships with doors and other tall objects.
	var/new_plane = depth >= FLUID_MINIMUM_VOLUME && depth < FLUID_MOB_HEAD_DEPTH ? ABOVE_GAME_PLANE : GAME_PLANE
	if(plane == new_plane)
		return
	plane = new_plane
	update_above()

/mob/living/carbon/var/fluid_mouth_submerged = FALSE
/mob/living/carbon/var/fluid_breath_hold_until = 0

/mob/living/carbon/proc/aspirate_fluid()
	if(!ishuman(src) || !breathing)
		return
	var/mob/living/carbon/human/human_mob = src
	var/obj/item/organ/internal/lungs/lungs = human_mob.internal_organs_by_name[human_mob.species?.breathing_organ]
	if(!istype(lungs))
		return
	var/current_water = REAGENT_VOLUME(breathing, /singleton/reagent/water/aspirated)
	var/amount = min(FLUID_ASPIRATION_PER_BREATH, FLUID_ASPIRATION_MAX - current_water)
	if(amount > 0)
		breathing.add_reagent(/singleton/reagent/water/aspirated, amount)

/mob/living/carbon/proc/eject_aspirated_water(amount = 1)
	if(!breathing || amount <= 0)
		return FALSE
	var/current_water = REAGENT_VOLUME(breathing, /singleton/reagent/water/aspirated)
	if(current_water <= 0)
		return FALSE
	breathing.remove_reagent(/singleton/reagent/water/aspirated, min(amount, current_water))
	visible_message(
		SPAN_WARNING("Water spills from [src]'s mouth as their chest is compressed!"),
		SPAN_WARNING("The compression forces water from your lungs!"),
		SPAN_NOTICE("You hear a wet splutter.")
	)
	return TRUE

/mob/living/carbon/human/proc/can_swim_vertical(direction)
	if(incapacitated() || restrained() || buckled_to)
		return FALSE
	var/turf/current_turf = get_turf(src)
	if(!current_turf)
		return FALSE
	if(direction == UP)
		return current_turf.is_flooded(FALSE) && GET_TURF_ABOVE(current_turf)
	if(direction == DOWN)
		var/turf/below = GET_TURF_BELOW(current_turf)
		return below?.is_flooded(FALSE)
	return FALSE

/atom/movable/proc/get_fluid_fall_damage_multiplier()
	var/turf/landing_turf = get_turf(src)
	if(!landing_turf)
		return 1
	var/fluid_depth = landing_turf.get_fluid_depth()
	var/turf/below = GET_TURF_BELOW(landing_turf)
	if(below)
		fluid_depth = max(fluid_depth, below.get_fluid_depth())
	if(fluid_depth < FLUID_FALL_CUSHION_DEPTH)
		return 1
	return max(FLUID_FALL_MIN_DAMAGE_MULTIPLIER, 1 - (min(fluid_depth, FLUID_MAX_DEPTH) / FLUID_MAX_DEPTH))

/obj/effect/decal/cleanable
	waterproof = FALSE

/atom/movable/is_flooded(lying_mob, absolute)
	var/turf/current_turf = get_turf(src)
	return current_turf?.is_flooded(lying_mob, absolute)

/atom/movable/proc/is_fluid_pushable(amount)
	return simulated && !anchored

/mob/living/is_fluid_pushable(amount)
	if(!..() || buckled_to || (!lying && Check_Shoegrip()))
		return FALSE
	if(amount < mob_size * (lying ? 5 : 10))
		return FALSE
	if(!lying)
		Weaken(1)
	return TRUE

/mob/living/water_act(depth)
	. = ..()
	if(on_fire)
		ExtinguishMob()
	fire_stacks = min(fire_stacks, -20)
	if(ishuman(src))
		var/mob/living/carbon/human/human_mob = src
		human_mob.wash()

/obj/is_fluid_pushable(amount)
	return ..() && w_class <= max(1, round(amount / 20))

/obj/structure/machinery/door/CanFluidPass(coming_from)
	return !density

/obj/structure/machinery/door/window/CanFluidPass(coming_from)
	return !density || ((dir in GLOB.cardinals) && coming_from != dir)

/obj/structure/window/CanFluidPass(coming_from)
	return !is_full_window() && coming_from != dir

/turf/var/obj/effect/liquid/fluid_effect
/turf/var/fluid_topology_valid = FALSE
/turf/var/fluid_blocked_dirs = NONE

/turf/return_fluid()
	return fluid_effect

/turf/get_fluid_depth()
	return fluid_effect?.volume || 0

/turf/is_flooded(lying_mob, absolute)
	var/depth = get_fluid_depth()
	if(absolute)
		return fluid_effect?.permanent_source
	return depth >= (lying_mob ? FLUID_MOB_HEAD_DEPTH : FLUID_DEEP_DEPTH)

/turf/submerged(depth)
	if(isnull(depth))
		depth = get_fluid_depth()
	return depth >= FLUID_MOB_HEAD_DEPTH

/turf/return_air_for_internal_lifeform(mob/living/carbon/lifeform)
	if(lifeform && is_flooded(lifeform.lying))
		var/datum/gas_mixture/water_breath = new
		water_breath.temperature = temperature
		if(lifeform.can_breathe_water() || istype(lifeform.wear_mask, /obj/item/clothing/mask/snorkel))
			lifeform.fluid_mouth_submerged = FALSE
			lifeform.fluid_breath_hold_until = 0
			water_breath.adjust_gas(GAS_OXYGEN, 300)
		else
			if(!lifeform.fluid_mouth_submerged)
				lifeform.fluid_mouth_submerged = TRUE
				lifeform.fluid_breath_hold_until = world.time + FLUID_BREATH_HOLD_DURATION
				to_chat(lifeform, SPAN_HIGHDANGER("Your mouth goes below the water! You hold your breath!"))
			if(world.time >= lifeform.fluid_breath_hold_until)
				if(lifeform.fluid_breath_hold_until)
					to_chat(lifeform, SPAN_HIGHDANGER("You can no longer hold your breath! Water rushes into your lungs!"))
					lifeform.fluid_breath_hold_until = 0
				lifeform.aspirate_fluid()
			var/exhaled_gas = GAS_CO2
			if(ishuman(lifeform))
				var/mob/living/carbon/human/human_lifeform = lifeform
				if(human_lifeform.species?.exhale_type)
					exhaled_gas = human_lifeform.species.exhale_type
			water_breath.adjust_gas(exhaled_gas, ONE_ATMOSPHERE)
		return water_breath
	if(lifeform)
		lifeform.fluid_mouth_submerged = FALSE
		lifeform.fluid_breath_hold_until = 0
	return return_air()

/turf/proc/get_or_create_fluid()
	if(fluid_effect && !QDELETED(fluid_effect))
		return fluid_effect
	if(density || is_fluid_sink())
		return null
	return new /obj/effect/liquid(src)

/turf/proc/add_fluid(amount, temperature)
	if(amount <= 0 || is_fluid_sink())
		return
	var/obj/effect/liquid/fluid = get_or_create_fluid()
	fluid?.add_volume(amount, temperature)

/turf/proc/remove_fluid(amount = INFINITY)
	return fluid_effect?.remove_volume(amount) || 0

/turf/proc/make_flooded(temperature = T20C)
	if(is_fluid_sink())
		return
	var/obj/effect/liquid/fluid = get_or_create_fluid()
	if(!fluid)
		return
	fluid.permanent_source = TRUE
	fluid.temperature = temperature
	fluid.volume = FLUID_MAX_DEPTH
	fluid.update_fluid_appearance()
	fluid.update_occupant_render_planes(fluid.volume)
	SSfluids.activate(fluid)
	activate_neighboring_fluids()

/turf/proc/is_fluid_sink()
	return FALSE

/turf/space/is_fluid_sink()
	return TRUE

/turf/proc/rebuild_fluid_topology()
	fluid_blocked_dirs = density ? ALL_CARDINALS : NONE
	if(!density)
		for(var/atom/movable/blocker as anything in src)
			if(!blocker.simulated)
				continue
			for(var/check_direction in GLOB.cardinals)
				if(!blocker.CanFluidPass(check_direction))
					fluid_blocked_dirs |= check_direction
	fluid_topology_valid = TRUE

/turf/proc/can_fluid_cross_to(turf/target, direction)
	if(!target)
		return FALSE
	if(!fluid_topology_valid)
		rebuild_fluid_topology()
	if(!target.fluid_topology_valid)
		target.rebuild_fluid_topology()
	return !(fluid_blocked_dirs & direction) && !(target.fluid_blocked_dirs & REVERSE_DIR(direction))

/turf/fluid_update(ignore_neighbors = FALSE)
	fluid_topology_valid = FALSE
	if(fluid_effect)
		fluid_effect.update_surface_hint()
		SSfluids.activate(fluid_effect)
	var/turf/below = GET_TURF_BELOW(src)
	below?.fluid_effect?.update_surface_hint()
	if(!ignore_neighbors)
		activate_neighboring_fluids()

/turf/proc/activate_neighboring_fluids()
	for(var/check_direction in GLOB.cardinals)
		var/turf/neighbor = get_step(src, check_direction)
		if(neighbor?.fluid_effect)
			SSfluids.activate(neighbor.fluid_effect)
	var/turf/above = GET_TURF_ABOVE(src)
	if(above?.fluid_effect)
		SSfluids.activate(above.fluid_effect)
	var/turf/below = GET_TURF_BELOW(src)
	if(below?.fluid_effect)
		SSfluids.activate(below.fluid_effect)

/turf/proc/fluid_depth_crossed(old_depth, new_depth)
	if(new_depth < FLUID_WET_DEPTH)
		return
	for(var/atom/movable/wet_atom as anything in src)
		if(wet_atom != fluid_effect && !wet_atom.waterproof)
			wet_atom.water_act(new_depth)

/proc/trigger_splash(turf/epicenter, volume, temperature = T20C)
	if(epicenter && volume > FLUID_MINIMUM_VOLUME)
		epicenter.add_fluid(volume, temperature)

/// Mapping helper for finite spills and infinitely replenishing bodies of water.
/obj/effect/fluid_source
	name = "fluid source"
	icon = 'icons/effects/liquid.dmi'
	icon_state = "7"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	var/volume = FLUID_MAX_DEPTH
	var/temperature = T20C
	var/permanent = TRUE

/obj/effect/fluid_source/Initialize(mapload)
	. = ..()
	var/turf/source_turf = get_turf(src)
	if(source_turf)
		if(permanent)
			source_turf.make_flooded(temperature)
		else
			source_turf.add_fluid(volume, temperature)
	return INITIALIZE_HINT_QDEL

/// Compatibility path used by maps from the original Europa fluids port.
/obj/effect/fluid_mapped
	parent_type = /obj/effect/fluid_source
	name = "mapped fluid"
	permanent = FALSE

/client/proc/splash()
	var/volume = input(src, "Volume?", "Volume?", 0) as num|null
	if(!isnum(volume) || volume <= FLUID_MINIMUM_VOLUME)
		return
	trigger_splash(get_turf(mob), volume)

/datum/admins/proc/spawn_fluid()
	set name = "Spawn Fluid"
	set category = "Admin.Game"
	if(!check_rights(R_SPAWN))
		return
	var/volume = tgui_input_number(usr, "How much fluid should be added?", "Spawn Fluid", FLUID_SHALLOW_DEPTH, FLUID_MAX_DEPTH, 1, round_value = FALSE)
	if(!isnum(volume) || volume <= 0)
		return
	var/turf/target = get_turf(usr)
	if(target)
		target.add_fluid(volume)

/datum/admins/proc/fluid_diagnostics()
	set name = "Fluid Diagnostics"
	set category = "Debug"
	if(!check_rights(R_DEBUG))
		return
	to_chat(usr, SPAN_NOTICE("Fluid simulation: [length(SSfluids.active_fluids)] active tiles; [length(SSfluids.all_fluids)] wet tiles."))

/datum/admins/proc/jump_to_fluid_source()
	set name = "Jump to Fluid Source"
	set category = "Admin.Jump"
	if(!check_rights(R_DEBUG) || isnewplayer(usr) || !GLOB.config.allow_admin_jump)
		return
	var/list/sources = list()
	for(var/obj/effect/liquid/fluid as anything in SSfluids.all_fluids)
		if(!QDELETED(fluid) && fluid.permanent_source)
			sources += fluid
	if(!length(sources))
		to_chat(usr, SPAN_WARNING("There are no permanent fluid sources."))
		return
	usr.on_mob_jump()
	usr.forceMove(get_turf(pick(sources)))

/datum/admins/proc/jump_to_active_fluid()
	set name = "Jump to Active Fluid"
	set category = "Admin.Jump"
	if(!check_rights(R_DEBUG) || isnewplayer(usr) || !GLOB.config.allow_admin_jump)
		return
	if(!length(SSfluids.active_fluids))
		to_chat(usr, SPAN_WARNING("There are no active fluid tiles."))
		return
	var/obj/effect/liquid/fluid = pick(SSfluids.active_fluids)
	if(!QDELETED(fluid))
		usr.on_mob_jump()
		usr.forceMove(get_turf(fluid))
