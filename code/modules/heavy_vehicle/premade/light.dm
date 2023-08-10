/mob/living/heavy_vehicle/premade/light
	name = "light exosuit"
	desc = "A light and agile exosuit."
	icon_state = "light"

	e_head = /obj/item/mech_component/sensors/light
	e_body = /obj/item/mech_component/chassis/light
	e_arms = /obj/item/mech_component/manipulators/light
	e_legs = /obj/item/mech_component/propulsion/light
	e_color = COLOR_OFF_WHITE

	h_back_utility = /obj/item/mecha_equipment/sleeper
	h_l_utility = /obj/item/mecha_equipment/catapult

/mob/living/heavy_vehicle/premade/light/testing
	name = "light testing exosuit"
	desc = "A light and agile exosuit. It looks rather temporary."

	e_head = /obj/item/mech_component/sensors/light
	e_body = /obj/item/mech_component/chassis/light
	e_arms = /obj/item/mech_component/manipulators/light
	e_legs = /obj/item/mech_component/propulsion/light
	e_color = null

	h_l_utility = /obj/item/mecha_equipment/drill
	h_r_utility = /obj/item/mecha_equipment/drill
	h_back_utility = null

/obj/item/mech_component/manipulators/light
	name = "light arms"
	exosuit_desc_string = "lightweight, segmented manipulators"
	icon_state = "light_arms"
	melee_damage = 15
	action_delay = 15
	max_damage = 100
	power_use = 3000
	desc = "As flexible as they are fragile, these Bishop Cybernetics manipulators can follow a pilot's movements in close to real time."
	punch_sound = 'sound/mecha/mech_punch_fast.ogg'

/obj/item/mech_component/propulsion/light
	name = "light legs"
	exosuit_desc_string = "aerodynamic electromechanic legs"
	icon_state = "light_legs"
	move_delay = 2
	turn_delay = 3
	max_damage = 100
	power_use = 3000
	desc = "The electrical systems driving these legs are almost totally silent. Unfortunately slamming a plate of metal against the ground is not."

/obj/item/mech_component/sensors/light
	name = "light sensors"
	gender = PLURAL
	exosuit_desc_string = "advanced sensor array"
	icon_state = "light_head"
	max_damage = 80
	power_use = 12000
	desc = "A series of high resolution optical sensors."
	vision_flags = SEE_TURFS
	see_invisible = SEE_INVISIBLE_NOLIGHTING

/obj/item/mech_component/sensors/light/prebuild()
	..()
	software = new(src)
	software.installed_software = list(MECH_SOFTWARE_UTILITY, MECH_SOFTWARE_MEDICAL)

/obj/item/mech_component/chassis/light
	name = "light exosuit chassis"
	pilot_coverage = 100
	transparent_cabin = TRUE
	hatch_descriptor = "canopy"
	exosuit_desc_string = "an open and light chassis"
	icon_state = "light_body"
	max_damage = 150
	power_use = 3000
	desc = "The Veymed Odysseus series cockpits combine ultralight materials and clear aluminum laminates to provide an optimized cockpit experience."


/obj/item/mech_component/chassis/light/prebuild()
	. = ..()
	mech_armor = new /obj/item/robot_parts/robot_component/armor/mech/radproof(src)

/obj/item/mech_component/chassis/light/Initialize()
	pilot_positions = list(
		list(
			"[NORTH]" = list("x" = 8,  "y" = -2),
			"[SOUTH]" = list("x" = 8,  "y" = -2),
			"[EAST]"  = list("x" = 1,  "y" = -2),
			"[WEST]"  = list("x" = 9,  "y" = -2)
		)
	)
	. = ..()

/mob/living/heavy_vehicle/premade/light/legion
	name = "legion support exosuit"
	desc = "A light and agile exosuit painted in the colours of the Tau Ceti Foreign Legion."

	e_color = COLOR_TCFL

	h_head_utility = /obj/item/mecha_equipment/light
	h_back_utility = /obj/item/mecha_equipment/sleeper
	h_l_utility = /obj/item/mecha_equipment/crisis_drone
	h_r_utility = /obj/item/mecha_equipment/mounted_system/medanalyzer
	h_frame_utility = /obj/item/mecha_equipment/clamp

/mob/living/heavy_vehicle/premade/light/iac
	name = "medical exosuit"
	desc = "A light and agile medical oriented exosuit."

	e_color = COLOR_IAC

	h_head_utility = /obj/item/mecha_equipment/light
	h_back_utility = /obj/item/mecha_equipment/sleeper
	h_l_utility = /obj/item/mecha_equipment/crisis_drone
	h_r_utility = /obj/item/mecha_equipment/mounted_system/medanalyzer

/mob/living/heavy_vehicle/premade/light/kataphract
	name = "kataphract exosuit"
	desc = "A light and nimble exosuit, bearing the colour scheme of the Unathi Kataphracts."

	e_color = COLOR_CHESTNUT

	h_back_utility = /obj/item/mecha_equipment/quick_enter
	h_r_utility = /obj/item/mecha_equipment/catapult

/mob/living/heavy_vehicle/premade/light/recon
	name = "gremlin exosuit"
	desc = "A light and nimble recon exosuit, bearing the colour scheme of the Solarian Armed Forces."

	e_color = COLOR_DARK_GREEN_GRAY
	e_arms = /obj/item/mech_component/manipulators/combat
	e_head = /obj/item/mech_component/sensors/combat
	e_legs = /obj/item/mech_component/propulsion/hover/light

	h_back_utility = /obj/item/mecha_equipment/quick_enter
	h_r_combat = /obj/item/mecha_equipment/mounted_system/combat/smg
