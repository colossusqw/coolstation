#define OPEN 1
#define CLOSED 2

/obj/firedoor_spawn
	name = "firedoor spawn"
	desc = "Place this over a door to spawn a firedoor underneath. Sets direction, too!"
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "f_spawn"

	New()
		..()
		SPAWN_DBG(1 DECI SECOND)
			src.setup()
			sleep(1 SECOND)
			qdel(src)

	proc/setup()
		for (var/obj/machinery/door/D in src.loc)
			var/obj/machinery/door/firedoor/F = new map_settings.firelock_style(src.loc)
			F.set_dir(D.dir)
			F.layer = D.layer + 0.01
			return
		//no doors? probably a line of spawners bridging the hallway
		for(var/direction in list(NORTH, WEST))
			var/turf/T = get_step(src, direction)
			if (T.density || (locate(/obj/window) in T) || (locate(/obj/firedoor_spawn) in T) || (locate(/obj/machinery/door/firedoor) in T))
				var/obj/machinery/door/firedoor/F = new map_settings.firelock_style(src.loc)
				F.set_dir(turn(direction, 90)) //Chosen test directions bias the doors to be west and south facing. I mostly did that for the latter, because then the writing is the right way up
				break

/obj/machinery/door/firedoor
	name = "Firelock"
	desc = "Thick, fire-proof doors that prevent the spread of fire, they can only be pried open unless the fire alarm is cleared."
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "door0"
	var/blocked = null
	opacity = 0
	density = 0
	var/nextstate = null
	var/datum/radio_frequency/control_frequency = FREQ_ALARM
	var/zone
	var/zone2 //mbc hack
	var/image/welded_image = null
	var/welded_icon_state = "welded"
	has_crush = 0

/obj/machinery/door/firedoor/border_only
	name = "Firelock"
	icon = 'icons/obj/doors/door_fire2.dmi'
	icon_state = "door0"

/obj/machinery/door/firedoor/pyro
	icon = 'icons/obj/doors/SL_doors.dmi'
	icon_state = "fdoor0"
	icon_base = "fdoor"
	welded_icon_state = "fdoor_welded"
	layer = 3.1 // might just be me but I think these look better when they're over the doors

/obj/machinery/door/firedoor/New()
	..()
	if(!zone)
		var/area/A = get_area(loc)
		if (A?.name)
			zone = A.name
	SPAWN_DBG(0.5 SECONDS)
		if (radio_controller)
			radio_controller.add_object(src, "[control_frequency]")

		if (!zone2) //MBC : Hey, this is pretty shitty! But I want to be able to handle firelocks that are bordering 2 areas... without reworking the whole dang thing
			for (var/d in cardinal)
				var/area/A = get_area(get_step(src,d))
				if (A?.name && A.name != zone)
					zone2 = A.name
					break

/obj/machinery/door/firedoor/disposing()
	if (radio_controller)
		radio_controller.remove_object(src, "[control_frequency]")
	..()

/obj/machinery/door/firedoor/proc/set_open()
	if(!blocked)
		if(operating)
			nextstate = OPEN
		else
			SPAWN_DBG(rand(1,6))
				open()
	return

/obj/machinery/door/firedoor/proc/set_closed()
	if(!blocked)
		if(operating)
			nextstate = CLOSED
		else
			SPAWN_DBG(rand(1,6))
				close()
	return

// listen for fire alert from firealarm
/obj/machinery/door/firedoor/receive_signal(datum/signal/signal)
	if((signal.data["zone"] == zone || signal.data["zone"] == zone2) && signal.data["type"] == "Fire")
		if(signal.data["alert"] == "fire")
			set_closed()
		else
			set_open()
	return


/obj/machinery/door/firedoor/power_change()
	if( powered(ENVIRON) )
		status &= ~NOPOWER
	else
		status |= NOPOWER

/obj/machinery/door/firedoor/bumpopen(mob/user as mob)
	return

/obj/machinery/door/firedoor/attack_hand(mob/user)
	if(!src.density)
		for(var/obj/machinery/door/candidate in src.loc)
			if(istype(candidate, /obj/machinery/door/firedoor))
				continue
			return candidate.attack_hand(user)
	return ..()


/obj/machinery/door/firedoor/isblocked()
	if (src.blocked)
		return 1
	return 0

/obj/machinery/door/firedoor/attackby(obj/item/C as obj, mob/user as mob)
	src.add_fingerprint(user)
	if (!ispryingtool(C))
		if (src.density && !src.operating)
			user.lastattacked = src
			attack_particle(user,src)
			playsound(src.loc, src.hitsound , 50, 1, pitch = 1.6)
			if (C) src.take_damage(C.force) //TODO: FOR MBC, WILL RUNTIME IF ATTACKED WITH BARE HAND, C IS NULL. ADD LIMB INTERACTIONS
		return

	if (!src.blocked && !src.operating)
		if(src.density)
			SPAWN_DBG( 0 )
				src.operating = 1

				play_animation("opening")
				update_icon(1)
				sleep(1.5 SECONDS)
				src.set_density(0)
				update_nearby_tiles()
				if (ignore_light_or_cam_opacity)
					src.opacity = 0
				else
					src.RL_SetOpacity(0)
				src.operating = 0
				return
		else //close it up again
			SPAWN_DBG( 0 )
				src.operating = 1

				play_animation("closing")
				update_icon(1)
				src.set_density(1)
				update_nearby_tiles()
				sleep(1.5 SECONDS)

				if (ignore_light_or_cam_opacity)
					src.opacity = 1
				else
					src.RL_SetOpacity(1)
				src.operating = 0
				return
		playsound(src, 'sound/machines/airlock_pry.ogg', 50, 1)

	return


/obj/machinery/door/firedoor/attack_ai(mob/user as mob)
	if(!blocked && !operating)
		if(density)
			set_open()
		else
			set_closed()
	return

/obj/machinery/door/firedoor/proc/check_nextstate()
	switch (src.nextstate)
		if (OPEN)
			src.open()
		if (CLOSED)
			src.close()
	src.nextstate = null

/obj/machinery/door/firedoor/opened()
	..()
	check_nextstate()

/obj/machinery/door/firedoor/closed()
	..()
	check_nextstate()

/obj/machinery/door/firedoor/border_only
	gas_cross(turf/target)
		return (dir != get_dir(src,target))

	update_nearby_tiles(need_rebuild)
		if(!air_master) return 0

		var/turf/source = loc
		var/turf/destination = get_step(source,dir)

		if(need_rebuild)
			if(istype(source)) //Rebuild/update nearby group geometry
				if(source.parent)
					air_master.groups_to_rebuild |= source.parent
				else
					air_master.tiles_to_update |= source
			if(istype(destination))
				if(destination.parent)
					air_master.groups_to_rebuild |= destination.parent
				else
					air_master.tiles_to_update |= destination

		else
			if(istype(source)) air_master.tiles_to_update |= source
			if(istype(destination)) air_master.tiles_to_update |= destination

		return 1

/obj/machinery/door/firedoor/update_icon(var/toggling = 0)
	if(toggling? !density : density)
		if (locked)
			icon_state = "[icon_base]_locked"
		else
			icon_state = "[icon_base]1"
		if (blocked)
			if (!src.welded_image)
				src.welded_image = image(src.icon, src.welded_icon_state)
			src.UpdateOverlays(src.welded_image, "weld")
		else
			src.UpdateOverlays(null, "weld")
	else
		src.UpdateOverlays(null, "weld")
		icon_state = "[icon_base]0"

	return

/obj/machinery/door/firedoor/custom_suicide = 1
/obj/machinery/door/firedoor/suicide(var/mob/living/carbon/human/user as mob)
	if (!istype(user) || !user.organHolder || !src.user_can_suicide(user))
		return 0
	if (!src.allowed(user) || src.density)
		return 0
	user.visible_message("<span class='alert'><b>[user] sticks [his_or_her(user)] head into [src] and closes it!</b></span>")
	src.close()
	var/obj/head = user.organHolder.drop_organ("head")
	qdel(head)
	make_cleanable( /obj/decal/cleanable/tracked_reagents/blood/gibs,src.loc)
	playsound(src.loc, "sound/impact_sounds/Flesh_Break_2.ogg", 50, 1)

	return 1

#undef OPEN
#undef CLOSED
