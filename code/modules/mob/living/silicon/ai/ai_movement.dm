/mob/living/silicon/ai/SelfMove(turf/n, direct)
	return 0

/mob/living/silicon/ai/fall_impact(levels_fallen, stopped_early = FALSE, var/damage_mod = 1)
	if(!anchored)
		return ..()

/mob/living/silicon/ai/facedir(var/ndir)
	. = ..()
	if(holo && holo.active_holograms[src])
		holo.active_holograms[src].dir = ndir
