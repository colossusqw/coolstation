// The lighting system
//
// consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/light)


// light_status values shared between lighting fixtures and items
// defines moved to _setup.dm by ZeWaka

/obj/item/light_parts
	name = "fixture parts"
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-fixture"
	mats = 4

	var/installed_icon_state = "tube-empty"
	var/installed_base_state = "tube"
	desc = "Parts of a lighting fixture"
	var/fixture_type = /obj/machinery/light
	var/light_type = /obj/item/light/tube
	var/fitting = "tube"
	//TODO: use some tool in hand to orient the mounts from wall to ceiling and vice versa

// For metal sheets. Can't easily change an item's vars the way it's set up (Convair880).
/obj/item/light_parts/bulb
	icon_state = "bulb-fixture"
	fixture_type = /obj/machinery/light/small
	installed_icon_state = "bulb1"
	installed_base_state = "bulb"
	fitting = "bulb"
	light_type = /obj/item/light/bulb

/obj/item/light_parts/floor
	icon_state = "floor-fixture"
	fixture_type = /obj/machinery/light/small/floor/neutral
	installed_icon_state = "floor1"
	installed_base_state = "floor"
	fitting = "floor"
	light_type = /obj/item/light/bulb
	//TODO: use some tool in hand to orient the mounts from floor to ceiling and vice versa

/obj/item/light_parts/proc/copy_light(obj/machinery/light/target)
	installed_icon_state = target.icon_state
	installed_base_state = target.base_state
	light_type = target.light_type
	fixture_type = target.type
	fitting = target.fitting
	if (fitting == "tube")
		icon_state = "tube-fixture"
	else if (fitting == "floor")
		icon_state = "floor-fixture"
	else
		icon_state = "bulb-fixture"


//MBC : moving lights to consume power inside as an area-wide process() instead of each individual light processing its own shit
/obj/machinery/light_area_manager
	#define LIGHTING_POWER_FACTOR 40
	name = "Area Lighting"
	event_handler_flags = IMMUNE_SINGULARITY | USE_FLUID_ENTER
	invisibility = INVIS_ALWAYS_ISH
	flags = TECHNICAL_ATOM
	var/area/my_area = null
	var/list/lights = list()
	var/brightness_placeholder = 1	//hey, maybe later use this in a way that is more optimized than iterating through each individual light

/obj/machinery/light_area_manager/ex_act(severity)
	return

/obj/machinery/light_area_manager/process()
	if(my_area?.power_light && my_area.lightswitch)
		..()
		var/thepower = src.brightness_placeholder * LIGHTING_POWER_FACTOR
		use_power(thepower * lights.len, LIGHT)




// the standard tube light fixture

/var/global/stationLights = new/list()
/obj/machinery/light //basic root of lighting, currently hosts fluorescent/tube/large lights, maybe move that to /obj/machinery/light/large for clarity
	name = "light fixture"
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube1"
	desc = "A lighting fixture."
	anchored = 1
	layer = EFFECTS_LAYER_UNDER_1
	plane = PLANE_NOSHADOW_ABOVE
	text = ""
	power_usage = 0
	power_channel = LIGHT
	// base description and icon_state
	var/base_state = "tube"
	//toggles the actual state of giving off light
	var/on = 0
	// luminosity when on, also used in power calculation
	var/brightness = 1.6
	// the type of the inserted light item
	var/obj/item/light/light_type = /obj/item/light/tube
	// the type of allowed light items
	var/allowed_type = /obj/item/light/tube
	// Reference for the actual lamp item inside
	var/inserted_lamp = null
	// For easily accessing inserted_lamp's variables, which we do often enough. Don't desync these two!
	var/obj/item/light/current_lamp = null
	//the style of bulb
	var/fitting = "tube"
	//1 for normal, 0 for not (i.e. floor or ceiling)
	var/wallmounted = TRUE
	//0 for normal, 1 for ceiling
	var/ceilingmounted = FALSE
	//the icon we update for the image overlay below
	var/ceiling_icon = null
	//the actual image representing "thing on the ceiling"
	var/image/lightfixtureimage = null // i'm going to eat my own head with my other head
	//If set to true, overrides the autopositioning.
	var/nostick = TRUE
	//Possible to remove this fixture with a screwdriver
	var/candismantle = 1
	//Possible to remove the bulb (emergency light, etc.)
	var/removable_bulb = 1
	//The actual thing that illuminates the world
	var/datum/light/point/light

	///If true, the light will apply a mouse-transparent glow image with iconstate [base_state]-glow when the light is on.
	var/has_glow = TRUE //TODO - transition maps to /obj/machinery/light/fluorescent so this can be false by default
	var/obj/overlay/glow = null

	var/has_bulb_overlay = FALSE
	var/image/bulb_overlay

	New()
		..()
		light = new
		light.set_brightness(brightness)
		light.set_color(initial(src.light_type.color_r), initial(src.light_type.color_g), initial(src.light_type.color_b))
		light.set_height(2.4)
		light.attach(src)

		if(src.has_bulb_overlay)
			src.bulb_overlay = image(src.icon, src, "[src.base_state]_g")
			src.bulb_overlay.plane = PLANE_SELFILLUM
			src.bulb_overlay.layer = LIGHTING_LAYER_FULLBRIGHT
			src.bulb_overlay.blend_mode = BLEND_OVERLAY
			src.bulb_overlay.color = rgb(clamp(src.light.r * 255, 150, 255), clamp(src.light.g * 255, 150, 255), clamp(src.light.b * 220, 150, 255))

		SPAWN_DBG(1 DECI SECOND)
			update()

		if(current_state <= GAME_STATE_WORLD_INIT) //close to map
			SPAWN_DBG(0)
				//attempt to get a lamp off the floor, as a mapper alternative to using
				//lamp items are reasonably well colour coded, but all the fixtures use the same sprites.
				//May be visually easier to debug a map, IDK.
				inserted_lamp = locate(/obj/item/light) in src.loc
				if (istype(inserted_lamp, allowed_type)) //also catches null
					insert(null, inserted_lamp) // a lil backwards going by names but shh
				else
					inserted_lamp = new light_type()
					current_lamp = inserted_lamp
		else
			inserted_lamp = new light_type()
			current_lamp = inserted_lamp


		if (src.loc.z == 1 ||(map_currently_very_dusty && src.loc.z == 3))
			stationLights += src

		if(ceilingmounted)
			icon_state = "blank"
			lightfixtureimage = image(src.icon,src,initial(src.icon_state),PLANE_NOSHADOW_ABOVE -1,src.dir)
			get_image_group(CLIENT_IMAGE_GROUP_CEILING_ICONS).add_image(lightfixtureimage)
			lightfixtureimage.alpha = 200

		if (has_glow)
			glow = new(src)//mage(src.icon,src,"[base_state]-glow",PLANE_NOSHADOW_ABOVE,src.dir)
			glow.icon_state = "[base_state]-glow"
			glow.plane = PLANE_LIGHTING
			glow.layer = LIGHTING_LAYER_BASE
			glow.blend_mode = BLEND_ADD
			glow.vis_flags = VIS_INHERIT_ICON | VIS_INHERIT_DIR  //IDK
			glow.mouse_opacity = FALSE //Here's what we do this for

		var/area/A = get_area(src)
		if (A)
			UnsubscribeProcess()
			A.add_light(src)

	disposing()
		if (src in stationLights)
			stationLights -= src

		if (inserted_lamp)
			qdel(inserted_lamp)
			inserted_lamp = null

		if(ceilingmounted)
			get_image_group(CLIENT_IMAGE_GROUP_CEILING_ICONS).remove_image(lightfixtureimage)

		if(glow)
			vis_contents -= glow
			qdel(glow)
			glow = null

		var/area/A = get_area(src)
		if (A)
			A.remove_light(src)
		if (light)
			light.dispose()
		..()

	//auto position these lights so i don't have to mess with dirs in the map editor that's annoying!!!
	proc/autoposition(setdir = null)

		if(nostick)
			return // we shouldn'a been here!! adding this for legacy uses (i dont feel like chasing them down right now im old and im tired and im back hurts)
		if(!wallmounted || ceilingmounted) //floor or ceiling
			return //some ceiling lights can be rotated but that will be by hand or map placement, not by this
		//if (map_settings)
		//	if (!map_settings.auto_walls)
		//		return // no walls to adjust to! stop it!! STOP IT!!
		// well now we have the standard lighting object that isn't sticky and the auto object that is and we gotta do this at some point!!

		SPAWN_DBG(1 DECI SECOND) //wait for the wingrille spawners to complete when map is loading (ugly i am sorry)
			var/turf/T = null
			var/list/directions = null
			if (setdir)
				directions = list(setdir)
			else
				directions = cardinal
			for (var/dir in directions)
				T = get_step(src,dir)
				if (istype(T,/turf/wall) || (locate(/obj/wingrille_spawn) in T) || (locate(/obj/window) in T)) //ah this was missing, set dir for every wall and check them later
					var/is_perspective = 0 //check if the walls are not flat and classic- special handling needed to make them look nice
					var/is_jen_wall = 0 // jen walls' ceilings are narrower, so let's move the lights a bit further inward!
					if (istype(T,/turf/wall/auto/supernorn) || istype(T,/turf/wall/auto/marsoutpost) || istype(T,/turf/wall/auto/supernorn/wood) || (locate(/obj/wingrille_spawn) in T) || (locate(/obj/window/auto) in T))
						is_perspective = 1 //basically if it's a perspective autowall or new glass?? let's a go
					//if ((locate(/obj/wingrille_spawn/classic) in T) || (locate(/obj/wingrille_spawn/reinforced/classic) in T))
						//is_perspective = 0 //oh no the root of wingrille spawn is perspective but the classic wingrille spawn is not! time to handle and unset (this can surely be done better but whatever)
						//actually shit how expensive is it to add a variable to turfs that says if they're perspective or classic?? i'm just imcoder enough to wonder but not enough to know
						//commented out until my new old grilles are readded
					if (istype(T, /turf/wall/auto/jen) || istype(T, /turf/wall/auto/reinforced/jen))
						is_jen_wall = 1 //handling for different offsets in the sprites
						is_perspective = 1 //these are also perspective and without this it doesn't go
					src.set_dir(dir) //okay here is the part that actually puts a light against a valid turf how did i accidentally delete this
					if (!is_perspective) //is this going on a flat wall?
						return //then all we need is the direction for sticking and are done here at this point
					if (dir == EAST) //all this is for handling offsets on 3d looking walls
						if (is_jen_wall)
							src.pixel_x = 12
						else
							src.pixel_x = 10
					else if (dir == WEST)
						if (is_jen_wall)
							src.pixel_x = -12
						else
							src.pixel_x = -10
					else if (dir == NORTH)
						if (is_jen_wall)
							src.pixel_y = 24
						else
							src.pixel_y = 21
					break
				T = null

//big standing lamps
/obj/machinery/light/flamp
	name = "floor lamp"
	icon = 'icons/obj/lighting.dmi'
	desc = "A tall and thin lamp that rests comfortably on the floor."
	anchored = 1
	light_type = /obj/item/light/bulb
	allowed_type = /obj/item/light/bulb
	fitting = "bulb"
	brightness = 1.4
	var/state
	base_state = "flamp"
	icon_state = "flamp1"
	wallmounted = FALSE

//regular light bulbs
/obj/machinery/light/small
	icon_state = "bulb1"
	base_state = "bulb"
	fitting = "bulb"
	brightness = 1.5
	desc = "A small lighting fixture."
	light_type = /obj/item/light/bulb
	allowed_type = /obj/item/light/bulb
	has_bulb_overlay = TRUE

	New()
		..()


/obj/machinery/light/small/auto
	nostick = FALSE

	New()
		..()
		autoposition()

//floor lights
/obj/machinery/light/small/floor
	icon_state = "floor1"
	base_state = "floor"
	desc = "A small lighting fixture, embedded in the floor."
	plane = PLANE_FLOOR
	allowed_type = /obj/item/light/bulb
	wallmounted = FALSE
	has_bulb_overlay = FALSE

//ceiling lights!!
/obj/machinery/light/small/ceiling
	icon_state = "floor1"
	base_state = "floor"
	desc = "A small round lighting fixture, embedded in the ceiling."
	plane = PLANE_NOSHADOW_ABOVE
	allowed_type = /obj/item/light/bulb
	level = 2
	wallmounted = FALSE
	ceilingmounted = TRUE
	has_bulb_overlay = FALSE

//finally redid these sprites
//good for shitty areas like maint
/obj/machinery/light/small/ceiling/bare
	icon_state = "overbulb1"
	base_state = "overbulb"
	desc = "A small bare-bulb lighting fixture, embedded in the ceiling."
	has_bulb_overlay = FALSE

//emergency lights that turn on when either the power is out or an alert is triggered on the bridge
/obj/machinery/light/emergency
	icon_state = "ebulb1"
	base_state = "ebulb"
	fitting = "bulb"
	brightness = 1
	desc = "A small light used to illuminate in emergencies."
	light_type = /obj/item/light/bulb/emergency
	allowed_type = /obj/item/light/bulb/emergency
	on = 0
	removable_bulb = 0
	has_glow = TRUE
	has_bulb_overlay = FALSE

//Same as the above but starts on and stays on
/obj/machinery/light/emergencyflashing
	icon_state = "ebulb1"
	base_state = "ebulb"
	fitting = "bulb"
	name = "warning light"
	brightness = 1.3
	desc = "This foreboding light warns of danger."
	light_type = /obj/item/light/bulb/emergency
	allowed_type = /obj/item/light/bulb/emergency
	on = 1
	removable_bulb = 0
	has_glow = TRUE
	has_bulb_overlay = FALSE

	//repurpose for actual exit signs per room that flash when the shuttle's here
	exitsign
		name = "illuminated exit sign"
		desc = "This sign points the way to the escape shuttle."
		brightness = 1.3

	alertonly
		name = "alert status light"
		desc = "A small light that illuminates during alerts."
		brightness = 1.3

/* -------------------------------------------------------------------------- */
/*                         Shuttle Escape Route Lights                        */
/* -------------------------------------------------------------------------- */
// first draft
// is set off by shuttle arriving on station and shuts off again when shuttle leaves
// intended for use in the middle of all main hallways to guide crew to departure
// alternates for going down the middle of 2 or 4 tile hallways or perhaps along walls
// build corners by using two of them, or intersections by using 3 or 4
// cardinal directions only

/obj/machinery/light/emergency/shuttle
	name = "shuttle evacuation light"
	desc = "A small light that directs the way to the departing shuttle bay."
	#ifdef IN_MAP_EDITOR
	icon_state = "shuttle-egress-map"
	#else
	icon_state = "blank"
	#endif IN_MAP_EDITOR
	brightness = 0.3
	wallmounted = FALSE
	plane = PLANE_FLOOR
	mouse_opacity = 1 //you can't click this because that'd kinda suck
	var/halves = 3 //1 for first, 2 for second, 3 for both
	var/even = FALSE // false for centered, true for offset to north or east line (for even-tile hallways)
	var/evenalt = FALSE //normally center to north or east, this will center to south or west
	var/on_state = "shuttle-egress" //when this turns on, what iconstate to load

	//this can all be done so much better but i'm doing it this way for now so i have something to show
	//everything is cardinal and basic, if you want compound lights and intersections just plop down more

	New()
		..()
		//initial slight offset due to the 32x32 cutoff
		//if unspecified, go with the default intended offsets
		if (!pixel_y || !pixel_x)
			if(dir & (NORTH | SOUTH))
				pixel_y = -4
			else
				pixel_x = 4

			if(even)
				//bonus nudge for horizontal or vertical instances
				if(dir & (NORTH | SOUTH))
					//if normal even handling
					if (!evenalt)
						//shift half a tile east
						pixel_x += 16
					else
						//shift half a tile west
						pixel_x -= 16
				else
					//if normal even handling
					if (!evenalt)
						//shift half a tile north
						pixel_y += 16
					else
						//shift half a tile south
						pixel_y -= 16

//the first half of the full light sequence, for building corners and intersections. direction is direction of light path
//for example, first half dir north + second half dir north = just a normal full light sequence dir north
/obj/machinery/light/emergency/shuttle/firsthalf
	name = "shuttle evacuation light"
	#ifdef IN_MAP_EDITOR
	icon_state = "shuttle-egress-1-map"
	#else
	icon_state = "blank"
	#endif IN_MAP_EDITOR
	on_state = "shuttle-egress-1"

//the second half of the full light sequence, for building corners and intersections. direction is direction of light path
/obj/machinery/light/emergency/shuttle/secondhalf
	name = "shuttle evacuation light"
	#ifdef IN_MAP_EDITOR
	icon_state = "shuttle-egress-2-map"
	#else
	icon_state = "blank"
	#endif IN_MAP_EDITOR
	on_state = "shuttle-egress-2"

//if you have a hallway where this will be off center scootch this by 16 to the right if NS or 16 down if EW
//the timing is also off by half because so is the positioning
/obj/machinery/light/emergency/shuttle/even
	name = "shuttle evacuation light"
	#ifdef IN_MAP_EDITOR
	icon_state = "shuttle-egress-map"
	#else
	icon_state = "blank"
	#endif IN_MAP_EDITOR
	even = TRUE
	on_state = "shuttle-egress-centered"

	//these are purely here as mapping aids but may help with buildmode/spawn stuff
	horizontal
		pixel_x = 4
		pixel_y = 16
		alt
			pixel_y = -16
	vertical
		pixel_x = 16
		pixel_y = -4
		alt
			pixel_x = -16

//the first half offset for even-tile hallways, with altered timing
/obj/machinery/light/emergency/shuttle/firsthalf/even
	even = TRUE
	on_state = "shuttle-egress-1-centered"

	horizontal
		pixel_x = 4
		pixel_y = 16

		alt
			pixel_y = -16

	vertical
		pixel_x = 16
		pixel_y = -4

		alt
			pixel_x = -16

//the second half offset for even-tile hallways, with altered timing
/obj/machinery/light/emergency/shuttle/secondhalf/even
	pixel_y = 12
	even = TRUE
	on_state = "shuttle-egress-2-centered"

	horizontal
		pixel_x = 4
		pixel_y = 16

		alt
			pixel_y = -16

	vertical
		pixel_x = 16
		pixel_y = -4

		alt
			pixel_x = -16

/obj/machinery/light/runway_light
	name = "runway light"
	desc = "A small light used to guide pods into hangars."
	icon_state = "runway10"
	base_state = "runway1"
	fitting = "bulb"
	brightness = 0.5
	light_type = /obj/item/light/bulb
	allowed_type = /obj/item/light/bulb
	plane = PLANE_NOSHADOW_BELOW
	on = 1
	wallmounted = FALSE
	removable_bulb = FALSE

	delay2
		icon_state = "runway20"
		base_state = "runway2"
	delay3
		icon_state = "runway30"
		base_state = "runway3"
	delay4
		icon_state = "runway40"
		base_state = "runway4"
	delay5
		icon_state = "runway50"
		base_state = "runway5"

/obj/machinery/light/beacon
	name = "tripod light"
	desc = "A large portable light tripod."
	density = 1
	anchored = 1
	icon_state = "tripod1"
	base_state = "tripod"
	fitting = "bulb"
	wallmounted = FALSE
	brightness = 1.5
	light_type = /obj/item/light/big_bulb
	allowed_type = /obj/item/light/big_bulb
	power_usage = 0
	has_bulb_overlay = FALSE

	attackby(obj/item/W, mob/user)

		if (issilicon(user))
			return

		if (istype(W, /obj/item/wrench))

			add_fingerprint(user)
			src.anchored = !src.anchored

			if (!src.anchored)
				boutput(user, "<span class='alert'>[src] can now be moved.</span>")
				src.on = 0
			else
				boutput(user, "<span class='alert'>[src] is now secured.</span>")
				src.on = 1

			update()

		else
			return ..()

	has_power()
		return src.anchored

//Older lighting that doesn't power up so well anymore.
/obj/machinery/light/fluorescent/worn
	desc = "A rather old-looking lighting fixture."
	brightness = 1
	New()
		..()
		SPAWN_DBG(1)
			current_lamp.breakprob = 6.25

// the desk lamp
/obj/machinery/light/lamp
	name = "desk lamp"
	icon_state = "lamp1"
	base_state = "lamp"
	fitting = "bulb"
	brightness = 1
	desc = "A desk lamp"
	light_type = /obj/item/light/bulb
	allowed_type = /obj/item/light/bulb
	wallmounted = FALSE
	deconstruct_flags = DECON_SIMPLE
	plane = PLANE_DEFAULT
	has_bulb_overlay = FALSE

	var/switchon = 0		// independent switching for lamps - not controlled by area lightswitch

	bright
		brightness = 1.8
		switchon = 1

// green-shaded desk lamp
/obj/machinery/light/lamp/green
	icon_state = "green1"
	base_state = "green"
	desc = "A green-shaded desk lamp"

	New()
		..()
		light.set_color(0.45, 0.85, 0.25)

//special lights w very specific colors. made for sealab!
/obj/machinery/light/fluorescent
	light_type = /obj/item/light/tube
	allowed_type = /obj/item/light/tube
	nostick = 0
	name = "fluorescent light fixture"
	light_type = /obj/item/light/tube/neutral
	has_bulb_overlay = TRUE

/obj/machinery/light/fluorescent/auto
	nostick = FALSE //do the stick

	New()
		..()
		autoposition()

/obj/machinery/light/fluorescent/ceiling
	icon_state = "overtube1"
	base_state = "overtube"
	desc = "A lighting fixture, mounted to the ceiling."
	plane = PLANE_NOSHADOW_ABOVE
	level = 2
	alpha = 200
	wallmounted = FALSE
	ceilingmounted = TRUE
	//check something like wiring for how to set direction relative to what tile you place it by hand, since we can freely rotate this thing unlike floor/ceiling lights and wall lights


// update the icon_state and luminosity of the light depending on its state
/obj/machinery/light/proc/update()
	if (!inserted_lamp)
		if (ceilingmounted)
			src.lightfixtureimage.icon_state = "[src.base_state]-empty"
		else
			icon_state = "[base_state]-empty"
		on = 0
		if(glow)
			src.vis_contents -= glow
	else
		switch(current_lamp.light_status) // set icon_states
			if(LIGHT_OK)
				if (ceilingmounted)
					lightfixtureimage.icon_state = "[src.base_state][on]"
				else
					icon_state = "[base_state][on]"
				if(glow)
					if (on)
						src.vis_contents += glow
					else
						src.vis_contents -= glow
			if(LIGHT_BURNED)
				if (ceilingmounted)
					lightfixtureimage.icon_state = "[src.base_state]-burned"
				else
					icon_state = "[base_state]-burned"
				on = 0
				if(glow)
					src.vis_contents -= glow
			if(LIGHT_BROKEN)
				if (ceilingmounted)
					lightfixtureimage.icon_state = "[base_state]-broken"
				else
					icon_state = "[base_state]-broken"
				on = 0
				if(glow)
					src.vis_contents -= glow

	// if the state changed, inc the switching counter
	//if(src.light.enabled != on)

	if (on)
		src.light.enable()
		if(src.has_bulb_overlay)
			src.UpdateOverlays(src.bulb_overlay, "bulb")
	else
		src.light.disable()
		if(src.has_bulb_overlay)
			src.UpdateOverlays(null, "bulb")

	SPAWN_DBG(0)
		// now check to see if the bulb is burned out
		if(current_lamp.light_status == LIGHT_OK)
			if(on && current_lamp.rigged)
				if (current_lamp.rigger)
					message_admins("[key_name(current_lamp.rigger)]'s rigged bulb exploded in [src.loc.loc], [showCoords(src.x, src.y, src.z)].")
					logTheThing("combat", current_lamp.rigger, null, "'s rigged bulb exploded in [current_lamp.rigger.loc.loc] ([showCoords(src.x, src.y, src.z)])")
				explode()
			if(on && prob(current_lamp.breakprob))
				if(prob(10)) //not every light needs to pop violently
					elecflash(src,radius = 1, power = 2, exclude_center = 0)
					current_lamp.light_status = LIGHT_BROKEN
					icon_state = "[base_state]-broken"
					logTheThing("station", null, null, "Light '[name]' burnt out explosively (breakprob: [current_lamp.breakprob]) at ([showCoords(src.x, src.y, src.z)])")
				else
					current_lamp.light_status = LIGHT_BURNED
					icon_state = "[base_state]-burned"
					logTheThing("station", null, null, "Light '[name]' burnt out (breakprob: [current_lamp.breakprob]) at ([showCoords(src.x, src.y, src.z)])")
				current_lamp.update()
				on = 0
				light.disable()
				if(src.has_bulb_overlay)
					src.UpdateOverlays(null, "bulb")
			else
				current_lamp.breakprob += 0.15 // critical that your "increasing probability" thing actually, yknow, increase. ever.


// attempt to set the light's on/off status
// will not switch on if broken/burned/empty
/obj/machinery/light/proc/seton(var/s)
	on = (s && current_lamp.light_status == LIGHT_OK)
	update()

// examine verb
/obj/machinery/light/examine(mob/user)
	. = ..()

	if(!user || user.stat)
		return

	if (!inserted_lamp)
		. += "The [fitting] has been removed."
		return
	switch(current_lamp.light_status)
		if(LIGHT_OK)
			. += "It is turned [on? "on" : "off"]."
		if(LIGHT_BURNED)
			. += "The [fitting] is burnt out."
		if(LIGHT_BROKEN)
			. += "The [fitting] has been smashed."

/obj/machinery/light/proc/replace(mob/user, var/obj/item/light/newlamp = null) // if there's no newlamp this will just take out the old one.
	if (!user)
		return
	var/obj/item/light/oldlamp = inserted_lamp
	inserted_lamp = null

	if (newlamp)
		user.u_equip(newlamp)
		insert(user, newlamp)
	else
		update()
	user.put_in_hand_or_drop(oldlamp) // This just returns if there's no oldlamp, don't worry

/obj/machinery/light/proc/insert(mob/user, var/obj/item/light/newlamp) // Overriding the inserted lamp entirely
	if (!newlamp)
		return
	if (inserted_lamp)
		qdel(inserted_lamp)
	if (user)
		boutput(user, "You insert a [newlamp.name].")
	inserted_lamp = newlamp
	current_lamp = inserted_lamp
	current_lamp.set_loc(null)
	light.set_color(current_lamp.color_r, current_lamp.color_g, current_lamp.color_b)
	if(src.bulb_overlay)
		src.bulb_overlay.color = rgb(clamp(current_lamp.color_r * 255, 150, 255), clamp(current_lamp.color_g * 255, 150, 255), clamp(current_lamp.color_b * 220, 150, 255))
	brightness = initial(brightness)
	on = has_power()
	update()

// attack with item - insert light (if right type and right level), otherwise try to break the light

/obj/machinery/light/attackby(obj/item/W, mob/user)

	if((ceilingmounted) && (!user.ceilingreach))
		boutput(user, "You can't seem to reach that high.")
		return

	if((!ceilingmounted) && (!wallmounted) && (user.ceilingreach))
		boutput(user, "You'll need to get back down on the ground for that.")
		return

	if (istype(W, /obj/item/lamp_manufacturer)) //deliberately placed above the borg check
		var/obj/item/lamp_manufacturer/M = W
		if (M.removing_toggled)
			return //This stuff gets handled in the manufacturer's after_attack
		if (removable_bulb == 0)
			boutput(user, "This fitting isn't user-serviceable.")
			return

		if (!inserted_lamp) //Taking charge/sheets
			if (!M.check_ammo(user, M.cost_empty))
				return
			M.take_ammo(user, M.cost_empty)
		else
			if (!M.check_ammo(user, M.cost_broken))
				return
			M.take_ammo(user, M.cost_broken)
		var/obj/item/light/L = null

		if (fitting == "tube")
			L = new M.dispensing_tube()
		else
			L = new M.dispensing_bulb()
		if(inserted_lamp)
			if (current_lamp.light_status == LIGHT_OK && current_lamp.name == L.name && brightness == initial(brightness) && current_lamp.color_r == L.color_r && current_lamp.color_g == L.color_g && current_lamp.color_b == L.color_b && on == has_power())
				boutput(user, "This fitting already has an identical lamp.")
				qdel(L)
				return // Stop borgs from making more sparks than necessary.

		insert(user, L)
		if (!isghostdrone(user)) // Same as ghostdrone RCDs, no sparks
			elecflash(user)
		return


	if (issilicon(user) && !isghostdrone(user))
		return
		/*if (isghostdrone(user))
			return src.Attackhand(user)
		else
			return*/


	// see if there's a magtractor involved and if so save it for later as mag
	var/obj/item/magtractor/mag
	if (istype(W, /obj/item/magtractor))
		mag = W
		if (!mag.holding)
			return src.Attackhand(user)
		else
			W = mag.holding

	// attempt to insert light
	if(istype(W, /obj/item/light))
		if(istype(W, allowed_type))
			replace(user, W)
		else
			boutput(user, "This type of light requires a [fitting].")
			return


	// attempt to stick weapon into light socket
	else if(!inserted_lamp)
		if (isscrewingtool(W))
			if (has_power())
				boutput(user, "That's not safe with the power on!")
				return
			if (candismantle)
				boutput(user, "You begin to unscrew the fixture from the wall...", group = "[user]-dismantle_fixture")
				playsound(src.loc, "sound/items/Screwdriver.ogg", 50, 1)
				if (!do_after(user, 2 SECONDS))
					return
				boutput(user, "You unscrew the fixture from the wall.", group = "[user]-dismantle_fixture")
				var/obj/item/light_parts/parts = new /obj/item/light_parts(get_turf(src))
				parts.copy_light(src)
				qdel(src)
				return
			else
				boutput(user, "You can't seem to dismantle it.")


		boutput(user, "You stick \the [W.name] into the light socket!")
		if(has_power() && (W.flags & CONDUCT))
			if(!user.bioHolder.HasEffect("resist_electric"))
				src.electrocute(user, 75, null, 20000)
				elecflash(src,radius = 1, power = 2, exclude_center = 1)

	// attempt to break the light
	else if(current_lamp.light_status != LIGHT_BROKEN)


		if(prob(1+W.force * 5))

			boutput(user, "You hit the light, and it smashes!")
			logTheThing("station", user, null, "smashes a light at [log_loc(src)]")
			for(var/mob/M in AIviewers(src))
				if(M == user)
					continue
				M.show_message("[user.name] smashed the light!", 3, "You hear a tinkle of breaking glass", 2)
			if(on && (W.flags & CONDUCT))
				if(!user.bioHolder.HasEffect("resist_electric"))
					src.electrocute(user, 50, null, 20000)
			broken()


		else
			boutput(user, "You hit the light!")


// returns whether this light has power
// true if area has power and lightswitch is on
/obj/machinery/light/proc/has_power()
	var/pow_stat = powered(LIGHT)
	if (pow_stat && wire_powered)
		return 1
	var/area/A = get_area(src)
	if (A.type == /area/space) //exact match, shouldn't bother the fixes done for /space/gehenna blowouts
		return 1
	return A ? A.lightswitch && A.power_light : 0

// ai attack - do nothing

/obj/machinery/light/attack_ai(mob/user)
	return


// attack with hand - remove tube/bulb
// if hands aren't protected and the light is on, burn the player

/obj/machinery/light/attack_hand(mob/user)

	add_fingerprint(user)

	if (isghostdrone(user))
		var/obj/item/magtractor/mag = user.equipped()
		if (!istype(mag) || mag.holding) // they aren't holding a magtractor or the magtractor already has something in it
			return // so there's no room for a bulb

	//check if you're reaching a ceiling mounted light from down low
	if((ceilingmounted) && (!user.ceilingreach))
		boutput(user, "You can't seem to reach that high.")
		return

	//check if you're reaching a floor mounted light from up high
	if((!ceilingmounted) && (!wallmounted) && (user.ceilingreach))
		boutput(user, "You'll need to get back down on the ground for that.")
		return

	interact_particle(user,src)

	if(current_lamp.light_status == LIGHT_EMPTY)
		boutput(user, "There is no [fitting] in this light.")
		return

	// hey don't run around and steal all the emergency bolts you jerk
	if(!removable_bulb)
		boutput(user, "The bulb is firmly locked into place and cannot be removed.")
		return

	// make it burn hands if not wearing modestly heat-insulated gloves
	if(on)
		var/prot = 0
		var/mob/living/carbon/human/H = user

		if(istype(H))

			if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				prot = (G.getProperty("heatprot") >= 5)	// Moved this to include janitor gloves instead of just black/SWAT (which is wild)
		else
			prot = 1 //other mobs get a free pass huh

		if (!in_interact_range(src, user))
			return
		if (prot > 0 || user.is_heat_resistant())
			boutput(user, "You remove the light [fitting].")
		else
			boutput(user, "You try to remove the light [fitting], but you burn your hand on it!")
			H.UpdateDamageIcon()
			H.TakeDamage(user.hand == 1 ? "l_arm" : "r_arm", 0, 5)
			return // if burned, don't remove the light

	// create a light tube/bulb item and put it in the user's hand
	replace(user)

// break the light and make sparks if was on

/obj/machinery/light/proc/broken(var/nospark = 0)
	if(current_lamp.light_status == LIGHT_EMPTY || current_lamp.light_status == LIGHT_BROKEN)
		return

	if(current_lamp.light_status == LIGHT_OK || current_lamp.light_status == LIGHT_BURNED)
		playsound(src.loc, "sound/impact_sounds/Glass_Hit_1.ogg", 75, 1)

	if(!nospark)
		if(on)
			logTheThing("station", null, null, "Light '[name]' was on and has been broken, spewing sparks everywhere ([showCoords(src.x, src.y, src.z)])")
			elecflash(src,radius = 1, power = 2, exclude_center = 0)
	current_lamp.light_status = LIGHT_BROKEN
	current_lamp.update()
	SPAWN_DBG(0)
		update()

// explosion effect
// destroy the whole light fixture or just shatter it

/obj/machinery/light/ex_act(severity)
	switch(severity)
		if(OLD_EX_SEVERITY_1)
			qdel(src)
			return
		if(OLD_EX_SEVERITY_2)
			if (prob(75))
				broken()
		if(OLD_EX_SEVERITY_3)
			if (prob(50))
				broken()
	return

//blob effect

/obj/machinery/light/blob_act(var/power)
	if(prob(power * 2.5))
		broken()

//mbc : i threw away this stuff in favor of a faster machine loop process
/*
/obj/machinery/light/process()
	if(on)
		..()
		var/thepower = src.brightness * LIGHTING_POWER_FACTOR
		use_power(thepower, LIGHT)
		if(rigged)
			if(prob(1))
				if (rigger)
					message_admins("[key_name(rigger)]'s rigged bulb exploded in [src.loc.loc], [showCoords(src.x, src.y, src.z)].")
					logTheThing("combat", rigger, null, "'s rigged bulb exploded in [rigger.loc.loc] ([showCoords(src.x, src.y, src.z)])")
				explode()
				rigged = 0
				rigger = null
			else if(prob(2))
				if (rigger)
					message_admins("[key_name(rigger)]'s rigged bulb tried to explode but failed in [src.loc.loc], [showCoords(src.x, src.y, src.z)].")
					logTheThing("combat", rigger, null, "'s rigged bulb tried to explode but failed in [rigger.loc.loc] ([showCoords(src.x, src.y, src.z)])")
				rigged = 0
				rigger = null
*/

// called when area power state changes

/obj/machinery/light/power_change()
	if(src.loc) //TODO fix the dispose proc for this so that when it is sent into the delete queue it doesn't try and exec this
		var/area/A = get_area(src)
		var/state = A.lightswitch && A.power_light
		if (A.type == /area/space) //oh hm, okay,
			state =  1 //sure
		//if (shipAlertState == SHIP_ALERT_BAD) state = 0
		seton(state)

// called when on fire

/obj/machinery/light/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(reagents) reagents.temperature_reagents(exposed_temperature, exposed_volume)
	if(prob(max(0, exposed_temperature - 1650)))   //0% at <400C, 100% at >500C   // previous value for subtraction was -673. tons of lights exploded Azungar edit: Nudged this up a bit just in case.
		broken()

// explode the light

/obj/machinery/light/proc/explode()
	var/turf/T = get_turf(src.loc)
	SPAWN_DBG(0)
		broken()	// break it first to give a warning
		sleep(0.2 SECONDS)
		explosion(src, T, 0, 1, 2, 2)
		sleep(0.1 SECONDS)
		qdel(src)


// special handling for emergency lights
// called when area power state changes
// override since emergency lights do not use area lightswitch

/obj/machinery/light/emergency/power_change()
	var/area/A = get_area(src)
	if (A)
		var/state = !A.power_light || shipAlertState == SHIP_ALERT_BAD
		seton(state)

//special handling for lights that should only be on in an alert situation

/obj/machinery/light/emergency/alertonly/power_change()
	seton(shipAlertState)

//special handling for lights that should only be on when the shuttle has docked with the station

/obj/machinery/light/emergency/shuttle/power_change()
	if(emergency_shuttle?.online)
		if(emergency_shuttle.location == SHUTTLE_LOC_STATION)
			src.on = TRUE
			src.icon_state = "[on_state]"
			light.enable()
		else
			src.on = FALSE
			src.icon_state = "blank"
			light.disable()

/obj/machinery/light/emergency/shuttle/update()
	return //don't do shit ok


// special handling for desk lamps

// if attack with hand, only "grab" attacks are an attempt to remove bulb
// otherwise, switch the lamp on/off

/obj/machinery/light/lamp/attack_hand(mob/user)

	if(user.a_intent == INTENT_GRAB)
		..()	// do standard hand attack
	else
		switchon = !switchon
		boutput(user, "You switch [switchon ? "on" : "off"] the [name].")
		seton(switchon && powered(LIGHT))

// called when area power state changes
// override since lamp does not use area lightswitch

/obj/machinery/light/lamp/power_change()
	var/area/A = get_area(src)
	seton(switchon && A.power_light)

// returns whether this lamp has power
// true if area has power and lamp switch is on

/obj/machinery/light/lamp/has_power()
	var/area/A = get_area(src)
	return switchon && A.power_light






// the light item
// can be tube or bulb subtypes
// will fit into empty /obj/machinery/light of the corresponding type

/obj/item/light
	icon = 'icons/obj/lighting.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	flags = FPRINT | TABLEPASS
	force = 2
	throwforce = 5
	w_class = W_CLASS_SMALL
	var/light_status = 0		// LIGHT_OK, LIGHT_BURNED or LIGHT_BROKEN
	var/base_state
	var/breakprob = 0	// number of times switched //warc: doesnt do ANYTHING anymore???? now it do????
	m_amt = 60
	var/rigged = 0		// true if rigged to explode
	var/mob/rigger = null // mob responsible
	mats = 1
	var/color_r = 1
	var/color_g = 1
	var/color_b = 1
	var/canberigged = 1

/obj/item/light/tube
	name = "light tube"
	desc = "A replacement light tube."
	icon_state = "tube-white"
	base_state = "tube-white"
	item_state = "c_tube"
	g_amt = 200
	color_r = 0.95
	color_g = 0.95
	color_b = 1

	red
		name = "red light tube"
		desc = "Fancy."
		icon_state = "tube-red"
		base_state = "tube-red"
		color_r = 0.95
		color_g = 0.2
		color_b = 0.2
	reddish //approx "#FABF80"
		name = "reddish light tube"
		desc = "Fancy."
		icon_state = "tube-red"
		base_state = "tube-red"
		color_r = 0.98
		color_g = 0.75
		color_b = 0.5
	yellow
		name = "yellow light tube"
		desc = "Fancy."
		icon_state = "tube-yellow"
		base_state = "tube-yellow"
		color_r = 0.95
		color_g = 0.95
		color_b = 0.2
	yellowish //approx "#FAFABF"
		name = "yellowish light tube"
		desc = "Fancy."
		icon_state = "tube-yellow"
		base_state = "tube-yellow"
		color_r = 0.98
		color_g = 0.98
		color_b = 0.75
	green
		name = "green light tube"
		desc = "Fancy."
		icon_state = "tube-green"
		base_state = "tube-green"
		color_r = 0.2
		color_g = 0.95
		color_b = 0.2
	cyan
		name = "cyan light tube"
		desc = "Fancy."
		icon_state = "tube-cyan"
		base_state = "tube-cyan"
		color_r = 0.2
		color_g = 0.95
		color_b = 0.95
	blue
		name = "blue light tube"
		desc = "Fancy."
		icon_state = "tube-blue"
		base_state = "tube-blue"
		color_r = 0.2
		color_g = 0.2
		color_b = 0.95
	purple
		name = "purple light tube"
		desc = "Fancy."
		icon_state = "tube-purple"
		base_state = "tube-purple"
		color_r = 0.95
		color_g = 0.2
		color_b = 0.95
	light_purpleish //approx "#FAC2FA"
		name = "light purpleish light tube" //we have purple, purpleish, harsh and very harsh, but I guess atlas needed its own flavour of mildly purple lights :V
		desc = "Fancy."
		icon_state = "tube-purple"
		base_state = "tube-purple"
		color_r = 0.98
		color_g = 0.76
		color_b = 0.98
	blacklight
		name = "black light tube"
		desc = "Fancy."
		icon_state = "tube-uv"
		base_state = "tube-uv"
		color_r = 0.3
		color_g = 0
		color_b = 0.9

	warm //approx "#FFD7CF"
		name = "fluorescent light tube"
		icon_state = "itube-orange"
		base_state = "itube-orange"
		color_r = 1
		color_g = 0.844
		color_b = 0.81

		very //approx "#FFABAB"
			name = "warm fluorescent light tube"
			icon_state = "itube-red"
			base_state = "itube-red"
			color_r = 1
			color_g = 0.67
			color_b = 0.67

	neutral
		name = "fluorescent light tube"
		icon_state = "itube-white"
		base_state = "itube-white"
		color_r = 0.95
		color_g = 0.98
		color_b = 0.97

	greenish //approx "#DEFAE3"
		name = "greenish fluorescent light tube"
		icon_state = "itube-yellow"
		base_state = "itube-yellow"
		color_r = 0.87
		color_g = 0.98
		color_b = 0.89

	blueish //approx "#82A8D9"
		name = "blueish fluorescent light tube"
		icon_state = "itube-blue"
		base_state = "itube-blue"
		color_r = 0.51
		color_g = 0.66
		color_b = 0.85

	purpleish //approx "#6B3394"
		name = "purpleish fluorescent light tube"
		icon_state = "itube-purple"
		base_state = "itube-purple"
		color_r = 0.42
		color_g = 0.20
		color_b = 0.58

	cool //approx "#E0E7FF"
		name = "cool fluorescent light tube"
		icon_state = "itube-white"
		base_state = "itube-white"
		color_r = 0.88
		color_g = 0.904
		color_b = 1

		very //approx "#BDBDFF"
			name = "very cool fluorescent light tube"
			icon_state = "itube-purple"
			base_state = "itube-purple"
			color_r = 0.74
			color_g = 0.74
			color_b = 1

	harsh //approx "#FCE6FC"
		name = "harsh fluorescent light tube"
		icon_state = "itube-white"
		base_state = "itube-white"
		color_r = 0.99
		color_g = 0.899
		color_b = 0.99

		very //approx "#FCCFFC"
			name = "very harsh fluorescent light tube"
			icon_state = "itube-pink"
			base_state = "itube-pink"
			color_r = 0.99
			color_g = 0.81
			color_b = 0.99

// the smaller bulb light fixture

/obj/item/light/bulb
	name = "light bulb"
	desc = "A replacement light bulb."
	icon_state = "bulb-yellow"
	base_state = "bulb-yellow"
	item_state = "contvapour"
	g_amt = 100
	color_r = 0.98
	color_g = 0.75
	color_b = 0.5

	red
		name = "red light bulb"
		desc = "Fancy."
		icon_state = "bulb-red"
		base_state = "bulb-red"
		color_r = 0.95
		color_g = 0.2
		color_b = 0.2
	reddish
		name = "reddish light bulb"
		desc = "Fancy."
		icon_state = "bulb-red"
		base_state = "bulb-red"
		color_r = 0.98
		color_g = 0.75
		color_b = 0.5
	yellow
		name = "yellow light bulb"
		desc = "Fancy."
		icon_state = "bulb-yellow"
		base_state = "bulb-yellow"
		color_r = 0.95
		color_g = 0.95
		color_b = 0.2
	yellowish
		name = "yellowish light bulb"
		desc = "Fancy."
		icon_state = "bulb-yellow"
		base_state = "bulb-yellow"
		color_r = 0.98
		color_g = 0.98
		color_b = 0.75
	green
		name = "green light bulb"
		desc = "Fancy."
		icon_state = "bulb-green"
		base_state = "bulb-green"
		color_r = 0.2
		color_g = 0.95
		color_b = 0.2
	cyan
		name = "cyan light bulb"
		desc = "Fancy."
		icon_state = "bulb-cyan"
		base_state = "bulb-cyan"
		color_r = 0.2
		color_g = 0.95
		color_b = 0.95
	blue
		name = "blue light bulb"
		desc = "Fancy."
		icon_state = "bulb-blue"
		base_state = "bulb-blue"
		color_r = 0.2
		color_g = 0.2
		color_b = 0.95
	purple
		name = "purple light bulb"
		desc = "Fancy."
		icon_state = "bulb-purple"
		base_state = "bulb-purple"
		color_r = 0.95
		color_g = 0.2
		color_b = 0.95
	blacklight
		name = "black light bulb"
		desc = "Fancy."
		icon_state = "bulb-uv"
		base_state = "bulb-uv"
		color_r = 0.3
		color_g = 0
		color_r = 0.9
	emergency
		name = "emergency light bulb"
		desc = "A frosted red bulb."
		icon_state = "bulb-emergency"
		base_state = "bulb-emergency"
		color_r = 1
		color_g = 0.2
		color_b = 0.2

	warm
		name = "fluorescent light bulb"
		icon_state = "ibulb-yellow"
		base_state = "ibulb-yellow"
		color_r = 1
		color_g = 0.844
		color_b = 0.81

		very
			name = "warm fluorescent light bulb"
			icon_state = "ibulb-yellow"
			base_state = "ibulb-yellow"
			color_r = 1
			color_g = 0.67
			color_b = 0.67

	neutral
		name = "incandescent light bulb"
		icon_state = "ibulb-white"
		base_state = "ibulb-white"
		color_r = 0.95
		color_g = 0.98
		color_b = 0.97

	greenish
		name = "greenish incandescent light bulb"
		icon_state = "ibulb-green"
		base_state = "ibulb-green"
		color_r = 0.87
		color_g = 0.98
		color_b = 0.89

	blueish
		name = "blueish fluorescent light bulb"
		icon_state = "ibulb-blue"
		base_state = "ibulb-blue"
		color_r = 0.51
		color_g = 0.66
		color_b = 0.85

	purpleish
		name = "purpleish fluorescent light bulb"
		icon_state = "ibulb-purple"
		base_state = "ibulb-purple"
		color_r = 0.42
		color_g = 0.20
		color_b = 0.58

	cool
		name = "cool incandescent light bulb"
		icon_state = "ibulb-white"
		base_state = "ibulb-white"
		color_r = 0.88
		color_g = 0.904
		color_b = 1

		very
			name = "very cool incandescent light bulb"
			icon_state = "ibulb-blue"
			base_state = "ibulb-blue"
			color_r = 0.74
			color_g = 0.74
			color_b = 1

	harsh
		name = "harsh incandescent light bulb"
		icon_state = "ibulb-pink"
		base_state = "ibulb-pink"
		color_r = 0.99
		color_g = 0.899
		color_b = 0.99

		very
			name = "very harsh incandescent light bulb"
			icon_state = "ibulb-pink"
			base_state = "ibulb-pink"
			color_r = 0.99
			color_g = 0.81
			color_b = 0.99

/obj/item/light/big_bulb
	name = "beacon bulb"
	desc = "An immense replacement light bulb."
	icon_state = "tbulb"
	base_state = "tbulb"
	item_state = "contvapour"
	g_amt = 250
	color_r = 1
	color_g = 1
	color_b = 1

// update the icon state and description of the light
/obj/item/light
	proc/update()
		switch(light_status)
			if(LIGHT_OK)
				icon_state = base_state
				desc = "A replacement [name]."
			if(LIGHT_BURNED)
				icon_state = "[base_state]-burned"
				desc = "A burnt-out [name]."
			if(LIGHT_BROKEN)
				icon_state = "[base_state]-broken"
				desc = "A broken [name]."


/obj/item/light/New()
	..()
	update()


// attack bulb/tube with object
// if a syringe, can inject plasma to make it explode
/obj/item/light/attackby(var/obj/item/I, var/mob/user)
	if (!canberigged)
		return
	if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I

		boutput(user, "You inject the solution into the [src].")

		if(S.reagents.has_reagent("plasma", 1))
			message_admins("[key_name(user)] rigged [src] to explode in [user.loc.loc], [showCoords(user.x, user.y, user.z)].")
			logTheThing("combat", user, null, "rigged [src] to explode in [user.loc.loc] ([showCoords(user.x, user.y, user.z)])")
			rigged = 1
			rigger = user

		S.reagents.clear_reagents()
	else
		..()
	return

// called after an attack with a light item
// shatter light, unless it was an attempt to put it in a light socket
// now only shatter if the intent was harm
// WHY THO?

/obj/item/light/afterattack(atom/target, mob/user)
	if(istype(target, /obj/machinery/light))
		return
	if(user.a_intent != "harm")
		return

	if(light_status == LIGHT_OK || light_status == LIGHT_BURNED)
		boutput(user, "The [name] shatters!")
		light_status = LIGHT_BROKEN
		force = 5
		playsound(src.loc, "sound/impact_sounds/Glass_Hit_1.ogg", 75, 1)
		update()

/obj/item/light/throw_impact(atom/A, datum/thrown_thing/thr)
	..()
	if(prob(30))
		return
	if(light_status == LIGHT_OK || light_status == LIGHT_BURNED)
		src.visible_message("The [name] shatters!")
		light_status = LIGHT_BROKEN
		force = 5
		playsound(src.loc, "sound/impact_sounds/Glass_Hit_1.ogg", 75, 1)
		update()

/obj/machinery/light/get_power_wire()
	if (wallmounted)
		var/obj/cable/C = null
		for (var/obj/cable/candidate in get_turf(src))
			if (candidate.d1 == dir || candidate.d2 == dir)
				C = candidate
				break
		return C
	else
		return ..()

/obj/machinery/light/small/broken //Made at first to replace a decal in cog1's wreckage area
	name = "shattered light bulb"
	New()
		..()
		SPAWN_DBG(1)
			current_lamp.light_status = LIGHT_BROKEN
			current_lamp.update()
