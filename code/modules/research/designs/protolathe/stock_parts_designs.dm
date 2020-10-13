/datum/design/item/stock_part
	p_category = "Stock Parts Designs"

/datum/design/item/stock_part/AssembleDesignDesc()
	..()
	var/obj/item/stock_parts/build_item = build_path
	desc += " It has a rating of [initial(build_item.rating)]."
	if(initial(build_item.rating) > 1)
		desc += " It is an upgraded variant of \a [initial(build_item.parent_stock_name)]."

/datum/design/item/stock_part/basic_capacitor
	req_tech = list('powerstorage':1)
	materials = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 50)
	build_path = /obj/item/stock_parts/capacitor

/datum/design/item/stock_part/adv_capacitor
	req_tech = list('powerstorage':3)
	materials = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 50)
	build_path = /obj/item/stock_parts/capacitor/adv

/datum/design/item/stock_part/super_capacitor
	req_tech = list('powerstorage':5,'materials':4)
	materials = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 50, MATERIAL_GOLD = 20)
	build_path = /obj/item/stock_parts/capacitor/super

/datum/design/item/stock_part/micro_mani
	req_tech = list('materials':1,'programming':1)
	materials = list(DEFAULT_WALL_MATERIAL = 30)
	build_path = /obj/item/stock_parts/manipulator

/datum/design/item/stock_part/nano_mani
	req_tech = list('materials':3,'programming':2)
	materials = list(DEFAULT_WALL_MATERIAL = 30)
	build_path = /obj/item/stock_parts/manipulator/nano

/datum/design/item/stock_part/pico_mani
	req_tech = list('materials':5,'programming':2)
	materials = list(DEFAULT_WALL_MATERIAL = 30)
	build_path = /obj/item/stock_parts/manipulator/pico

/datum/design/item/stock_part/basic_matter_bin
	req_tech = list('materials':1)
	materials = list(DEFAULT_WALL_MATERIAL = 80)
	build_path = /obj/item/stock_parts/matter_bin

/datum/design/item/stock_part/adv_matter_bin
	req_tech = list('materials':3)
	materials = list(DEFAULT_WALL_MATERIAL = 80)
	build_path = /obj/item/stock_parts/matter_bin/adv

/datum/design/item/stock_part/super_matter_bin
	req_tech = list('materials':5)
	materials = list(DEFAULT_WALL_MATERIAL = 80)
	build_path = /obj/item/stock_parts/matter_bin/super

/datum/design/item/stock_part/basic_micro_laser
	req_tech = list('magnets':1)
	materials = list(DEFAULT_WALL_MATERIAL = 10, MATERIAL_GLASS = 20)
	build_path = /obj/item/stock_parts/micro_laser

/datum/design/item/stock_part/high_micro_laser
	req_tech = list('magnets':3)
	materials = list(DEFAULT_WALL_MATERIAL = 10, MATERIAL_GLASS = 20)
	build_path = /obj/item/stock_parts/micro_laser/high

/datum/design/item/stock_part/ultra_micro_laser
	req_tech = list('magnets':5,'materials':5)
	materials = list(DEFAULT_WALL_MATERIAL = 10, MATERIAL_GLASS = 20, MATERIAL_URANIUM = 10)
	build_path = /obj/item/stock_parts/micro_laser/ultra

/datum/design/item/stock_part/basic_sensor
	req_tech = list('magnets':1)
	materials = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 20)
	build_path = /obj/item/stock_parts/scanning_module

/datum/design/item/stock_part/adv_sensor
	req_tech = list('magnets':3)
	materials = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 20)
	build_path = /obj/item/stock_parts/scanning_module/adv

/datum/design/item/stock_part/phasic_sensor
	req_tech = list('magnets':5,'materials':3)
	materials = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 20, MATERIAL_SILVER = 10)
	build_path = /obj/item/stock_parts/scanning_module/phasic

/datum/design/item/stock_part/rped
	desc = "A special mechanical device made to store, sort, and apply standard machine parts."
	req_tech = list('engineering':3,'materials':3)
	materials = list(DEFAULT_WALL_MATERIAL = 15000, MATERIAL_GLASS = 5000)
	build_path = /obj/item/storage/part_replacer

/datum/design/item/stock_part/subspace_ansible
	desc = "A component used in telecomms machinery construction."
	req_tech = list('programming':3,'magnets':4,'materials':4,'bluespace':2)
	materials = list(DEFAULT_WALL_MATERIAL = 80, MATERIAL_SILVER = 20)
	build_path = /obj/item/stock_parts/subspace/ansible

/datum/design/item/stock_part/hyperwave_filter
	desc = "A component used in telecomms machinery construction."
	req_tech = list('programming':3,'magnets':3)
	materials = list(DEFAULT_WALL_MATERIAL = 40, MATERIAL_SILVER = 10)
	build_path = /obj/item/stock_parts/subspace/filter

/datum/design/item/stock_part/subspace_amplifier
	desc = "A component used in telecomms machinery construction."
	req_tech = list('programming':3,'magnets':4,'materials':4,'bluespace':2)
	materials = list(DEFAULT_WALL_MATERIAL = 10, MATERIAL_GOLD = 30, MATERIAL_URANIUM = 15)
	build_path = /obj/item/stock_parts/subspace/amplifier

/datum/design/item/stock_part/subspace_treatment
	desc = "A component used in telecomms machinery construction."
	req_tech = list('programming':3,'magnets':2,'materials':4,'bluespace':2)
	materials = list(DEFAULT_WALL_MATERIAL = 10, MATERIAL_SILVER = 20)
	build_path = /obj/item/stock_parts/subspace/treatment

/datum/design/item/stock_part/subspace_analyzer
	desc = "A component used in telecomms machinery construction."
	req_tech = list('programming':3,'magnets':4,'materials':4,'bluespace':2)
	materials = list(DEFAULT_WALL_MATERIAL = 10, MATERIAL_GOLD = 15)
	build_path = /obj/item/stock_parts/subspace/analyzer

/datum/design/item/stock_part/subspace_crystal
	desc = "A component used in telecomms machinery construction."
	req_tech = list('magnets':4,'materials':4,'bluespace':2)
	materials = list(MATERIAL_GLASS = 1000, MATERIAL_SILVER = 20, MATERIAL_GOLD = 20)
	build_path = /obj/item/stock_parts/subspace/crystal

/datum/design/item/stock_part/subspace_transmitter
	desc = "A component used in telecomms machinery construction."
	req_tech = list('magnets':5,'materials':5,'bluespace':3)
	materials = list(MATERIAL_GLASS = 100, MATERIAL_SILVER = 10, MATERIAL_URANIUM = 15)
	build_path = /obj/item/stock_parts/subspace/transmitter