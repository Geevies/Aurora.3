//Character trait system. Currently geared only for disabilities but a refactor to make it trait neutral would be trivial.

/datum/character_disabilities
	var/name = "Enigma"
	var/desc = "This trait was not meant to be seen by mortal minds."

/datum/character_disabilities/proc/apply_self(var/mob/living/carbon/human/H)
	return

/datum/character_disabilities/nearsighted
	name = "Nearsightedness"
	desc = "Without prescription glasses your vision is impaired."

/datum/character_disabilities/nearsighted/apply_self(var/mob/living/carbon/human/H)
	H.disabilities |= NEARSIGHTED

/datum/character_disabilities/stutter
	name = "Stuttering"
	desc = "You have a chronic case of stuttering, repeating sounds involuntarily."

/datum/character_disabilities/stutter/apply_self(var/mob/living/carbon/human/H)
	H.disabilities |= STUTTERING

/datum/character_disabilities/deuteranomaly
	name = "Deuteranopia"
	desc = "You have difficulty perceiving green."

/datum/character_disabilities/deuteranomaly/apply_self(var/mob/living/carbon/human/H)
	H.add_client_color(/datum/client_color/deuteranopia, TRUE)

/datum/character_disabilities/protanopia
	name = "Protanopia"
	desc = "You have difficulty perceiving red."

/datum/character_disabilities/protanopia/apply_self(var/mob/living/carbon/human/H)
	H.add_client_color(/datum/client_color/protanopia, TRUE)

/datum/character_disabilities/tritanopia
	name = "Tritanopia"
	desc = "You have difficulty perceiving green and yellow."

/datum/character_disabilities/tritanopia/apply_self(var/mob/living/carbon/human/H)
	H.add_client_color(/datum/client_color/tritanopia, TRUE)

/datum/character_disabilities/total_colorblind
	name = "Total Colorblindness"
	desc = "You cannot see color, only black, white, and shades of gray."

/datum/character_disabilities/total_colorblind/apply_self(var/mob/living/carbon/human/H)
	H.add_client_color(/datum/client_color/monochrome, TRUE)

/datum/character_disabilities/deaf
	name = "Deafness"
	desc = "You are unable to percieve sound."

/datum/character_disabilities/deaf/apply_self(var/mob/living/carbon/human/H)
	H.sdisabilities |= DEAF

/datum/character_disabilities/asthma
	name = "Asthma"
	desc = "You are prone to inflammation in the lungs."

/datum/character_disabilities/asthma/apply_self(var/mob/living/carbon/human/H)
	H.disabilities |= ASTHMA
	if(H.max_stamina)
		H.max_stamina *= 0.8
		H.stamina = H.max_stamina

/datum/character_disabilities/hemophilia
	name = "Hemophilia"
	desc = "Your blood lacks some clotting factors, causing wounds to take twice as long to stop bleeding."
	/// This takes a TRAIT_DISABILITY_* type trait, and assigns it to the character on apply_self
	var/trait_type = TRAIT_DISABILITY_HEMOPHILIA

/datum/character_disabilities/hemophilia/apply_self(var/mob/living/carbon/human/H)
	ADD_TRAIT(H, trait_type, DISABILITY_TRAIT)

/datum/character_disabilities/hemophilia/major
	name = "Major Hemophilia"
	desc = "Your blood lacks ALL clotting factors, causing wounds to never stop bleeding."
	trait_type = TRAIT_DISABILITY_HEMOPHILIA_MAJOR


ABSTRACT_TYPE(/datum/character_disabilities/bruising)
	name = "Bruised Limb"
	var/affected_limb

/datum/character_disabilities/bruising/apply_self(var/mob/living/carbon/human/target)
	target.apply_damage(10, DAMAGE_BRUTE, affected_limb, armor_pen = 100, silent = TRUE)

#define BRUISING_DISABILITY(LIMB_PATH, LIMB_NAME, LIMB_TAG) \
/datum/character_disabilities/bruising/##LIMB_PATH { \
	name = "Bruised Limb: " + ##LIMB_NAME; \
	affected_limb = ##LIMB_TAG; \
}

BRUISING_DISABILITY(head, "Head", BP_HEAD)
BRUISING_DISABILITY(torso, "Torso", BP_CHEST)
BRUISING_DISABILITY(groin, "Groin", BP_GROIN)
BRUISING_DISABILITY(left_arm, "Left Arm", BP_L_ARM)
BRUISING_DISABILITY(right_arm, "Right Arm", BP_R_ARM)
BRUISING_DISABILITY(left_hand, "Left Hand", BP_L_HAND)
BRUISING_DISABILITY(right_hand, "Right Hand", BP_R_HAND)
BRUISING_DISABILITY(left_leg, "Left Leg", BP_L_LEG)
BRUISING_DISABILITY(right_leg, "Right Leg", BP_R_LEG)
BRUISING_DISABILITY(left_foot, "Left Foot", BP_L_FOOT)
BRUISING_DISABILITY(right_foot, "Right Foot", BP_R_FOOT)

#undef BRUISING_DISABILITY


ABSTRACT_TYPE(/datum/character_disabilities/burn)
	name = "Bruised Limb"
	var/affected_limb

/datum/character_disabilities/burn/apply_self(var/mob/living/carbon/human/target)
	target.apply_damage(10, DAMAGE_BURN, affected_limb, armor_pen = 100, silent = TRUE)

#define BURN_DISABILITY(LIMB_PATH, LIMB_NAME, LIMB_TAG) \
/datum/character_disabilities/burn/##LIMB_PATH { \
	name = "Burned Limb: " + ##LIMB_NAME; \
	affected_limb = ##LIMB_TAG; \
}

BURN_DISABILITY(head, "Head", BP_HEAD)
BURN_DISABILITY(torso, "Torso", BP_CHEST)
BURN_DISABILITY(groin, "Groin", BP_GROIN)
BURN_DISABILITY(left_arm, "Left Arm", BP_L_ARM)
BURN_DISABILITY(right_arm, "Right Arm", BP_R_ARM)
BURN_DISABILITY(left_hand, "Left Hand", BP_L_HAND)
BURN_DISABILITY(right_hand, "Right Hand", BP_R_HAND)
BURN_DISABILITY(left_leg, "Left Leg", BP_L_LEG)
BURN_DISABILITY(right_leg, "Right Leg", BP_R_LEG)
BURN_DISABILITY(left_foot, "Left Foot", BP_L_FOOT)
BURN_DISABILITY(right_foot, "Right Foot", BP_R_FOOT)

#undef BURN_DISABILITY


ABSTRACT_TYPE(/datum/character_disabilities/broken)
	name = "Bruised Limb"
	var/affected_limb

/datum/character_disabilities/broken/apply_self(var/mob/living/carbon/human/target)
	var/obj/item/organ/external/affecting = target.get_organ(affected_limb)
	if(affecting)
		affecting.fracture(silent = TRUE)
		affecting.status |= ORGAN_SPLINTED

#define BROKEN_DISABILITY(LIMB_PATH, LIMB_NAME, LIMB_TAG) \
/datum/character_disabilities/broken/##LIMB_PATH { \
	name = "Broken Limb: " + ##LIMB_NAME; \
	affected_limb = ##LIMB_TAG; \
}

BROKEN_DISABILITY(left_arm, "Left Arm", BP_L_ARM)
BROKEN_DISABILITY(right_arm, "Right Arm", BP_R_ARM)
BROKEN_DISABILITY(left_hand, "Left Hand", BP_L_HAND)
BROKEN_DISABILITY(right_hand, "Right Hand", BP_R_HAND)
BROKEN_DISABILITY(left_leg, "Left Leg", BP_L_LEG)
BROKEN_DISABILITY(right_leg, "Right Leg", BP_R_LEG)
BROKEN_DISABILITY(left_foot, "Left Foot", BP_L_FOOT)
BROKEN_DISABILITY(right_foot, "Right Foot", BP_R_FOOT)

#undef BROKEN_DISABILITY
