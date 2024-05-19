/datum/component/overhead_emote
	/// the mob with the emote
	var/mob/emote_mob

	/// path of relevant overhead emote singleton
	var/emote_type

	/// the image added above the mob during the emote
	var/image/emote_image

/datum/component/overhead_emote/Initialize(var/set_emote_type, var/mob/victim)
	emote_mob = parent
	emote_type = set_emote_type

	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(remove_from_mob))

	var/singleton/overhead_emote/emote = GET_SINGLETON(emote_type)

	emote_image = emote.get_image()
	emote_mob.AddOverlays(emote_image)

	emote.start_emote(parent, victim)

/datum/component/overhead_emote/proc/remove_from_mob()
	emote_mob.CutOverlays(emote_image)
	RemoveComponent()

/singleton/overhead_emote
	abstract_type = /singleton/overhead_emote

	var/icon = 'icons/mob/overhead_emote.dmi'
	var/icon_state = "abstract"

	var/emote_description = "abstract"
	var/emote_sound

/singleton/overhead_emote/proc/get_image()
	var/image/image = image(icon, icon_state)
	image.pixel_y = 26
	return image

/singleton/overhead_emote/proc/start_emote(var/mob/parent, var/mob/victim)
	var/others_message
	if(victim)
		others_message = "<b>[parent]</b> lifts their hand to [emote_description] [victim]!"
	else
		others_message = "<b>[parent]</b> lifts their hand for a [emote_description]!"

	var/self_message
	if(victim)
		self_message = SPAN_NOTICE("You lift your hand to [emote_description] [victim]!")
	else
		self_message = SPAN_NOTICE("You lift your hand for a [emote_description]!")

	parent.visible_message(others_message, self_message)

/singleton/overhead_emote/proc/reciprocate_emote(var/mob/reciprocator, var/mob/original, var/reciprocating_emote_path)
	var/datum/component/overhead_emote/original_emote_component = original.GetComponent(/datum/component/overhead_emote)
	var/singleton/overhead_emote/original_emote = original_emote_component.emote_type

	if(original_emote.type != reciprocating_emote_path)
		fail_emote(reciprocator, original, original_emote_component, original_emote, reciprocating_emote_path)
		return

	var/others_message = "<b>[reciprocator]</b> lifts their to meet [original]'s, delivering a stunning [emote_description]!"
	var/self_message = SPAN_NOTICE("You lift your hand to meet [original]'s, delivering a stunning [emote_description]!")
	reciprocator.visible_message(others_message, self_message)

	if(emote_sound)
		playsound(reciprocator.loc, emote_sound, 30, 1)

	original_emote_component.remove_from_mob()

/singleton/overhead_emote/proc/fail_emote(var/mob/reciprocator, var/mob/original, var/datum/component/overhead_emote/original_emote_component, var/singleton/overhead_emote/original_emote, var/fail_emote_path)
	var/singleton/overhead_emote/fail_emote = GET_SINGLETON(fail_emote_path)

	var/others_message = "<b>[reciprocator]</b> lifts their to meet [original]'s, who was expecting a [original_emote.emote_description], but received a [fail_emote.emote_description] instead."
	var/self_message = SPAN_NOTICE("You lift your hand to meet [original]'s, who was expecting a [original_emote.emote_description], but received a [fail_emote.emote_description] instead.")
	reciprocator.visible_message(others_message, self_message)

	playsound(reciprocator.loc, /singleton/sound_category/punchmiss_sound, 30, 1)

	original_emote_component.remove_from_mob()


/singleton/overhead_emote/highfive
	icon_state = "emote_highfive"
	emote_description = "high-five"
	emote_sound = 'sound/effects/snap.ogg'

/singleton/overhead_emote/fistbump
	icon_state = "emote_fistbump"
	emote_description = "fist-bump"
	emote_sound = 'sound/weapons/Genhit.ogg'
