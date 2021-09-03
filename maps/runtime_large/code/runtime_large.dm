/datum/map/runtime_large
	name = "Runtime Station"
	full_name = "Runtime Debugging Station"
	path = "runtime_large"
	lobby_icons = list('icons/misc/titlescreens/runtime/developers.dmi')
	lobby_transitions = 10 SECONDS

	station_levels = list(1)
	admin_levels = list()
	contact_levels = list(1)
	player_levels = list(1)
	accessible_z_levels = list(1)

	station_name = "NSS Runtime"
	station_short = "Runtime"
	dock_name = "singulo"
	boss_name = "#code_dungeon"
	boss_short = "Coders"
	company_name = "BanoTarsen"
	company_short = "BT"

	use_overmap = TRUE

	station_networks = list(
		NETWORK_CIVILIAN_MAIN,
		NETWORK_COMMAND,
		NETWORK_ENGINEERING,
	)

/datum/map/runtime_large/finalize_load()
	var/datum/map_template/kataphract_ship/KS = new
	KS.load_new_z()