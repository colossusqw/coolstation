/* ._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._. */
/*-=-=-=-=--=-=-=-SHUTTLE TURFS & OBJS, DUH!-=-=-=-=-=-=-=-=-=-*/
/* '~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~'-._.-'~' */


////////////////////////////////////////////////////////////////TURFS
/turf/shuttle
	name = "shuttle wall"
	icon = 'icons/turf/shuttle.dmi'
	thermal_conductivity = 0.05
	heat_capacity = 0
	explosion_resistance = 8

	attackby()
	attack_hand()
	hitby()
		. = ..()
	reagent_act()
	bullet_act()
	ex_act()
	blob_act()
	meteorhit()
	damage_heat()
	damage_corrosive()
	damage_piercing()
	damage_slashing()
	damage_blunt()

/turf/space/shuttle_transit
	icon_state = "tplaceholder"

	New()
		..()
		if (icon_state == "tplaceholder") icon_state = (channel_open ? "near_blank" : "[rand(1,25)]" )

/turf/space/shuttle_transit/deadly
	#ifdef IN_MAP_EDITOR
	icon_state = "tplaceholder_red"
	#endif
	New()
		..()
		#ifdef DESERT_MAP
		src.AddComponent(/datum/component/pitfall/planetary_splat,\
			BruteDamageMax = 1050,\
			HangTime = 0 SECONDS,\
			FallTime = 0.1 SECONDS)
		#endif

	Entered(atom/movable/A)
		#ifdef DATALOGGER
		if (ishuman(A) || issilicon(A))
			game_stats.Increment("workplacesafety") //Please keep your arms and legs inside the shuttle at all times.
		#endif
		..()

/turf/floor/shuttle_noprotections
	name = "shuttle floor"
	icon_state = "floord"
	icon = 'icons/turf/shuttle.dmi'

	oxygen = MOLES_N2STANDARD
	nitrogen = MOLES_O2STANDARD

	ex_act(severity)
		switch(severity)
			if(OLD_EX_SEVERITY_1)
				if(prob(50))
					src.ReplaceWithSpace()
				else
					src.ReplaceWithLattice()

			if(OLD_EX_SEVERITY_2)
				if(prob(80))
					src.break_tile_to_plating()
				else
					src.break_tile()
				src.hotspot_expose(1000,CELL_VOLUME)
			if(OLD_EX_SEVERITY_3)
				if (prob(50))
					src.break_tile()
					src.hotspot_expose(1000,CELL_VOLUME)
		return

/turf/wall/r_wall/shuttle_noprotections
	name = "shuttle wall"
	icon = 'icons/turf/shuttle.dmi'
	icon_state = "wall"
	var/icon_style = "wall"
	opacity = 0
	density = 1
	gas_impermeable = 1
	pathable = 0

	New()
		..()
		SPAWN_DBG(6 SECONDS) // patch up some ugly corners in derelict mode
			if (derelict_mode)
				if (src.icon_state == "[src.icon_style]_space")
					src.icon_state = "[src.icon_style]_void"
		return

/turf/floor/shuttle // theres a bug with the crowbar special attack here. not great.
	name = "shuttle floor"
	icon_state = "floor"
	icon = 'icons/turf/shuttle.dmi'
	thermal_conductivity = 0.05
	heat_capacity = 0
	turf_flags = MOB_STEP

	attackby()
	attack_hand()
	hitby()
		. = ..()
	reagent_act()
	bullet_act()
	ex_act()
	blob_act()
	meteorhit()
	damage_heat()
	damage_corrosive()
	damage_piercing()
	damage_slashing()
	damage_blunt()

/turf/wall/auto/shuttle
	icon = 'icons/turf/walls_shuttle.dmi'
	light_mod = "wall-"
	connect_overlay = 1
	connects_to = list(/turf/wall/auto/shuttle, /turf/wall/false_wall, /obj/machinery/door, /obj/window)
	connects_with_overlay = list(/turf/wall/false_wall/reinforced, /obj/machinery/door, /obj/window)
/*
	update_neighbors()
		..()
		for (var/obj/window/auto/O in orange(1,src))
			O.update_icon()
*/
	/////////////////////////////////////////////////////////////////OBJECTS

/obj/indestructible/
	anchored = 2

	attackby()
	attack_hand()
	hitby()
		. = ..()
	reagent_act()
	bullet_act()
	ex_act()
	blob_act()
	meteorhit()
	damage_heat()
	damage_corrosive()
	damage_piercing()
	damage_slashing()
	damage_blunt()

/obj/indestructible/invisible_block // an invisible thing to stop people walking where they 'aint meant to.
	density = 1
	mouse_opacity = 0

	examine()
		return list()


/obj/indestructible/invisible_block/opaque
	opacity = 1

	examine()
		return list()


/turf/shuttle/wall/cockpit
	name = "shuttle cockpit"
	icon = 'icons/effects/160x160.dmi'
	icon_state = "shuttlecock"
	layer = EFFECTS_LAYER_BASE
	pixel_x = -64
	pixel_y = -64
	opacity = 0
	plane = PLANE_DEFAULT

/turf/shuttle/wall/cockpit/window
	name = "shuttle wall"
	icon_state = "wall"
	icon = 'icons/turf/shuttle.dmi'
	opacity = 0
	pixel_x = 0
	pixel_y = 0
	layer = TURF_LAYER

/obj/indestructible/shuttle_corner
	plane = PLANE_WALL
	name = "shuttle wall"
	desc = "A shuttle wall. Pretty reinforced. This appears to be a corner."
	icon = 'icons/turf/walls_shuttle.dmi'
	icon_state = "corner"
	density = 1
	opacity = 0
	layer = EFFECTS_LAYER_BASE - 1
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID

/turf/wall/auto/shuttle
	name = "shuttle wall"
	desc = "A shuttle wall. Pretty reinforced."
	icon = 'icons/turf/walls_shuttle.dmi'
	light_mod = "wall-"
	opacity = 0
	flags = ALWAYS_SOLID_FLUID | IS_PERSPECTIVE_FLUID
	connect_overlay = 1
	connects_to = list(/turf/wall/auto/supernorn, /turf/wall/auto/reinforced/supernorn, /turf/wall/auto/supernorn/wood,
	/turf/wall/false_wall, /obj/machinery/door, /obj/window, /obj/wingrille_spawn, /turf/wall/auto/shuttle, /obj/indestructible/shuttle_corner)
	connects_with_overlay = list(/turf/wall/auto/supernorn/wood, /turf/wall/false_wall/reinforced, /obj/machinery/door, /obj/window, /obj/wingrille_spawn)

	attackby()
	attack_hand()
	hitby()
		. = ..()
	reagent_act()
	bullet_act()
	ex_act()
	blob_act()
	meteorhit()
	damage_heat()
	damage_corrosive()
	damage_piercing()
	damage_slashing()
	damage_blunt()

//TODO: CLEAN UP
/turf/shuttle/wall
	name = "shuttle wall"
	icon_state = "wall"
	var/icon_style = "wall"
	opacity = 1
	density = 1
	gas_impermeable = 1
	pathable = 0

	New()
		..()
		SPAWN_DBG(6 SECONDS) // patch up some ugly corners in derelict mode
			if (derelict_mode)
				if (src.icon_state == "[src.icon_style]_space")
					src.icon_state = "[src.icon_style]_void"
		return

/turf/shuttle/wall/escape
	opacity = 0

/turf/shuttle/wall/corner
	icon_state = "wall_space"
	opacity = 0
//END TODO
