/datum/species/human/offworlder
	name = SPECIES_HUMAN_OFFWORLD
	name_plural = "Off-Worlder Humans"
	blurb = "The Offworlders are humans that have adapted to zero-G conditions through a lifetime of conditioning, exposure, and physical modification. \
	They thrive in thinner atmosphere and weightlessness, more often than not utilizing advanced life support and body-bracing equipment to sustain themselves in normal Human environments."
	hide_name = FALSE

	icobase = 'icons/mob/human_races/human/r_offworlder.dmi'
	deform = 'icons/mob/human_races/human/r_offworlder.dmi'
	preview_icon = 'icons/mob/human_races/human/offworlder_preview.dmi'

	flash_mod = 1.2
	oxy_mod = 0.8
	brute_mod = 1.2
	toxins_mod = 1.2
	bleed_mod = 0.5
	grab_mod = 1.1
	resist_mod = 0.75

	warning_low_pressure = 30
	hazard_low_pressure = 10

	examine_color = "#C2AE95"

/datum/species/human/offworlder/equip_later_gear(var/mob/living/carbon/human/H)
	if(istype(H.get_equipped_item(slot_back), /obj/item/storage/backpack) && H.equip_to_slot_or_del(new /obj/item/storage/pill_bottle/rmt(H.back), slot_in_backpack))
		return
	var/obj/item/storage/pill_bottle/rmt/PB = new /obj/item/storage/pill_bottle/rmt(get_turf(H))
	H.put_in_hands(PB)

/datum/species/human/offworlder/get_species_tally(var/mob/living/carbon/human/H)

	if(istype(H.back, /obj/item/rig/light/offworlder))
		var/obj/item/rig/light/offworlder/rig = H.back
		if(!rig.offline)
			return 0
		else
			return 3

	var/obj/item/organ/external/l_leg = H.get_organ(BP_L_LEG)
	var/obj/item/organ/external/r_leg = H.get_organ(BP_R_LEG)

	if((l_leg.status & ORGAN_ROBOT) && (r_leg.status & ORGAN_ROBOT))
		return

	if(H.w_uniform)
		var/obj/item/clothing/under/suit = H.w_uniform
		if(locate(/obj/item/clothing/accessory/offworlder/bracer) in suit.accessories)
			return 0

	var/obj/item/organ/internal/stomach/S = H.internal_organs_by_name[BP_STOMACH]
	if(S)
		for(var/_R in S.ingested.reagent_volumes)
			if(_R == /decl/reagent/rmt)
				return 0

	return 4

/datum/species/human/offworlder/handle_environment_special(var/mob/living/carbon/human/H)
	if(prob(5))
		if(!H.can_feel_pain())
			return

		var/area/A = get_area(H)
		if(A && !A.has_gravity())
			return

		var/obj/item/organ/external/l_leg = H.get_organ(BP_L_LEG)
		var/obj/item/organ/external/r_leg = H.get_organ(BP_R_LEG)

		if((l_leg.status & ORGAN_ROBOT) && (r_leg.status & ORGAN_ROBOT))
			return

		if(istype(H.back, /obj/item/rig/light/offworlder))
			var/obj/item/rig/light/offworlder/rig = H.back
			if(!rig.offline)
				return

		if(H.w_uniform)
			var/obj/item/clothing/under/uniform = H.w_uniform
			if(locate(/obj/item/clothing/accessory/offworlder/bracer) in uniform.accessories)
				return

		var/obj/item/organ/internal/stomach/S = H.internal_organs_by_name[BP_STOMACH]
		if(S)
			for(var/_R in S.ingested.reagent_volumes)
				if(_R == /decl/reagent/rmt)
					return

		var/pain_message = pick("You feel sluggish as if something is weighing you down.",
								"Your legs feel harder to move.",
								"You begin to have trouble standing upright.")

		to_chat(H, "<span class='warning'>[pain_message]</span>")

/datum/species/human/shell
	name = SPECIES_IPC_SHELL
	hide_name = TRUE
	short_name = "jak"
	name_plural = "Shells"
	category_name = "Integrated Positronic Chassis"
	bodytype = BODYTYPE_HUMAN

	age_min = 1
	age_max = 60
	economic_modifier = 3

	default_genders = list(MALE, FEMALE)
	selectable_pronouns = list(MALE, FEMALE, PLURAL, NEUTER)

	burn_mod = 1.2
	grab_mod = 1

	blurb = "IPCs with humanlike properties. Their focus is on service, civilian, and medical, but there are no \
	job restrictions. Created in the late days of 2450, the Shell is a controversial IPC model equipped with a synthskin weave applied over its metal chassis \
	to create an uncannily close approximation of the organic form. Early models of Shell had the advantage of being able to compose themselves of a wide \
	 variety of organic parts, but contemporary models have been restricted to a single species for the sake of prosthetic integrity. The additional weight of \
	 the synthskin on the original Hephaestus frame reduces the efficacy of the unit's already strained coolant systems, and increases charge consumption."

	name_language = LANGUAGE_EAL
	num_alternate_languages = 3
	secondary_langs = list(LANGUAGE_EAL, LANGUAGE_SOL_COMMON, LANGUAGE_ELYRAN_STANDARD)
	ethanol_resistance = -1 // Can't get drunk
	radiation_mod = 0	// not affected by radiation

	icobase = 'icons/mob/human_races/human/r_human.dmi'
	deform = 'icons/mob/human_races/ipc/robotic.dmi'
	preview_icon = 'icons/mob/human_races/ipc/shell_preview.dmi'

	unarmed_types = list(
		/datum/unarmed_attack/punch/ipc,
		/datum/unarmed_attack/stomp/ipc,
		/datum/unarmed_attack/kick/ipc,
		/datum/unarmed_attack/bite
	)

	meat_type = /obj/item/reagent_containers/food/snacks/meat/syntiflesh

	eyes = "eyes_s"
	show_ssd = "completely quiescent"

	heat_level_1 = 500
	heat_level_2 = 1000
	heat_level_3 = 2000

	cold_level_1 = 50
	cold_level_2 = -1
	cold_level_3 = -1

	body_temperature = null
	passive_temp_gain = 10

	heat_discomfort_level = 400
	heat_discomfort_strings = list(
		"Your CPU temperature probes warn you that you are approaching critical heat levels!",
		"Your synthetic flesh crawls in the heat, swelling into a disgusting morass of plastic."
	)

	halloss_message_self = "ERROR: Unrecoverable machine check exception.<BR>System halted, rebooting..."

	flags = NO_PAIN
	spawn_flags = CAN_JOIN | IS_WHITELISTED | NO_AGE_MINIMUM

	blood_type_overrides = list("X")
	blood_type = "synth blood"
	blood_color = COLOR_SYNTH_BLOOD
	reagent_tag = IS_MACHINE

	has_organ = list(
		BP_BRAIN =    /obj/item/organ/internal/mmi_holder/posibrain,
		BP_HEART =    /obj/item/organ/internal/heart/shell,
		BP_LUNGS =    /obj/item/organ/internal/lungs,
		BP_LIVER =    /obj/item/organ/internal/liver,
		BP_KIDNEYS =  /obj/item/organ/internal/kidneys,
		BP_STOMACH =  /obj/item/organ/internal/stomach,
		BP_EYES =     /obj/item/organ/internal/eyes,
		BP_IPCTAG =   /obj/item/organ/internal/ipc_tag
	)

	robotize_internal_organs = TRUE

	has_limbs = list(
		BP_CHEST =  list("path" = /obj/item/organ/external/chest/shell),
		BP_GROIN =  list("path" = /obj/item/organ/external/groin/shell),
		BP_HEAD =   list("path" = /obj/item/organ/external/head/shell),
		BP_L_ARM =  list("path" = /obj/item/organ/external/arm/shell),
		BP_R_ARM =  list("path" = /obj/item/organ/external/arm/right/shell),
		BP_L_LEG =  list("path" = /obj/item/organ/external/leg/shell),
		BP_R_LEG =  list("path" = /obj/item/organ/external/leg/right/shell),
		BP_L_HAND = list("path" = /obj/item/organ/external/hand/shell),
		BP_R_HAND = list("path" = /obj/item/organ/external/hand/right/shell),
		BP_L_FOOT = list("path" = /obj/item/organ/external/foot/shell),
		BP_R_FOOT = list("path" = /obj/item/organ/external/foot/right/shell)
		)

	inherent_verbs = list(
		/mob/living/carbon/human/proc/self_diagnostics,
		/mob/living/carbon/human/proc/check_tag,
		/mob/living/carbon/human/proc/tie_hair
	)

/datum/species/human/shell/handle_death_check(var/mob/living/carbon/human/H)
	if(H.get_total_health() <= config.health_threshold_dead)
		return TRUE
	return FALSE

/datum/species/human/shell/get_species(var/reference, var/mob/living/carbon/human/H, var/records)
	if(reference)
		return src
	// it's illegal for shells in Tau Ceti space to not have tags, so their records would have to be falsified
	if(records && !H.internal_organs_by_name[BP_IPCTAG])
		return "Human"
	return name

/datum/species/human/shell/sanitize_name(var/new_name)
	return sanitizeName(new_name, allow_numbers = TRUE)

/datum/species/human/shell/rogue
	name = SPECIES_IPC_SHELL_ROGUE
	short_name = "roguejak"
	name_plural = "Rogue Shells"

	spawn_flags = IS_RESTRICTED

	break_cuffs = TRUE

	has_organ = list(
		BP_BRAIN   = /obj/item/organ/internal/mmi_holder/posibrain,
		BP_CELL    = /obj/item/organ/internal/cell,
		BP_EYES  = /obj/item/organ/internal/eyes/optical_sensor,
		"surge"   = /obj/item/organ/internal/surge/advanced
	)

	unarmed_types = list(
		/datum/unarmed_attack/stomp/ipc,
		/datum/unarmed_attack/kick/ipc,
		/datum/unarmed_attack/terminator,
		/datum/unarmed_attack/bite/strong
	)

	inherent_verbs = list(
		/mob/living/carbon/human/proc/self_diagnostics
	)

/datum/species/human/shell/rogue/check_tag(var/mob/living/carbon/human/new_machine, var/client/player)
	return
