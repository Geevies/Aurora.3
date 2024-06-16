/obj/item/circuitboard/fusion/core_control
	name = T_BOARD("fusion core controller")
	build_path = /obj/machinery/computer/fusion/core_control
	origin_tech = list(TECH_DATA = 4, TECH_ENGINEERING = 4)

/obj/item/circuitboard/kinetic_harvester
	name = T_BOARD("kinetic harvester")
	build_path = /obj/machinery/kinetic_harvester
	board_type = BOARD_MACHINE
	origin_tech = list(TECH_DATA = 4, TECH_ENGINEERING = 4, TECH_MATERIAL = 4)
	req_components = list(
		"/obj/item/stock_parts/manipulator/pico" = 2,
		"/obj/item/stock_parts/matter_bin/super" = 1,
		"/obj/item/stock_parts/console_screen" = 1,
		"/obj/item/stack/cable_coil" = 5
		)

/obj/item/circuitboard/fusion_fuel_compressor
	name = T_BOARD("fusion fuel compressor")
	build_path = /obj/machinery/fusion_fuel_compressor
	board_type = BOARD_MACHINE
	origin_tech = list(TECH_POWER = 3, TECH_ENGINEERING = 4, TECH_MATERIAL = 4)
	req_components = list(
							"/obj/item/stock_parts/manipulator/pico" = 2,
							"/obj/item/stock_parts/matter_bin/super" = 2,
							"/obj/item/stock_parts/console_screen" = 1,
							"/obj/item/stack/cable_coil" = 5
							)

/obj/item/circuitboard/fusion_fuel_control
	name = T_BOARD("fusion fuel controller")
	build_path = /obj/machinery/computer/fusion/fuel_control
	origin_tech = list(TECH_DATA = 4, TECH_ENGINEERING = 4)

/obj/item/circuitboard/gyrotron_control
	name = T_BOARD("gyrotron controller")
	build_path = /obj/machinery/computer/fusion/gyrotron
	origin_tech = list(TECH_DATA = 4, TECH_ENGINEERING = 4)

/obj/item/circuitboard/fusion_core
	name = T_BOARD("fusion core")
	build_path = /obj/machinery/power/fusion_core
	board_type = BOARD_MACHINE
	origin_tech = list(TECH_BLUESPACE = 2, TECH_MAGNET = 4, TECH_POWER = 4)
	req_components = list(
							"/obj/item/stock_parts/manipulator/pico" = 2,
							"/obj/item/stock_parts/micro_laser/ultra" = 1,
							"/obj/item/stock_parts/subspace/crystal" = 1,
							"/obj/item/stock_parts/console_screen" = 1,
							"/obj/item/stack/cable_coil" = 5
							)

/obj/item/circuitboard/fusion_injector
	name = T_BOARD("fusion fuel injector")
	build_path = /obj/machinery/fusion_fuel_injector
	board_type = BOARD_MACHINE
	origin_tech = list(TECH_POWER = 3, TECH_ENGINEERING = 4, TECH_MATERIAL = 4)
	req_components = list(
							"/obj/item/stock_parts/manipulator/pico" = 2,
							"/obj/item/stock_parts/scanning_module/phasic" = 1,
							"/obj/item/stock_parts/matter_bin/super" = 1,
							"/obj/item/stock_parts/console_screen" = 1,
							"/obj/item/stack/cable_coil" = 5
							)

/obj/item/circuitboard/gyrotron
	name = T_BOARD("gyrotron")
	build_path = /obj/machinery/power/emitter/gyrotron
	board_type = BOARD_MACHINE
	origin_tech = list(TECH_POWER = 4, TECH_ENGINEERING = 4)
	req_components = list(
							"/obj/item/stack/cable_coil" = 20,
							"/obj/item/stock_parts/micro_laser/ultra" = 2
							)

/datum/design/circuit/fusion
	name = "fusion core control console"
	build_path = /obj/item/circuitboard/fusion/core_control
	req_tech = list(TECH_POWER = 3, TECH_ENGINEERING = 3, TECH_MATERIAL = 3)

/datum/design/circuit/fusion/fuel_compressor
	name = "fusion fuel compressor"
	build_path = /obj/item/circuitboard/fusion_fuel_compressor

/datum/design/circuit/fusion/fuel_control
	name = "fusion fuel control console"
	build_path = /obj/item/circuitboard/fusion_fuel_control

/datum/design/circuit/fusion/gyrotron_control
	name = "gyrotron control console"
	build_path = /obj/item/circuitboard/gyrotron_control

/datum/design/circuit/fusion/core
	name = "fusion core"
	build_path = /obj/item/circuitboard/fusion_core

/datum/design/circuit/fusion/injector
	name = "fusion fuel injector"
	build_path = /obj/item/circuitboard/fusion_injector

/datum/design/circuit/fusion/kinetic_harvester
	name = "fusion toroid kinetic harvester"
	build_path = /obj/item/circuitboard/kinetic_harvester
	req_tech = list(TECH_DATA = 4, TECH_ENGINEERING = 4, TECH_MATERIAL = 4)

/datum/design/circuit/fusion/gyrotron
	name = "gyrotron"
	build_path = /obj/item/circuitboard/gyrotron
