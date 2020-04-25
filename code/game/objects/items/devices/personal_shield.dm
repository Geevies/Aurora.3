/obj/item/device/personal_shield
	name = "personal shield"
	desc = "Truely a life-saver: this device protects its user from being hit by objects moving very, very fast, though only for a few shots."
	icon = 'icons/obj/device.dmi'
	icon_state = "batterer"
	var/next_recharge
	var/uses = 5
	var/obj/aura/personal_shield/device/shield

/obj/item/device/personal_shield/examine(mob/user, distance)
	..()
	if(Adjacent(user))
		to_chat(user, SPAN_NOTICE("\The [src] can absorb [uses] more shot\s."))

/obj/item/device/personal_shield/Initialize()
	. = ..()
	START_PROCESSING(SSprocessing, src)

/obj/item/device/personal_shield/process()
	if(next_recharge < world.time)
		uses = min(5, uses + 1)
		if(uses == 1)
			update_icon()
		next_recharge = world.time + 1 MINUTE

/obj/item/device/personal_shield/attack_self(mob/living/user)
	if(uses && !shield)
		shield = new /obj/aura/personal_shield/device(user, src)
	else
		dissipate()

/obj/item/device/personal_shield/Move()
	dissipate()
	return ..()

/obj/item/device/personal_shield/forceMove()
	dissipate()
	return ..()

/obj/item/device/personal_shield/proc/take_charge()
	uses--
	if(!uses)
		to_chat(shield.user, FONT_LARGE(SPAN_WARNING("\The [src] begins to spark as it breaks!")))
		QDEL_NULL(shield)
		update_icon()
		return

/obj/item/device/personal_shield/update_icon()
	if(uses)
		icon_state = "batterer"
	else
		icon_state = "battererburnt"

/obj/item/device/personal_shield/Destroy()
	dissipate()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/item/device/personal_shield/proc/dissipate()
	if(shield?.user)
		to_chat(shield.user, FONT_LARGE(SPAN_WARNING("\The [src] fades around you, dissipating.")))
	QDEL_NULL(shield)