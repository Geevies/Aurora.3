/mob/living/heavy_vehicle/premade
	name = "impossible mech"
	desc = "It seems to be saying 'please let me die'."
	icon = 'icons/mecha/mecha.dmi'
	icon_state = "light"
	pixel_x = -10

	//equipment path vars, which get added to the mech in the add_parts() proc
	//e_ means equipment - geeves
	var/e_head
	var/e_body
	var/e_arms
	var/e_legs
	var/e_color = COLOR_DARK_ORANGE // the colour all the parts uses

	//hardpoint equipment path vars, which gets added to the mech in the spawn_mech_equipment() proc
	//h_ means hardpoint, the rest should be sensical, i hope - geeves
	var/h_head_utility = /obj/item/mecha_equipment/light
	var/h_back_utility
	var/h_back_combat
	var/h_back_superheavy
	var/h_frame_utility
	var/h_l_combat
	var/h_r_combat
	var/h_l_utility
	var/h_r_utility

/mob/living/heavy_vehicle/premade/Initialize()
	icon = null
	icon_state = null
	add_parts()
	do_decals()
	if(!material)
		material = SSmaterials.get_material_by_name(MATERIAL_STEEL)
	update_icon()
	. = ..()
	spawn_mech_equipment()
	if(remote_network)
		become_remote()

/mob/living/heavy_vehicle/premade/proc/add_parts()
	if(!head && e_head)
		head = new e_head(src)
		if(e_color)
			head.color = e_color
	if(!body && e_body)
		body = new e_body(src)
		if(e_color)
			body.color = e_color
	if(!arms && e_arms)
		arms = new e_arms(src)
		if(e_color)
			arms.color = e_color
	if(!legs && e_arms)
		legs = new e_legs(src)
		if(e_color)
			legs.color = e_color

/mob/living/heavy_vehicle/premade/proc/do_decals()
	if(arms)
		arms.decal = decal
		arms.prebuild()
	if(legs)
		legs.decal = decal
		legs.prebuild()
	if(head)
		head.decal = decal
		head.prebuild()
	if(body)
		body.decal = decal
		body.prebuild()

/mob/living/heavy_vehicle/premade/proc/spawn_mech_equipment()
	if(head)
		if(h_head_utility && (HARDPOINT_HEAD_UTILITY in head.has_hardpoints))
			install_system(new h_head_utility(src), HARDPOINT_HEAD_UTILITY)
	if(body)
		if(h_back_utility && (HARDPOINT_BACK_UTILITY in body.has_hardpoints))
			install_system(new h_back_utility (src), HARDPOINT_BACK_UTILITY)
		if(h_back_combat && (HARDPOINT_BACK_COMBAT in body.has_hardpoints))
			install_system(new h_back_combat(src), HARDPOINT_BACK_COMBAT)
		if(h_back_superheavy && (HARDPOINT_BACK_SUPERHEAVY in body.has_hardpoints))
			install_system(new h_back_superheavy(src), HARDPOINT_BACK_SUPERHEAVY)
		if(h_frame_utility && (HARDPOINT_FRAME_UTILITY in body.has_hardpoints))
			install_system(new h_frame_utility(src), HARDPOINT_FRAME_UTILITY)
	if(arms)
		if(h_l_utility && (HARDPOINT_LEFT_UTILITY in arms.has_hardpoints))
			install_system(new h_l_utility(src), HARDPOINT_LEFT_UTILITY)
		if(h_r_utility && (HARDPOINT_LEFT_UTILITY in arms.has_hardpoints))
			install_system(new h_r_utility(src), HARDPOINT_RIGHT_UTILITY)
		if(h_l_combat && (HARDPOINT_LEFT_COMBAT in arms.has_hardpoints))
			install_system(new h_l_combat(src), HARDPOINT_LEFT_COMBAT)
		if(h_r_combat && (HARDPOINT_RIGHT_COMBAT in arms.has_hardpoints))
			install_system(new h_r_combat(src), HARDPOINT_RIGHT_COMBAT)

/mob/living/heavy_vehicle/premade/random
	name = "mismatched exosuit"
	desc = "It seems to have been roughly thrown together and then spraypainted a single colour."

	h_head_utility = /obj/item/mecha_equipment/light

/mob/living/heavy_vehicle/premade/random/Initialize(mapload, var/obj/structure/heavy_vehicle_frame/source_frame, var/super_random = FALSE, var/using_boring_colours = FALSE)
	var/list/use_colours
	if(using_boring_colours)
		use_colours = list(
			COLOR_DARK_GRAY,
			COLOR_GRAY40,
			COLOR_DARK_BROWN,
			COLOR_GRAY,
			COLOR_RED_GRAY,
			COLOR_BROWN,
			COLOR_GREEN_GRAY,
			COLOR_BLUE_GRAY,
			COLOR_PURPLE_GRAY,
			COLOR_BEIGE,
			COLOR_PALE_GREEN_GRAY,
			COLOR_PALE_RED_GRAY,
			COLOR_PALE_PURPLE_GRAY,
			COLOR_PALE_BLUE_GRAY,
			COLOR_SILVER,
			COLOR_GRAY80,
			COLOR_OFF_WHITE,
			COLOR_GUNMETAL,
			COLOR_HULL,
			COLOR_TITANIUM,
			COLOR_DARK_GUNMETAL,
			COLOR_BRONZE,
			COLOR_BRASS
		)
	else
		use_colours = list(
			COLOR_NAVY_BLUE,
			COLOR_GREEN,
			COLOR_DARK_GRAY,
			COLOR_MAROON,
			COLOR_PURPLE,
			COLOR_VIOLET,
			COLOR_OLIVE,
			COLOR_BROWN_ORANGE,
			COLOR_DARK_ORANGE,
			COLOR_GRAY40,
			COLOR_SEDONA,
			COLOR_DARK_BROWN,
			COLOR_BLUE,
			COLOR_DEEP_SKY_BLUE,
			COLOR_LIME,
			COLOR_CYAN,
			COLOR_TEAL,
			COLOR_RED,
			COLOR_PINK,
			COLOR_ORANGE,
			COLOR_YELLOW,
			COLOR_GRAY,
			COLOR_RED_GRAY,
			COLOR_BROWN,
			COLOR_GREEN_GRAY,
			COLOR_BLUE_GRAY,
			COLOR_SUN,
			COLOR_PURPLE_GRAY,
			COLOR_BLUE_LIGHT,
			COLOR_RED_LIGHT,
			COLOR_BEIGE,
			COLOR_PALE_GREEN_GRAY,
			COLOR_PALE_RED_GRAY,
			COLOR_PALE_PURPLE_GRAY,
			COLOR_PALE_BLUE_GRAY,
			COLOR_LUMINOL,
			COLOR_SILVER,
			COLOR_GRAY80,
			COLOR_OFF_WHITE,
			COLOR_DARK_RED,
			COLOR_BOTTLE_GREEN,
			COLOR_PALE_BTL_GREEN,
			COLOR_GUNMETAL,
			COLOR_MUZZLE_FLASH,
			COLOR_CHESTNUT,
			COLOR_BEASTY_BROWN,
			COLOR_WHEAT,
			COLOR_CYAN_BLUE,
			COLOR_LIGHT_CYAN,
			COLOR_PAKISTAN_GREEN,
			COLOR_HULL,
			COLOR_AMBER,
			COLOR_COMMAND_BLUE,
			COLOR_SKY_BLUE,
			COLOR_PALE_ORANGE,
			COLOR_CIVIE_GREEN,
			COLOR_TITANIUM,
			COLOR_DARK_GUNMETAL,
			COLOR_BRONZE,
			COLOR_BRASS,
			COLOR_INDIGO
		)
	var/mech_colour = super_random ? FALSE : pick(use_colours)
	if(!arms)
		var/list/forbidden_arm_types = list(/obj/item/mech_component/manipulators/cult, /obj/item/mech_component/manipulators/superheavy, /obj/item/mech_component/manipulators/combat)
		var/armstype = pick(subtypesof(/obj/item/mech_component/manipulators) - forbidden_arm_types)
		arms = new armstype(src)
		arms.color = mech_colour ? mech_colour : pick(use_colours)
	if(!legs)
		var/list/forbidden_leg_types = list(/obj/item/mech_component/propulsion/cult, /obj/item/mech_component/propulsion/superheavy, /obj/item/mech_component/propulsion/combat)
		var/legstype = pick(subtypesof(/obj/item/mech_component/propulsion) - forbidden_leg_types)
		legs = new legstype(src)
		if(legs.hover)
			pass_flags |= PASSRAILING
		legs.color = mech_colour ? mech_colour : pick(use_colours)
	if(!head)
		var/list/forbidden_head_types = list(/obj/item/mech_component/sensors/cult, /obj/item/mech_component/sensors/superheavy, /obj/item/mech_component/sensors/combat)
		var/headtype = pick(subtypesof(/obj/item/mech_component/sensors) - forbidden_head_types)
		head = new headtype(src)
		head.color = mech_colour ? mech_colour : pick(use_colours)
	if(!body)
		var/list/forbidden_body_types = list(/obj/item/mech_component/chassis/cult, /obj/item/mech_component/chassis/superheavy, /obj/item/mech_component/chassis/combat)
		var/bodytype = pick(subtypesof(/obj/item/mech_component/chassis) - forbidden_body_types)
		body = new bodytype(src)
		body.color = mech_colour ? mech_colour : pick(use_colours)
	update_icon()
	. = ..()

/mob/living/heavy_vehicle/premade/random/spawn_mech_equipment()
	if(prob(25))
		if(MECH_SOFTWARE_UTILITY in head.software.installed_software)
			h_frame_utility = /obj/item/mecha_equipment/clamp
			if(prob(20))
				h_back_utility = /obj/item/mecha_equipment/autolathe
		if(MECH_SOFTWARE_MEDICAL in head.software.installed_software)
			if(HARDPOINT_LEFT_UTILITY in body.has_hardpoints)
				h_l_utility = /obj/item/mecha_equipment/crisis_drone
			else
				h_back_utility = /obj/item/mecha_equipment/sleeper
		if(MECH_SOFTWARE_ENGINEERING in head.software.installed_software)
			h_r_utility = /obj/item/mecha_equipment/mounted_system/rfd
	..()

/mob/living/heavy_vehicle/premade/random/boring/Initialize(mapload, var/obj/structure/heavy_vehicle_frame/source_frame)
	. = ..(mapload, source_frame, using_boring_colours = TRUE)

/mob/living/heavy_vehicle/premade/random/extra/Initialize(mapload, var/obj/structure/heavy_vehicle_frame/source_frame)
	. = ..(mapload, source_frame, super_random = TRUE)
