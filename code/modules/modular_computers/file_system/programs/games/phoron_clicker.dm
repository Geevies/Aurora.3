#define UIDEBUG 1

/datum/computer_file/program/phoron_clicker
	filename = "phoronclicker"
	filedesc = "Phoron Clicker"
	extended_desc = "One of the hottest new Ingi Usang Entertainment Company video games, this new installment has you collecting phoron to get rich quick!"
	program_icon_state = "game"
	color = LIGHT_COLOR_BLUE
	size = 4
	requires_ntnet = FALSE
	available_on_ntnet = TRUE
	usage_flags = PROGRAM_ALL
	var/phoron_count = 0
	var/per_second = 0
	var/last_phoron_increase = 0

/datum/computer_file/program/phoron_clicker/ui_interact(var/mob/user)
	var/datum/vueui/ui = SSvueui.get_open_ui(user, src)
	if(!ui)
		ui = new /datum/vueui/modularcomputer(user, src, "mcomputer-games-phoronclicker", 650, 500, filedesc)
		ui.auto_update_content = TRUE
	ui.open()

/datum/computer_file/program/phoron_clicker/vueui_transfer(oldobj)
	. = FALSE
	var/uis = SSvueui.transfer_uis(oldobj, src, "mcomputer-games-phoronclicker", 650, 500, filedesc)
	for(var/tui in uis)
		var/datum/vueui/ui = tui
		ui.auto_update_content = TRUE
		. = TRUE

/datum/computer_file/program/phoron_clicker/vueui_data_change(var/list/data, var/mob/user, var/datum/vueui/ui)
	. = ..()
	data = . || data || list()

	// Gather data for computer header
	var/headerdata = get_header_data(data["_PC"])
	if(headerdata)
		data["_PC"] = headerdata
		. = data

	if(!data["phoron_count"])
		data["phoron_count"] = phoron_count

	phoron_count = data["phoron_count"]
	if(!last_phoron_increase)
		last_phoron_increase = world.time
	var/seconds_passed = (world.time - last_phoron_increase) / 10
	phoron_count += seconds_passed * per_second
	last_phoron_increase = world.time
	data["phoron_count"] = phoron_count

	data["per_second"] = per_second

	return data