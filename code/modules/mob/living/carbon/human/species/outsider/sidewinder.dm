/mob/living/carbon/human/snake/Initialize(mapload)
	. = ..(mapload, SPECIES_SNAKE)

/datum/species/snake
	name = SPECIES_SNAKE
	short_name = "snek"
	name_plural = "Sidewinders"
	bodytype = BODYTYPE_SNAKE
	icobase = 'icons/mob/human_races/r_snake.dmi'
	deform = 'icons/mob/human_races/r_snake.dmi'
	move_trail = /obj/effect/decal/cleanable/blood/tracks/snake
	blurb = "They are snakes."
	eyes = "eyes_sidewinder"
	break_cuffs = TRUE

	tail_stance = TRUE
	tail_length = 3

	mob_size = 15
	gluttonous = GLUT_MESSY
	rarity_value = 10
	slowdown = -1 // Compensating for a total inability to wear shoes.
	
	brute_mod = 0.8
	ethanol_resistance = 0.7
	
	siemens_coefficient = 0.5

	cold_level_1 = 280
	cold_level_2 = 220
	cold_level_3 = 130
	heat_level_1 = 420
	heat_level_2 = 480
	heat_level_3 = 1100
	heat_discomfort_level = 295
	
	heat_discomfort_strings = list(
		"You feel soothingly warm.",
		"You feel the heat sink into your bones.",
		"You feel warm enough to take a nap."
		)
	cold_discomfort_level = 292
	cold_discomfort_strings = list(
		"You feel chilly.",
		"You feel sluggish and cold.",
		"Your scales bristle against the cold."
		)

	hud_type = /datum/hud_data/snake
	unarmed_types = list(/datum/unarmed_attack/claws/strong, /datum/unarmed_attack/bite/sharp)

	default_language = "Sidewinder Language"
	language = "Ceti Basic"
	num_alternate_languages = 1

	appearance_flags = HAS_HAIR_COLOR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	flags = NO_SLIP

	inherent_verbs = list(
		/mob/living/carbon/human/proc/coil_up
		)

	flesh_color = "#006600"
	blood_color = "#1D2CBF"
	base_color = "#006666"
	
	reagent_tag = IS_UNATHI

	has_limbs = list(
		BP_CHEST =  list("path" = /obj/item/organ/external/chest/snake),
		BP_GROIN =  list("path" = /obj/item/organ/external/groin/snake),
		BP_HEAD =   list("path" = /obj/item/organ/external/head/snake),
		BP_L_ARM =  list("path" = /obj/item/organ/external/arm),
		BP_R_ARM =  list("path" = /obj/item/organ/external/arm/right),
		BP_L_HAND = list("path" = /obj/item/organ/external/hand),
		BP_R_HAND = list("path" = /obj/item/organ/external/hand/right)
		)

	has_organ = list(
		BP_HEART =    /obj/item/organ/internal/heart,
		BP_LUNGS =    /obj/item/organ/internal/lungs,
		BP_LIVER =    /obj/item/organ/internal/liver,
		BP_KIDNEYS =  /obj/item/organ/internal/kidneys,
		BP_BRAIN =    /obj/item/organ/internal/brain,
		BP_EYES =     /obj/item/organ/internal/eyes,
		BP_VENOM_GLAND =  /obj/item/organ/internal/venom_gland
		)

	stamina = 120
	sprint_speed_factor = 0.8
	stamina_recovery = 2
	
/datum/species/snake
	autohiss_basic_map = list(
			"s" = list("ssss", "sssss", "ssssss"),
			"c" = list("cksss", "ckssss", "cksssss"),
			"k" = list("ksss", "kssss", "ksssss"),
			"x" = list("ksss", "kssss", "ksssss")
		)