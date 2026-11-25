/// Returns whether langchat is enabled for a given mob.
#define LANGCHAT_CLIENT_ENABLED(M) (M && M.client && M.client.prefs && (M.client.prefs.toggles_secondary & FLOATING_MESSAGES))

#define LANGCHAT_LONGEST_TEXT 64
#define LANGCHAT_WIDTH 96
#define LANGCHAT_MAX_ALPHA 196

// Types of message pop
#define LANGCHAT_DEFAULT_POP 0 // Normal messages.
#define LANGCHAT_PANIC_POP 1   // Fast, shaking messages.
#define LANGCHAT_FAST_POP 2    // Fast messages.

// Parameters for LANGCHAT_DEFAULT_POP
#define LANGCHAT_MESSAGE_POP_TIME 3
#define LANGCHAT_MESSAGE_POP_Y_SINK 8

// Parameters for LANGCHAT_PANIC_POP
#define LANGCHAT_MESSAGE_PANIC_POP_TIME 1
#define LANGCHAT_MESSAGE_PANIC_POP_Y_SINK 8
#define LANGCHAT_MESSAGE_PANIC_SHAKE_SIZE 6
#define LANGCHAT_MESSAGE_PANIC_SHAKE_TIMES 6
#define LANGCHAT_MESSAGE_PANIC_SHAKE_TIME_TAKEN 1

// Parameters for LANGCHAT_FAST_POP
#define LANGCHAT_MESSAGE_FAST_POP_TIME 1
#define LANGCHAT_MESSAGE_FAST_POP_Y_SINK 8

/atom/var/langchat_height = 32 // Abovetile usually
/atom/var/langchat_color = "#FFFFFF"
/atom/var/langchat_styles = ""

/// A single overhead bubble storing the text image, and the listeners it was shown to.
/datum/langchat_bubble
	var/image/bubble
	var/list/mob/listeners

/// Initializes a new bubble from a text image and a list of listeners.
/datum/langchat_bubble/New(image/bubble, list/mob/listeners)
	. = ..()
	src.bubble = bubble
	src.listeners = listeners

/datum/langchat_bubble/Destroy()
	for(var/mob/listener in listeners)
		if(listener.client)
			listener.client.images -= bubble
	bubble = null
	listeners = null
	return ..()

/// A client-private bubble positioned by the same projection map as the speaker's sprite.
/datum/langchat_bubble/stargate
	var/mob/speaker
	var/client/viewer
	var/obj/structure/stargate/gate
	var/atom/movable/screen/stargate_speech/screen_text

/// A screen object cannot be picked up by a portal's world render target.
/atom/movable/screen/stargate_speech
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/langchat_bubble/stargate/New(image/bubble, mob/speaker, client/viewer, obj/structure/stargate/gate, animation_style)
	. = ..(bubble)
	listeners = null
	src.speaker = speaker
	src.viewer = viewer
	src.gate = gate
	screen_text = new
	screen_text.appearance = bubble.appearance
	screen_text.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	src.bubble = null
	LAZYINITLIST(gate.projected_langchat)
	var/list/active = gate.projected_langchat[viewer]
	if(!active)
		active = list()
		gate.projected_langchat[viewer] = active
	active += src
	RegisterSignal(speaker, COMSIG_MOVABLE_MOVED, PROC_REF(update_position))
	RegisterSignal(speaker, COMSIG_QDELETING, PROC_REF(on_speaker_deleted))
	update_position()
	speaker.animate_style(screen_text, animation_style)

/datum/langchat_bubble/stargate/proc/update_position()
	SIGNAL_HANDLER
	if(QDELETED(viewer))
		return
	if(!screen_text)
		// Bubbles created before a hot reload still own the old world image.
		if(bubble)
			viewer.images -= bubble
		return
	var/turf/camera = get_turf(viewer.eye)
	var/turf/projected = gate.get_projected_speaker_turf(speaker, viewer)
	if(!projected || !camera || projected.z != camera.z)
		viewer.screen -= screen_text
		return
	var/across = projected.x - camera.x
	var/depth = projected.y - camera.y
	var/list/view_size = getviewsize(viewer.view)
	if(abs(across) > floor(view_size[1] / 2) || abs(depth) > floor(view_size[2] / 2))
		viewer.screen -= screen_text
		return
	var/position = "CENTER:[across * WORLD_ICON_SIZE + speaker.pixel_x],CENTER:[depth * WORLD_ICON_SIZE + speaker.pixel_y]"
	if(screen_text.screen_loc != position)
		screen_text.screen_loc = position
	if(!(screen_text in viewer.screen))
		viewer.screen += screen_text

/datum/langchat_bubble/stargate/proc/on_speaker_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/langchat_bubble/stargate/Destroy()
	UnregisterSignal(speaker, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING))
	if(!QDELETED(viewer))
		if(screen_text)
			viewer.screen -= screen_text
		if(bubble)
			viewer.images -= bubble
	QDEL_NULL(screen_text)
	var/list/active = gate.projected_langchat?[viewer]
	if(active)
		active -= src
		if(!length(active))
			gate.projected_langchat -= viewer
	viewer = null
	speaker = null
	gate = null
	listeners = null
	return ..()

/// The floating bubbles currently shown for this atom.
/atom/var/list/langchat_images

/// Drops all active bubbles for this atom.
/atom/proc/langchat_drop_images()
	QDEL_NULL_LIST(langchat_images)

/atom/proc/get_maptext_x_offset(image/maptext_image)
	return (world.icon_size / 2) - (maptext_image.maptext_width / 2)

/atom/movable/get_maptext_x_offset(image/maptext_image)
	return (bound_width / 2) - (maptext_image.maptext_width / 2)

/mob/get_maptext_x_offset(image/maptext_image)
	return (icon_size / 2) - (maptext_image.maptext_width / 2)

/// Constructs a single floating langchat bubble showing maptext_string to the given listeners.
/atom/proc/langchat_build_image(maptext_string, list/mob/listeners, override_color, animation_style = LANGCHAT_DEFAULT_POP, list/additional_styles = list("langchat"))
	if(!length(listeners))
		return

	var/image/bubble = langchat_make_image(maptext_string, override_color, additional_styles)
	for(var/mob/listener as anything in listeners)
		listener.client.images += bubble

	animate_style(bubble, animation_style)
	LAZYADD(langchat_images, new /datum/langchat_bubble(bubble, listeners))

/atom/proc/langchat_make_image(maptext_string, override_color, list/additional_styles)
	var/image/bubble = image(null, src)
	bubble.layer = 20
	bubble.plane = RUNECHAT_PLANE
	bubble.appearance_flags = NO_CLIENT_COLOR|KEEP_APART|RESET_COLOR|RESET_TRANSFORM
	bubble.maptext_y = langchat_height - LANGCHAT_MESSAGE_POP_Y_SINK
	bubble.maptext_height = 64
	bubble.alpha = 0
	bubble.color = override_color ? override_color : langchat_color
	if(appearance_flags & PIXEL_SCALE)
		bubble.appearance_flags |= PIXEL_SCALE
	langchat_configure_bubble(bubble, override_color)

	bubble.maptext = generate_text_image(maptext_string, additional_styles)
	bubble.maptext_width = LANGCHAT_WIDTH
	bubble.maptext_x = get_maptext_x_offset(bubble)
	bubble.loc = isturf(loc) ? src : recursive_holder_check(src)
	return bubble

/// Per-type appearance tweaks applied to a freshly built bubble.
/atom/proc/langchat_configure_bubble(image/bubble, override_color)
	return

/mob/abstract/ghost/langchat_configure_bubble(image/bubble, override_color)
	if(!override_color)
		bubble.color = "#c51fb7"
	bubble.appearance_flags |= RESET_ALPHA

/// Floats flat text to everybody who can see it.
/atom/proc/langchat_speech(message, list/mob/listeners, override_color, animation_style = LANGCHAT_DEFAULT_POP, list/additional_styles = list("langchat"))
	langchat_drop_images()

	var/list/mob/shown = list()
	for(var/mob/listener in listeners)
		if(!LANGCHAT_CLIENT_ENABLED(listener) || listener.ear_deaf)
			continue
		shown += listener
	if(!length(shown))
		return

	langchat_build_image(message, shown, override_color, animation_style, additional_styles)

	var/timer = (length(message) / LANGCHAT_LONGEST_TEXT) * 4 SECONDS + 2 SECONDS
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, langchat_drop_images)), timer, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)

/// Floats a say message to every listener in view. Each listener receives their own perceived text based on
/// their comprehension of the spoken languages. Identical text is grouped into a single bubble for performance.
/atom/proc/langchat_say_message(datum/say_message/msg, list/mob/listeners, override_color, animation_style = LANGCHAT_DEFAULT_POP, list/additional_styles = list("langchat"))
	langchat_drop_images()

	// Group listeners by exact text perceived.
	var/list/groups = list()
	for(var/mob/listener in listeners)
		var/perceived = langchat_perceived_text(msg, listener)
		if(!length(perceived))
			continue
		var/list/group = groups[perceived]
		if(!group)
			group = list()
			groups[perceived] = group
		group += listener
	for(var/perceived in groups)
		langchat_build_image(perceived, groups[perceived], override_color, animation_style, additional_styles)

	for(var/obj/structure/stargate/gate as anything in msg.stargate_audiences)
		if(QDELETED(gate) || !gate.preview_anchor)
			continue
		var/list/audience = msg.stargate_audiences[gate]
		for(var/mob/listener as anything in audience)
			var/datum/say_message/heard_message = audience[listener] == TRUE ? msg : audience[listener]
			var/perceived = langchat_perceived_text(heard_message, listener)
			if(!length(perceived))
				continue
			var/image/projected = langchat_make_image(perceived, override_color, additional_styles)
			LAZYADD(langchat_images, new /datum/langchat_bubble/stargate(projected, msg.speaker, listener.client, gate, animation_style))
	msg.stargate_audiences = null
	if(!length(langchat_images))
		return

	// One-off timer for duration. Disappears for all listeners at the same time.
	var/timer = (length(msg.to_string()) / LANGCHAT_LONGEST_TEXT) * 4 SECONDS + 2 SECONDS
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, langchat_drop_images)), timer, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)

/atom/proc/langchat_perceived_text(datum/say_message/msg, mob/listener)
	if(!LANGCHAT_CLIENT_ENABLED(listener))
		return
	var/clarity = listener.get_clarity(msg, feedback = FALSE)
	if(clarity == CLARITY_NONE || clarity == CLARITY_DROWSY)
		return
	var/perceived = msg.plain_text_for(listener)
	return (clarity == CLARITY_FAINT) ? stars(perceived) : perceived

/// Builds the maptext span for a floating message.
/atom/proc/generate_text_image(message, list/additional_styles = list("langchat"))
	var/list/styles = additional_styles ? additional_styles.Copy() : list()
	var/text_to_display = message
	var/use_mob_style = TRUE

	if(length(text_to_display) > LANGCHAT_LONGEST_TEXT)
		text_to_display = copytext_char(text_to_display, 1, LANGCHAT_LONGEST_TEXT + 1) + "..."
	if("emote" in styles)
		styles.Remove("emote")
		use_mob_style = FALSE
		var/image/r_icon = image('icons/ui/chat_icons.dmi', icon_state = "emote")
		text_to_display = "\icon[r_icon]&zwsp;[text_to_display]"
	if("radio" in styles)
		styles.Remove("radio")
		use_mob_style = FALSE
		var/image/r_icon = image('icons/ui/chat_icons.dmi', icon_state = "radio")
		text_to_display = "\icon[r_icon]&zwsp;[text_to_display]"

	return "<span class='center [styles.Join(" ")] [use_mob_style ? langchat_styles : ""] langchat'>[text_to_display]</span>"

/// Animates maptext on either a world image or a screen object.
/atom/proc/animate_style(bubble, animation_style = LANGCHAT_DEFAULT_POP)
	if(bubble)
		switch(animation_style)
			if(LANGCHAT_DEFAULT_POP)
				bubble:alpha = 0
				animate(bubble, pixel_y = bubble:pixel_y + LANGCHAT_MESSAGE_POP_Y_SINK, alpha = LANGCHAT_MAX_ALPHA, time = LANGCHAT_MESSAGE_POP_TIME)
			if(LANGCHAT_PANIC_POP)
				bubble:alpha = LANGCHAT_MAX_ALPHA
				animate(bubble, pixel_y = bubble:pixel_y + LANGCHAT_MESSAGE_PANIC_POP_Y_SINK, time = LANGCHAT_MESSAGE_PANIC_POP_TIME)
				animate(pixel_x = bubble:pixel_x - LANGCHAT_MESSAGE_PANIC_SHAKE_SIZE, time = LANGCHAT_MESSAGE_PANIC_SHAKE_TIME_TAKEN, easing = CUBIC_EASING)
				for(var/i = 1 to LANGCHAT_MESSAGE_PANIC_SHAKE_TIMES)
					animate(pixel_x = bubble:pixel_x + 2*LANGCHAT_MESSAGE_PANIC_SHAKE_SIZE, time = 2*LANGCHAT_MESSAGE_PANIC_SHAKE_TIME_TAKEN, easing = CUBIC_EASING)
					animate(pixel_x = bubble:pixel_x - 2*LANGCHAT_MESSAGE_PANIC_SHAKE_SIZE, time = LANGCHAT_MESSAGE_PANIC_SHAKE_TIME_TAKEN, easing = CUBIC_EASING)
				animate(pixel_x = bubble:pixel_x + LANGCHAT_MESSAGE_PANIC_SHAKE_SIZE, time = LANGCHAT_MESSAGE_PANIC_SHAKE_TIME_TAKEN, easing = CUBIC_EASING)
			if(LANGCHAT_FAST_POP)
				bubble:alpha = 0
				animate(bubble, pixel_y = bubble:pixel_y + LANGCHAT_MESSAGE_FAST_POP_Y_SINK, alpha = LANGCHAT_MAX_ALPHA, time = LANGCHAT_MESSAGE_FAST_POP_TIME)

/// Attempts to return what's holding this item if being contained by something. e.g. Cortical borer returns their host.
/proc/recursive_holder_check(obj/item/held_item, recursion_limit = 3)
	if(recursion_limit <= 0)
		return held_item
	if(!held_item.loc || isturf(held_item.loc))
		return held_item
	recursion_limit--
	return recursive_holder_check(held_item.loc, recursion_limit)
