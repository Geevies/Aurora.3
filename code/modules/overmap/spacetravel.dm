//list used to cache empty zlevels to avoid nedless map bloat
var/man_overboard_counter = 1 // used for naming the man overboard sites in case multiple appear in close proximity
var/list/cached_space = list()

//Space stragglers go here

/obj/effect/overmap/visitable/sector/temporary
	name = "Man Overboard"
	known = FALSE
	layer = OVERMAP_IMPORTANT_SECTOR_LAYER

/obj/effect/overmap/visitable/sector/temporary/New(var/nx, var/ny, var/nz)
	name = man_overboard_counter > 1 ? "[name] ([man_overboard_counter])" : name
	loc = locate(nx, ny, current_map.overmap_z)
	x = nx
	y = ny
	map_z += nz
	map_sectors["[nz]"] = src
	testing("Temporary sector at [x],[y] was created, corresponding zlevel is [nz].")
	new /obj/effect/shuttle_landmark/automatic(locate(127, 127, nz))
	man_overboard_counter++
	START_PROCESSING(SSslow_process, src)

/obj/effect/overmap/visitable/sector/temporary/Destroy()
	STOP_PROCESSING(SSslow_process, src)
	map_sectors["[map_z]"] = null
	testing("Temporary sector at [x],[y] was deleted.")
	return ..()

/obj/effect/overmap/visitable/sector/temporary/process()
	if(can_die())
		shift_to_cache()

/obj/effect/overmap/visitable/sector/temporary/proc/can_die(var/mob/observer)
	testing("Checking if sector at [map_z[1]] can die.")
	for(var/mob/M in player_list)
		if(M != observer && (M.z in map_z))
			testing("There are people on it.")
			return 0
	return 1

/// uncache the sector and move it to the specified overmap area
/obj/effect/overmap/visitable/sector/temporary/proc/uncache(var/x, var/y)
	cached_space -= "[x]-[y]"
	forceMove(locate(x, y, current_map.overmap_z))
	START_PROCESSING(SSslow_process, src)

/obj/effect/overmap/visitable/sector/temporary/proc/shift_to_cache()
	testing("Caching [src] for future use")
	forceMove(locate(x, y, pick(map_z))) // move ourselves into our z-level, where we're kept alive but cannot be reached by overmap objects
	cached_space["[x]-[y]"] = src
	STOP_PROCESSING(SSslow_process, src)

proc/get_deepspace(x,y)
	var/obj/effect/overmap/visitable/sector/temporary/res = locate() in locate(x, y, current_map.overmap_z)
	if(istype(res))
		return res
	else if(length(cached_space) && cached_space["[x]-[y]"])
		res = cached_space["[x]-[y]"]
		res.uncache(x, y)
		return res
	else
		return new /obj/effect/overmap/visitable/sector/temporary(x, y, current_map.get_empty_zlevel(x, y))

/atom/movable/proc/lost_in_space()
	for(var/atom/movable/AM in contents)
		if(!AM.lost_in_space())
			return FALSE
	return TRUE

/mob/lost_in_space()
	return isnull(client)

/mob/living/carbon/human/lost_in_space()
	return isnull(client) && stat == DEAD

proc/overmap_spacetravel(var/turf/space/T, var/atom/movable/A)
	if (!T || !A)
		return

	var/obj/effect/overmap/visitable/M = map_sectors["[T.z]"]
	if (!M)
		return

	if(A.lost_in_space())
		if(!QDELETED(A))
			qdel(A)
		return

	var/nx = 1
	var/ny = 1
	var/nz = 1

	if(T.x <= TRANSITIONEDGE)
		nx = world.maxx - TRANSITIONEDGE - 2
		ny = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

	else if (A.x >= (world.maxx - TRANSITIONEDGE - 1))
		nx = TRANSITIONEDGE + 2
		ny = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

	else if (T.y <= TRANSITIONEDGE)
		ny = world.maxy - TRANSITIONEDGE -2
		nx = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

	else if (A.y >= (world.maxy - TRANSITIONEDGE - 1))
		ny = TRANSITIONEDGE + 2
		nx = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

	testing("[A] spacemoving from [M] ([M.x], [M.y]).")

	var/turf/map = locate(M.x,M.y,current_map.overmap_z)
	var/obj/effect/overmap/visitable/TM
	for(var/obj/effect/overmap/visitable/O in map)
		if(O != M && O.in_space && prob(50))
			TM = O
			break
	if(!TM)
		TM = get_deepspace(M.x,M.y)
	nz = pick(TM.map_z)

	var/turf/dest = locate(nx,ny,nz)
	if(dest)
		A.forceMove(dest)
		if(ismob(A))
			var/mob/D = A
			if(D.pulling)
				D.pulling.forceMove(dest)

	if(istype(M, /obj/effect/overmap/visitable/sector/temporary))
		var/obj/effect/overmap/visitable/sector/temporary/source = M
		if (source.can_die())
			source.shift_to_cache()

