/mob/living/carbon/human/LateLogin()
	..()
	update_hud()
	if(species)
		species.handle_login_special(src)
	var/datum/antagonist/antag = player_is_antag(mind, FALSE)
	if(antag)
		antag.handle_latelogin(src)

	var/icon/mouse_pointer = get_mouse_pointer()
	if(mouse_pointer)
		client.mouse_pointer_icon = mouse_pointer