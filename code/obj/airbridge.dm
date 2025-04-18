// Includes:
// - Airbridge controllers
// - Airbridge computers
// - Airbridge test buttons
// - Dummy turfs

//air bridge controllers of the same id will automatically establish and destroy air bridges between each other if told to.
//dont create more than 2 controllers with the same id or stuff will break. And itll be your fault.
//Also, make sure the bridges can extend in a straight line. Or you're gonna have a really bad time

/* -------------------- Controller -------------------- */

//There's a bunch for loops across the width of the bridge. Since this rounding to deal with both even and uneven width bridges isn't easy to read, in a define it goes. 'w'
#define FOR_ACROSS_TUNNEL_WIDTH(_iterator) for(var/_iterator = -trunc(tunnel_width/2), _iterator <= trunc((tunnel_width-1)/2), _iterator++)
//A side effect to how these are coded is it's not consistent which controller establishes or retracts a bridge.
//Since even-width bridges aren't centered on the controllers, the two controllers would give different offsets with just turn()
//so this had to be done instead.
#define TUNNEL_PERPENDICULAR dir & (NORTH|SOUTH) ? EAST : NORTH

/obj/airbridge_controller
	name = "Airbridge Controller"
	desc = "This is an invisible thing. Yet you can see it. You notice reality unraveling around you."
	icon = 'icons/map-editing/mark.dmi'
	icon_state = "airbr"
	invisibility = 99
	anchored = 1
	density = 0

	///Total tunnel width in tiles including walls. Even width biases to negative (a vertically oriented bridge of width 4 goes from x-2 to x+1)
	var/tunnel_width = 3 //anything less than 3 isn't gonna be useful, unless you want a retracting wall I guess? But with floor lights. :P
	var/id = "noodles"
	var/working = 0
	var/maintaining_bridge = 0
	var/obj/airbridge_controller/linked = null

	var/list/path = new/list()
	var/list/maintaining_turfs = new/list()

	var/primary_controller = 0 // if 1, the bridge extends from this controller to the other one when toggled by an airbridge computer
	// ONLY SET ONE CONTROLLER TO 1 OR IT'S TOTALLY POINTLESS
	var/list/obj/machinery/computer/airbr/computers = null

	var/original_turf = /turf/space
	var/floor_turf = /turf/floor/airbridge
	var/wall_turf = /turf/wall/airbridge
	var/floor_light_type = /obj/machinery/light/small/floor

	var/list/obj/my_lights = null

	var/slide_delay = 1 SECOND

	var/area/original_area = /area/space
	var/area/airbridge/airbridge_area// = /area/airbridge

	var/auto_pressurize = TRUE // just gonna make this default true cause it makes sense

	drawbridge
		name = "Drawbridge Controller"
		original_turf = /turf/floor/plating/airless/asteroid

	classic
		floor_turf = /turf/floor/airbridge/classic
		wall_turf = /turf/wall/airbridge/classic

		gray
			floor_turf = /turf/floor/airbridge/classic/white
			wall_turf = /turf/wall/airbridge/classic/gray

		orangeyellow
			floor_turf = /turf/floor/airbridge/classic/yellow
			wall_turf = /turf/wall/airbridge/classic/orange

		green
			floor_turf = /turf/floor/airbridge/classic/green
			wall_turf = /turf/wall/airbridge/classic/green

		red
			floor_turf = /turf/floor/airbridge/classic/red
			wall_turf = /turf/wall/airbridge/classic/gray

		purple
			floor_turf = /turf/floor/airbridge/classic/purple

	New()
		START_TRACKING
		..()
		original_area = get_area_by_type(original_area)
		airbridge_area = new

	proc/get_link()
		for_by_tcl(C, /obj/airbridge_controller)
			if(C.z == src.z && C.id == src.id && C != src)
				linked = C
				break

	proc/toggle_bridge()
		if(linked == null) get_link()
		if(linked == null) return

		if(linked.maintaining_bridge)
			return linked.remove_bridge()
		else if(maintaining_bridge)
			return linked.remove_bridge()
		else
			return establish_bridge()

	proc/pressurize()
		if(linked == null) get_link()
		if(linked == null) return

		if(linked.working || working) return
		if(!linked.maintaining_bridge && !maintaining_bridge) return

		if(!maintaining_turfs.len) return

		working = 1

		SPAWN_DBG(5 SECONDS)
			for(var/turf/T in maintaining_turfs)
				if(istype(T, /turf/space))
					continue
				if(!T.air && T.density)
					continue
				ZERO_BASE_GASES(T.air)
#ifdef ATMOS_ARCHIVING
				ZERO_ARCHIVED_BASE_GASES(T.air)
				T.air.ARCHIVED(temperature) = null
#endif
				T.air.oxygen = MOLES_O2STANDARD
				T.air.nitrogen = MOLES_N2STANDARD
				T.air.fuel_burnt = 0
				T.air.remove_trace_gas()
				T.air.temperature = T20C
				LAGCHECK(LAG_LOW)

			working = 0
			updateComps()

		return

	proc/get_state_string()
		if(linked == null) get_link()
		if(linked == null) return "ERROR: Connection to secondary Airbridge controller lost."

		if(linked.working || working) return "Airbridge controller working. Please wait."
		if(linked.maintaining_bridge || maintaining_bridge) return "Airbridge established."
		if(!linked.maintaining_bridge && !maintaining_bridge) return "No active Airbridge."

		return "Unknown State."

	proc/is_working()
		if(linked == null) get_link()
		if(linked == null) return 0

		if(linked.working || working) return 1
		else return 0

	proc/establish_bridge(bolt_id = null)
		if(linked == null) get_link()
		if(linked == null) return

		if(linked.working || working) return
		if(linked.maintaining_bridge || maintaining_bridge) return

		working = 1
		maintaining_bridge = 1

		SPAWN_DBG(0)
			path.Cut()

			var/turf/current = src.loc
			path.Add(current)
			var/direction = get_dir(current, get_step(current,get_dir(current, linked.loc)))
			path[current] = direction

			while(current != linked.loc)
				var/previous = current
				current = get_step(current,get_dir(current, linked.loc))
				path.Add(current)
				direction = get_dir(previous,current)
				path[current] = direction

			var/turf/curr
			var/j = 1
			var/light_index = 1
			for(var/turf/T in path)
				if(j % 3 == 2 && floor_light_type)
					var/obj/light = null
					if(light_index <= length(my_lights))
						light = my_lights[light_index]
					else
						if(!my_lights)
							my_lights = list()
						light = new floor_light_type(T)
						my_lights += light
					light.set_loc(T)
					light.alpha = 0
					light_index++
				j++

			for(var/turf/T in path)
				var/dir = path[T]
				FOR_ACROSS_TUNNEL_WIDTH(i)
					curr = get_steps(T, TUNNEL_PERPENDICULAR,i)
					airbridge_area.add_turf(curr)
					if(i == -trunc(tunnel_width/2) || i == trunc((tunnel_width-1)/2)) // wall
						animate_turf_slideout(curr, src.wall_turf, dir, slide_delay)
					else // floor
						animate_turf_slideout(curr, src.floor_turf, dir, slide_delay)
					curr.set_dir(dir)
					maintaining_turfs.Add(curr)
				playsound(T, "sound/effects/airbridge_dpl.ogg", 50, 1)
				sleep(slide_delay)
				FOR_ACROSS_TUNNEL_WIDTH(i)
					curr = get_steps(T, TUNNEL_PERPENDICULAR, i)
					animate_turf_slideout_cleanup(curr)

			for(var/obj/light in my_lights)
				animate_open_from_floor(light, time=1 SECOND, self_contained=0)
				light.alpha = 255
			sleep(1 SECOND)
			for(var/obj/light in my_lights)
				light.filters = null
				var/obj/machinery/light/l = light
				if(istype(l))
					l.seton(1)

			if(bolt_id != null)
				for (var/obj/machinery/door/airlock/M in by_type[/obj/machinery/door])
					if (M.id == bolt_id)
						if (M.locked)
							M.locked = 0
							playsound(M, 'sound/machines/airlock_bolted.ogg', 40)
							SPAWN_DBG(0) M.update_icon()

			if(auto_pressurize)
				SPAWN_DBG (1 SECOND) pressurize()

			working = 0
			updateComps()

		return

	proc/remove_bridge(bolt_id = null)
		if(linked == null) get_link()
		if(linked == null) return

		if(linked.working || working) return
		if(!linked.maintaining_bridge && !maintaining_bridge) return

		if(!maintaining_bridge && linked.maintaining_bridge)
			linked.remove_bridge()
			return

		working = 1
		maintaining_bridge = 0
		playsound(src.loc, "sound/machines/warning-buzzer.ogg", 50, 1)

		SPAWN_DBG(2 SECONDS)
			var/list/path_reverse = reverse_list(path)

			for(var/obj/light in src.my_lights)
				animate_close_into_floor(light, time=1 SECOND, self_contained=0)
			sleep(1 SECOND)
			for(var/obj/light in my_lights)
				light.filters = null
				light.alpha = 0

			var/turf/curr
			for(var/turf/T in path_reverse)
				var/dir = path[T]
				var/opdir = turn(dir, 180)
				FOR_ACROSS_TUNNEL_WIDTH(i)
					curr = get_steps(T, TUNNEL_PERPENDICULAR, i)
					original_area.add_turf(curr)
					animate_turf_slidein(curr, src.original_turf, opdir, slide_delay)
				playsound(T, "sound/effects/airbridge_dpl.ogg", 50, 1)
				sleep(slide_delay)
				FOR_ACROSS_TUNNEL_WIDTH(i)
					curr = get_steps(T, TUNNEL_PERPENDICULAR, i)
					animate_turf_slidein_cleanup(curr)

			for(var/obj/light in src.my_lights)
				light.set_loc(src)

			maintaining_turfs.Cut()
			working = 0
			updateComps()

			if(bolt_id != null)
				SPAWN_DBG(1 SECOND)
				for (var/obj/machinery/door/airlock/M in by_type[/obj/machinery/door])
					if (M.id == bolt_id)
						if (!M.locked)
							M.force_close()
							M.operating = 0
							M.locked = 1
							playsound(M, 'sound/machines/airlock_bolted.ogg', 40)
							SPAWN_DBG(0) M.update_icon()

		return

	proc/updateComps()
		for (var/obj/machinery/computer/airbr/C in src.computers)
			C.updateDialog()

	disposing()
		STOP_TRACKING
		. = ..()


/* -------------------- Computer -------------------- */

/obj/machinery/computer/airbr
	name = "Airbridge Computer"
	desc = "Used to control the airbridge."
	id = "noodles"
	icon_state = "airbr0"
	glow_in_dark_screen = FALSE
	// set this var to 1 in the map editor if you want the airbridge to establish and pressurize when the round starts
	// only do it to ONE of the computers for the airbridge ID or they will both try to do it and get confused
	var/starts_established = 0

	var/bolt_doors = FALSE // Are there doors that will bolt after the airbridge retracts? (uses door id var)
	var/auto_retract = FALSE // Will the airbridge automatically retract?
	var/auto_retract_time = 1 MINUTE

	var/working = 0
	var/state_str = ""

	req_access = list(access_heads)

	var/list/links = list()

	var/obj/airbridge_controller/primary_controller = null

	var/emergency = 0 // 1 to automatically extend when the emergency shuttle docks

	New()
		..()
		START_TRACKING
		if (src.emergency && emergency_shuttle) // emergency_shuttle is the controller datum
			emergency_shuttle.airbridges += src

	initialize()
		..()
		update_status()
		if (starts_established && length(links))
			SPAWN_DBG(1 SECOND)
				do_initial_extend()

	disposing()
		STOP_TRACKING
		..()

	proc/get_links()
		for_by_tcl(C, /obj/airbridge_controller)
			if (C.id == src.id)
				links.Add(C)
				if (C.primary_controller)
					src.primary_controller = C
				if(isnull(C.computers))
					C.computers = list(src)
				else
					C.computers += src

	process()
		..()
		update_status()
		if (starts_established && length(links))
			SPAWN_DBG(1 SECOND)
				do_initial_extend()
		if (auto_retract)
			if (ON_COOLDOWN(src, "auto_retract", auto_retract_time)) return
			remove_bridge()
		return

	proc/pick_controller()
		if (istype(src.primary_controller))
			return src.primary_controller
		var/obj/airbridge_controller/C = pick(links)
		if (istype(C))
			return C

	proc/do_initial_extend()
		var/obj/airbridge_controller/C = src.pick_controller()
		if (!istype(C))
			return

		C.establish_bridge()

		var/sanity_counter = 0
		while (C.working && sanity_counter < 30)
			sanity_counter++
			sleep(2 SECONDS)

		C.pressurize()
		starts_established = 0

	proc/update_status()
		if (!links.len)
			get_links()

		if (!links.len)
			working = 0
			starts_established = 0
			state_str = "ERROR: No controllers found."
			return

		var/obj/airbridge_controller/C = src.pick_controller()
		if (!istype(C))
			return

		working = C.is_working()
		icon_state = "airbr[working]"
		state_str = C.get_state_string()

	attack_hand(var/mob/user as mob, params)
		if (..(user, params))
			return

		update_status()

		var/dat = {"
		<b>Controller Status:</b><BR>
		[state_str]<BR><BR>
		[working ? "Working..." : "Idle..."]<BR><BR>
		<b>Airbridge Control:</b><BR>
		<A href='byond://?src=\ref[src];create=1'>Establish</A><BR>
		<A href='byond://?src=\ref[src];remove=1'>Retract</A><BR>
		<A href='byond://?src=\ref[src];air=1'>Pressurize</A><BR>
		"}

		if (user.client.tooltipHolder)
			user.client.tooltipHolder.showClickTip(src, list(
				"params" = params,
				"title" = src.name,
				"content" = dat,
			))

		return

	proc/ensure_links()
		if (!src.links.len)
			src.get_links()
		if (!src.links.len)
			src.working = 0
			src.state_str = "ERROR: No controllers found."
			return 0
		else
			return 1

	proc/establish_bridge()
		if (!src.ensure_links())
			return 0
		var/obj/airbridge_controller/C = src.pick_controller()
		if (istype(C))
			C.establish_bridge(bolt_doors ? id : null)
			return 1

	proc/remove_bridge()
		if (!src.ensure_links())
			return 0
		var/obj/airbridge_controller/C = src.pick_controller()
		if (istype(C))
			C.remove_bridge(bolt_doors ? id : null)
			return 1

	proc/pressurize()
		if (!src.ensure_links())
			return 0
		var/obj/airbridge_controller/C = src.pick_controller()
		if (istype(C))
			C.pressurize()
			return 1

	Topic(href, href_list)
		if (..(href, href_list))
			return

		if (href_list["create"])
			if (src.emergency && emergency_shuttle)
				if (emergency_shuttle.location != SHUTTLE_LOC_STATION)
					boutput(usr, "<span class='alert'>The airbridge cannot be deployed while the shuttle is not in position.</span>")
					return
			if (!(src.allowed(usr)))
				boutput(usr, "<span class='alert'>Access denied.</span>")
				return
			if (src.establish_bridge())
				logTheThing("station", usr, null, "extended the airbridge at [usr.loc.loc] ([showCoords(usr.x, usr.y, usr.z)])")

		else if (href_list["remove"])
			if (!(src.allowed(usr)))
				boutput(usr, "<span class='alert'>Access denied.</span>")
				return
			if (src.remove_bridge())
				logTheThing("station", usr, null, "retracted the airbridge at [usr.loc.loc] ([showCoords(usr.x, usr.y, usr.z)])")

		else if (href_list["air"])
			if (!(src.allowed(usr)))
				boutput(usr, "<span class='alert'>Access denied.</span>")
				return
			if (src.pressurize())
				logTheThing("station", usr, null, "pressurized the airbridge at [usr.loc.loc] ([showCoords(usr.x, usr.y, usr.z)])")

		update_status()
		src.updateDialog()
		return

	power_change()
		if(status & BROKEN)
			icon_state = "airbrbr"
			light.disable()

		else if(powered())
			icon_state = "airbr0"
			status &= ~NOPOWER
			light.enable()
		else
			SPAWN_DBG(rand(0, 15))
				icon_state = "airbroff"
				status |= NOPOWER
				light.disable()
	set_broken()
		if (status & BROKEN) return
		var/datum/effects/system/harmless_smoke_spread/smoke = new /datum/effects/system/harmless_smoke_spread()
		smoke.set_up(5, 0, src)
		smoke.start()
		icon_state = initial(icon_state)
		icon_state = "airbrbr"
		light.disable()
		status |= BROKEN

/obj/machinery/computer/airbr/emergency_shuttle
	icon = 'icons/obj/airtunnel.dmi'
	emergency = 1

/* -------------------- Button -------------------- */

/obj/machinery/airbr_test_button
	name = "Airbridge Button"
	icon = 'icons/obj/objects.dmi'
	icon_state = "launcherbtt"
	desc = ""
	var/id = "noodles"
	var/state = 0
	anchored = 1.0

	attack_hand(mob/user as mob)
		for(var/obj/airbridge_controller/C in range(3, src))
			boutput(user, "<span class='notice'>[C.toggle_bridge()]</span>")
			break
		return

/area/airbridge
	name = "Airbridge"
	is_atmos_simulated = TRUE
	is_construction_allowed = TRUE
	requires_power = FALSE //>:(

#undef FOR_ACROSS_TUNNEL_WIDTH
#undef TUNNEL_PERPENDICULAR
