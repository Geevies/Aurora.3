/obj/item/spellbook/artificer
	spellbook_type = /datum/spellbook/artificer

/datum/spellbook/artificer
	name = "\improper artificer toolkit"
	feedback = "AT"
	title = "Toolkit of Tinkercraft"
	title_desc = "Buy spells using your available spell slots. Artefacts may also be bought however their cost is permanent."
	book_desc = "Build your magical arsenal. Deconstruct all that oppose you."
	book_flags = CAN_MAKE_CONTRACTS
	max_uses = 12

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
				/obj/item/gun/energy/staff/animate =				1,
				/obj/structure/closet/wizard/scrying =				1,
				/obj/item/monster_manual =							2,
				/obj/item/contract/apprentice =						1,
				/obj/item/apprentice_pebble =						2
				)

	apprentice_spells = list(
		/spell/targeted/projectile/dumbfire/fireball = 1,
		/spell/aoe_turf/smoke = 1,
		/spell/targeted/mindcontrol = 2,
		/obj/structure/closet/wizard/scrying = 1
	)