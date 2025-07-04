
/datum/lifeprocess/disability

	//proc/handle_disabilities(var/mult = 1)
	process(var/datum/gas_mixture/environment)
		var/mult = get_multiplier()

		// moved drowsy, confusion and such from handle_chemicals because it seems better here
		if (owner.drowsyness)
			owner.drowsyness = max(0, owner.drowsyness - mult)
			owner.change_eye_blurry(2*mult)
			if (probmult(5))
				owner.sleeping = 1
				owner.changeStatus("paralysis", 5 SECONDS)
				owner.drowsyness = 0

		if (owner.misstep_chance > 0)
			switch(owner.misstep_chance)
				if (50 to INFINITY)
					owner.change_misstep_chance(-2 * mult)
				else
					owner.change_misstep_chance(-1 * mult)

		// The value at which this stuff is capped at can be found in mob.dm
		if (owner.hasStatus("resting"))
			owner.dizziness = max(0, owner.dizziness - 5*mult)
			owner.jitteriness = max(0, owner.jitteriness - 5*mult)
		else
			owner.dizziness = max(0, owner.dizziness - 2*mult)
			owner.jitteriness = max(0, owner.jitteriness - 2*mult)

		if (owner.mind && isvampire(owner))
			if (istype(get_area(owner), /area/station/chapel) && owner.check_vampire_power(3) != 1)
				if (prob(33))
					boutput(owner, "<span class='alert'>The holy ground burns you!</span>")
				owner.TakeDamage("chest", 0, 5 * mult, 0, DAMAGE_BURN)
			if (owner.loc && istype(owner.loc, /turf/space))
				if (prob(33))
					boutput(owner, "<span class='alert'>The starlight burns you!</span>")
				owner.TakeDamage("chest", 0, 2 * mult, 0, DAMAGE_BURN)

		if (owner.loc && isarea(owner.loc.loc))
			var/area/A = owner.loc.loc
			if (A.irradiated)
				//spatial interdictor: mitigate effect of radiation
				//consumes 250 units of charge per person per life tick
				var/interdictor_influence = 0
				for (var/obj/machinery/interdictor/IX in by_type[/obj/machinery/interdictor])
					if (IN_RANGE(IX,owner,IX.interdict_range) && IX.expend_interdict(250))
						interdictor_influence = 1
						break
				if(!interdictor_influence)
					owner.changeStatus("radiation", (A.irradiated * 10 * mult) SECONDS)
			if (A.sandstorm)
				if(ishuman(owner))
					var/mob/living/carbon/human/H = owner
					H.change_eye_blurry(15, 30)
					if(!istype(H.glasses, /obj/item/clothing/glasses) && !istype(H.head, /obj/item/clothing/head/helmet))
						if(prob(30))
							H.take_eye_damage(rand(3,5))

					if(!H.wear_mask)
						if (prob(25))
							boutput(owner, "<span class='alert'>You inhale a bunch of sand!</span>")
							owner.emote("cough")
							if (prob(70)) // favors the left lung so both of a spaceman's lungs don't die at the same time
								if (!H.organHolder.left_lung.robotic)
									H.organHolder.damage_organ(3, 0, 0, "left_lung")
							else
								if (!H.organHolder.right_lung.robotic)
									H.organHolder.damage_organ(3, 0, 0, "right_lung")

				owner.changeStatus("sandy", (A.sandstorm * 5 * mult) SECONDS)


		if (owner.bioHolder)
			var/total_stability = owner.bioHolder.genetic_stability

			if (owner.reagents && owner.reagents.has_reagent("mutadone"))
				total_stability += 60

			if (total_stability <= 40 && probmult(5))
				owner.bioHolder.DegradeRandomEffect()

			if (total_stability <= 20 && probmult(10))
				owner.bioHolder.DegradeRandomEffect()

		..()
