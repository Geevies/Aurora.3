/datum/job/merchant
	title = "Merchant"
	faction = "Station"
	flag = MERCHANT
	department_flag = OFFMAP
	total_positions = 0
	spawn_positions = 0
	supervisors = "yourself and the market"
	minimal_player_age = 10
	economic_modifier = 5
	ideal_character_age = 30

	create_record = FALSE
	account_allowed = TRUE
	public_account = FALSE
	initial_funds_override = 2500

	access = list(access_merchant)
	minimal_access = list(access_merchant)

	latejoin_at_spawnpoints = TRUE

	outfit = /datum/outfit/job/merchant
	blacklisted_species = list(SPECIES_VAURCA_BULWARK, SPECIES_VAURCA_BREEDER)

	var/global/spawned_merchant_ship = FALSE

/datum/job/merchant/announce(mob/living/carbon/human/H)
	to_chat(H,"You are a merchant heading to the [station_name()] to make profit, your main objective is to sell and trade with the crew.")

/datum/job/merchant/New()
	..()
	merchant_spawn_chance()

/datum/job/merchant/proc/merchant_spawn_chance()
	if(prob(config.merchant_chance))
		spawn_positions = 1
		total_positions = 1
		var/datum/job/merchant/assistant/A = SSjobs.GetJobType(/datum/job/merchant/assistant)
		A.spawn_positions = 2
		A.total_positions = 2

/datum/job/merchant/pre_spawn()
	if(spawned_merchant_ship)
		return

	var/datum/map_template/merchant_ship/MS = new()
	MS.load_new_z()
	spawned_merchant_ship = TRUE

/datum/outfit/job/merchant
	name = "Merchant"
	jobtype = /datum/job/merchant

	uniform =/obj/item/clothing/under/suit_jacket/charcoal
	shoes = /obj/item/clothing/shoes/laceup
	head = /obj/item/clothing/head/that
	id = /obj/item/card/id/merchant
	tab_pda = /obj/item/modular_computer/handheld/pda/civilian/merchant
	wristbound = /obj/item/modular_computer/handheld/wristbound/preset/pda/civilian
	tablet = /obj/item/modular_computer/handheld/preset/civilian
	r_pocket = /obj/item/device/price_scanner

/datum/job/merchant/assistant
	title = "Merchant Assistant"
	flag = MERCHANTASS
	supervisors = "your ship's captain, the Merchant"

	initial_funds_override = 500

	outfit = /datum/outfit/merchant_assistant

/datum/job/merchant/assistant/merchant_spawn_chance()
	return

/datum/job/merchant/assistant/can_spawn(mob/abstract/new_player/NP)
	if(SSticker.current_state < GAME_STATE_PLAYING)
		for(var/mob/abstract/new_player/player in player_list - NP)
			for(var/i = 1 to 3)
				if(player.client.prefs.GetJobDepartment(src, i) & MERCHANT)
					return TRUE
		return FALSE
	return TRUE

/datum/outfit/merchant_assistant
	name = "Merchant's Assistant"
	id = /obj/item/card/id/merchant
	tab_pda = /obj/item/modular_computer/handheld/pda/civilian/merchant
	wristbound = /obj/item/modular_computer/handheld/wristbound/preset/pda/civilian
	tablet = /obj/item/modular_computer/handheld/preset/civilian
	r_pocket = /obj/item/device/price_scanner
	belt = /obj/item/storage/belt/utility/full
	uniform = list(
		/obj/item/clothing/under/det/black,
		/obj/item/clothing/under/suit_jacket/charcoal,
		/obj/item/clothing/under/suit_jacket/tan,
		)
	shoes = list(
		/obj/item/clothing/shoes/laceup/brown,
		/obj/item/clothing/shoes/laceup,
		/obj/item/clothing/shoes/workboots,
		/obj/item/clothing/shoes/black,
		/obj/item/clothing/shoes/cowboy
		)
	head = list(
		/obj/item/clothing/head/fez,
		/obj/item/clothing/head/flatcap,
		/obj/item/clothing/head/cowboy,
		/obj/item/clothing/head/turban/grey,
		/obj/item/clothing/head/ushanka
		)
	suit = list(
		/obj/item/clothing/suit/storage/toggle/bomber,
		/obj/item/clothing/suit/storage/toggle/leather_jacket/designer,
		/obj/item/clothing/suit/storage/toggle/leather_jacket/flight/green,
		/obj/item/clothing/suit/storage/toggle/trench,
		/obj/item/clothing/suit/storage/hooded/wintercoat
		)
	back = /obj/item/storage/backpack/satchel
	backpack_contents = list(
		/obj/item/storage/box/survival = 1,
		/obj/item/storage/wallet/random = 1
		)

/datum/outfit/merchant_assistant/get_id_rank(mob/living/carbon/human/H)
	return "Merchant's Assistant"

/datum/outfit/merchant_assistant/get_id_access()
	return list(access_merchant)
