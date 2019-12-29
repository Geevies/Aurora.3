/obj/item/stellascope
	name = "stellascope"
	desc = "An antique and delicate looking instrument used to study the stars."
	icon = 'icons/obj/skrell_items.dmi'
	icon_state = "starscope"
	w_class = 1
	matter = list("glass" = 200)
	drop_sound = 'sound/items/drop/glass.ogg'
	var/list/constellations = list("Island", "Hatching Egg", "Star Chanter", "Jiu'x'klua", "Stormcloud", "Gnarled Tree", "Poet", "Bloated Toad", "Qu'Poxiii", "Fisher")
	var/selected_constellation
	var/projection_ready = TRUE

/obj/item/stellascope/Initialize()
	. = ..()
	pick_constellation()

/obj/item/stellascope/examine(mob/user)
	..(user)
	to_chat(user, "\The [src] displays the \"[selected_constellation]\".")

/obj/item/stellascope/throw_impact(atom/hit_atom)
	..()
	visible_message("<span class='notice'>\The [src] lands on \the [pick_constellation()].</span>")

/obj/item/stellascope/attack_self(mob/user as mob)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(isskrell(H))
			H.visible_message("<span class='notice'>\The [H] holds the brassy instrument up to \his eye and peers at something unseen.</span>",
							"<span class='notice'>You see the starry edge of srom floating on the void of space.</span>")
			if(projection_ready)
				new/obj/effect/temp_visual/constellation (get_turf(user))
				projection_ready = FALSE
				addtimer(CALLBACK(src, .proc/rearm), 30 SECONDS)


/obj/item/stellascope/proc/rearm()
	projection_ready = TRUE

/obj/item/stellascope/proc/pick_constellation()
	var/chosen_constellation = pick(constellations)
	selected_constellation = chosen_constellation
	return chosen_constellation

/obj/effect/temp_visual/constellation
	name = "starry projection"
	desc = "A holographic projection of star system."
	icon = 'icons/obj/skrell_items.dmi'
	icon_state = "starprojection"
	mouse_opacity = TRUE
	duration = 30 SECONDS
	layer = LIGHTING_LAYER + 0.1
	light_power = 1
	light_range = 1
	light_color = LIGHT_COLOR_HALOGEN

/obj/effect/temp_visual/constellation/attackby(obj/item/W as obj, mob/user as mob)
	visible_message("<span class='notice'>\The [src] vanishes!</span>")
	qdel(src)
	return

/obj/effect/temp_visual/constellation/attackby(obj/item/W as obj, mob/user as mob)
	visible_message("<span class='notice'>\The [src] vanishes!</span>")
	qdel(src)
	return

/obj/effect/temp_visual/constellation/attack_hand(mob/user as mob)
	if(user.a_intent == I_HURT)
		visible_message("<span class='notice'>\The [src] vanishes!</span>")
		qdel(src)
		return

/obj/item/skrell_projector
	name = "nralakk projector"
	desc = "A projector meant to help Federation Skrell feel like theyre carrying home with them wherever they go. It looks very complex."
	icon = 'icons/obj/skrell_items.dmi'
	icon_state = "projector"
	w_class = 1
	matter = list("glass" = 200)
	drop_sound = 'sound/items/drop/glass.ogg'
	var/list/worlds_selection = list("Xrim", "Kal'lo", "Nralakk")
	var/selected_world
	var/working = FALSE

/obj/item/skrell_projector/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/item/skrell_projector/examine(mob/user)
	..(user)
	if(selected_world && working)
		to_chat(user, "\The [src] displays the world of [selected_world].")

/obj/item/skrell_projector/attack_self(mob/user as mob)
	working = !working

	if(working)
		var/choice = input("You change the projector's world to;","Change the projector's world.") as null|anything in worlds_selection
		apply_world(choice)
		START_PROCESSING(SSprocessing, src)
	else
		set_light(0)
		working = FALSE
		icon_state = initial(icon_state)
		STOP_PROCESSING(SSprocessing, src)

/obj/item/skrell_projector/proc/apply_world(var/choice)
	set_light(2)
	if(choice)
		selected_world = choice

	switch(choice)

		if("Xrim")
			icon_state = "projector_pink"
			light_color = LIGHT_COLOR_PINK

		if("Kal'lo")
			icon_state = "projector_blue"
			light_color = LIGHT_COLOR_BLUE

		if("Nralakk")
			icon_state = "projector_purple"
			light_color = LIGHT_COLOR_PURPLE
		else
			working = FALSE
			set_light(0)
			icon_state = initial(icon_state)
			STOP_PROCESSING(SSprocessing, src)

/obj/item/skrell_projector/process()
	if(!selected_world)
		return

	if(prob(10))
		var/hologram_message
		switch(selected_world)

			if("Xrim")
				hologram_message = pick("You hear strange, warbling birdsong.",
										" You see sunlight filtered through overgrown trees projected on the ceiling.",
										"You see large insects hovering above the projector.")

			if("Kal'lo")
				hologram_message = pick("You see the ocean surface projected on the ceiling.",
										"You see colorful fish swimming above the projector.",
										"You hear the muffled sound of waves breaking above you.")

			if("Nralakk")
				hologram_message = pick("You see the Jargon system sky projected on the ceiling.",
										"You see planets slowly orbiting Nralakk above the projector.",
										"You hear faint ceremonial hymms.")

		if(hologram_message)
			visible_message("<span class='notice'>[hologram_message]</span>")

/obj/item/skrell_puzzle_box
	name = "puzzle box"
	desc = "A puzzle box of seeming Skrellian design. It appears to have a microphone near the locked opening latch."
	description_info = "Click and drag the box' sprite to transfer it to your hands, if one of them are empty. Use this box while in it's in your active hand to activate the open prompt. When it's unlocked and open, you can use it in-hand again to lock it again, or attack it with a different empty hand to pull out the item contained within. When the box is open and empty, you can click it with an item of a small size to store it within."
	icon = 'icons/obj/skrell_items.dmi'
	icon_state = "lockbox"
	contained_sprite = TRUE
	var/obj/item/contained_item = /obj/item/toy/crossbow // generic item until something cool can be put in
	var/opening_message = "OpenSaysMe"
	var/state = 0 // 0 is locked, 1 is unlocked, 2 is empty

/obj/item/skrell_puzzle_box/Initialize()
	..()
	contained_item = new contained_item(src)

/obj/item/skrell_puzzle_box/attack_self(var/mob/user)
	if(state == 0)
		if(!ishuman(user))
			to_chat(user, span("notice", "You don't know how to operate this!"))
			return
		var/mob/living/carbon/human/H = user
		var/message = sanitize(input(H, "Whisper into the puzzlebox' microphone.") as text|null)
		if(!message)
			return

		H.whisper_say(message)

		if(findtext(message, opening_message))
			visible_message(span("warning", "The box chimes and springs open!"))
			if(contained_item)
				to_chat(user, span("notice", "You think you can use your other hand to pull the contained item out now."))
				update_state(1)
			else
				to_chat(user, span("notice", "You notice the puzzle box is empty!"))
				update_state(2)
		else
			visible_message(span("warning", "The box buzzes, rejecting the answer."))
	else
		visible_message(span("notice", "The puzzlebox locks shut."))
		update_state(0)

/obj/item/skrell_puzzle_box/attack_hand(var/mob/user)
	switch(state)
		if(0)
			attack_self(user)
		if(1)
			to_chat(user, span("notice", "You reach in and pull out the item contained within."))
			update_state(2)
			user.put_in_hands(contained_item)
			contained_item = null
		if(2)
			to_chat(user, span("notice", "You reach into the open puzzlebox and find it woefully empty."))

/obj/item/skrell_puzzle_box/attackby(var/obj/item/C, var/mob/user)
	switch(state)
		if(0)
			to_chat(user, span("notice", "The box is locked, \the [C.name] has no effect."))
		if(1)
			to_chat(user, span("notice", "There's something in the box already!"))
		if(2)
			if(C.w_class >= ITEMSIZE_NORMAL)
				to_chat(user, span("notice", "\The [C.name] is too big for \the [src]!"))
			else
				to_chat(user, span("notice", "You put \the [C.name] into \the [src]."))
				contained_item = C
				user.drop_from_inventory(C, src)
				update_state(1)

// Extreme shitcode copied from surgery trays. We should really standardize this with a proc.
/obj/item/skrell_puzzle_box/MouseDrop(var/mob/user)
	if((user && (!use_check(user))) && (user.contents.Find(src) || in_range(src, user)))
		if(ishuman(user) && !user.get_active_hand())
			var/mob/living/carbon/human/H = user
			var/obj/item/organ/external/temp = H.organs_by_name[BP_R_HAND]

			if(H.hand)
				temp = H.organs_by_name[BP_L_HAND]
			if(temp && !temp.is_usable())
				to_chat(user, span("notice", "You try to move your [temp.name], but cannot!"))
				return

			to_chat(user, span("notice", "You pick up \the [src]."))
			pixel_x = 0
			pixel_y = 0
			forceMove(get_turf(user))
			user.put_in_hands(src)

	return

/obj/item/skrell_puzzle_box/proc/update_state(var/newstate)
	switch(newstate)
		if(0)
			state = 0
			icon_state = "lockbox"
			desc = "A puzzle box of seeming Skrellian design. It appears to have a microphone near the locked opening latch."
		if(1)
			state = 1
			icon_state = "unlockbox"
			desc = "A puzzle box of seeming Skrellian design. It appears to have a microphone near the opening latch. It is open."
		if(2)
			state = 2
			icon_state = "unlockbox_empty"
			desc = "A puzzle box of seeming Skrellian design. It appears to have a microphone near the opening latch. It is open and the lights are off."

/obj/item/skrell_puzzle_box/special
	contained_item = /obj/item/paper
	opening_message = "Qu&#39;Pluux"

/obj/item/skrell_puzzle_box/Initialize()
	..()
	if(istype(contained_item, /obj/item/paper))
		var/obj/item/paper/paper = contained_item
		paper.set_content("secret message", "\[hr\]\[center\]You see an encoded image printed on this piece of paper.\[/center\]\[center\]https://i.imgur.com/HYvWgty.png\[/center\]\[hr\]")