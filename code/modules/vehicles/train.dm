/obj/vehicle/train
	name = "train"
	dir = EAST

	move_delay = 1

	health = 100
	maxhealth = 100
	fire_dam_coeff = 0.7
	brute_dam_coeff = 0.5

	var/passenger_allowed = TRUE

	var/active_engines = 0
	var/train_length = 0

	var/obj/vehicle/train/lead
	var/obj/vehicle/train/tow

	can_hold_mob = TRUE


//-------------------------------------------
// Standard procs
//-------------------------------------------
/obj/vehicle/train/Initialize()
	. = ..()
	for(var/obj/vehicle/train/T in orange(1, src))
		latch(T)

/obj/vehicle/train/examine(mob/user)
	. = ..()
	if(lead)
		to_chat(user, span("notice", "It is being towed by \the [lead]."))
	if(tow)
		to_chat(user, span("notice", "It is towing \the [tow]."))

/obj/vehicle/train/Move()
	var/old_loc = get_turf(src)
	if(..())
		if(tow)
			tow.Move(old_loc)
		return TRUE
	else
		if(lead)
			unattach()
		return FALSE

/obj/vehicle/train/CollidedWith()
	if(tow || lead)
		return
	..()

/obj/vehicle/train/Collide(atom/Obstacle)
	. = ..()
	if(!istype(Obstacle, /atom/movable))
		return
	var/atom/movable/A = Obstacle

	if(istype(A, /obj/vehicle/train))
		var/obj/vehicle/train/T = A
		if(T.tow || T.lead) // don't push things that are attached
			return

	if(!A.anchored)
		var/turf/T = get_step(A, dir)
		if(isturf(T))
			A.Move(T) //bump things away when hit

	if(emagged)
		if(istype(A, /mob/living))
			var/mob/living/M = A
			visible_message(span("warning", "\The [src] knocks over [M]!"))
			var/def_zone = ran_zone()
			M.apply_effects(5, 5) //knock people down if you hit them
			M.apply_damage(22 / move_delay, BRUTE, def_zone, M.run_armor_check(def_zone, "melee")) // and do damage according to how fast the train is going
			if(istype(load, /mob/living/carbon/human))
				var/mob/living/D = load
				to_chat(D, span("warning", "You run over [M] with \the [src]!"))
				msg_admin_attack("[D.name] ([D.ckey]) ran over [M.name] ([M.ckey]) with \the [src]. (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[src.x];Y=[src.y];Z=[src.z]'>JMP</a>)", ckey = key_name(D), ckey_target = key_name(M))


//-------------------------------------------
// Vehicle procs
//-------------------------------------------
/obj/vehicle/train/explode()
	if(tow)
		tow.unattach()
	unattach()
	..()


//-------------------------------------------
// Interaction procs
//-------------------------------------------
/obj/vehicle/train/relaymove(mob/user, direction)
	var/turf/T = get_step_to(src, get_step(src, direction))
	if(!T)
		to_chat(user, span("warning", "You can't find a clear area to step onto."))
		return FALSE

	if(user != load)
		if(user in src) //for handling players stuck in src - this shouldn't happen - but just in case it does
			user.forceMove(T)
			return TRUE
		return FALSE

	unload(user, direction)

	to_chat(user, span("notice", "You climb down from \the [src]."))

	return TRUE

/obj/vehicle/train/MouseDrop_T(atom/movable/C, mob/user)
	if(user.buckled || user.stat || user.restrained() || !Adjacent(user) || !user.Adjacent(C) || !istype(C) || (user == C && !user.canmove))
		return
	if(istype(C,/obj/vehicle/train))
		latch(C, user)
	else
		if(!load(C))
			to_chat(user, span("warning", "You were unable to load \the [C] on \the [src]."))

/obj/vehicle/train/attack_hand(mob/user)
	if(user.stat || user.restrained() || !Adjacent(user))
		return FALSE

	if(user != load && (user in src))
		user.forceMove(loc) //for handling players stuck in src
	else if(load)
		unload(user) //unload if loaded
	else if(!load && !user.buckled)
		load(user) //else try climbing on board
	else
		return FALSE

/obj/vehicle/train/verb/unlatch_v()
	set name = "Unlatch"
	set desc = "Unhitches this train from the one in front of it."
	set category = "Vehicle"
	set src in view(1)

	if(!istype(usr, /mob/living/carbon/human))
		return

	if(!usr.canmove || usr.stat || usr.restrained() || !Adjacent(usr))
		return

	unattach(usr)


//-------------------------------------------
// Latching/unlatching procs
//-------------------------------------------

//attempts to attach src as a follower of the train T
//Note: there is a modified version of this in code\modules\vehicles\cargo_train.dm specifically for cargo train engines
/obj/vehicle/train/proc/attach_to(obj/vehicle/train/T, mob/user)
	if(get_dist(src, T) > 1)
		to_chat(user, span("warning", "\The [src] is too far away from \the [T] to hitch them together."))
		return

	if(lead)
		to_chat(user, span("warning", "\The [src] is already hitched to something."))
		return

	if(T.tow)
		to_chat(user, span("warning", "\The [T] is already towing something."))
		return

	//check for cycles.
	var/obj/vehicle/train/next_car = T
	while(next_car)
		if(next_car == src)
			to_chat(user, span("warning", "That seems very silly."))
			return
		next_car = next_car.lead

	//latch with src as the follower
	lead = T
	T.tow = src
	set_dir(lead.dir)

	if(user)
		to_chat(user, span("notice", "You hitch \the [src] to \the [T]."))

	update_stats()


//detaches the train from whatever is towing it
/obj/vehicle/train/proc/unattach(mob/user)
	if(!lead)
		to_chat(user, span("warning", "\The [src] is not hitched to anything."))
		return

	lead.tow = null
	lead.update_stats()

	to_chat(user, span("notice", "You unhitch \the [src] from \the [lead]."))
	lead = null

	update_stats()

/obj/vehicle/train/proc/latch(obj/vehicle/train/T, mob/user)
	if(!istype(T) || !Adjacent(T))
		return FALSE

	var/T_dir = get_dir(src, T) //figure out where T is wrt src

	if(dir == T_dir) //if car is ahead
		src.attach_to(T, user)
	else if(reverse_direction(dir) == T_dir) //else if car is behind
		T.attach_to(src, user)

//returns 1 if this is the lead car of the train
/obj/vehicle/train/proc/is_train_head()
	if(lead)
		return FALSE
	return TRUE

//-------------------------------------------------------
// Stat update procs
//
// Used for updating the stats for how long the train is.
// These are useful for calculating speed based on the
// size of the train, to limit super long trains.
//-------------------------------------------------------
/obj/vehicle/train/update_stats()
	//first, seek to the end of the train
	var/obj/vehicle/train/T = src
	while(T.tow)
		//check for cyclic train.
		if(T.tow == src)
			lead.tow = null
			lead.update_stats()

			lead = null
			update_stats()
			return
		T = T.tow

	//now walk back to the front.
	var/active_engines = 0
	var/train_length = 0
	while(T)
		train_length++
		if(T.powered && T.on)
			active_engines++
		T.update_car(train_length, active_engines)
		T = T.lead

/obj/vehicle/train/proc/update_car(var/train_length, var/active_engines)
	return