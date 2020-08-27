/obj/item/device/radio/headset
	name = "radio headset"
	desc = "An updated, modular intercom that fits over the head. Takes encryption keys."
	icon_state = "headset"
	item_state = "headset"
	matter = list(DEFAULT_WALL_MATERIAL = 75)
	subspace_transmission = TRUE
	canhear_range = 0 // can't hear headsets from very far away

	slot_flags = SLOT_EARS
	var/translate_binary = FALSE
	var/translate_hivenet = FALSE
	var/obj/item/device/encryptionkey/keyslot1 = null
	var/obj/item/device/encryptionkey/keyslot2 = null

	var/ks1type = /obj/item/device/encryptionkey
	var/ks2type = null
	var/radio_sound = null

	drop_sound = 'sound/items/drop/component.ogg'
	pickup_sound = 'sound/items/pickup/component.ogg'

/obj/item/device/radio/headset/Initialize()
	. = ..()
	internal_channels.Cut()
	if(ks1type)
		keyslot1 = new ks1type(src)
	if(ks2type)
		keyslot2 = new ks2type(src)
	recalculateChannels(TRUE)

/obj/item/device/radio/headset/Destroy()
	QDEL_NULL(keyslot1)
	QDEL_NULL(keyslot2)
	return ..()

/obj/item/device/radio/headset/list_channels(var/mob/user)
	return list_secure_channels()

/obj/item/device/radio/headset/examine(mob/user)
	if(!(..(user, 1) && radio_desc))
		return

	to_chat(user, "The following channels are available:")
	to_chat(user, radio_desc)

/obj/item/device/radio/headset/setupRadioDescription()
	if(translate_binary || translate_hivenet)
		..(", :+ - Special")
	else
		..()

/obj/item/device/radio/headset/handle_message_mode(mob/living/M, message, channel)
	if(channel == "special")
		if(translate_binary)
			var/datum/language/binary = all_languages[LANGUAGE_ROBOT]
			binary.broadcast(M, message)
		if(translate_hivenet)
			var/datum/language/bug = all_languages[LANGUAGE_VAURCA]
			bug.broadcast(M, message)
		return null

	return ..()

/obj/item/device/radio/headset/receive_range(freq, level, aiOverride = 0)
	if (aiOverride)
		return ..(freq, level)
	if(ishuman(src.loc))
		var/mob/living/carbon/human/H = src.loc
		if(H.l_ear == src || H.r_ear == src)
			return ..(freq, level)
	return -1

/obj/item/device/radio/headset/attackby(obj/item/W, mob/user)
	if(W.isscrewdriver())
		if(keyslot1 || keyslot2)
			for(var/ch_name in channels)
				SSradio.remove_object(src, radiochannels[ch_name])
				secure_radio_connections[ch_name] = null

			if(keyslot1)
				var/turf/T = get_turf(user)
				if(T)
					keyslot1.forceMove(T)
					keyslot1 = null

			if(keyslot2)
				var/turf/T = get_turf(user)
				if(T)
					keyslot2.forceMove(T)
					keyslot2 = null

			recalculateChannels(TRUE)
			to_chat(user, SPAN_NOTICE("You pop out the encryption keys in the headset!"))
		else
			to_chat(user, SPAN_WARNING("This headset doesn't have any encryption keys!"))

	else if(istype(W, /obj/item/device/encryptionkey))
		if(keyslot1 && keyslot2)
			to_chat(user, SPAN_WARNING("The headset can't hold another key!"))
			return

		if(!keyslot1)
			user.drop_from_inventory(W, src)
			keyslot1 = W
		else
			user.drop_from_inventory(W, src)
			keyslot2 = W

		recalculateChannels(TRUE)


/obj/item/device/radio/headset/proc/recalculateChannels(var/setDescription = FALSE)
	src.channels = list()
	src.translate_binary = FALSE
	src.translate_hivenet = FALSE
	src.syndie = FALSE

	for(var/keyslot in list(keyslot1, keyslot2))
		if(!keyslot)
			continue
		var/obj/item/device/encryptionkey/K = keyslot

		for(var/ch_name in K.channels)
			if(ch_name in src.channels)
				continue
			src.channels[ch_name] = K.channels[ch_name]

		for(var/ch_name in K.additional_channels)
			if(ch_name in src.channels)
				continue
			src.channels[ch_name] = K.additional_channels[ch_name]

		if(K.translate_binary)
			src.translate_binary = TRUE

		if(K.translate_hivenet)
			src.translate_hivenet = TRUE

		if(K.syndie)
			src.syndie = TRUE

	for (var/ch_name in channels)
		if(!SSradio)
			sleep(30) // Waiting for the SSradio to be created.
		if(!SSradio)
			src.name = "broken radio headset"
			return

		secure_radio_connections[ch_name] = SSradio.add_object(src, radiochannels[ch_name], RADIO_CHAT)

	if(setDescription)
		setupRadioDescription()

	return

/obj/item/device/radio/headset/alt
	name = "bowman headset"
	icon_state = "headset_alt"
	item_state = "headset_alt"

/*
 * Civillian
 */

/obj/item/device/radio/headset/headset_service
	name = "service radio headset"
	desc = "Headset used by the service staff, tasked with keeping the station full, happy and clean."
	icon_state = "srv_headset"
	ks2type = /obj/item/device/encryptionkey/headset_service

/obj/item/device/radio/headset/heads/hop
	name = "head of personnel's headset"
	desc = "The headset of the guy who will one day be captain."
	icon_state = "hop_headset"
	ks2type = /obj/item/device/encryptionkey/heads/hop

/obj/item/device/radio/headset/heads/hop/alt
	name = "head of personnel's bowman headset"
	icon_state = "hop_headset_alt"
	item_state = "headset_alt"

/*
 * Engineering
 */

/obj/item/device/radio/headset/headset_eng
	name = "engineering radio headset"
	desc = "When the engineers wish to chat like girls."
	icon_state = "eng_headset"
	ks2type = /obj/item/device/encryptionkey/headset_eng

/obj/item/device/radio/headset/headset_eng/alt
	name = "engineering bowman headset"
	icon_state = "eng_headset_alt"
	item_state = "headset_alt"

/obj/item/device/radio/headset/heads/ce
	name = "chief engineer's headset"
	desc = "The headset of the guy who is in charge of morons."
	icon_state = "ce_headset"
	ks2type = /obj/item/device/encryptionkey/heads/ce

/obj/item/device/radio/headset/heads/ce/alt
	name = "chief engineer's bowman headset"
	icon_state = "ce_headset_alt"
	item_state = "headset_alt"

/*
 * Cargo
 */

/obj/item/device/radio/headset/headset_cargo
	name = "supply radio headset"
	desc = "A headset used by the quartermaster's slaves."
	icon_state = "cargo_headset"
	ks2type = /obj/item/device/encryptionkey/headset_cargo

/obj/item/device/radio/headset/headset_cargo/alt
	name = "cargo bowman headset"
	icon_state = "cargo_headset_alt"
	item_state = "headset_alt"

/obj/item/device/radio/headset/headset_mining
	name = "mining radio headset"
	desc = "Headset used by dwarves. It has an inbuilt subspace antenna for better reception."
	icon_state = "mine_headset"
	ks2type = /obj/item/device/encryptionkey/headset_cargo

/obj/item/device/radio/headset/headset_mining/alt
	name = "mining bowman radio headset"
	icon_state = "mine_headset_alt"
	item_state = "headset_alt"

/obj/item/device/radio/headset/qm
	name = "quartermaster's headset"
	desc = "A headset used by the head honcho of paper pushing."
	icon_state = "qm_headset"
	ks2type = /obj/item/device/encryptionkey/headset_cargo

/obj/item/device/radio/headset/qm/alt
	name = "quartermaster bowman headset"
	icon_state = "qm_headset_alt"
	item_state = "headset_alt"

/*
 * Medical
 */

/obj/item/device/radio/headset/headset_med
	name = "medical radio headset"
	desc = "A headset for the trained staff of the medbay."
	icon_state = "med_headset"
	ks2type = /obj/item/device/encryptionkey/headset_med

/obj/item/device/radio/headset/headset_med/alt
	name = "medical bowman headset"
	icon_state = "med_headset_alt"
	item_state = "headset_alt"

/obj/item/device/radio/headset/heads/cmo
	name = "chief medical officer's headset"
	desc = "The headset of the highly trained medical chief."
	icon_state = "cmo_headset"
	ks2type = /obj/item/device/encryptionkey/heads/cmo

/obj/item/device/radio/headset/heads/cmo/alt
	name = "chief medical officer's bowman headset"
	icon_state = "cmo_headset_alt"
	item_state = "headset_alt"

/*
 * Science
 */

/obj/item/device/radio/headset/headset_sci
	name = "science radio headset"
	desc = "A sciency headset. Like usual."
	icon_state = "sci_headset"
	ks2type = /obj/item/device/encryptionkey/headset_sci

/obj/item/device/radio/headset/headset_sci/alt
	name = "science bowman headset"
	icon_state = "sci_headset_alt"

/obj/item/device/radio/headset/headset_rob
	name = "robotics radio headset"
	desc = "Made specifically for the roboticists who cannot decide between departments."
	icon_state = "rob_headset"
	ks2type = /obj/item/device/encryptionkey/headset_rob

/obj/item/device/radio/headset/heads/rd
	name = "research director's headset"
	desc = "Headset of the researching God."
	icon_state = "rd_headset"
	ks2type = /obj/item/device/encryptionkey/heads/rd

/obj/item/device/radio/headset/heads/rd/alt
	name = "research director's bowman headset"
	icon_state = "rd_headset_alt"
	item_state = "headset_alt"

/*
 * Security
 */

/obj/item/device/radio/headset/headset_sec
	name = "security radio headset"
	desc = "This is used by your elite security force."
	icon_state = "sec_headset"
	ks2type = /obj/item/device/encryptionkey/headset_sec

/obj/item/device/radio/headset/headset_sec/alt
	name = "security bowman headset"
	icon_state = "sec_headset_alt"
	item_state = "headset_alt"

/obj/item/device/radio/headset/heads/hos
	name = "head of security's headset"
	desc = "The headset of the man who protects your worthless lifes."
	icon_state = "hos_headset"
	ks2type = /obj/item/device/encryptionkey/heads/hos

/obj/item/device/radio/headset/heads/hos/alt
	name = "head of security's bowman headset"
	icon_state = "hos_headset_alt"
	item_state = "headset_alt"

/*
 * Captain
 */

/obj/item/device/radio/headset/headset_com
	name = "command radio headset"
	desc = "A headset with a commanding channel."
	icon_state = "com_headset"
	ks2type = /obj/item/device/encryptionkey/headset_com

/obj/item/device/radio/headset/headset_com/alt
	name = "command bowman headset"
	icon_state = "com_headset_alt"
	item_state = "headset_alt"

/obj/item/device/radio/headset/heads/captain
	name = "captain's headset"
	desc = "The headset of the boss."
	icon_state = "cap_headset"
	ks2type = /obj/item/device/encryptionkey/heads/captain

/obj/item/device/radio/headset/heads/captain/alt
	name = "captain's bowman headset"
	icon_state = "cap_headset_alt"
	item_state = "headset_alt"

/*
 * Misc
 */

/obj/item/device/radio/headset/headset_medsci
	name = "medical research radio headset"
	desc = "A headset that is a result of the mating between medical and science."
	icon_state = "medsci_headset"
	ks2type = /obj/item/device/encryptionkey/headset_medsci

/obj/item/device/radio/headset/hivenet
	translate_hivenet = 1
	ks2type = /obj/item/device/encryptionkey/hivenet

/obj/item/device/radio/headset/syndicate
	name = "military headset"
	icon_state = "syn_headset"
	origin_tech = list(TECH_ILLEGAL = 3)
	syndie = 1
	ks1type = /obj/item/device/encryptionkey/syndicate

/obj/item/device/radio/headset/syndicate/alt
	name = "military bowman headset"
	icon_state = "syn_headset_alt"
	item_state = "headset_alt"

/obj/item/device/radio/headset/raider
	icon_state = "syn_headset"
	origin_tech = list(TECH_ILLEGAL = 2)
	syndie = 1
	ks1type = /obj/item/device/encryptionkey/raider

/obj/item/device/radio/headset/burglar
	icon_state = "syn_headset"
	origin_tech = list(TECH_ILLEGAL = 2)
	syndie = TRUE
	ks1type = /obj/item/device/encryptionkey/burglar

/obj/item/device/radio/headset/ninja
	icon_state = "syn_headset"
	origin_tech = list(TECH_ILLEGAL = 3)
	syndie = 1
	ks1type = /obj/item/device/encryptionkey/ninja

/obj/item/device/radio/headset/binary
	origin_tech = list(TECH_ILLEGAL = 3)
	ks2type = /obj/item/device/encryptionkey/binary

/obj/item/device/radio/headset/ert
	name = "emergency response team radio headset"
	desc = "The headset of the boss's boss."
	icon_state = "com_headset"
	ks2type = /obj/item/device/encryptionkey/ert

/obj/item/device/radio/headset/legion
	name = "Tau Ceti Foreign Legion radio headset"
	desc = "The headset used by NanoTrasen sanctioned response forces."
	icon_state = "com_headset"
	ks2type = /obj/item/device/encryptionkey/onlyert

/obj/item/device/radio/headset/distress
	name = "specialist radio headset"
	desc = "A headset used by specialists."
	ks2type = /obj/item/device/encryptionkey/onlyert

/obj/item/device/radio/headset/representative
	name = "representative headset"
	desc = "The headset of your worst enemy."
	icon_state = "com_headset"
	ks2type = /obj/item/device/encryptionkey/headset_com

/obj/item/device/radio/headset/heads/ai_integrated //No need to care about icons, it should be hidden inside the AI anyway.
	name = "\improper AI subspace transceiver"
	desc = "Integrated AI radio transceiver."
	icon = 'icons/obj/robot_component.dmi'
	icon_state = "radio"
	ks2type = /obj/item/device/encryptionkey/heads/ai_integrated
	var/myAi = null    // Atlantis: Reference back to the AI which has this radio.
	var/disabledAi = 0 // Atlantis: Used to manually disable AI's integrated radio via intellicard menu.

/obj/item/device/radio/headset/heads/ai_integrated/receive_range(freq, level)
	if (disabledAi)
		return -1 //Transciever Disabled.
	return ..(freq, level, 1)

/obj/item/device/radio/headset/heads/ai_integrated/Destroy()
	myAi = null
	return ..()