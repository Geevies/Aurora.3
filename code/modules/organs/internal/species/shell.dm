/obj/item/organ/internal/heart/shell/handle_blood()
	if(!owner)
		return

	if(owner.stat == DEAD || owner.bodytemperature < 170 || owner.InStasis())	//Dead or cryosleep people do not pump the blood.
		return

	var/blood_volume = round(REAGENT_VOLUME(owner.vessel, /decl/reagent/blood))

	//Blood regeneration if there is some space
	if(blood_volume < species.blood_volume && blood_volume)
		if(REAGENT_DATA(owner.vessel, /decl/reagent/blood)) // Make sure there's blood at all
			owner.vessel.add_reagent(/decl/reagent/blood, BLOOD_REGEN_RATE + LAZYACCESS(owner.chem_effects, CE_BLOODRESTORE), temperature = species?.body_temperature)
			if(blood_volume <= BLOOD_VOLUME_SAFE) //We lose nutrition and hydration very slowly if our blood is too low
				owner.adjustNutritionLoss(2)
				owner.adjustHydrationLoss(1)

		var/blood_oxygenation = owner.get_blood_oxygenation()
		switch(blood_oxygenation)
			if(BLOOD_VOLUME_OKAY to BLOOD_VOLUME_SAFE)
				if(prob(1))
					to_chat(owner, SPAN_WARNING("You feel a bit [pick("lightheaded","dizzy","pale")]..."))
				owner.bodytemperature += owner.species.passive_temp_gain / 2
			if(BLOOD_VOLUME_BAD to BLOOD_VOLUME_OKAY)
				owner.eye_blurry = max(owner.eye_blurry,6)
				if(!owner.paralysis && prob(10))
					owner.Paralyse(rand(1,3))
					to_chat(owner, SPAN_WARNING("You feel [pick("weak","disoriented","faint","warm")]."))
				owner.bodytemperature += owner.species.passive_temp_gain
			if(BLOOD_VOLUME_SURVIVE to BLOOD_VOLUME_BAD)
				owner.eye_blurry = max(owner.eye_blurry,6)
				if(!owner.paralysis && prob(15))
					owner.Paralyse(rand(3, 5))
					to_chat(owner, SPAN_WARNING("You feel <b>extremely</b> [pick("warm","woozy","faint","weak","confused","tired","lethargic")]."))
				owner.bodytemperature += owner.species.passive_temp_gain * 2
			if(-(INFINITY) to BLOOD_VOLUME_SURVIVE) // Also see heart.dm, being below this point puts you into cardiac arrest.
				owner.eye_blurry = max(owner.eye_blurry,6)
				owner.bodytemperature += owner.species.passive_temp_gain * 3

	//Bleeding out
	var/blood_max = 0
	var/open_wound
	var/list/do_spray = list()
	for(var/obj/item/organ/external/temp as anything in owner.bad_external_organs)
		if(HAS_FLAG(temp.status, ORGAN_BLEEDING) && !BP_IS_ROBOTIC(temp))
			for(var/datum/wound/W in temp.wounds)
				if(W.bleeding())
					open_wound = TRUE
					if(temp.applied_pressure)
						if(ishuman(temp.applied_pressure))
							var/mob/living/carbon/human/H = temp.applied_pressure
							H.bloody_hands(src, 0)
						var/min_eff_damage = max(0, W.damage - 10) / 6
						blood_max += max(min_eff_damage, W.damage - 30) / 40
					else
						blood_max += ((W.damage / 40) * species.bleed_mod)

		if(temp.status & ORGAN_ARTERY_CUT)
			var/bleed_amount = Floor((owner.vessel.total_volume / (temp.applied_pressure || !open_wound ? 450 : 250)) * temp.arterial_bleed_severity)
			if(bleed_amount)
				if(CE_BLOODCLOT in owner.chem_effects)
					bleed_amount *= 0.8 // won't do much, but it'll help
				if(open_wound)
					blood_max += bleed_amount
					do_spray += "[temp.name]"
				else
					owner.vessel.remove_reagent(/decl/reagent/blood, bleed_amount)

	if(CE_BLOODCLOT in owner.chem_effects)
		blood_max *= 0.7

	if(world.time >= next_blood_squirt && istype(owner.loc, /turf) && do_spray.len)
		owner.visible_message("<span class='danger'>Blood squirts from \the [owner]'s [pick(do_spray)]!</span>", \
							"<span class='danger'><font size=3>Blood sprays out of your [pick(do_spray)]!</font></span>")
		owner.eye_blurry = 2
		owner.Stun(1)
		next_blood_squirt = world.time + 100
		var/turf/sprayloc = get_turf(owner)
		blood_max -= owner.drip(Ceiling(blood_max/3), sprayloc)
		if(blood_max > 0)
			blood_max -= owner.blood_squirt(blood_max, sprayloc)
			if(blood_max > 0)
				owner.drip(blood_max, get_turf(owner))
	else
		owner.drip(blood_max)
