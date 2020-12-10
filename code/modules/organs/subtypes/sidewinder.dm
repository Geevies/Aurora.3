/obj/item/organ/external/groin/snake
	name = BP_TAIL
	max_damage = 200
	min_broken_damage = 160
	body_hair = "markings"

/obj/item/organ/external/head/snake
	body_hair = "markings"

/obj/item/organ/external/chest/snake
	body_hair = "markings"

/obj/item/organ/internal/venom_gland
	name = BP_VENOM_GLAND
	desc = "Oversized glands, filled with a venomous liquid."
	parent_organ = "head"
	icon = 'icons/effects/blood.dmi'
	icon_state = "xgibtorso"
	organ_tag = BP_VENOM_GLAND

	var/last_venom_message = 0

/obj/item/organ/internal/venom_gland/process()
	if(is_broken() && last_venom_message + 5 MINUTES > world.time)
		to_chat(owner, SPAN_NOTICE("Your fangs dry up as your venom glands are damaged."))
		last_venom_message = world.time
	..()