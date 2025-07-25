//	Put to 1 to make reagent storage on object creation
#define ENV_BUSH_REAG_STORAGE_ON_NEW 0
//	Put to 1 to always make reagent storage regardless of edible or not
#define ENV_BUSH_REAG_STORAGE_ALWAYS 0

/obj/poolwater
	name = "water"
	density = 0
	anchored = 1
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "poolwater"
	layer = EFFECTS_LAYER_UNDER_3
	mouse_opacity = 0
	var/float_anim = 1
	event_handler_flags = USE_HASENTERED

	New()
		..()
		src.create_reagents(10)
		reagents.add_reagent("cleaner", 5)
		reagents.add_reagent("water", 5)
		SPAWN_DBG(0.5 SECONDS)
			if (src.float_anim)
				for (var/atom/movable/A in src.loc)
					if (!A.anchored)
						animate_bumble(A, floatspeed = 8, Y1 = 3, Y2 = 0)

	HasEntered(atom/A)
		if (src.float_anim)
			if (istype(A, /atom/movable) && !isobserver(A) && !istype(A, /mob/living/critter/small_animal/bee) && !istype(A, /obj/critter/domestic_bee))
				var/atom/movable/AM = A
				if (!AM.anchored)
					animate_bumble(AM, floatspeed = 8, Y1 = 3, Y2 = 0)
		if (isliving(A))
			var/mob/living/L = A
			L.update_burning(-30)
		reagents.reaction(A, TOUCH, 2)
		return ..()

	HasExited(atom/movable/A, atom/newloc)
		var/turf/T = get_turf(newloc)
		if (istype(T))
			var/obj/poolwater/P = locate() in T
			if (!istype(P))
				if (istype(A, /atom/movable) && !isobserver(A) && !istype(A, /mob/living/critter/small_animal/bee) && !istype(A, /obj/critter/domestic_bee))
					animate(A)
					A.pixel_y = initial(A.pixel_y)
		return ..()

/obj/tree1
	name = "Tree"
	desc = "It's a tree."
	icon = 'icons/effects/96x96.dmi' // changed from worlds.dmi
	icon_state = "tree" // changed from 0.0
	anchored = 1
	layer = EFFECTS_LAYER_UNDER_3
	pixel_x = -20
	density = 1
	opacity = 0 // this causes some of the super ugly lighting issues too

	elm_random
		New()
			. = ..()
			src.dir = pick(cardinal - SOUTH)

// what the hell is all this and why wasn't it just using a big icon? the lighting system gets all fucked up with this stuff

/*
 	New()
		var/image/tile10 = image('icons/misc/worlds.dmi',null,"1,0",10)
		tile10.pixel_x = 32

		var/image/tile01 = image('icons/misc/worlds.dmi',null,"0,1",10)
		tile01.pixel_y = 32

		var/image/tile11 = image('icons/misc/worlds.dmi',null,"1,1",10)
		tile11.pixel_y = 32
		tile11.pixel_x = 32

		overlays += tile10
		overlays += tile01
		overlays += tile11

		var/image/tile20 = image('icons/misc/worlds.dmi',null,"2,0",10)
		tile20.pixel_x = 64

		var/image/tile02 = image('icons/misc/worlds.dmi',null,"0,2",10)
		tile02.pixel_y = 64

		var/image/tile22 = image('icons/misc/worlds.dmi',null,"2,2",10)
		tile22.pixel_y = 64
		tile22.pixel_x = 64

		var/image/tile21 = image('icons/misc/worlds.dmi',null,"2,1",10)
		tile21.pixel_y = 32
		tile21.pixel_x = 64

		var/image/tile12 = image('icons/misc/worlds.dmi',null,"1,2",10)
		tile12.pixel_y = 64
		tile12.pixel_x = 32

		overlays += tile20
		overlays += tile02
		overlays += tile22
		overlays += tile21
		overlays += tile12 */


/obj/river
	name = "River"
	desc = "Its a river."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "river"
	anchored = 1
	plane = PLANE_NOSHADOW_BELOW //You'd be amazed at what has depth shadows in space

/obj/stone
	name = "Stone"
	desc = "Its a stone."
	icon = 'icons/misc/worlds.dmi'
	icon_state = "stone"
	anchored = 1
	density=1

	random
		New()
			. = ..()
			src.dir = pick(alldirs)

/obj/rock/
	name = "rock"
	desc = "Some lil' rocks."
	icon = 'icons/obj/rocks.dmi'
	icon_state = "other"
	anchored = 1
	density = 0

	lava1
		name = "rocks"
		density = 0
		icon_state = "lava1"
	lava2
		name = "rocks"
		density = 0
		icon_state = "lava2"

	lava3
		name = "rocks"
		density = 0
		icon_state = "lava3"

	lava4
		name = "rocks"
		density = 0
		icon_state = "lava4"

	lava5
		name = "rocks"
		density = 0
		icon_state = "lava5"

	lava6
		name = "rocks"
		density = 0
		icon_state = "lava6"

	lava7
		name = "rocks"
		density = 0
		icon_state = "lava7"

	lava8
		name = "rocks"
		density = 1
		icon_state = "lava8"

	lava9
		name = "rocks"
		density = 0
		icon_state = "lava9"

/obj/shrub
	name = "shrub"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "shrub"
	anchored = 1
	density = 0
	layer = EFFECTS_LAYER_UNDER_1
	flags = FLUID_SUBMERGE
	text = "<font color=#5c5>s"
	var/health = 50
	var/destroyed = 0 // Broken shrubs are unable to vend prizes, this is also used to track a objective.
	var/max_uses = 0 // The maximum amount of time one can try to shake this shrub for something.
	var/spawn_chance = 0 // How likely is this shrub to spawn something?
	var/last_use = 0 // To prevent spam.
	var/time_between_uses = 400 // The default time between uses.
	var/override_default_behaviour = 0 // When this is set to 1, the additional_items list will be used to dispense items.
	var/list/additional_items = list() // See above.
	var/base_x = 0
	var/base_y = 0

	//	edible bushes
	//	max amount of reagent a bush can contain
	var/const/REAG_MAX_VOLUME = 50
	//	probability (in %) that its an edible shrub
	var/const/EDIBLE_PROB = 50
	//	limits for the random max_uses when edible
	var/const/MIN_MUNCHES = 2
	var/const/MAX_MUNCHES = 10
	//	probability (in %) to much
	var/const/MUNCH_PROB = 65
	//	time (in 1/10 seconds) between munches
	var/const/MUNCH_COOLDOWN = 50
	//	enabling this replaces the drop function with eat function
	var/edible = 0
	//	flavor of the bush
	var/flavor = "menthol"
	//	amount of flavor
	var/flavor_amount = 10
	//	amount of food to give a player cow
	var/food = 10
	//	feed multiplier, scales how much it feeds a cow
	var/feed_mult = 6
	//	bladder multiplier, scales how much it unbladders a cow (not even sure if cows have bladders)
	var/bladder_mult = -0.2

	New()
		..()

		if (prob(EDIBLE_PROB))
			edible = 1
			max_uses = rand(MIN_MUNCHES, MAX_MUNCHES)
			//	when edible, its the chance of munching
			spawn_chance = MUNCH_PROB
			//	when edible,
			time_between_uses = MUNCH_COOLDOWN
		else
			edible = 0
			max_uses = rand(0, 5)
			spawn_chance = rand(1, 40)

		base_x = pixel_x
		base_y = pixel_y

//	Allows for easier control at compile time
#if defined(ENV_BUSH_REAG_STORAGE_ON_NEW) && ENV_BUSH_REAG_STORAGE_ON_NEW
#if defined(ENV_BUSH_REAG_STORAGE_ALWAYS) && ENV_BUSH_REAG_STORAGE_ALWAYS
		//	I hope the compiler removes it directly
		if (1)
#else
		if (edible)
#endif
			src.create_reagents(REAG_MAX_VOLUME)
#endif

	ex_act(var/severity)
		switch(severity)
			if(1,2)
				qdel(src)
			else
				src.take_damage(45)
	attack_hand(mob/user as mob)
		if (!user) return
		if (destroyed) return ..()

		user.lastattacked = src

		//BUSH ANIMATION!!!!
		src.shake_bush(50)

		if (max_uses > 0 && ((last_use + time_between_uses) < world.time) && prob(spawn_chance))
			//	allows user to eat the shrub
			if (src.edible)
				if (user.a_intent == "harm")
					//	TODO: Add some compile-time checks
					//	This might be skipped if the define FLAGS are properly set
					if (!src.reagents)
						src.create_reagents(REAG_MAX_VOLUME);

					//	adds the flavor to this object before moving it to the eater and forcing a reaction
					src.reagents.add_reagent(flavor, flavor_amount)
					src.reagents.trans_to(user, flavor_amount)
					src.reagents.reaction(user, INGEST, flavor_amount)

					//	a player with mutant race "cow" will also be fed from it
					if (istype(user, /mob/living/carbon/human/))
						var/mob/living/carbon/human/h = user
						if (h.mutantrace && h.mutantrace.name == "cow")
							if (h.sims)
								h.sims.affectMotive("Hunger", food*feed_mult)
								h.sims.affectMotive("Bladder", food*bladder_mult)

					//	TODO: Visual effects
					//	Some effects of the bush being eaten would be cool

					//	shows message AFTER applying effects
					visible_message("<b><span class='alert'>[user] plucks some leafs from [src] and eats them!</span></b>", 1)
				else
					visible_message("<b><span class='alert'>[user] violently shakes [src] around![prob(20) ? " A few leaves fall out!" : null]</span></b>", 1)
			else
				var/something = null

				if (override_default_behaviour && islist(additional_items) && length(additional_items))
					something = pick(additional_items)
				else
					something = pick(trinket_safelist)

				if (ispath(something))
					var/thing = new something(src.loc)
					visible_message("<b><span class='alert'>[user] violently shakes [src] around! \An [thing] falls out!</span></b>", 1)
					last_use = world.time
					max_uses--
		else
			visible_message("<b><span class='alert'>[user] violently shakes [src] around![prob(20) ? " A few leaves fall out!" : null]</span></b>", 1)

		//no more BUSH SHIELDS
		for(var/mob/living/L in get_turf(src))
			if (!L.getStatusDuration("weakened") && !L.hasStatus("resting"))
				boutput(L, "<span class='alert'><b>A branch from [src] smacks you right in the face!</b></span>")
				L.TakeDamageAccountArmor("head", rand(1,6), 0, 0, DAMAGE_BLUNT)
				logTheThing("combat", user, L, "shakes a bush and smacks [L] with a branch [log_loc(user)].")
				var/r = rand(1,2)
				switch(r)
					if (1)
						L.changeStatus("weakened", 4 SECONDS)
					if (2)
						L.changeStatus("stunned", 2 SECONDS)

		interact_particle(user,src)

//BUSH ANIMATION!!!!
	proc/shake_bush(var/volume)
		playsound(src, "sound/impact_sounds/Bush_Hit.ogg", volume, 1, -1)

		var/wiggle = 6

		SPAWN_DBG(0) //need spawn, why would we sleep in attack_hand that's disgusting
			while (wiggle > 0)
				wiggle--
				animate(src, pixel_x = rand(src.base_x-3,src.base_x+3), pixel_y = rand(src.base_y-3,src.base_y+3), time = 2, easing = EASE_IN)
				sleep(0.1 SECONDS)

		animate(src, pixel_x = src.base_x, pixel_y = src.base_y, time = 2, easing = EASE_OUT)


	Crossed(atom/movable/AM)
		. = ..()
		if(isliving(AM))
			var/mob/living/L = AM
			L.name_tag?.set_visibility(FALSE)

	Uncrossed(atom/movable/AM)
		. = ..()
		if(isliving(AM))
			var/mob/living/L = AM
			L.name_tag?.set_visibility(TRUE)

	attackby(var/obj/item/W as obj, mob/user as mob)
		user.lastattacked = src
		hit_twitch(src)
		attack_particle(user,src)
		playsound(src, "sound/impact_sounds/Bush_Hit.ogg", 50, 1, 0)
		src.take_damage(W.force)
		user.visible_message("<span class='alert'><b>[user] hacks at [src] with [W]!</b></span>")

	proc/take_damage(var/damage_amount = 5)
		src.health -= damage_amount
		if (src.health <= 0)
			src.visible_message("<span class='alert'><b>The [src.name] falls apart!</b></span>")
			new /obj/decal/cleanable/leaves(get_turf(src))
			playsound(src.loc, "sound/impact_sounds/Slimy_Hit_3.ogg", 100, 0)
			qdel(src)
			return

	random
		New()
			. = ..()
			src.dir = pick(alldirs)

/obj/shrub/big
	name = "fern"
	icon = 'icons/obj/large/64x64.dmi'
	icon_state = "fern1"
	pixel_x = -16
	pixel_y = -16
	bound_width = 64
	bound_height = 64
	event_handler_flags = USE_HASENTERED

	//check if somebody walked in and its russlin' time
	HasEntered(atom/movable/AM as mob|obj)
		..()

		if(!(ishuman(AM) || AM.throwing))
			return

		if(isnpc(AM)) //if its a monkey (a type of human NPC)
			src.shake_bush(10)
			return

		if (AM.throwing) //if its a thlrown item and not a human/monke
			src.shake_bush(20)
			return
		//humans are much louder than thrown items and mobs
		//Only players will trigger this
		src.shake_bush(50)

/obj/shrub/big/big2
	icon_state = "fern2"

/obj/shrub/big/big3
	icon_state = "fern3"

//It'll show up on multitools
/obj/shrub/syndicateplant
	var/net_id
	New()
		. = ..()
		var/turf/T = get_turf(src.loc)
		var/obj/machinery/power/data_terminal/link = locate() in T
		link.master = src

/obj/shrub/captainshrub
	name = "\improper Captain's bonsai tree"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "shrub"
	desc = "The Captain's most prized possession. Don't touch it. Don't even look at it."
	anchored = 1
	density = 1
	layer = EFFECTS_LAYER_UNDER_1
	dir = EAST

	// Added ex_act and meteorhit handling here (Convair880).
	proc/update_icon()
		if (!src) return
		src.set_dir(NORTHEAST)
		src.destroyed = 1
		src.set_density(0)
		src.desc = "The scattered remains of a once-beautiful bonsai tree."
		playsound(src.loc, "sound/impact_sounds/Slimy_Hit_3.ogg", 100, 0)
		// The bonsai tree goes to the deadbar because of course it does
		var/obj/shrub/captainshrub/C = new /obj/shrub/captainshrub
		C.overlays += image('icons/misc/32x64.dmi',"halo")
		C.set_loc(pick(get_area_turfs(/area/afterlife/bar)))
		C.anchored = 0
		C.set_density(0)
		for (var/mob/living/M in mobs)
			if (M.mind && M.mind.assigned_role == "Captain")
				boutput(M, "<span class='alert'>You suddenly feel hollow. Something very dear to you has been lost.</span>")
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (!W) return
		if (!user) return
		if (inafterlife(user))
			boutput(user, "You can't bring yourself to hurt such a beautiful thing!")
			return
		if (src.destroyed) return
		if (user.mind && user.mind.assigned_role == "Captain")
			if (issnippingtool(W))
				boutput(user, "<span class='notice'>You carefully and lovingly sculpt your bonsai tree.</span>")
				global_objective_status["bonsai_tree_pruning"] = SUCCEEDED
			else
				boutput(user, "<span class='alert'>Why would you ever destroy your precious bonsai tree?</span>")
		else if(isitem(W) && (user.mind && user.mind.assigned_role != "Captain"))
			src.update_icon()
			boutput(user, "<span class='alert'>I don't think the Captain is going to be too happy about this...</span>")
			src.visible_message("<b><span class='alert'>[user] ravages the [src] with [W].</span></b>", 1)
			src.interesting = "Inexplicably, the genetic code of the bonsai tree has the words 'fuck [user.real_name]' encoded in it over and over again."
		return

	meteorhit(obj/O as obj)
		src.visible_message("<b><span class='alert'>The meteor smashes right through [src]!</span></b>")
		src.update_icon()
		src.interesting = "Looks like it was crushed by a giant fuck-off meteor."
		return

	ex_act(severity)
		src.visible_message("<b><span class='alert'>[src] is ripped to pieces by the blast!</span></b>")
		src.update_icon()
		src.interesting = "Looks like it was blown to pieces by some sort of explosive."
		return

	broccoliss
		name = "bonsai \"broccoliss\" tree"
		desc = "I don't think that Jeff guy knows what broccoli even is..."
		anchored = 0
		density = 1
		anchored = 0

		attackby(obj/item/W as obj, mob/user as mob)
			if (!W) return
			if (!user) return
			if (src.destroyed) return
			if (issnippingtool(W))
				boutput(user, "<span class='notice'>You aimlessly snip the broccoliss tree. Whatever.</span>")
			else
				src.update_icon()
				src.visible_message("<b><span class='alert'>[user] ravages the [src] with [W].</span></b>", 1)
			return

		update_icon()
			if (!src) return
			src.set_dir(NORTHEAST)
			src.destroyed = 1
			src.set_density(0)
			src.desc = "Broccoliss no more."
			playsound(src.loc, "sound/impact_sounds/Slimy_Hit_3.ogg", 100, 0)

/obj/captain_bottleship
	name = "\improper Captain's ship in a bottle"
	desc = "The Captain's most prized possession. Don't touch it. Don't even look at it."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "bottleship"
	anchored = 1
	density = 0
	layer = EFFECTS_LAYER_1
	var/destroyed = 0

	// stole all of this from the captain's shrub lol
	proc/update_icon()
		if (!src) return
		src.destroyed = 1
		src.desc = "The scattered remains of a once-beautiful ship in a bottle."
		playsound(src.loc, "sound/impact_sounds/Glass_Shards_Hit_1.ogg", 100, 0)
		// The bonsai goes to the deadbar so I guess the ship in a bottle does too lol
		var/obj/captain_bottleship/C = new /obj/captain_bottleship
		C.overlays += image('icons/misc/32x64.dmi',"halo")
		C.set_loc(pick(get_area_turfs(/area/afterlife/bar)))
		C.anchored = 0
		for (var/mob/living/M in mobs)
			if (M.mind && M.mind.assigned_role == "Captain")
				boutput(M, "<span class='alert'>You suddenly feel hollow. Something very dear to you has been lost.</span>")
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if (!W) return
		if (!user) return
		if (inafterlife(user))
			boutput(user, "You can't bring yourself to hurt such a beautiful thing!")
			return
		if (src.destroyed) return
		if (user.mind && user.mind.assigned_role == "Captain")
			boutput(user, "<span class='alert'>Why would you ever destroy your precious ship in a bottle?</span>")
		else if(isitem(W) && (user.mind && user.mind.assigned_role != "Captain"))
			src.update_icon()
			boutput(user, "<span class='alert'>I don't think the Captain is going to be too happy about this...</span>")
			src.visible_message("<b><span class='alert'>[user] ravages the [src] with [W].</span></b>", 1)
			src.interesting = "Inexplicably, the signal flags on the shattered mast just say 'fuck [user.real_name]'."
		return

	meteorhit(obj/O as obj)
		src.visible_message("<b><span class='alert'>The meteor smashes right through [src]!</span></b>")
		src.update_icon()
		src.interesting = "Looks like it was crushed by a giant fuck-off meteor."
		return

	ex_act(severity)
		src.visible_message("<b><span class='alert'>[src] is shattered and pulverized by the blast!</span></b>")
		src.update_icon()
		src.interesting = "Looks like it was blown to pieces by some sort of explosive."
		return

/obj/potted_plant
	name = "potted plant"
	icon = 'icons/obj/decoration.dmi'
	icon_state = "ppot0"
	anchored = 1
	density = 0

	New()
		..()
		if (src.icon_state == "ppot0") // only randomize a plant if it's not set to something specific
			src.icon_state = "ppot[rand(1,5)]"

	potted_plant1
		icon_state = "ppot1"

	potted_plant2
		icon_state = "ppot2"

	potted_plant3
		icon_state = "ppot3"

	potted_plant4
		icon_state = "ppot4"

	potted_plant5
		icon_state = "ppot5"

/obj/grassplug
	name = "grass"
	icon = 'icons/misc/worlds.dmi'
	icon_state = "grassplug"
	anchored = 1

/obj/window_blinds
	name = "blinds"
	icon = 'icons/obj/decoration.dmi'
	icon_state = "blindsH-o"
	anchored = 1
	density = 0
	opacity = 0
	layer = FLY_LAYER+1.01 // just above windows
	var/base_state = "blindsH"
	var/open = 1
	var/id = null
	var/obj/blind_switch/mySwitch = null

	New()
		. = ..()
		START_TRACKING

	disposing()
		. = ..()
		STOP_TRACKING

	ex_act(var/severity)
		switch(severity)
			if(1,2)
				qdel(src)
			else
				if(prob(50))
					qdel(src)
	attack_hand(mob/user as mob)
		src.toggle()
		src.toggle_group()

	attackby(obj/item/W, mob/user)
		src.toggle()
		src.toggle_group()

	proc/toggle(var/force_state as null|num)
		if (!isnull(force_state))
			src.open = force_state
		else
			src.open = !(src.open)
		src.update_icon()

	proc/toggle_group()
		if (istype(src.mySwitch))
			src.mySwitch.toggle()

	proc/update_icon()
		if (src.open)
			src.icon_state = "[src.base_state]-c"
			src.opacity = 1
		else
			src.icon_state = "[src.base_state]-o"
			src.opacity = 0

	left
		icon_state = "blindsH-L-o"
		base_state = "blindsH-L"
	middle
		icon_state = "blindsH-M-o"
		base_state = "blindsH-M"
	right
		icon_state = "blindsH-R-o"
		base_state = "blindsH-R"

	vertical
		icon_state = "blindsV-o"
		base_state = "blindsV"

		left
			icon_state = "blindsV-L-o"
			base_state = "blindsV-L"
		middle
			icon_state = "blindsV-M-o"
			base_state = "blindsV-M"
		right
			icon_state = "blindsV-R-o"
			base_state = "blindsV-R"

	cog2
		icon_state = "blinds_cog2-o"
		base_state = "blinds_cog2"

		left
			icon_state = "blinds_cog2-L-o"
			base_state = "blinds_cog2-L"
		middle
			icon_state = "blinds_cog2-M-o"
			base_state = "blinds_cog2-M"
		right
			icon_state = "blinds_cog2-R-o"
			base_state = "blinds_cog2-R"

/obj/blind_switch
	name = "blind switch"
	desc = "A switch for opening the blinds."
	icon = 'icons/obj/machines/power.dmi'
	icon_state = "light1"
	anchored = 1
	density = 0
	var/on = 0
	var/id = null
	var/list/myBlinds = list()

	New()
		..()
		if (!src.name || (src.name in list("N blind switch", "E blind switch", "S blind switch", "W blind switch")))//== "N light switch" || name == "E light switch" || name == "S light switch" || name == "W light switch")
			src.name = "blind switch"
		SPAWN_DBG(0.5 SECONDS)
			src.locate_blinds()
	ex_act(var/severity)
		switch(severity)
			if(1,2)
				qdel(src)
			else
				if(prob(50))
					qdel(src)
	proc/locate_blinds()
		for_by_tcl(blind, /obj/window_blinds)
			if (blind.id == src.id)
				if (!(blind in src.myBlinds))
					src.myBlinds += blind
					blind.mySwitch = src

	proc/toggle()
		src.on = !(src.on)
		src.icon_state = "light[!(src.on)]"
		if (!islist(myBlinds) || !length(myBlinds))
			return
		for (var/obj/window_blinds/blind in myBlinds)
			blind.toggle(src.on)

	attack_hand(mob/user as mob)
		src.toggle()

	attack_ai(mob/user as mob)
		src.toggle()

	attackby(obj/item/W, mob/user)
		src.toggle()

/obj/blind_switch/north
	name = "N blind switch"
	pixel_y = 24

/obj/blind_switch/east
	name = "E blind switch"
	pixel_x = 24

/obj/blind_switch/south
	name = "S blind switch"
	pixel_y = -24

/obj/blind_switch/west
	name = "W blind switch"
	pixel_x = -24

/obj/blind_switch/area
	locate_blinds()
		var/area/A = get_area(src)
		for_by_tcl(blind, /obj/window_blinds)
			var/area/blind_area = get_area(blind)
			if(blind_area != A)
				continue
			LAGCHECK(LAG_LOW)
			if (!(blind in src.myBlinds))
				src.myBlinds += blind
				blind.mySwitch = src

/obj/blind_switch/area/north
	name = "N blind switch"
	pixel_y = 24

/obj/blind_switch/area/east
	name = "E blind switch"
	pixel_x = 24

/obj/blind_switch/area/south
	name = "S blind switch"
	pixel_y = -24

/obj/blind_switch/area/west
	name = "W blind switch"
	pixel_x = -24

/obj/disco_ball
	name = "disco ball"
	icon = 'icons/obj/decoration.dmi'
	icon_state = "disco0"
	anchored = 1
	density = 0
	layer = 6
	var/on = 0
	var/datum/light/point/light

	New()
		..()
		light = new
		light.set_brightness(1)
		light.set_color(2,2,2)
		light.set_height(2.4)
		light.attach(src)

	attack_hand(mob/user as mob)
		src.toggle_on()

	proc/toggle_on()
		src.on = !src.on
		src.icon_state = "disco[src.on]"
		if (src.on)
			light.enable()
			if (!particleMaster.CheckSystemExists(/datum/particleSystem/sparkles_disco, src))
				particleMaster.SpawnSystem(new /datum/particleSystem/sparkles_disco(src))
		else
			light.disable()
			particleMaster.RemoveSystem(/datum/particleSystem/sparkles_disco, src)

/obj/billiard_lamp
	name = "billiards lamp"
	icon = 'icons/obj/decoration.dmi'
	icon_state = "billiardlamp"
	desc = "One of those old timey stained glass pool table lamps."
	anchored = 1
	density = 0
	layer = 6
	var/on = 0
	var/datum/light/point/light

	New()
		..()
		light = new
		light.set_brightness(1)
		light.set_color(2,2,2)
		light.set_height(2.4)
		light.attach(src)

	attack_hand(mob/user as mob)
		src.toggle_on()

	proc/toggle_on()
		src.on = !src.on
		if (src.on)
			light.enable()
		else
			light.disable()

/obj/admin_plaque
	name = "Admin's Office"
	desc = "A nameplate signifying who this office belongs to."
	icon = 'icons/obj/decals/wallsigns.dmi'
	icon_state = "office_plaque"
	anchored = 1

/obj/chainlink_fence
	name = "chain-link fence"
	icon = 'icons/obj/decoration.dmi'
	icon_state = "chainlink"
	anchored = 1
	density = 1
	centcom_edition
		name = "electrified super high-security mk. X-22 edition chain-link fence"
		desc = "Whoa."

		ex_act(severity)
			return

		meteorhit(obj/meteor)
			return

/obj/effects/background_objects
	icon = 'icons/misc/512x512.dmi'
	icon_state = "moon-ice"
	name = "X15"
	desc = "A nearby icy moon orbiting the gas giant. Deep reserves of liquid water have been detected below the fractured and desolate surface."
	mouse_opacity = 0
	opacity = 0
	anchored = 2
	density = 0
	plane = PLANE_SPACE
	var/rotate = FALSE
	var/rotate_speed = 100

	New()
		..()
		if(rotate)
			animate_spin(src, "L", rotate_speed, -1, FALSE)

	x3
		icon_state = "moon-green"
		name = "X3"
		desc = "A nearby rocky moon orbiting the gas giant. Steady intake of icy debris from the giant's ring system feeds moisture into the shallow, chilly atmosphere."

	x5
		icon_state = "moon-chunky"
		name = "X5"
		desc = "A nearby moon orbiting the gas giant. At certain elevations the atmosphere is thick enough to support terraforming efforts.."

	x4
		icon = 'icons/obj/large/160x160.dmi'
		icon_state = "bigasteroid_1"
		name = "X4"
		desc = "A jagged little moonlet or a really big asteroid. It's fairly close to your orbit, you can see the lights of Outpost Kappa."

	x0
		icon = 'icons/misc/1024x1024.dmi'
		icon_state = "plasma_giant"
		name = "X0"
		desc = "Your neighborhood plasma giant, a fair bit larger than Jupiter. The atmosphere is primarily composed of volatile FAAE. Little can be discerned of the denser layers below the plasma storms."

	star_red
		icon = 'icons/misc/galactic_objects_large.dmi'
		icon_state = "star-red"
		name = "Fugg"
		desc = "A dying red subgiant star shrouded in cast-off shells of gas."

	star_blue
		icon = 'icons/misc/galactic_objects_large.dmi'
		icon_state = "star-blue"
		name = "Shidd"
		desc = "A blazing young blue star."

	station
		name = "Space Station 14"
		desc = "Another Nanotrasen station passing by your orbit."
		icon = 'icons/obj/backgrounds.dmi'
		icon_state = "ss14"

		ss12
			name = "Space Station 12"
			desc = "That's... not good."
			icon_state = "ss12-broken"

		ss10
			name = "Space Station 10"
			desc = "Looks like the regional Nanotrasen hub station passing by your orbit."
			icon_state = "ss10"

obj/decoration


obj/decoration/decorativeplant
	name = "decorative plant"
	desc = "Is it flora or is it fauna? Hm."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "plant1"
	anchored = 1
	density = 1

	plant2
		icon_state = "plant2"
	plant3
		icon_state = "plant3"
	plant4
		icon_state = "plant4"
	plant5
		icon_state = "plant5"
	plant6
		icon_state = "plant6"
	plant7
		icon_state = "plant7"

obj/decoration/junctionbox
	name = "junction box"
	desc = "It seems to be locked pretty tight with no reasonable way to open it."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "junctionbox"
	anchored = 2

	junctionbox2
		icon_state = "junctionbox2"
	junctionbox3
		icon_state = "junctionbox3"

obj/decoration/clock
	name = "clock"
	//desc = "No wonder time always feels so frozen.."
	icon_state = "clock"
	desc = " "
	icon = 'icons/obj/decoration.dmi'
	anchored = 1

	get_desc()
		. += "[pick("The time is", "It's", "It's currently", "It reads", "It says")] [o_clock_time()]."

obj/decoration/clock/frozen
	desc = "The clock seems to be completely unmoving, frozen at exactly 3 AM."

	get_desc()
		return

obj/decoration/vent
	name = "vent"
	desc = "Better not to stick your hand in there, those blades look sharp.."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "vent1"
	anchored = 1

	vent2
		icon_state = "vent2"
	vent3
		icon_state = "vent3"

obj/decoration/ceilingfan
	name = "ceiling fan"
	desc = "It's actually just kinda hovering above the floor, not actually in the ceiling. Don't tell anyone."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "detectivefan"
	anchored = 1
	layer = EFFECTS_LAYER_BASE
	alpha = 255
	plane = PLANE_NOSHADOW_ABOVE
	#ifdef IN_MAP_EDITOR
	color = "#FFFFFF"
	alpha = 128
	#endif
	New()
		..()
		var/image/fanimage = image(src.icon,src,initial(src.icon_state),PLANE_NOSHADOW_ABOVE,src.dir)
		get_image_group(CLIENT_IMAGE_GROUP_CEILING_ICONS).add_image(fanimage)
		fanimage.alpha = 120
		src.alpha = 0


/obj/decoration/candles
	name = "wall mounted candelabra"
	desc = "It's a big candle."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "candles-unlit"
	density = 0
	anchored = 2
	opacity = 0
	var/icon_off = "candles-unlit"
	var/icon_on = "candles"
	var/brightness = 1
	var/col_r = 0.5
	var/col_g = 0.3
	var/col_b = 0.0
	var/lit = 0
	var/datum/light/light

	New()
		..()
		light = new /datum/light/point
		light.set_brightness(brightness)
		light.set_color(col_r, col_g, col_b)
		light.attach(src)

	proc/update_icon()
		if (src.lit == 1)
			src.icon_state = src.icon_on
			light.enable()

		else
			src.lit = 0
			src.icon_state = src.icon_off
			light.disable()

	attackby(obj/item/W as obj, mob/user as mob)
		if (!src.lit)
			if (isweldingtool(W) && W:try_weld(user,0,-1,0,0))
				boutput(user, "<span class='alert'><b>[user]</b> casually lights [src] with [W], what a badass.</span>")
				src.lit = 1
				update_icon()

			if (istype(W, /obj/item/clothing/head/cakehat) && W:on)
				boutput(user, "<span class='alert'>Did [user] just light [his_or_her(user)] [src] with [W]? Holy Shit.</span>")
				src.lit = 1
				update_icon()

			if (istype(W, /obj/item/device/igniter))
				boutput(user, "<span class='alert'><b>[user]</b> fumbles around with [W]; a small flame erupts from [src].</span>")
				src.lit = 1
				update_icon()

			if (istype(W, /obj/item/device/light/zippo) && W:on)
				boutput(user, "<span class='alert'>With a single flick of their wrist, [user] smoothly lights [src] with [W]. Damn they're cool.</span>")
				src.lit = 1
				update_icon()

			if ((istype(W, /obj/item/match) || istype(W, /obj/item/device/light/candle)) && W:on)
				boutput(user, "<span class='alert'><b>[user] lights [src] with [W].</span>")
				src.lit = 1
				update_icon()

			if (W.burning)
				boutput(user, "<span class='alert'><b>[user]</b> lights [src] with [W]. Goddamn.</span>")
				src.lit = 1
				update_icon ()

	attack_hand(mob/user as mob)
		if (src.lit)
			var/fluff = pick("snuff", "blow")
			src.lit = 0
			update_icon()
			user.visible_message("<b>[user]</b> [fluff]s out the [src].",\
			"You [fluff] out the [src].")


	disposing()
		if (light)
			light.dispose()
		..()

/obj/decoration/rustykrab
	name = "rusty krab sign"
	desc = "It's one of those old neon signs that diners used to have."
	icon_state = "rustykrab"
	icon = 'icons/obj/large/64x32.dmi'
	density = 0
	opacity = 0
	anchored = 2

/obj/decoration/bookcase
	name = "bookcase"
	desc = "It's a bookcase. Full of books."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "bookcase"
	anchored = 2
	density = 0
	layer = DECAL_LAYER

/obj/decoration/toiletholder
	name = "toilet paper holder"
	desc = "It's a toilet paper holder.<br>Finally, after all this time, you can wipe! Or not wipe, that's also a choice you can make."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "toiletholder"
	anchored = 1
	density = 0
	//var/papersleft = 20 //whatever

	attack_hand(mob/user as mob) //paper into toilet handling needed
		if (ishuman(user)) //buttcheck
			var/mob/living/carbon/human/H = user
			if (!H.get_organ("butt"))
				boutput(user, "So, uh. Hey. Bad news: you can't wipe right now. But hey, at least you don't need to, either, right?")
				return
		if (!user.wiped)
			if (prob(70))
				user.visible_message("[user] wipes [his_or_her(user)] [pick("ASS","BUTT","DUMPER","TUCHUS","BOOTY","BUTTOCKS","REAR END","HOAL", "BONUS ZONE")].","You wipe your [pick("ASS","BUTT","DUMPER","TUCHUS","BOOTY","BUTTOCKS","REAR END","HOAL", "BONUS ZONE")].") //i don't know i should be asleep
				user.wiped = 1
			else
				user.visible_message("[user] wipes [his_or_her(user)] [pick("ASS","BUTT","DUMPER","TUCHUS","BOOTY","BUTTOCKS","REAR END","HOAL", "BONUS ZONE")].","You wipe your [pick("ASS","BUTT","DUMPER","TUCHUS","BOOTY","BUTTOCKS","REAR END","HOAL", "BONUS ZONE")], but you need to go back for another pass!") //i don't know i should be asleep
			//papersleft--
		else
			boutput(user, "You don't need to wipe right now, but you're showing good initiative.")

/obj/decoration/toiletholder/empty
	name = "toilet paper holder"
	desc = "It's a toilet paper holder.<br>Someone used the last of it and didn't replace it..."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "toiletholder-empty"
	anchored = 1
	density = 0

	attack_hand(mob/user as mob)
		if (!user.wiped)
			user.visible_message("Oh, poo... You really needed that.")
		else
			user.visible_message("Well, damn. At least you don't need it right now.")

	//attack with toilet paper to refill. whatever.

/obj/decoration/tabletopfull
	name = "tabletop shelf"
	desc = "It's a shelf full of things that you'll need to play your favourite tabletop campaigns. Mainly a lot of dice that can only roll 1's."
	icon_state = "tabletopfull"
	icon = 'icons/obj/large/64x32.dmi'
	anchored = 2
	density = 0
	layer = DECAL_LAYER

/obj/decoration/syndiepc
	name = "syndicate computer"
	desc = "It looks rather sinister with all the red text. I wonder what does it all mean?"
	anchored = 2
	density = 1
	icon = 'icons/obj/decoration.dmi'
	icon_state = "syndiepc1"

	syndiepc2
		icon_state = "syndiepc2"

	syndiepc3
		icon_state = "syndiepc3"

	syndiepc4
		icon_state = "syndiepc4"

	syndiepc5
		icon_state = "syndiepc5"

	syndiepc6
		icon_state = "syndiepc6"

	syndiepc7
		icon_state = "syndiepc7"

	syndiepc8
		icon_state = "syndiepc8"

	syndiepc9
		icon_state = "syndiepc9"

	syndiepc10
		icon_state = "syndiepc10"

	syndiepc11
		icon_state = "syndiepc11"

	syndiepc12
		icon_state = "syndiepc12"

	syndiepc13
		icon_state = "syndiepc13"

	syndiepc14
		icon_state = "syndiepc14"

	syndiepc15
		icon_state = "syndiepc15"

	syndiepc16
		icon_state = "syndiepc16"

	syndiepc17
		icon_state = "syndiepc17"

	syndiepc18
		icon_state = "syndiepc18"

	syndiepc19
		icon_state = "syndiepc19"

	syndiepc20
		icon_state = "syndiepc20"

/obj/decoration/bustedmantapc
	name = "broken computer"
	desc = "Yeaaah, it has certainly seen some better days."
	anchored = 2
	density = 1
	icon = 'icons/obj/decoration.dmi'
	icon_state = "bustedmantapc"

	bustedmantapc2
		icon_state = "bustedmantapc2"
		name = "cracked computer"

	bustedmantapc3
		icon_state = "bustedmantapc3"
		name = "demolished computer"

/obj/decoration/collapsedwall
	name = "collapsed wall"
	anchored = 2
	density = 0
	opacity = 0
	icon = 'icons/obj/decoration.dmi'
	icon_state = "collapsedwall"

/obj/decoration/ntcratesmall
	name = "metal crate"
	anchored = 2
	density = 1
	desc = "A tightly locked metal crate."
	icon = 'icons/obj/decoration.dmi'
	icon_state = "ntcrate"

/obj/decoration/ntcrate
	name = "metal crate"
	anchored = 2
	density = 1
	desc = "Assortment of two metal crates, both of them sealed shut."
	icon = 'icons/obj/large/32x64.dmi'
	icon_state = "ntcrate1"
	layer = EFFECTS_LAYER_1
	appearance_flags = TILE_BOUND
	bound_height = 32
	bound_width = 32

	ntcrate2
		icon_state = "ntcrate2"

/obj/decoration/weirdmark
	name = "weird mark"
	anchored = 2
	icon = 'icons/obj/decoration.dmi'
	icon_state = "weirdmark"

/obj/decoration/frontwalldamage
	anchored = 2
	icon = 'icons/obj/decoration.dmi'
	icon_state = "frontwalldamage"
	mouse_opacity = 0

/obj/decoration/damagedchair
	name = "damaged chair"
	anchored = 2
	icon = 'icons/obj/decoration.dmi'
	icon_state = "damagedchair"

/obj/decoration/syndcorpse5
	anchored = 2
	name = "syndicate corpse"
	icon = 'icons/obj/decoration.dmi'
	desc = "Whoever this was, you're pretty sure they've had better days. Makes you wonder where the other half is..."
	icon_state = "syndcorpse5"

/obj/decoration/syndcorpse10
	anchored = 2
	name = "syndicate corpse"
	icon = 'icons/obj/decoration.dmi'
	desc = "... Oh, there it is."
	icon_state = "syndcorpse10"

/obj/decoration/bullethole
	anchored = 2
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bhole"
	mouse_opacity = 0
	plane = PLANE_NOSHADOW_BELOW

	examine()
		return list()

/obj/decoration/plasmabullethole
	anchored = 2
	icon = 'icons/obj/decoration.dmi'
	icon_state = "plasma-bhole"
	mouse_opacity = 0
	plane = PLANE_NOSHADOW_BELOW

	examine()
		return list()

//fake guns for shooting range prefab

/obj/item/gun/laser_pistol
	name = "laser pistol"
	icon = 'icons/obj/decoration.dmi'
	desc = "A terribly cheap and discontinued old model of laser pistol."
	icon_state = "laser_pistol"
	inhand_image_icon = 'icons/mob/inhand/hand_weapons.dmi'
	item_state = "protopistol"
	stamina_damage = 0
	stamina_cost = 4
	stamina_crit_chance = 0
	throwforce = 0

	attack_hand(mob/user as mob)
		if ((user.r_hand == src || user.l_hand == src) && src.contents && length(src.contents))
			user.visible_message("The cell on this is corroded. Good luck getting this thing to fire ever again!")
			src.add_fingerprint(user)
		else
			return ..()

/obj/item/gun/laser_pistol/prototype
	name = "prototype laser pistol"
	icon = 'icons/obj/decoration.dmi'
	desc = "You've never heard of this pistol before... who made it?"
	icon_state = "e_laser_pistol"

//stolen code for anchorable and movable target sheets. cannot get projectile tracking on them to work right now so. oh well. help appreciated!
/obj/item/caution/target_sheet
	desc = "A paper silhouette target sheet with a cardboard backing."
	name = "paper target"
	icon = 'icons/obj/decoration.dmi'
	icon_state = "target_paper"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "table_parts"
	density = 1
	force = 1.0
	throwforce = 3.0
	throw_speed = 1
	throw_range = 5
	w_class = W_CLASS_SMALL
	flags = FPRINT | TABLEPASS
	stamina_damage = 0
	stamina_cost = 4
	stamina_crit_chance = 0
	var/list/proj_impacts = list()
	var/image/proj_image = null
	var/last_proj_update_time = null

	New()
		..()
		BLOCK_SETUP(BLOCK_SOFT)

	attackby(obj/item/W, mob/user, params)
		if(iswrenchingtool(W))
			actions.start(new /datum/action/bar/icon/anchor_or_unanchor(src, W, duration=2 SECONDS), user)
			return
		. = ..()

	get_desc()
		if (islist(src.proj_impacts) && length(src.proj_impacts))
			var/shots_taken = 0
			for (var/i in src.proj_impacts)
				shots_taken ++
			. += "<br>[src] has [shots_taken] hole[s_es(shots_taken)] in it."

	proc/update_projectile_image(var/update_time)
		if (src.proj_impacts.len > 10)
			return
		if (src.last_proj_update_time && (src.last_proj_update_time + 1) < ticker.round_elapsed_ticks)
			return
		if (!src.proj_image)
			src.proj_image = image('icons/obj/projectiles.dmi', "bhole-small")
		src.proj_image.overlays = null
		for (var/image/i in src.proj_impacts)
			src.proj_image.overlays += i
		src.UpdateOverlays(src.proj_image, "projectiles")

//Walp Decor

/obj/decoration/regallamp
	name = "golden candelabra"
	desc = "Fancy."
	icon = 'icons/obj/furniture/walp_decor.dmi'
	icon_state = "lamp_regal_unlit"
	density = 0
	anchored = 0
	opacity = 0
	var/parts_type = /obj/item/furniture_parts/decor/regallamp
	var/icon_off = "lamp_regal_unlit"
	var/icon_on = "lamp_regal_lit"
	var/brightness = 1
	var/col_r = 0.5
	var/col_g = 0.3
	var/col_b = 0.0
	var/lit = 0
	var/securable = 1
	var/datum/light/light
	var/deconstructable = 1

	New()
		..()
		light = new /datum/light/point
		light.set_brightness(brightness)
		light.set_color(col_r, col_g, col_b)
		update_icon()
		light.attach(src)

	proc/update_icon()
		if (src.lit == 1)
			src.icon_state = src.icon_on
			light.enable()

		else
			src.lit = 0
			src.icon_state = src.icon_off
			light.disable()

	attackby(obj/item/W as obj, mob/user as mob)
		if (!src.lit)
			if (isweldingtool(W) && W:try_weld(user,0,-1,0,0))
				boutput(user, "<span class='alert'><b>[user]</b> casually lights [src] with [W], what a badass.</span>")
				src.lit = 1
				update_icon()

			if (istype(W, /obj/item/clothing/head/cakehat) && W:on)
				boutput(user, "<span class='alert'>Did [user] just light [his_or_her(user)] [src] with [W]? Holy Shit.</span>")
				src.lit = 1
				update_icon()

			if (istype(W, /obj/item/device/igniter))
				boutput(user, "<span class='alert'><b>[user]</b> fumbles around with [W]; a small flame erupts from [src].</span>")
				src.lit = 1
				update_icon()

			if (istype(W, /obj/item/device/light/zippo) && W:on)
				boutput(user, "<span class='alert'>With a single flick of their wrist, [user] smoothly lights [src] with [W]. Damn they're cool.</span>")
				src.lit = 1
				update_icon()

			if ((istype(W, /obj/item/match) || istype(W, /obj/item/device/light/candle)) && W:on)
				boutput(user, "<span class='alert'><b>[user] lights [src] with [W].</span>")
				src.lit = 1
				update_icon()

			if (W.burning)
				boutput(user, "<span class='alert'><b>[user]</b> lights [src] with [W]. Goddamn.</span>")
				src.lit = 1
				update_icon ()

	attack_hand(mob/user as mob)
		if (src.lit)
			var/fluff = pick("snuff", "blow")
			src.lit = 0
			update_icon()
			user.visible_message("<b>[user]</b> [fluff]s out the [src].",\
			"You [fluff] out the [src].")

	attackby(obj/item/W as obj, mob/user as mob)
		if (iswrenchingtool(W) && src.deconstructable)
			actions.start(new /datum/action/bar/icon/furniture_deconstruct(src, W, 30), user)
			return
		else if (isscrewingtool(W) && src.securable)
			src.toggle_secure(user)
			return
		else
			return ..()

	proc/toggle_secure(mob/user as mob)
		if (user)
			user.visible_message("<b>[user]</b> [src.anchored ? "loosens" : "tightens"] the floor bolts of [src].[istype(src.loc, /turf/space) ? " It doesn't do much, though, since [src] is in space and all." : null]")
		playsound(src, "sound/items/Screwdriver.ogg", 100, 1)
		src.anchored = !(src.anchored)
		src.p_class = src.anchored ? initial(src.p_class) : 2
		return

	disposing()
		if (light)
			light.dispose()
		..()

	proc/deconstruct()
		if (!src.deconstructable)
			return
		if (ispath(src.parts_type))
			var/obj/item/furniture_parts/P = new src.parts_type(src.loc)
			if (P && src.material)
				P.setMaterial(src.material)
			if (P && src.color)
				P.color = src.color
		else
			playsound(src.loc, "sound/items/Ratchet.ogg", 50, 1)
			var/obj/item/sheet/S = new (src.loc)
			if (src.material)
				S.setMaterial(src.material)
			else
				var/datum/material/M = getMaterial("steel")
				S.setMaterial(M)
		qdel(src)
		return


/obj/decoration/floralarrangement
	name = "floral arrangement"
	desc = "These look... Very plastic. Huh."
	icon = 'icons/obj/furniture/walp_decor.dmi'
	icon_state = "floral_arrange"
	anchored = 1
	density = 1

/obj/decoration/railbed
	icon = 'icons/obj/large/32x64.dmi'
	icon_state = "railbed"
	anchored = 1
	density = 0
	mouse_opacity = 0
	plane = PLANE_NOSHADOW_BELOW
	layer = TURF_LAYER - 0.1
	//Grabs turf color set in gehenna.dm for sand
	New()
		..()
		var/turf/T = get_turf(src)
		src.color = T.color

/obj/decoration/railbed/cracked1
	icon_state = "railbedcracked1"

/obj/decoration/railbed/cracked2
	icon_state = "railbedcracked2"

/obj/decoration/railbed/trans
	icon_state = "railbedtrans"
	New()
		..()
		src.color = null

/obj/decoration/railbed/trans/cracked1
	icon_state = "railbedcracked1trans"

/obj/decoration/railbed/trans/cracked2
	icon_state = "railbedcracked2trans"

/obj/decoration/train_signal
	icon = 'icons/obj/large/32x64.dmi'
	icon_state = "trainsignal"
	anchored = 1
	density = 0
	plane = PLANE_NOSHADOW_BELOW
	//this is just a dummy until it gets logic

/obj/neon_sign
	name = "neon sign"
	desc = "A neon sign that lights up the area with a soft glow."
	icon = 'icons/obj/neonsigns.dmi'
	icon_state = "git"
	var/base_icon_state = "git"
	var/animated = FALSE
	var/light_brightness = 0.5
	var/light_r = 1
	var/light_g = 1
	var/light_b = 1
	var/datum/light/light
	plane = BLEND_OVERLAY
	layer = PLANE_SELFILLUM

	New()
		..()
		if(animated)
			icon_state = "[base_icon_state]-a"
		else
			icon_state = base_icon_state
		light = new /datum/light/point
		light.set_brightness(light_brightness)
		light.set_color(light_r, light_g, light_b)
		light.attach(src)
		light.enable()


/obj/neon_sign/toolbox
	name = "toolbox neon sign"
	desc = "A neon sign shaped like a toolbox."
	icon_state = "toolbox"
	base_icon_state = "toolbox"
	animated = TRUE
	light_r = 0.9
	light_g = 0.3
	light_b = 0.86
/obj/neon_sign/exit
	name = "exit neon sign"
	desc = "A neon exit sign."
	icon_state = "exit"
	base_icon_state = "exit"
	animated = FALSE
	light_r = 0.3
	light_g = 0.9
	light_b = 0.39
/obj/neon_sign/nt
	name = "nanotrasen neon sign"
	desc = "A neon sign with the Nanotrasen logo."
	icon_state = "nt"
	base_icon_state = "nt"
	animated = FALSE
	light_r = 0.2
	light_g = 0.5
	light_b = 1
/obj/neon_sign/syndie
	name = "syndicate neon sign"
	desc = "A neon sign with the Syndicate logo."
	icon_state = "syndie"
	base_icon_state = "syndie"
	animated = FALSE
	light_r = 0.9
	light_g = 0.3
	light_b = 0.86
/obj/neon_sign/open
	name = "open neon sign"
	desc = "A neon sign that says 'OPEN'."
	icon_state = "open"
	base_icon_state = "open"
	animated = TRUE
	light_r = 0.52
	light_g = 0.2
	light_b = 1
/obj/neon_sign/hearts
	name = "heart neon sign"
	desc = "A heart shaped neon sign."
	icon_state = "hearts"
	base_icon_state = "hearts"
	animated = TRUE
	light_r = 0.9
	light_g = 0.3
	light_b = 0.86
/obj/neon_sign/diamonds
	name = "diamond neon sign"
	desc = "A diamond shaped neon sign."
	icon_state = "diamonds"
	base_icon_state = "diamonds"
	animated = TRUE
	light_r = 0.9
	light_g = 0.3
	light_b = 0.86
/obj/neon_sign/spades
	name = "spade neon sign"
	desc = "A spade shaped neon sign."
	icon_state = "spades"
	base_icon_state = "spades"
	animated = TRUE
	light_r = 0.2
	light_g = 0.5
	light_b = 1
/obj/neon_sign/clubs
	name = "club neon sign"
	desc = "A club shaped neon sign."
	icon_state = "clubs"
	base_icon_state = "clubs"
	animated = TRUE
	light_r = 0.2
	light_g = 0.5
	light_b = 1
/obj/neon_sign/sun
	name = "sun neon sign"
	desc = "A neon sign shaped like a sun."
	icon_state = "sun"
	base_icon_state = "sun"
	animated = TRUE
	light_r = 0.2
	light_g = 1
	light_b = 0.78
/obj/neon_sign/medical
	name = "medical neon sign"
	desc = "A neon sign with a medical cross."
	icon_state = "medical"
	base_icon_state = "medical"
	animated = FALSE
	light_r = 0.9
	light_g = 0.3
	light_b = 0.86
/obj/neon_sign/medical/weed
	name = "weed neon sign"
	desc = "A neon sign with a green 'medical' cross."
	icon_state = "weedzone"
	base_icon_state = "weedzone"
	animated = TRUE
	light_r = 0.3
	light_g = 0.9
	light_b = 0.39
/obj/neon_sign/peace
	name = "peace neon sign"
	desc = "A neon sign with a peace symbol."
	icon_state = "peace"
	base_icon_state = "peace"
	animated = TRUE
	light_r = 0.3
	light_g = 0.9
	light_b = 0.39
/obj/neon_sign/bees
	name = "bees neon sign"
	desc = "A neon sign spelling out BIG BEES."
	icon_state = "bees"
	base_icon_state = "bees"
	animated = TRUE
	light_r = 0.2
	light_g = 1
	light_b = 0.78
/obj/neon_sign/syringe
	name = "syringe neon sign"
	desc = "A neon sign shaped like a syringe."
	icon_state = "syringe"
	base_icon_state = "syringe"
	animated = TRUE
	light_r = 0.2
	light_g = 0.5
	light_b = 1
/obj/neon_sign/knife
	name = "knife neon sign"
	desc = "A neon sign shaped like a knife."
	icon_state = "knife"
	base_icon_state = "knife"
	animated = TRUE
	light_r = 0.2
	light_g = 0.5
	light_b = 1
/obj/neon_sign/gun
	name = "gun neon sign"
	desc = "A neon sign shaped like a gun."
	icon_state = "gun"
	base_icon_state = "gun"
	animated = FALSE
	light_r = 0.2
	light_g = 0.5
	light_b = 1
/obj/neon_sign/flaming
	name = "flamingo neon sign"
	desc = "A neon sign shaped like a flamingo."
	icon_state = "flaming"
	base_icon_state = "flaming"
	animated = TRUE
	light_r = 0.9
	light_g = 0.3
	light_b = 0.86
/obj/neon_sign/caviar
	name = "cocktail neon sign"
	desc = "A neon sign shaped like a cocktail glass."
	icon_state = "caviar"
	base_icon_state = "caviar"
	animated = TRUE
	light_r = 0.2
	light_g = 0.5
	light_b = 1
/obj/neon_sign/beer
	name = "beer neon sign"
	desc = "A neon sign shaped like a beer mug."
	icon_state = "beer"
	base_icon_state = "beer"
	animated = TRUE
	light_r = 0.94
	light_g = 0.98
	light_b = 0.02
