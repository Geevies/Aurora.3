// Originally a debug verb, made it a proper adminverb for ~fun~
/client/proc/makePAI()
	set name = "Make pAI"
	set category = "Admin"

	if(!check_rights(R_ADMIN))
		return
	if(!mob)
		return

	var/turf/T = get_turf(mob)
	var/pai_key
	var/name = input(mob, "", "What will the pAI's name be?") as text|null
	if(!name)
		return

	if(!pai_key)
		var/client/C = input("Select client") as null|anything in clients
		if(!C)
			return
		pai_key = C.key

	log_and_message_admins("made a pAI with key=[pai_key] at ([T.x],[T.y],[T.z])")
	var/obj/item/device/paicard/card = new(T)
	var/mob/living/silicon/pai/pai = new(card)
	pai.key = pai_key
	card.setPersonality(pai)

	if(name)
		pai.SetName(name)