/obj/effect/rune/summon_soulstone
	can_talisman = TRUE

/obj/effect/rune/summon_soulstone/do_rune_action(mob/living/user, obj/O = src)
	if(istype(O, /obj/effect/rune))
		user.say("N[pick("'","`")]ath reth sh'yro eth d'raggathnor!")
	else
		user.whisper("N[pick("'","`")]ath reth sh'yro eth d'raggathnor!")
	new /obj/item/device/soulstone(get_turf(O))
	qdel(O)
	return TRUE