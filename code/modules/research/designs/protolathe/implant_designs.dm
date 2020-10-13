/datum/design/item/implant
	materials = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 50)
	p_category = "Implantable Biocircuit Designs"

/datum/design/item/implant/chemical
	name = "Chemical"
	req_tech = list('materials':2,'biotech':3)
	build_path = /obj/item/implantcase/chem

/datum/design/item/implant/freedom
	name = "Freedom"
	req_tech = list('syndicate':2,'biotech':3)
	build_path = /obj/item/implantcase/freedom