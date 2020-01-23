/obj/effect/rune/summon_narsie/do_rune_action(mob/living/user)
	if(!cult.allow_narsie)
		return fizzle(user)

	var/turf/T = get_turf(src)
	if(isNotStationLevel(T.z))
		to_chat(user, span("warning", "You are too far from the station, Nar'sie can not be summoned here."))
		return fizzle(user)

	var/list/cultists = list()
	for(var/mob/M in range(1,src))
		if(istype(M, /mob/living/carbon/human/apparition))
			continue
		if(iscultist(M) && !M.stat)
			M.say("Tok-lyr rqa'nap g[pick("'","`")]lt-ulotf!")
			cultists += M
	if(cultists.len >= 9)
		log_and_message_admins_many(cultists, "summoned Nar-sie.")
		new /obj/singularity/narsie/large(src.loc)

		// Can't summon a singular entity twice.
		cult.allow_narsie = FALSE
		return
	else
		return fizzle(user)