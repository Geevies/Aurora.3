/mob/living/simple_animal/hostile/retaliate/aquatic
	icon = 'icons/mob/aquatic.dmi'
	meat_type = /obj/item/reagent_containers/food/snacks/carpmeat
	turns_per_move = 5
	attacktext = "bitten"
	attack_sound = 'sound/weapons/bite.ogg'
	speed = 4
	mob_size = MOB_MEDIUM
	emote_see = list("gnashes")

	// They only really care if there's water around them or not.
	min_oxy = 0
	max_tox = 0
	max_co2 = 0
	minbodytemp = 0

/mob/living/simple_animal/hostile/retaliate/aquatic/Life()
	if(!loc || !loc.is_flooded(1))
		if(icon_state == icon_living)
			icon_state = "[icon_living]_dying"
		SetStunned(3)
		stat = UNCONSCIOUS
	. = ..()