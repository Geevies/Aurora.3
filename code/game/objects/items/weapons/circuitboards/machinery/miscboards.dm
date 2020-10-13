#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it! 
#endif

//Stuff that doesn't fit into any category goes here

/obj/item/circuitboard/aicore
	name = T_BOARD("AI core")
	origin_tech = "{'programming':4,'biotech':2}"
	board_type = "other"

/obj/item/circuitboard/sleeper
	name = T_BOARD("Sleeper")
	desc = "The circuitboard for a sleeper."
	build_path = /obj/machinery/sleeper
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 2,
							"/obj/item/stock_parts/scanning_module" = 2,
							"/obj/item/stock_parts/console_screen" = 1,
							"/obj/item/reagent_containers/glass/beaker/large" = 1)

/obj/item/circuitboard/cryotube
	name = T_BOARD("Cryo Cell")
	desc = "The circuitboard for a cryo tube."
	build_path = /obj/machinery/atmospherics/unary/cryo_cell
	origin_tech = "{'magnets':2,'engineering':3}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/scanning_module" = 2,
							"/obj/item/stock_parts/console_screen" = 1,
							"/obj/item/reagent_containers/glass/beaker/large" = 1)


/obj/item/circuitboard/bodyscanner
	name = T_BOARD("Body Scanner Machine")
	desc = "The circuitboard for a body scanner machine."
	build_path = /obj/machinery/bodyscanner
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 1,
							"/obj/item/stock_parts/scanning_module" = 1,
							"/obj/item/device/healthanalyzer" = 1)

/obj/item/circuitboard/bodyscannerconsole
	name = T_BOARD("Body Scanner Console")
	desc = "The circuitboard for a body scanner console."
	build_path = /obj/machinery/body_scanconsole
	origin_tech = "{'programming':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/scanning_module" = 2,
							"/obj/item/stock_parts/console_screen" = 1)

/obj/item/circuitboard/requestconsole
	name = T_BOARD("Request Console")
	desc = "The circuitboard for a body scanner console."
	build_path = /obj/machinery/requests_console
	origin_tech = "{'programming':3,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 1,
							"/obj/item/stock_parts/console_screen" = 1)

/obj/item/circuitboard/optable
	name = T_BOARD("Operation Table")
	desc = "The circuitboard for a operation table."
	build_path = /obj/machinery/optable
	origin_tech = "{'magnets':1,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/scanning_module" = 1)

/obj/item/circuitboard/smartfridge
	name = T_BOARD("Smart Fridge")
	desc = "The circuitboard for a smart fridge."
	build_path = /obj/machinery/smartfridge
	origin_tech = "{'magnets':1,'engineering':3}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/manipulator" = 3)


/obj/item/circuitboard/refiner
	name = T_BOARD("ore processor")
	desc = "The circuitboard for an ore processing machine."
	build_path = /obj/machinery/mineral/processing_unit
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "other" // change this to machine if you want it to be buildable
	req_components = list(
							/obj/item/stock_parts/capacitor = 2,
							/obj/item/stock_parts/scanning_module = 1,
							/obj/item/stock_parts/matter_bin = 1,
							/obj/item/stock_parts/micro_laser = 2)

/obj/item/circuitboard/oven
	name = T_BOARD("oven")
	desc = "The circuitboard for an oven."
	build_path = /obj/machinery/appliance/cooker/oven
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 3,
							"/obj/item/stock_parts/scanning_module" = 1,
							"/obj/item/stock_parts/matter_bin" = 2)

/obj/item/circuitboard/fryer
	name = T_BOARD("deep fryer")
	desc = "The circuitboard for a deep fryer."
	build_path = /obj/machinery/appliance/cooker/fryer
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 3,
							"/obj/item/stock_parts/scanning_module" = 1,
							"/obj/item/stock_parts/matter_bin" = 2)

/obj/item/circuitboard/stove
	name = T_BOARD("stove")
	desc = "The circuitboard for a stove."
	build_path = /obj/machinery/appliance/cooker/stove
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 3,
							"/obj/item/stock_parts/scanning_module" = 1,
							"/obj/item/stock_parts/matter_bin" = 2)

/obj/item/circuitboard/cerealmaker
	name = T_BOARD("cereal maker")
	desc = "The circuitboard for a cereal maker."
	build_path = /obj/machinery/appliance/mixer/cereal
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 3,
							"/obj/item/stock_parts/scanning_module" = 1,
							"/obj/item/stock_parts/matter_bin" = 2)

/obj/item/circuitboard/candymachine
	name = T_BOARD("candy machine")
	desc = "The circuitboard for a candy machine."
	build_path = /obj/machinery/appliance/mixer/candy
	origin_tech = "{'magnets':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 3,
							"/obj/item/stock_parts/scanning_module" = 1,
							"/obj/item/stock_parts/matter_bin" = 2)

/obj/item/circuitboard/holopad
	name = T_BOARD("Holopad")
	desc = "The circuitboard for a holopad."
	build_path = /obj/machinery/hologram/holopad
	origin_tech = "{'magnets':3,'engineering':2}"
	board_type = "machine" 
	req_components = list(
							"/obj/item/stock_parts/capacitor" = 2,
							"/obj/item/stock_parts/scanning_module" = 1)

/obj/item/circuitboard/crystelpodconsole
	name = T_BOARD("Crystal Therapy Pod Console")
	desc = "The circuitboard for a crystal therapy pod console."
	build_path = /obj/machinery/chakraconsole
	origin_tech = "{'programming':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/scanning_module" = 2,
							"/obj/item/stock_parts/capacitor" = 1)

/obj/item/circuitboard/crystelpod
	name = T_BOARD("Crystal Therapy Pod")
	desc = "The circuitboard for a crystal therapy pod."
	build_path = /obj/machinery/chakrapod
	origin_tech = "{'programming':2,'engineering':2}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/scanning_module" = 2,
							"/obj/item/stock_parts/capacitor" = 2)

/obj/item/circuitboard/weapons_analyzer
	name = T_BOARD("Weapons Analyzer")
	desc = "The circuitboard for a weapons analyzer."
	build_path = /obj/machinery/weapons_analyzer
	origin_tech = "{'programming':3,'engineering':4,'combat':3}"
	board_type = "machine"
	req_components = list(
							"/obj/item/stock_parts/scanning_module" = 2,
							"/obj/item/stock_parts/capacitor" = 1,
							"/obj/item/stock_parts/console_screen" = 1)