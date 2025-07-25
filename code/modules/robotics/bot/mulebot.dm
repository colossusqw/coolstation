// Mulebot - carries crates around for Quartermaster
// Navigates via floor navbeacons
// Remote Controlled from QM's PDA


/obj/machinery/bot/mulebot
	name = "Mulebot"
	desc = "A Multiple Utility Load Effector bot."
	icon_state = "mulebot0"
	layer = MOB_LAYER
	density = 1
	anchored = 1
	animate_movement=1
	soundproofing = 0
	on = 1
	locked = 1
	access_lookup = "Captain"
	var/atom/movable/load = null		// the loaded crate (usually)

	var/beacon_freq = FREQ_BOT_NAV
	var/control_freq = FREQ_BOT_CONTROL
	var/pda_freq = FREQ_PDA

	suffix = ""

	var/turf/target				// this is turf to navigate to (location of beacon)
	var/loaddir = 0				// this the direction to unload onto/load from
	var/new_destination = ""	// pending new destination (waiting for beacon response)
	var/destination = ""		// destination description
	var/home_destination = "" 	// tag of home beacon
	req_access = list(access_cargo)

	var/mode = 0		//0 = idle/ready
						//1 = loading/unloading
						//2 = moving to deliver
						//3 = returning to home
						//4 = blocked
						//5 = computing navigation
						//6 = waiting for nav computation
						//7 = no destination beacon found (or no route)

	var/blockcount	= 0		//number of times retried a blocked path
	var/reached_target = 1 	//true if already reached the target

	var/auto_return = 1	// true if auto return to home beacon after unload
	var/auto_pickup = 1 // true if auto-pickup at beacon

	var/open = 0		// true if maint hatch is open
	var/obj/item/cell/cell
						// the installed power cell
	no_camera = 1
	// constants for internal wiring bitflags
	var/const
		wire_power1 = 1			// power connections
		wire_power2 = 2
		wire_mobavoid = 4		// mob avoidance
		wire_loadcheck = 8		// load checking (non-crate)
		wire_motor1 = 16		// motor wires
		wire_motor2 = 32		//
		wire_remote_rx = 64		// remote recv functions
		wire_remote_tx = 128	// remote trans status
		wire_beacon_rx = 256	// beacon ping recv
		wire_beacon_tx = 512	// beacon ping trans

	var/wires = 1023		// all flags on

	var/list/wire_text	// list of wire colours
	var/list/wire_order	// order of wire indices

	var/bloodiness = 0		// count of bloodiness
	var/nocellspawn = 0 //Used for spawning a MULE w/o a cell.
	var/turf/last_loc

	New()
		..()

		var/global/mulecount = 0
		if(!suffix)
			mulecount++
			suffix = "#[mulecount]"
		name = "Mulebot ([suffix])"

		if (!nocellspawn)
			cell = new(src)
			cell.charge = 2000
			cell.maxcharge = 2000
		setup_wires()

		SPAWN_DBG(0.5 SECONDS)	// must wait for map loading to finish
			if(radio_controller)
				radio_controller.add_object(src, "[control_freq]")
				radio_controller.add_object(src, "[beacon_freq]")
				radio_controller.add_object(src, "[pda_freq]")

	// set up the wire colours in random order
	// and the random wire display order
	// needs 10 wire colours
	proc/setup_wires()
		var/list/colours = list("Red", "Green", "Blue", "Magenta", "Cyan", "Yellow", "Black", "White", "Orange", "Grey")
		var/list/orders = list("0","1","2","3","4","5","6","7","8","9")
		wire_text = list()
		wire_order = list()
		while(colours.len > 0)
			var/colour = colours[ rand(1,colours.len) ]
			wire_text += colour
			colours -= colour

			var/order = orders[ rand(1,orders.len) ]
			wire_order += text2num(order)
			orders -= order

	// attack by item
	// emag : lock/unlock,
	// screwdriver: open/close hatch
	// cell: insert it
	// other: chance to knock rider off bot

	emag_act(var/mob/user, var/obj/item/card/emag/E)
		locked = !locked
		if(user)
			boutput(user, "<span class='notice'>You [locked ? "lock" : "unlock"] the mulebot's controls!</span>")

		flick("mulebot-emagged", src)
		playsound(src.loc, "sound/effects/sparks1.ogg", 100, 0)
		return 1

	attackby(var/obj/item/I, var/mob/user)
		if(istype(I,/obj/item/cell) && open && !cell)
			var/obj/item/cell/C = I
			user.drop_item()
			C.set_loc(src)
			cell = C
			updateDialog()
		else if (isscrewingtool(I))
			if (locked)
				boutput(user, "<span class='notice'>The maintenance hatch cannot be opened or closed while the controls are locked.</span>")
				return

			open = !open
			if(open)
				src.visible_message("[user] opens the maintenance hatch of [src]", "<span class='notice'>You open [src]'s maintenance hatch.</span>")
				on = 0
				icon_state="mulebot-hatch"
			else
				src.visible_message("[user] closes the maintenance hatch of [src]", "<span class='notice'>You close [src]'s maintenance hatch.</span>")
				icon_state = "mulebot0"

			updateDialog()
		else if(load && ismob(load))  // chance to knock off rider
			if(prob(1+I.force * 2))
				unload(0)
				user.visible_message("<span class='alert'>[user] knocks [load] off [src] with \the [I]!</span>", "<span class='alert'>You knock [load] off [src] with \the [I]!</span>")
			else
				boutput(user, "You hit [src] with \the [I] but to no effect.")
		else
			..()
		return


	ex_act(var/severity)
		unload(0)
		switch(severity)
			if(1)
				qdel(src)
			if(2)
				wires &= ~(1 << rand(0,9))
				wires &= ~(1 << rand(0,9))
				wires &= ~(1 << rand(0,9))
			if(3)
				wires &= ~(1 << rand(0,9))

		return

	bullet_act(var/obj/projectile/P)
		if (!P)
			return
		if(prob(50) && src.load)
			src.load.bullet_act(P)
			src.unload(0)
		if(prob(25))
			src.visible_message("Something shorts out inside [src]!")
			var/index = 1<< (rand(0,9))
			if(wires & index)
				wires &= ~index
			else
				wires |= index


	attack_ai(var/mob/user, params)
		interacted(user, 1, params)

	attack_hand(var/mob/user, params)
		interacted(user, 0, params)

	proc/interacted(var/mob/user, var/ai=0, params)
		var/dat
		dat += "<TT><B>Multiple Utility Load Effector Mk. III</B></TT><BR><BR>"
		dat += "ID: [suffix]<BR>"
		dat += "Power: [on ? "On" : "Off"]<BR>"

		if(!open)
			dat += "Status: "
			switch(mode)
				if(0)
					dat += "Ready"
				if(1)
					dat += "Loading/Unloading"
				if(2)
					dat += "Navigating to Delivery Location"
				if(3)
					dat += "Navigating to Home"
				if(4)
					dat += "Waiting for clear path"
				if(5,6)
					dat += "Calculating navigation path"
				if(7)
					dat += "Unable to locate destination"

			dat += "<BR>Current Load: [load ? load.name : "<i>none</i>"]<BR>"
			dat += "Destination: [!destination ? "<i>none</i>" : destination]<BR>"
			dat += "Power level: [cell ? cell.percent() : 0]%<BR>"

			if(locked && !ai)
				dat += "Controls are locked <A href='byond://?src=\ref[src];op=unlock'><I>(unlock)</I></A>"
			else
				dat += "Controls are unlocked <A href='byond://?src=\ref[src];op=lock'><I>(lock)</I></A><hr>"

				dat += "<A href='byond://?src=\ref[src];op=power'>Toggle Power</A><BR>"
				dat += "<A href='byond://?src=\ref[src];op=stop'>Stop</A><BR>"
				dat += "<A href='byond://?src=\ref[src];op=go'>Proceed</A><BR>"
				dat += "<A href='byond://?src=\ref[src];op=home'>Return to Home</A><BR>"
				dat += "<A href='byond://?src=\ref[src];op=destination'>Set Destination</A><BR>"
				dat += "<A href='byond://?src=\ref[src];op=setid'>Set Bot ID</A><BR>"
				dat += "<A href='byond://?src=\ref[src];op=sethome'>Set Home</A><BR>"
				dat += "<A href='byond://?src=\ref[src];op=autoret'>Toggle Auto Return Home</A> ([auto_return ? "On":"Off"])<BR>"
				dat += "<A href='byond://?src=\ref[src];op=autopick'>Toggle Auto Pickup Crate</A> ([auto_pickup ? "On":"Off"])<BR>"

				if(load)
					dat += "<A href='byond://?src=\ref[src];op=unload'>Unload Now</A><BR>"
				dat += "<HR>The maintenance hatch is closed.<BR>"

		else
			if(!ai)
				dat += "The maintenance hatch is open.<BR><BR>"
				dat += "Power cell: "
				if(cell)
					dat += "<A href='byond://?src=\ref[src];op=cellremove'>Installed</A><BR>"
				else
					dat += "<A href='byond://?src=\ref[src];op=cellinsert'>Removed</A><BR>"

				dat += wires()
			else
				dat += "The bot is in maintenance mode and cannot be controlled.<BR>"

		if (user.client.tooltipHolder)
			user.client.tooltipHolder.showClickTip(src, list(
				"params" = params,
				"title" = "Mulebot [suffix ? "([suffix])" : ""] controls",
				"content" = dat,
			))

		return

	// returns the wire panel text
	proc/wires()
		var/t = ""
		for(var/i = 0 to 9)
			var/index = 1<<wire_order[i+1]
			t += "[wire_text[i+1]] wire: "
			if(index & wires)
				t += "<A href='byond://?src=\ref[src];op=wirecut;wire=[index]'>(cut)</A> <A href='byond://?src=\ref[src];op=wirepulse;wire=[index]'>(pulse)</A><BR>"
			else
				t += "<A href='byond://?src=\ref[src];op=wiremend;wire=[index]'>(mend)</A><BR>"

		return t

	Topic(href, href_list)
		if(..())
			return
		if (usr.stat)
			return
		if ((in_interact_range(src, usr) && istype(src.loc, /turf)) || (issilicon(usr)))
			src.add_dialog(usr)

			switch(href_list["op"])
				if("lock", "unlock")
					if(src.allowed(usr))
						locked = !locked
					else
						boutput(usr, "<span class='alert'>Access denied.</span>")
						return

				if("power")
					on = !on
					if(!cell || open)
						on = 0
						return
					boutput(usr, "You switch [on ? "on" : "off"] [src].")
					for(var/mob/M in AIviewers(src))
						if(M==usr) continue
						boutput(M, "[usr] switches [on ? "on" : "off"] [src].")

				if("cellremove")
					if(open && cell && !usr.equipped())
						usr.put_in_hand_or_drop(cell)

						cell.add_fingerprint(usr)
						cell.updateicon()
						cell = null

						usr.visible_message("<span class='notice'>[usr] removes the power cell from [src].</span>", "<span class='notice'>You remove the power cell from [src].</span>")

				if("cellinsert")
					if(open && !cell)
						var/obj/item/cell/C = usr.equipped()
						if(istype(C))
							usr.drop_item()
							cell = C
							C.set_loc(src)
							C.add_fingerprint(usr)

							usr.visible_message("<span class='notice'>[usr] inserts a power cell into [src].</span>", "<span class='notice'>You insert the power cell into [src].</span>")

				if("stop")
					if(mode >=2)
						mode = 0
						KillPathAndGiveUp()

				if("go")
					mode = 2
					start()

				if("home")
					mode = 3
					start_home()

				if("destination")
					var/new_dest = input("Enter new destination tag", "Mulebot [suffix ? "([suffix])" : ""]", destination) as text|null
					new_dest = copytext(adminscrub(new_dest),1, MAX_MESSAGE_LEN)
					if(new_dest)
						set_destination(new_dest)

				if("setid")
					var/new_id = input("Enter new bot ID", "Mulebot [suffix ? "([suffix])" : ""]", suffix) as text|null
					new_id = copytext(adminscrub(new_id), 1, 128)
					if(new_id)
						suffix = new_id
						name = "Mulebot ([suffix])"

				if("sethome")
					var/new_home = input("Enter new home tag", "Mulebot [suffix ? "([suffix])" : ""]", home_destination) as text|null
					new_home = copytext(adminscrub(new_home),1, 128)
					if(new_home)
						home_destination = new_home

				if("unload")
					if(load && mode !=1)
						if(loc == target)
							unload(loaddir)
						else
							unload(0)

				if("autoret")
					auto_return = !auto_return

				if("autopick")
					auto_pickup = !auto_pickup

				if("close")
					src.remove_dialog(usr)
					usr.Browse(null,"window=mulebot")

				if("wirecut")
					if (usr.find_tool_in_hand(TOOL_SNIPPING))
						var/wirebit = text2num(href_list["wire"])
						if (wirebit == wire_mobavoid)
							logTheThing("vehicle", usr, null, "disables the safety of a MULE ([src.name]) at [log_loc(usr)].")
							src.emagger = usr
						wires &= ~wirebit
					else
						boutput(usr, "<span class='notice'>You need wirecutters!</span>")
				if("wiremend")
					if (usr.find_tool_in_hand(TOOL_SNIPPING))
						var/wirebit = text2num(href_list["wire"])
						if (wirebit == wire_mobavoid)
							logTheThing("vehicle", usr, null, "reactivates the safety of a MULE ([src.name]) at [log_loc(usr)].")
							src.emagger = null
						wires |= wirebit
					else
						boutput(usr, "<span class='notice'>You need wirecutters!</span>")

				if("wirepulse")
					if (usr.find_tool_in_hand(TOOL_PULSING))
						switch(href_list["wire"])
							if("1","2")
								boutput(usr, "<span class='notice'>[bicon(src)] The charge light flickers.</span>")
							if("4")
								boutput(usr, "<span class='notice'>[bicon(src)] The external warning lights flash briefly.</span>")
							if("8")
								boutput(usr, "<span class='notice'>[bicon(src)] The load platform clunks.</span>")
							if("16", "32")
								boutput(usr, "<span class='notice'>[bicon(src)] The drive motor whines briefly.</span>")
							else
								boutput(usr, "<span class='notice'>[bicon(src)] You hear a radio crackle.</span>")
					else
						boutput(usr, "<span class='notice'>You need a multitool or similar!</span>")

			updateDialog()
		else
			usr.Browse(null, "window=mulebot")
			src.remove_dialog(usr)
		return

	// returns true if the bot has power
	proc/has_power()
		return !open && cell?.charge>0 && (wires & wire_power1) && (wires & wire_power2)

	// mousedrop the bot to unload the bot
	MouseDrop(var/turf/T)
		if(!istype(T))
			T = get_turf(T)

		if(usr.stat)
			return

		if(!isliving(usr))
			return

		if(load && GET_DIST(src, usr) <= 1 && GET_DIST(src, T) <= 1)
			unload(get_dir(src,T))
			return
		..()

	// mousedrop a crate to load the bot
	MouseDrop_T(var/atom/movable/C, mob/user)

		if(user.stat)
			return

		if (!on || !istype(C)|| C.anchored || get_dist(user, src) > 1 || get_dist(src,C) > 1 )
			return

		if(load)
			return

		if(C == user && !src.emagged)
			src.remove_dialog(user)

		load(C)

	// called to load a crate
	proc/load(var/atom/movable/C)
		if (istype(C, /atom/movable/screen) || C.anchored)
			return

		if(get_dist(C, src) > 1 || load || !on)
			return
		mode = 1

		// if a create, close before loading
		var/obj/storage/crate/crate = C
		if(istype(crate))
			crate.close()
		C.anchored = 1
		C.set_loc(src.loc)
		sleep(0.2 SECONDS)
		C.set_loc(src)
		load = C
		if(ismob(C))
			var/mob/rider = C
			rider.pixel_y = 9
			rider.ceilingreach = 1 //you may touch the ceiling junk, but when riding on a MULE you currently cannot
		else
			C.pixel_y += 9
		if(C.layer < layer)
			C.layer = layer + 0.1
		overlays += C

		mode = 0
		send_status()

	// called to unload the bot
	// argument is optional direction to unload
	// if zero, unload at bot's location
	proc/unload(var/dirn = 0)
		if(!load)
			return

		mode = 1
		overlays = null

		load.set_loc(src.loc)
		load.pixel_y -= 9
		load.layer = initial(load.layer)
		if(ismob(load))
			var/mob/rider = load
			rider.pixel_y = 0
			rider.ceilingreach = 0

		reset_anchored(load)

		if(dirn)
			step(load, dirn)

		load = null

		// in case non-load items end up in contents, dump every else too
		// this seems to happen sometimes due to race conditions
		// with items dropping as mobs are loaded

		for(var/atom/movable/AM in src)
			if(AM == cell || AM == botcard) continue

			AM.set_loc(src.loc)
			AM.layer = initial(AM.layer)
			AM.pixel_y = initial(AM.pixel_y)
		mode = 0

	process()
		. = ..()
		if(!has_power())
			on = 0
			return
		if(on)
			SPAWN_DBG(0)
				// speed varies between 1-4 depending on how many wires are cut (and which of the two), slowing dramatically if BOTH are cut
				var/speed = ((wires & wire_motor1) ? 1:0) + ((wires & wire_motor2) ? 2:0) + 1
				src.bot_move_delay = list(15, 0.45, 1.25, 2)[speed]

	DoWhileMoving()
		if(src.mode <= 0) return TRUE
		if(bloodiness && issimulatedturf(src.last_loc))
			//boutput(world, "at ([x],[y]) moving to ([next.x],[next.y])")
			var/obj/decal/cleanable/tracked_reagents/blood/tracks/B = make_cleanable(/obj/decal/cleanable/tracked_reagents/blood/tracks, loc)
			var/newdir = get_dir(loc, last_loc)
			if(newdir == dir)
				B.set_dir(newdir)
			else
				newdir = newdir | dir
				if(newdir == 3)
					newdir = 1
				else if(newdir == 12)
					newdir = 4
				B.set_dir(newdir)
			bloodiness--
		if(cell) cell.use(1)
		if (src.last_loc == get_turf(src))
			blockcount++
			mode = 4
			if(blockcount == 5)
				src.visible_message("[src] makes an annoyed buzzing sound.", "You hear an electronic buzzing sound.")
				playsound(src.loc, "sound/machines/buzz-two.ogg", 40, 0)

			if(blockcount > 8)	// attempt 8 times before recomputing (why 8? because it was annoyingly loud on 5)
				// find new path excluding blocked turf
				src.visible_message("[src] makes a sighing buzz.", "You hear an electronic buzzing sound.")
				playsound(src.loc, "sound/machines/buzz-sigh.ogg", 50, 0)

				mode = 6
				SPAWN_DBG(0.2 SECONDS)
					src.navigate_with_navbeacons(src.target, src.bot_move_delay, exclude = src.path[1])
					if(path)
						blockcount = 0
						src.visible_message("[src] makes a delighted ping!", "You hear a ping.")
						playsound(src.loc, "sound/machines/ping.ogg", 50, 0)
				return TRUE
		else
			src.last_loc = get_turf(src)
			src.blockcount = 0
			src.mode = 2 + reached_target

	// sets the current destination
	// signals all beacons matching the delivery code
	// beacons will return a signal giving their locations
	proc/set_destination(var/new_dest)
		SPAWN_DBG(0)
			KillPathAndGiveUp()
			new_destination = new_dest
			post_signal(beacon_freq, "findbeacon", new_dest)
			updateDialog()

	proc/set_destination_pda(var/net_id)
		if(src.wires & wire_mobavoid)
			SPAWN_DBG(0)
				KillPathAndGiveUp()
				new_destination = net_id
				post_signal(pda_freq, "address_1", "ping")
				updateDialog()

	// starts bot moving to current destination
	proc/start()
		if(src.target)
			if(destination == home_destination)
				mode = 3
			else
				reached_target = 0
				mode = 2
			KillPathAndGiveUp()
			src.navigate_with_navbeacons(src.target, src.bot_move_delay)
			if(src.path)
				icon_state = "mulebot[(wires & wire_mobavoid) == wire_mobavoid]"
				return
		src.visible_message("[src] makes an annoyed buzzing sound.", "You hear an electronic buzzing sound.")
		playsound(src.loc, "sound/machines/buzz-two.ogg", 50, 0)
		mode = 0

	// starts bot moving to home
	// sends a beacon query to find
	proc/start_home()
		if(src.mode <= 0) return
		SPAWN_DBG(0)
			set_destination(home_destination)
			reached_target = 1
			mode = 4
			sleep(0.5 SECONDS)
			start()

	// called when bot reaches current target
	DoAtDestination()
		mode = 0
		if(!reached_target)
			if(get_turf(src) == get_turf(src.target))
				src.visible_message("[src] makes a chiming sound!", "You hear a chime.")
				playsound(src.loc, "sound/machines/chime.ogg", 50, 0)
				reached_target = 1

				if(load)		// if loaded, unload at target
					unload(loaddir)
				else
					// not loaded
					if(auto_pickup)		// find a crate
						var/atom/movable/AM
						if(!(wires & wire_loadcheck))		// if emagged, load first unanchored thing we find
							for(var/atom/movable/A in get_step(loc, loaddir))
								if(!A.anchored)
									AM = A
									break
						else			// otherwise, look for crates only
							AM = locate(/obj/storage) in get_step(loc,loaddir)
						if (AM && !AM.anchored)
							load(AM)
				// whatever happened, check to see if we return home

			if(auto_return && home_destination && destination != home_destination)
				// auto return set and not at home already
				mode = 4
				start_home()
			else
				mode = 0	// otherwise go idle

		send_status()	// report status to anyone listening

		return

	// called when bot bumps into anything
	Bump(var/atom/obs)
		if(!(wires & wire_mobavoid)) //usually just bumps, but if avoidance disabled knock over mobs
			var/mob/M = obs
			if(ismob(M))
				if(isrobot(M))
					src.visible_message("<span class='alert'>[src] bumps into [M]!</span>")
				else
					src.visible_message("<span class='alert'>[src] knocks over [M]!</span>")
					M.pulling = null
					M.changeStatus("stunned", 8 SECONDS)
					M.changeStatus("weakened", 5 SECONDS)
					M.force_laydown_standup()
		..()

	alter_health()
		return get_turf(src)

	// called from mob/living/carbon/human/HasEntered()
	// when mulebot is in the same loc
	proc/RunOver(var/mob/living/carbon/human/H)
		src.visible_message("<span class='alert'>[src] drives over [H]!</span>")
		playsound(src.loc, "sound/impact_sounds/Slimy_Splat_1.ogg", 50, 1)

		#ifdef DATALOGGER
		game_stats.Increment("workplacesafety")
		#endif

		logTheThing("vehicle", H, src.emagger, "is run over by a MULE ([src.name]) at [log_loc(src)].[src.emagger && ismob(src.emagger) ? " Safety disabled by [constructTarget(src.emagger,"vehicle")]." : ""]")

		if(ismob(load))
			var/mob/M = load
			if (M.reagents && M.reagents.has_reagent("ethanol"))
				M.unlock_medal("DUI", 1)

		var/damage = rand(5,15)

		H.TakeDamage("head", 2*damage, 0)
		H.TakeDamage("chest",2*damage, 0)
		H.TakeDamage("l_leg",0.5*damage, 0)
		H.TakeDamage("r_leg",0.5*damage, 0)
		H.TakeDamage("l_arm",0.5*damage, 0)
		H.TakeDamage("r_arm",0.5*damage, 0)

		take_bleeding_damage(H, null, 2 * damage, DAMAGE_BLUNT)

		bloodiness += 4

	// player on mulebot attempted to move
	relaymove(var/mob/user)
		if(user.stat)
			return
		if(load == user)
			unload(0)
		return

	// receive a radio signal
	// used for control and beacon reception

	receive_signal(datum/signal/signal)

		if(!on)
			return

		/*
		boutput(world, "rec signal: [signal.source]")
		for(var/x in signal.data)
			boutput(world, "* [x] = [signal.data[x]]")
		*/
		var/recv = signal.data["command"]
		// process all-bot input
		if(recv=="bot_status" && (wires & wire_remote_rx))
			send_status()
			return

		if(recv=="ping_reply" && (wires & wire_remote_rx))
			if(wires & wire_beacon_rx && signal.data["sender"] == new_destination)
				destination = new_destination
				new_destination = null
				target = signal.source.loc
				loaddir = 0
				updateDialog()
			return

		recv = signal.data["command_[ckey(suffix)]"]
		if(wires & wire_remote_rx)
			// process control input
			switch(recv)
				if("stop")
					mode = 0
					KillPathAndGiveUp()
					return

				if("go")
					mode = 2
					start()
					return

				if("target")
					set_destination(signal.data["destination"] )
					return

				if("pda_target")
					set_destination_pda(signal.data["destination"] )
					return

				if("unload")
					if(loc == target)
						unload(loaddir)
					else
						unload(0)
					return

				if("home")
					mode = 3
					start_home()
					return

				if("bot_status")
					send_status()
					return

				if("autoret")
					auto_return = text2num(signal.data["value"])
					return

				if("autopick")
					auto_pickup = text2num(signal.data["value"])
					return

		// receive response from beacon
		recv = signal.data["beacon"]
		if(wires & wire_beacon_rx)
			if(recv && recv == new_destination)	// if the recvd beacon location matches the set destination
										// the we will navigate there
				destination = new_destination
				new_destination = null
				target = signal.source.loc
				var/direction = signal.data["dir"]	// this will be the load/unload dir
				if(direction)
					loaddir = text2num(direction)
				else
					loaddir = 0
				icon_state = "mulebot[(wires & wire_mobavoid) == wire_mobavoid]"
				updateDialog()

	// send a radio signal with a single data key/value pair
	proc/post_signal(var/freq, var/key, var/value)
		post_signal_multiple(freq, list("[key]" = value) )

	// send a radio signal with multiple data key/values
	proc/post_signal_multiple(var/freq, var/list/keyval)

		if(freq == beacon_freq && !(wires & wire_beacon_tx))
			return
		if((freq == control_freq || freq == pda_freq) && !(wires & wire_remote_tx))
			return

		var/datum/radio_frequency/frequency = radio_controller.return_frequency("[freq]")

		if(!frequency) return

		var/datum/signal/signal = get_free_signal()
		signal.source = src
		signal.transmission_method = 1
		signal.data["sender"] = src.botnet_id
		for(var/key in keyval)
			signal.data[key] = keyval[key]
			//boutput(world, "sent [key],[keyval[key]] on [freq]")
		frequency.post_signal(src, signal)

	// signals bot status etc. to controller
	proc/send_status()
		var/list/kv = new()
		kv["type"] = "mulebot"
		kv["name"] = ckey(suffix)
		kv["loca"] = get_area(src)
		kv["mode"] = mode
		kv["powr"] = cell ? cell.percent() : 0
		kv["dest"] = destination
		kv["home"] = home_destination
		kv["load"] = load
		kv["retn"] = auto_return
		kv["pick"] = auto_pickup
		post_signal_multiple(control_freq, kv)

/obj/machinery/bot/mulebot/QM1
	home_destination = "QM #1"

/obj/machinery/bot/mulebot/QM2
	home_destination = "QM #2"

/obj/machinery/bot/mulebot/broken //cell is missing, hatch open
	nocellspawn = 1
	open = 1
	locked = 0
	icon_state="mulebot-hatch"
