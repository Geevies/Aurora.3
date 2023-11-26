/atom
	///Whether /atom/Initialize() has already run for the object
	var/initialized = FALSE
	var/update_icon_on_init	// Default to 'no'.

/atom/New(loc, ...)
	// For the DMM Suite.
	if(use_preloader && (type == _preloader.target_path))//in case the instanciated atom is creating other atoms in New()
		_preloader.load(src)

	//. = ..() //uncomment if you are dumb enough to add a /datum/New() proc

	var/do_initialize = SSatoms.initialized
	if(do_initialize > INITIALIZATION_INSSATOMS)
		args[1] = do_initialize == INITIALIZATION_INNEW_MAPLOAD
		if(SSatoms.InitAtom(src, args))
			//we were deleted
			return

	var/list/created = SSatoms.created_atoms
	if(created)
		created += src

/atom/proc/Initialize(mapload, ...)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_NOT_SLEEP(TRUE)

	if(initialized)
		crash_with("Warning: [src]([type]) initialized multiple times!")
	initialized = TRUE

	if(LAZYLEN(reagents_to_add))
		if(!reagents)
			create_reagents(0)
		for(var/v in reagents_to_add)
			reagents.maximum_volume += max(LAZYACCESS(reagents_to_add, v) - REAGENTS_FREE_SPACE(reagents), 0)
			reagents.add_reagent(v, LAZYACCESS(reagents_to_add, v), LAZYACCESS(reagent_data, v))

	if (light_power && light_range)
		update_light()

	if (opacity && isturf(loc))
		var/turf/T = loc
		T.has_opaque_atom = TRUE // No need to recalculate it in this case, it's guaranteed to be on afterwards anyways.

	#ifdef AO_USE_LIGHTING_OPACITY
		if (!mapload)
			T.regenerate_ao()
	#endif

	if (update_icon_on_init)
		SSicon_update.add_to_queue(src)

	return INITIALIZE_HINT_NORMAL

/**
 * Late Intialization, for code that should run after all atoms have run Intialization
 *
 * To have your LateIntialize proc be called, your atoms [Initalization][/atom/proc/Initialize]
 *  proc must return the hint
 * [INITIALIZE_HINT_LATELOAD] otherwise it will never be called.
 *
 * useful for doing things like finding other machines because you can guarantee
 * that all atoms will actually exist in the "WORLD" at this time and that all their Intialization
 * code has been run
 */
/atom/proc/LateInitialize()
	set waitfor = FALSE

	//You can override this in your inheritance if you *really* need to, but probably shouldn't
	SHOULD_NOT_SLEEP(TRUE)

	var/static/list/warned_types = list()
	if(!warned_types[type])
		WARNING("Old style LateInitialize behaviour detected in [type]!")
		warned_types[type] = TRUE
	Initialize(FALSE)

/atom/Destroy(force = FALSE)
	if (reagents)
		QDEL_NULL(reagents)

	//We're being destroyed, no need to update the icon
	SSicon_update.remove_from_queue(src)

	LAZYCLEARLIST(our_overlays)
	LAZYCLEARLIST(priority_overlays)

	QDEL_NULL(light)

	if (orbiters)
		for (var/thing in orbiters)
			var/datum/orbit/O = thing
			if (O.orbiter)
				O.orbiter.stop_orbit()

	if(length(overlays))
		overlays.Cut()

	if(light)
		QDEL_NULL(light)

	if (length(light_sources))
		light_sources.Cut()

	if(smoothing_flags & SMOOTH_QUEUED)
		SSicon_smooth.remove_from_queues(src)

	return ..()
