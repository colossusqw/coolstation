//Used by: NT Incapacitor ammo (sorry warc I can't be arsed), Mk. 1 Combat Taser pod weapon, taser gun (single shot), egun (stun)
/datum/projectile/energy_bolt
	name = "energy bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "taser_projectile"
//How much of a punch this has, tends to be seconds/damage before any resist
	power = 40
//How much ammo this costs
	cost = 25
//How fast the power goes away
	dissipation_rate = 0.5
//How many tiles till it starts to lose power
	dissipation_delay = 2
	max_range = 12 //how many ticks the projectile can go regardless of falloff
//Kill/Stun ratio
	ks_ratio = 0.0
//name of the projectile setting, used when you change a guns setting
	sname = "stun"
//file location for the sound you want it to play
	shot_sound = 'sound/weapons/Taser.ogg'
//should the sound have extra range?
	shot_sound_extrarange = 5
//How many projectiles should be fired, each will cost the full cost
	shot_number = 1
//What is our damage type
/*
kinetic - raw power
piercing - punches though things
slashing - cuts things
energy - energy
burning - hot
radioactive - rips apart cells or some shit
toxic - poisons
*/
	damage_type = D_ENERGY
	//With what % do we hit mobs laying down
	hit_ground_chance = 0
	//Can we pass windows
	window_pass = 0
	brightness = 1
	color_red = 0.9
	color_green = 0.9
	color_blue = 0.1

	disruption = 8

	hit_mob_sound = 'sound/effects/sparks6.ogg'


//Any special things when it hits shit?
	/* this is now handled in the projectile parent on_hit for all ks_ratio 0.0 weapons.
	on_hit(atom/hit)
		if (ishuman(hit))
			var/mob/living/carbon/human/H = hit
			H.changeStatus("slowed", power)
			H.change_misstep_chance(5)
			H.emote("twitch_v")
			if (H.getStatusDuration("slowed") > power)
				H.changeStatus("stunned", power)
		return*/

//Used by: ricochet taser gun (unused?)
/datum/projectile/energy_bolt/bouncy
	name = "ricochet energy bolt"
	var/max_bounce_count = 1
	var/reflect_on_nondense_hits = FALSE

	on_hit(atom/hit, direction, obj/projectile/P)
		if (!ismob(hit))
			if (shoot_reflected_bounce(P, hit, max_bounce_count, PROJ_NO_HEADON_BOUNCE, reflect_on_nondense_hits))
				elecflash(get_turf(P),radius=0, power=2, exclude_center = 0)
		..()

//Used by: heavy ion blaster
/datum/projectile/heavyion
	name = "ion bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "heavyion"
	power = 20
	cost = 25
	dissipation_rate = 2
	dissipation_delay = 8
	ks_ratio = 1
	shot_sound = 'sound/weapons/heavyion.ogg'
	shot_number = 1
	damage_type = D_ENERGY
	hit_ground_chance = 0
	brightness = 0.8
	color_red = 0.2
	color_green = 0.6
	color_blue = 0.8
	ie_type = "E"

	on_hit(atom/hit)
		if (isliving(hit))
			var/mob/living/L = hit
			L.changeStatus("slowed", 2 SECONDS)
			L.change_misstep_chance(5)
			L.emote("twitch_v")
		impact_image_effect(ie_type, hit)
		return

//Used by: guardbuddy taser module, AI turret (stun)
/datum/projectile/energy_bolt/robust
	power = 65
	dissipation_rate = 6

//Used by: taser gun (volley)
/datum/projectile/energy_bolt/burst
	shot_number = 3
	cost = 75
	sname = "burst stun"

//Unused
/datum/projectile/energy_bolt/tiny
	power = 5
	cost = 10
	sname = "teeny bolt"


	on_pointblank(var/obj/projectile/P, var/mob/living/M)
		M.changeStatus("slowed", 2 SECONDS)
		M.change_misstep_chance(1)
		M.emote("twitch_v")

	on_hit(atom/hit)
		if (isliving(hit))
			var/mob/living/L = hit
			L.changeStatus("slowed", 1 SECOND)
			L.change_misstep_chance(1)
			L.emote("twitch_v")
		return

//////////// VUVUZELA
//Used by: amplified vuvuzela
/datum/projectile/energy_bolt_v
	name = "vuvuzela bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "v_sound"
//How much of a punch this has, tends to be seconds/damage before any resist
	power = 75 // 100 was way too fucking long what the HECK
//How much ammo this costs
	cost = 25
//How fast the power goes away
	dissipation_rate = 5
//How many tiles till it starts to lose power
	dissipation_delay = 1
//Kill/Stun ratio
	ks_ratio = 0.0
//name of the projectile setting, used when you change a guns setting
	sname = "sonic wave"
//file location for the sound you want it to play
	shot_sound = 'sound/musical_instruments/Vuvuzela_1.ogg'
//How many projectiles should be fired, each will cost the full cost
	shot_number = 1
//What is our damage type
/*
kinetic - raw power
piercing - punches though things
slashing - cuts things
energy - energy
burning - hot
radioactive - rips apart cells or some shit
toxic - poisons
*/
	damage_type = D_SPECIAL
	//With what % do we hit mobs laying down
	hit_ground_chance = 0
	//Can we pass windows
	window_pass = 0

	disruption = 0
	ie_type = "T"

//Any special things when it hits shit?
	on_hit(atom/hit) //purposefully not getting falloff, so it's not just a worse taser
		if (isliving(hit))
			var/mob/living/L = hit
			L.apply_sonic_stun(1.5, 0, 25, 10, 0, rand(1, 3), stamina_damage = 120)
			impact_image_effect(ie_type, hit)
		return

 //purposefully keeping (some of) the pointblank double-dip,
 //because a staffie with a vuvu won't always have the option to follow up with a baton and cuffs, and this helps keep a guy down
	on_pointblank(var/obj/projectile/P, var/mob/living/M)
		M.apply_sonic_stun(6, 0, 25, 20, 0, rand(2, 4), stamina_damage = 40)
		impact_image_effect(ie_type, M)

//////////// Ghost Hunting for Halloween
//Used by: ectoplasmic destabilizer
/datum/projectile/energy_bolt_antighost
	name = "ectoplasmic bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "green_spark"
//How much of a punch this has, tends to be seconds/damage before any resist
	power = 2
//How much ammo this costs
	cost = 25
//How fast the power goes away
	dissipation_rate = 2
//How many tiles till it starts to lose power
	dissipation_delay = 4
//Kill/Stun ratio
	ks_ratio = 0.0
//name of the projectile setting, used when you change a guns setting
	sname = "deghostify"
//file location for the sound you want it to play
	shot_sound = 'sound/weapons/Taser.ogg'
//How many projectiles should be fired, each will cost the full cost
	shot_number = 1

	damage_type = D_ENERGY
	//With what % do we hit mobs laying down
	hit_ground_chance = 0
	//Can we pass windows
	window_pass = 0
	brightness = 0.8
	color_red = 0.2
	color_green = 0.8
	color_blue = 0.2

	disruption = 0


//Projectile for Hatsune Miku's NT gun.
//Used by: Assault laser rifle
/datum/projectile/energy_bolt/ntburst // fixed overlapping path - /datum/projectile/energy_bolt/burst already exists for taser burst fire
	shot_number = 1
	power = 15
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "minispark"
	cost = 5
	sname = "burst stun"

//Used by: lawgiver (detain)
/datum/projectile/energy_bolt/aoe
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "detain-projectile"
	sname = "detain"
	power = 20
	cost = 50
	dissipation_rate = 5
	dissipation_delay = 3
	color_red = 255
	color_green = 165
	color_blue = 0
	max_range = 7 //slight range boost
	damage_type = D_ENERGY

	on_hit(atom/O, angle, var/obj/projectile/P)
		detonate(O, P)

	on_max_range_die(obj/projectile/O)
		detonate(O, O)

	proc/detonate(atom/O, var/obj/projectile/P)
		if (istype(O, /obj/projectile))
			var/obj/projectile/proj = O
			new /obj/effects/energy_bolt_aoe_burst(get_turf(proj), x_val = proj.xo, y_val = proj.yo)
		else
			new /obj/effects/energy_bolt_aoe_burst(get_turf(O))

		for (var/mob/M in range(1, O)) //direct hit power is a 'bonus for aim', so we want this to hit the target
			if (isliving(M) && M != P.shooter) //don't stun ourself while shooting in close quarters
				var/mob/living/L = M
				L.changeStatus("slowed", 2 SECONDS)
				L.do_disorient(stamina_damage = 40, weakened = 0, stunned = 0, disorient = 20, remove_stamina_below_zero = 0)
				L.emote("twitch_v")


//Used by: lawbringer detain projectile (sidetrack: really loving the garbage approach to inheritance and type naming in this file so far)
/obj/effects/energy_bolt_aoe_burst
	name = "shockwave"
	desc = ""
	density = 0
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "shockwave"

	New(var/x_val, var/y_val)
		..()
		pixel_x = x_val
		pixel_y = y_val
		src.Scale(0.4,0.4)
		animate(src, matrix(2, MATRIX_SCALE), time = 6, color = "#ffdddd", easing = LINEAR_EASING)
		var/matrix/m1 = transform
		var/matrix/m2 = transform
		m1.Scale(7,7)
		m2.Scale(0.4,0.4)
		transform = m2
		animate(src,transform=m1,time=3)
		animate(transform=m2,time=5)


		SPAWN_DBG(7 DECI SECONDS) qdel(src)

//Used by: lawbringer (pulse), pulse rifle
/datum/projectile/energy_bolt/pulse
	name = "pulse"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "pulse"
	power = 20
	cost = 35
	sname = "kinetic pulse"
	shot_sound = 'sound/weapons/pulse.ogg'
	damage_type = D_SPECIAL
	hit_ground_chance = 30
	brightness = 1
	color_red = 0.18
	color_green = 0.2
	color_blue = 1

	disruption = 8

	hit_mob_sound = 'sound/effects/sparks6.ogg'

	on_pointblank(var/obj/projectile/P, var/mob/living/M)
		// var/dir = angle2dir(angle)
		M.throw_at(get_edge_target_turf(M, get_dir(P, M)),7,1, throw_type = THROW_GUNIMPACT)

		//When it hits a mob or such should anything special happen
	on_hit(atom/hit, angle, var/obj/projectile/O)
		// var/dir = angle2dir(angle)
		var/dir = get_dir(O.shooter, hit)
		var/pow = O.power
		if (ishuman(hit))
			O.die()
			var/mob/living/carbon/human/H = hit
			H.do_disorient(stamina_damage = pow*1.5, weakened = 0, stunned = 0, disorient = pow, remove_stamina_below_zero = 0)
			H.throw_at(get_edge_target_turf(hit, dir),(pow-7)/2,1, throw_type = THROW_GUNIMPACT)
			H.emote("twitch_v")

	impact_image_effect(var/type, atom/hit, angle, var/obj/projectile/O)
		return

//Used by: pulse rifle
/datum/projectile/energy_bolt/electromagnetic_pulse
	name = "pulse"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "pulse"
	power = 20
	cost = 100
	sname = "electromagnetic pulse"
	shot_sound = 'sound/weapons/Taser.ogg'
	damage_type = D_SPECIAL
	hit_ground_chance = 0
	brightness = 1
	color_red = 0.18
	color_green = 0.2
	color_blue = 1

	disruption = 25

	hit_mob_sound = 'sound/effects/sparks6.ogg'

	on_hit(atom/hit, angle, var/obj/projectile/P)
		var/turf/T = get_turf(hit)
		for(var/turf/tile in range(1, T))
			for(var/atom/movable/O in tile.contents)
				if(!istype(O, /obj/machinery/nuclearbomb)) //emp does not affect nuke
					O.emp_act()
		if (ishuman(hit))
			var/mob/living/carbon/human/H = hit
			H.do_disorient(stamina_damage = 30, weakened = 0, stunned = 0, disorient = 6 SECONDS, remove_stamina_below_zero = 0)
		elecflash(T)

//Used by: Signifer II
/datum/projectile/energy_bolt/signifer_tase
	name = "signifer spark"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "signifer2_tase"
	shot_sound = 'sound/weapons/SigTase.ogg'
	cost = 12
	power = 10
	ks_ratio = 0.1

	sname = "non-lethal"
	damage_type = D_ENERGY
	hit_ground_chance = 0
	brightness = 1
	color_red = 1
	color_green = 1
	color_blue = 0

	disruption = 2
	ie_type = "T"

	hit_mob_sound = 'sound/effects/sparks6.ogg'

//Used by: Taser SMG (burst)
/datum/projectile/energy_bolt/smgburst
	name = "energy bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "taser_projectile"
	power = 15
	cost = 40
	max_range = 12
	ks_ratio = 0.0
	sname = "burst"
	shot_sound = 'sound/weapons/Taser.ogg'
	shot_sound_extrarange = 5
	shot_number = 2
	damage_type = D_ENERGY

	disruption = 8

	hit_mob_sound = 'sound/effects/sparks6.ogg'

//Used by: taser SMG (automatic)
/datum/projectile/energy_bolt/smgauto
	name = "energy bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "signifer2_tase"
	power = 10
	cost = 8
	max_range = 8
	ks_ratio = 0.0
	sname = "full-auto"
	shot_sound = 'sound/weapons/SigTase.ogg'
	shot_sound_extrarange = 5
	shot_number = 1
	damage_type = D_ENERGY

	disruption = 8

	hit_mob_sound = 'sound/effects/sparks6.ogg'

//Used by: experimental ray gun
/datum/projectile/energy_bolt/raybeam
	name = "energy bolt"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "green_spark"
	power = 5
	cost = 25
	max_range = 6
	ks_ratio = 1.0
	sname = "burst"
	shot_sound = 'sound/weapons/Taser.ogg'
	shot_sound_extrarange = 3
	shot_number = 1
	damage_type = D_ENERGY

	disruption = 2

	hit_mob_sound = 'sound/effects/sparks6.ogg'
