/obj/item/spellbook/occultist
	spellbook_type = /datum/spellbook/occultist

/datum/spellbook/occultist
	name = "\improper occultist skull"
	feedback = "OS"
	title = "Skull of Blood and Power"
	title_desc = "Buy spells using your available spell slots. Artefacts may also be bought however their cost is permanent."
	book_desc = "Dig your hands deep within the blood arcane, stealing power from the great Nar'sie."
	book_flags = CAN_MAKE_CONTRACTS
	max_uses = 12
	wizard_type = "Occultist"

	spells = list(/spell/targeted/projectile/magic_missile =		1,
				/spell/targeted/projectile/dumbfire/fireball =		1,
				/spell/aoe_turf/disable_tech =						1,
				/spell/aoe_turf/smoke =								1,
				/spell/targeted/genetic/blind =						1,
				/spell/targeted/subjugation =						1,
				/spell/targeted/mindcontrol =						2,
				/spell/aoe_turf/conjure/forcewall =					1,
				/spell/targeted/genetic/mutate =					1,
				/spell/aoe_turf/knock =								1,
				/spell/noclothes =									2,
				/obj/item/gun/energy/staff =						1,
				/obj/item/gun/energy/staff/focus =					1,
				/obj/structure/closet/wizard/souls =				1,
				/obj/structure/closet/wizard/armor =				1,
				/obj/item/book/tome/partial =						1,
				/obj/item/contract/apprentice =						1,
				/obj/item/apprentice_pebble =						2
				)

	apprentice_spells = list(
		/spell/targeted/projectile/dumbfire/fireball = 1,
		/spell/aoe_turf/smoke = 1,
		/spell/targeted/mindcontrol = 2,
		/obj/item/book/tome/partial = 1
	)

/datum/spellbook/occultist/on_spellbook_get(mob/living/user)
	..()
	to_chat(user, SPAN_CULT("The knowledge of Nar'sie's powers fills your mind. You can now intone in the language of the great Geometer of blood."))
	user.add_language(LANGUAGE_CULT)
	user.add_language(LANGUAGE_OCCULT)