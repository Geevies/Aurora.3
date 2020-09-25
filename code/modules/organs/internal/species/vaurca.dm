/obj/item/organ/internal/eyes/night/vaurca
	name = "vaucaesian eyes"
	desc = "A set of four vaurcaesian eyes, adapted to the low or no light tunnels of Sedantis."
	icon_state = "eyes_vaurca"
	action_button_name = "Activate Low Light Vision"

/obj/item/organ/internal/eyes/night/vaurca/enable_night_vision()
	if(!owner)
		return
	if(night_vision)
		return
	var/show_message = TRUE
	for(var/obj/item/protection in list(owner.head, owner.wear_mask, owner.glasses))
		if((protection && (protection.body_parts_covered & EYES)))
			show_message = FALSE
	if(show_message)
		owner.visible_message(SPAN_NOTICE("\The [owner]'s eyes gently shift."))

	night_vision = TRUE
	owner.stop_sight_update = TRUE
	owner.see_invisible = SEE_INVISIBLE_NOLIGHTING
	owner.add_client_color(/datum/client_color/vaurca_blue)

/obj/item/organ/internal/eyes/night/vaurca/disable_night_vision()
	if(!owner)
		return
	if(!night_vision)
		return
	night_vision = FALSE
	owner.stop_sight_update = FALSE
	owner.remove_client_color(/datum/client_color/vaurca_blue)

/obj/item/organ/internal/eyes/night/vaurca/flash_act()
	if(!owner)
		return

	to_chat(owner, SPAN_WARNING("Your eyes burn with the intense light of the flash!"))
	owner.Weaken(10)
	take_damage(rand(10, 11))

	if(damage > 12)
		owner.eye_blurry += rand(3,6)

	if(damage >= min_broken_damage)
		owner.sdisabilities |= BLIND

	else if(damage >= min_bruised_damage)
		owner.eye_blind = 5
		owner.eye_blurry = 5
		owner.disabilities |= NEARSIGHTED
		addtimer(CALLBACK(owner, /mob/.proc/reset_nearsighted), 100)