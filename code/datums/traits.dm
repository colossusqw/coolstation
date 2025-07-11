//Unlockable traits? tied to achievements?
#define TRAIT_STARTING_POINTS 1 //How many "free" points you get
#define TRAIT_MAX 7			    //How many traits people can select at most.

/proc/getTraitById(var/id)
	. = traitList[id]

/proc/traitCategoryAllowed(var/list/targetList, var/idToCheck)
	. = TRUE
	var/obj/trait/C = getTraitById(idToCheck)
	if(C.category == null)
		return TRUE
	for(var/A in targetList)
		var/obj/trait/T = getTraitById(A)
		if(T.category == C.category)
			return FALSE

/datum/traitPreferences
	var/list/traits_selected = list()

	var/point_total = TRAIT_STARTING_POINTS
	var/free_points = TRAIT_STARTING_POINTS

	proc/selectTrait(var/id)
		if(id in traitList)
			traits_selected |= id
		calcTotal()
		return 1

	proc/unselectTrait(var/id)
		traits_selected -= id
		calcTotal()
		return 1

	proc/calcTotal()
		. = free_points
		for(var/T in traits_selected)
			if(T in traitList)
				var/obj/trait/O = traitList[T]
				. += O.points
		point_total = .

	proc/isValid()
		var/list/categories = list()
		for(var/A in traits_selected)
			var/obj/trait/T = getTraitById(A)
			if(T.unselectable) return 0
			//if(T.requiredUnlock != null && usr.client)  //This will likely fail since the unlocks will not have loaded by the time the trait preferences are created. getscores is too slow.
			//	if(usr.client.qualifiedXpRewards != null)
			//		if(!usr.client.qualifiedXpRewards.Find(T.requiredUnlock))
			//			return 0
			if(T.category != null)
				if(T.category in categories)
					return 0
				else
					categories.Add(T.category)
		return (calcTotal() >= 0)

	proc/updateTraits(var/mob/user)

		// Not passed a user, try to gracefully recover.
		if (!user)
			user = usr
			if (!user)
				return

		if(!user.client)
			return

		if(!winexists(user, "traitssetup_[user.ckey]"))
			winclone(user, "traitssetup", "traitssetup_[user.ckey]")

		var/list/selected = list()
		var/list/available = list()

		var/skipUnlocks = 0
		for(var/X in traitList)
			var/obj/trait/C = getTraitById(X)
			if(C.unselectable) continue
			if(C.requiredUnlock != null && skipUnlocks) continue
			if(C.requiredUnlock != null && user.client) //If this needs an xp unlock, check against the pre-generated list of related xp unlocks for this person.
				if(!isnull(user.client.qualifiedXpRewards))
					if(!(C.requiredUnlock in user.client.qualifiedXpRewards))
						continue
				else
					boutput(user, "<span class='alert'><b>WARNING: XP unlocks failed to update. Some traits may not be available. Please try again in a moment.</b></span>")
					SPAWN_DBG(0) user.client.updateXpRewards()
					skipUnlocks = 1
					continue

			if(X in traits_selected)
				selected += X
			else
				available += X

		winset(user, "traitssetup_[user.ckey].traitsSelected", "cells=\"1x[selected.len]\"")
		var/countSel = 0
		for(var/S in selected)
			winset(user, "traitssetup_[user.ckey].traitsSelected", "current-cell=1,[++countSel]")
			user << output(traitList[S], "traitssetup_[user.ckey].traitsSelected")

		winset(user, "traitssetup_[user.ckey].traitsAvailable", "cells=\"1x[available.len]\"")
		var/countAvail = 0
		for(var/A in available)
			winset(user, "traitssetup_[user.ckey].traitsAvailable", "current-cell=1,[++countAvail]")
			user << output(traitList[A], "traitssetup_[user.ckey].traitsAvailable")

		winset(user, "traitssetup_[user.ckey].traitPoints", "text=\"Points left : [calcTotal()]\"&text-color=\"[calcTotal() > 0 ? "#00AA00" : "#AA0000"]\"")
		return

	proc/showTraits(var/mob/user)
		if(!user.client)
			return

		if(!winexists(user, "traitssetup_[user.ckey]"))
			winclone(user, "traitssetup", "traitssetup_[user.ckey]")

		winshow(user, "traitssetup_[user.ckey]")
		updateTraits(user)

		user.Browse(null, "window=preferences")
		return


/datum/traitHolder
	var/list/traits = list()
	var/list/moveTraits = list() // differentiate movement traits for Move()
	var/mob/owner = null

	New(var/mob/ownerMob)
		owner = ownerMob
		return ..()

	proc/addTrait(id)
		if(!(id in traits) && owner)
			var/obj/trait/T = traitList[id]
			traits[id] = T
			if(T.isMoveTrait)
				moveTraits.Add(id)
			T.onAdd(owner)

	proc/removeTrait(id)
		if((id in traits) && owner)
			traits.Remove(id)
			var/obj/trait/T = traitList[id]
			if(T.isMoveTrait)
				moveTraits.Remove(id)
			T.onRemove(owner)

	proc/removeAll()
		for (var/obj/trait/T in traits)
			traits.Remove(T.id)
			if(T.isMoveTrait)
				moveTraits.Remove(T.id)
			T.onRemove(owner)

	proc/hasTrait(var/id)
		. = (id in traits)

//Yes these are objs because grid control. Shut up. I don't like it either.
/obj/trait
	icon = 'icons/ui/traits.dmi'
	icon_state = "placeholder"
	var/id = ""        //Unique ID
	var/points = 0	   //The change in points when this is selected.
	var/isPositive = 1 //Is this a positive, good effect or a bad one.
	var/category = null //If set to a non-null string, People will only be able to pick one trait of any given category
	var/unselectable = 0 //If 1 , trait can not be select at char setup
	var/requiredUnlock = null //If set to a string, the xp unlock of that name is required for this to be selectable.
	var/cleanName = ""   //Name without any additional information.
	var/isMoveTrait = 0 // If 1, onMove will be called each movement step from the holder's mob
	var/datum/mutantrace/mutantRace = null //If set, should be in the "species" category.

	proc/onAdd(var/mob/owner)
		if(mutantRace && ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.set_mutantrace(mutantRace)
		return

	proc/onRemove(var/mob/owner)
		return

	proc/onLife(var/mob/owner, var/mult)
		return

	proc/onMove(var/mob/owner)
		return

	Click(location,control,params)
		if(!usr)
			return
		if(control)
			if(control == "traitssetup_[usr.ckey].traitsAvailable")
				if(!(id in usr.client.preferences.traitPreferences.traits_selected))
					if(traitCategoryAllowed(usr.client.preferences.traitPreferences.traits_selected, id))
						if(usr.client.preferences.traitPreferences.traits_selected.len >= TRAIT_MAX)
							alert(usr, "You can not select more than [TRAIT_MAX] traits.")
						else
							if(((usr.client.preferences.traitPreferences.calcTotal()) + points) < 0)
								alert(usr, "You do not have enough points available to select this trait.")
							else
								usr.client.preferences.traitPreferences.selectTrait(id)
					else
						alert(usr, "You can only select one trait of this category.")
			else if (control == "traitssetup_[usr.ckey].traitsSelected")
				if(id in usr.client.preferences.traitPreferences.traits_selected)
					if(((usr.client.preferences.traitPreferences.calcTotal()) - points) < 0)
						alert(usr, "Removing this trait would leave you with less than 0 points. Please remove a different trait.")
					else
						usr.client.preferences.traitPreferences.unselectTrait(id)

			usr.client.preferences.traitPreferences.updateTraits(usr)
		return

	MouseEntered(location,control,params)
		if(winexists(usr, "traitssetup_[usr.ckey]"))
			winset(usr, "traitssetup_[usr.ckey].traitName", "text=\"[name]\"")
			winset(usr, "traitssetup_[usr.ckey].traitDesc", "text=\"[desc]\"")

// BODY - Red Border

/obj/trait/roboarms
	name = "Robotic arms (0) \[Body\]"
	cleanName = "Robotic arms"
	desc = "Your arms have been replaced with light robotic arms."
	id = "roboarms"
	icon_state = "robotarmsR"
	points = 0
	isPositive = 1
	category = "body"

	onAdd(var/mob/owner)
		SPAWN_DBG(4 SECONDS) //Fuck this. Fuck the way limbs are added with a delay. FUCK IT
			if(ishuman(owner))
				var/mob/living/carbon/human/H = owner
				if(H.limbs != null)
					H.limbs.replace_with("l_arm", /obj/item/parts/robot_parts/arm/left/light, null , 0)
					H.limbs.replace_with("r_arm", /obj/item/parts/robot_parts/arm/right/light, null , 0)
					H.limbs.l_arm.holder = H
					H.limbs.r_arm.holder = H
					H.update_body()

/obj/trait/syntharms
	name = "Green Fingers (-2) \[Body\]"
	cleanName = "Green Fingers"
	desc = "Excess exposure to radiation, mutagen and gardening have turned your arms into plants. The horror!"
	id = "syntharms"
	icon_state = "robotarmsR"
	points = -2
	isPositive = 0
	category = "body"

	onAdd(var/mob/owner)
		SPAWN_DBG(4 SECONDS)
			if(ishuman(owner))
				var/mob/living/carbon/human/H = owner
				if(H.limbs != null)
					H.limbs.replace_with("l_arm", pick(/obj/item/parts/human_parts/arm/left/synth/bloom, /obj/item/parts/human_parts/arm/left/synth), null , 0)
					H.limbs.replace_with("r_arm", pick(/obj/item/parts/human_parts/arm/right/synth/bloom, /obj/item/parts/human_parts/arm/right/synth), null , 0)
					H.limbs.l_arm.holder = H
					H.limbs.r_arm.holder = H
					H.update_body()

/obj/trait/explolimbs
	name = "Adamantium Skeleton (-2) \[Body\]"
	cleanName = "Adamantium Skeleton"
	desc = "Halves the chance that an explosion will blow off your limbs."
	id = "explolimbs"
	category = "body"
	points = -2
	isPositive = 1

/obj/trait/deaf
	name = "Deaf (+1) \[Body\]"
	cleanName = "Deaf"
	desc = "Spawn with permanent deafness and an auditory headset."
	id = "deaf"
	icon_state = "deaf"
	category = "body"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(ishuman(owner))
				var/mob/living/carbon/human/H = owner
				owner.bioHolder.AddEffect("deaf", 0, 0, 0, 1)
				H.equip_new_if_possible(/obj/item/device/radio/headset/deaf, H.slot_ears)

	onLife(var/mob/owner) //Just to be super safe.
		if(!owner.ear_disability)
			owner.bioHolder.AddEffect("deaf", 0, 0, 0, 1)

// LANGUAGE - Yellow Border

/obj/trait/swedish
	name = "Swedish (0) \[Language\]"
	cleanName = "Swedish"
	desc = "You are from sweden. Meat balls and so on."
	id = "swedish"
	icon_state = "swedenY"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_swedish", 0, 0, 0, 1)

/obj/trait/french
	name = "French (0) \[Language\]"
	cleanName = "French"
	desc = "You are from Quebec. y'know, the other Canada."
	id = "french"
	icon_state = "frY"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_french", 0, 0, 0, 1)

/obj/trait/scots
	name = "Scots (0) \[Language\]"
	cleanName = "Scottish"
	desc = "Hear the pipes are calling, down thro' the glen. Och aye!"
	id = "scottish"
	icon_state = "scott"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_scots", 0, 0, 0, 1)

/obj/trait/brummie
	name = "brummie (0) \[Language\]"
	cleanName = "brummie"
	desc = "U wot m8? I sware i'll fite u."
	id = "brummie"
	icon_state = "ukY"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_brummie", 0, 0, 0, 1)

/obj/trait/elvis
	name = "Funky Accent (0) \[Language\]"
	cleanName = "Funky Accent"
	desc = "Give a man a banana and he will clown for a day. Teach a man to clown and he will live in a cold dark corner of a space station for the rest of his days. - Elvis, probably."
	id = "elvis"
	icon_state = "elvis"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_elvis", 0, 0, 0, 1)

/obj/trait/tommy // please do not re-enable this without talking to spy tia
	name = "New Jersey Accent (0) \[Language\]"
	cleanName = "New Jersey Accent"
	desc = "Ha ha ha. What a story, Mark."
	id = "tommy"
	icon_state = "whatY"
	points = 0
//	isPositive = 1
	category = "language"
	unselectable = 1 // this was not supposed to be a common thing!!
/*
	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_tommy")
		return
*/

/obj/trait/finnish
	name = "Finnish Accent (0) \[Language\]"
	cleanName = "Finnish Accent"
	desc = "...and you thought space didn't have Finns?"
	id = "finnish"
	icon_state = "finnish"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_finnish", 0, 0, 0, 1)

/obj/trait/tyke
	name = "Tyke (0) \[Language\]"
	cleanName = "Tyke"
	desc = "You're from Oop North in Yorkshire, and don't let anyone forget it!"
	id = "tyke"
	icon_state = "yorkshire"
	points = 0
	isPositive = 1
	category = "language"

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("accent_tyke")

// VISION/SENSES - Green Border

/obj/trait/cateyes
	name = "Cat eyes (-1) \[Vision\]"
	cleanName = "Cat eyes"
	desc = "You can see 2 tiles further in the dark."
	id = "cateyes"
	icon_state = "catseyeG"
	points = -1
	isPositive = 1
	category = "vision"

/obj/trait/infravision
	name = "Infravision (-1) \[Vision\]"
	cleanName = "Infravision"
	desc = "You can always see messages written in infra-red ink."
	id = "infravision"
	icon_state = "infravisionG"
	points = -1
	isPositive = 0
	category = "vision"

/obj/trait/shortsighted
	name = "Short-sighted (+1) \[Vision\]"
	cleanName = "Short-sighted"
	desc = "Spawn with permanent short-sightedness and glasses."
	id = "shortsighted"
	icon_state = "glassesG"
	category = "vision"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(ishuman(owner))
				var/mob/living/carbon/human/H = owner
				owner.bioHolder.AddEffect("bad_eyesight", 0, 0, 0, 1)
				H.equip_if_possible(new /obj/item/clothing/glasses/regular(H), H.slot_glasses)

	onLife(var/mob/owner) //Just to be super safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("bad_eyesight"))
			owner.bioHolder.AddEffect("bad_eyesight", 0, 0, 0, 1)

/obj/trait/blind
	name = "Blind (+2)"
	cleanName = "Blind"
	desc = "Spawn with permanent blindness and a VISOR."
	icon_state = "blind"
	id = "blind"
	category = "vision"
	points = 2
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(istype(owner, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = owner
				owner.bioHolder.AddEffect("blind", 0, 0, 0, 1)
				H.equip_if_possible(new /obj/item/clothing/glasses/visor(H), H.slot_glasses)

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("blind"))
			owner.bioHolder.AddEffect("blind", 0, 0, 0, 1)

/obj/trait/blind/protanopia
	name = "Protanopia (+1)"
	cleanName="Protanopia"
	desc = "You are colorblind: unable to see red and green, leaving a yellowish tint."
	id = "protanopia"
	category = "vision"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(istype(owner, /mob/living/carbon/human))
				owner.bioHolder.AddEffect("protanopia", 0, 0, 0, 1)

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("protanopia"))
			owner.bioHolder.AddEffect("protanopia", 0, 0, 0, 1)

/obj/trait/blind/deuteranopia
	name = "Deuteranopia (+1)"
	cleanName="Deuteranopia"
	desc = "You are colorblind: cannot see green."
	id = "deuteranopia"
	category = "vision"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(istype(owner, /mob/living/carbon/human))
				owner.bioHolder.AddEffect("deuteranopia", 0, 0, 0, 1)

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("deuteranopia"))
			owner.bioHolder.AddEffect("deuteranopia", 0, 0, 0, 1)

/obj/trait/blind/tritanopia
	name = "Tritanopia (+1)"
	cleanName="Tritanopia"
	desc = "You are colorblind: cannot see blue."
	id = "tritanopia"
	category = "vision"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		if(owner.bioHolder)
			if(istype(owner, /mob/living/carbon/human))
				owner.bioHolder.AddEffect("tritanopia", 0, 0, 0, 1)

	onLife(var/mob/owner) //Just to be safe.
		if(owner.bioHolder && !owner.bioHolder.HasEffect("tritanopia"))
			owner.bioHolder.AddEffect("tritanopia", 0, 0, 0, 1)

// GENETICS - Blue Border
/obj/trait/italian
	name = "Italian (??) \[Italian\]"
	cleanName = "Italian"
	desc = "You are Italian."
	id = "italian"
	icon_state = "italian"
	points = 0
	isPositive = 0
	category = "genetics"

/obj/trait/robustgenetics
	name = "Robust Genetics (-2) \[Genetics\]"
	cleanName = "Robust Genetics"
	desc = "You gain an additional 20 genetic stability."
	id = "robustgenetics"
	icon_state = "stablegenesB"
	points = -2
	isPositive = 0
	category = "genetics"

	onAdd(var/mob/owner)
		owner.bioHolder?.genetic_stability = 120

/obj/trait/mildly_mutated
	name = "Mildly Mutated (0) \[Genetics\]"
	cleanName = "Mildly Mutated"
	desc = "A random mutation in your gene pool starts activated."
	id = "mildly_mutated"
	icon_state = "mildly_mutatedB"
	points = 0
	isPositive = 0
	category = "genetics"

	onAdd(var/mob/owner)
		var/datum/bioHolder/B = owner.bioHolder
		B.ActivatePoolEffect(B.effectPool[pick(B.effectPool)], 1, 0)

/obj/trait/stablegenes
	name = "Stable Genes (-2) \[Genetics\]"
	cleanName = "Stable Genes"
	desc = "You are less likely to mutate from radiation or mutagens."
	id = "stablegenes"
	icon_state = "dontmutateB"
	points = -2
	isPositive = 0
	category = "genetics"

// TRINKETS/ITEMS - Purple Border

/obj/trait/loyalist
	name = "NT loyalist (-1) \[Trinkets\]"
	cleanName = "NT loyalist"
	desc = "Start with a Nanotrasen Beret as your trinket."
	id = "loyalist"
	icon_state = "beretP"
	points = -1
	isPositive = 1
	category = "trinkets"

/obj/trait/petasusaphilic
	name = "Petasusaphilic (-1) \[Trinkets\]"
	cleanName = "Petasusaphilic"
	desc = "Start with a random hat as your trinket."
	id = "petasusaphilic"
	icon_state = "hatP"
	points = -1
	isPositive = 1
	category = "trinkets"

/obj/trait/conspiracytheorist
	name = "Conspiracy Theorist (-1) \[Trinkets\]"
	cleanName = "Conspiracy Theorist"
	desc = "Start with a tin foil hat as your trinket."
	id = "conspiracytheorist"
	icon_state = "conspP"
	points = -1
	isPositive = 1
	category = "trinkets"

//2025-6-17: Moved from 25% of wage bonus starting cash to a flat 300$ and from -1 to 0 pts
//300 was the highest you'd get out of it (being captain), which is't much anyway
//Even then it's hardly on par with Unionized for cost.
/obj/trait/pawnstar
	name = "Pawn Star (0) \[Trinkets\]"
	cleanName = "Pawn Star"
	//desc has to be done at runtime :v
	id = "pawnstar"
	icon_state = "pawnP"
	points = 0
	isPositive = 1
	category = "trinkets"

	New()
		desc = "You sold your trinket before you departed for the station. You start with a bonus of 300[CREDIT_SIGN] to your starting cash in your inventory."
		..()

/obj/trait/beestfriend
	name = "BEEst friend (-1) \[Trinkets\]"
	cleanName = "BEEst friend"
	desc = "Start with a bee egg as your trinket."
	id = "beestfriend"
	icon_state = "bee"
	points = -1
	isPositive = 1
	category = "trinkets"

/obj/trait/lunchbox
	name = "Lunchbox (-1) \[Trinkets\]"
	cleanName = "Lunchbox"
	desc = "Start your shift with a cute little lunchbox, packed with all your favourite foods!"
	id = "lunchbox"
	icon_state = "lunchbox"
	points = -1
	isPositive = 1
	category = "trinkets"

// Skill - White Border

/obj/trait/smoothtalker
	name = "Smooth talker (-1) \[Skill\]"
	cleanName = "Smooth talker"
	desc = "Traders will tolerate 50% more when you are haggling with them."
	id = "smoothtalker"
	category = "skill"
	points = -1
	isPositive = 1
/*
/obj/trait/matrixflopout
	name = "Matrix Flopout (-2) \[Skill\]"
	cleanName = "Matrix Flopout"
	desc = "Flipping lets you dodge bullets and attacks for a higher stamina cost!"
	id = "matrixflopout"
	category = "skill"
	points = -2
	isPositive = 1
*/
/obj/trait/happyfeet
	name = "Happyfeet (-1) \[Skill\]"
	cleanName = "Happyfeet"
	desc = "Sometimes people can't help but dance along with you."
	id = "happyfeet"
	category = "skill"
	points = -1
	isPositive = 1

/obj/trait/claw
	name = "Claw School Graduate (-1) \[Skill\]"
	cleanName = "Claw School Graduate"
	desc = "Your skill at claw machines is unparalleled."
	id = "claw"
	icon_state = "claw"
	category = "skill"
	points = -1
	isPositive = 1

/* Hey dudes, I moved these over from the old bioEffect/Genetics system so they work on clone */

/obj/trait/job
	name = "hi yes I'm a bug"
	desc = "This is an error! Please report this to coders. May cause pointed questions towards the affected!"
	id = "error"
	points = 0
	isPositive = 1
	unselectable = 1
	category = "job"

	onAdd(mob/owner)
		return

	onLife(mob/owner) //Just to be safe.
		return

/obj/trait/job/chaplain
	name = "Chaplain Training"
	cleanName = "Chaplain Training"
	desc = "Subject is trained in cultural and psychological matters."
	id = "training_chaplain"

/obj/trait/job/medical
	name = "Medical Training"
	cleanName = "Medical Training"
	desc = "Subject is a proficient surgeon."
	id = "training_medical"

/obj/trait/job/engineer
	name = "Engineering Training"
	cleanName = "Engineering Training"
	desc = "Subject is trained in engineering."
	id = "training_engineer"

/obj/trait/job/security
	name = "Security Training"
	cleanName = "Security Training"
	desc = "Subject is trained in generalized robustness and asskicking."
	id = "training_security"

// bartender, detective, HoS
/obj/trait/job/drinker
	name = "Professional Drinker"
	cleanName = "Professional Drinker"
	desc = "Sometimes you drink on the job, sometimes drinking is the job."
	id = "training_drinker"

/obj/trait/job/chef
	name = "Kitchen Training"
	cleanName = "Kitchen Training"
	desc = "You've spent years in the chef academy."
	id = "training_chef"

// scientist scream gimmick, unrelated to training but putting it here anyway
/obj/trait/job/scienceteam
	name = "Member of the Science Team"
	cleanName = "Science Teammate"
	desc = "You don't know who ate all the donuts."
	id = "scienceteam"

	onAdd(var/mob/owner)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.sound_list_scream = list('sound/voice/scientist/scream01.ogg','sound/voice/scientist/scream02.ogg','sound/voice/scientist/scream03.ogg','sound/voice/scientist/scream04.ogg','sound/voice/scientist/scream05.ogg','sound/voice/scientist/scream06.ogg','sound/voice/scientist/scream07.ogg','sound/voice/scientist/scream08.ogg','sound/voice/scientist/scream09.ogg','sound/voice/scientist/scream10.ogg','sound/voice/scientist/scream11.ogg','sound/voice/scientist/scream12.ogg','sound/voice/scientist/scream14.ogg','sound/voice/scientist/scream15.ogg','sound/voice/scientist/scream16.ogg','sound/voice/scientist/scream17.ogg','sound/voice/scientist/scream20.ogg','sound/voice/scientist/scream22.ogg','sound/voice/scientist/scream23.ogg','sound/voice/scientist/scream24.ogg','sound/voice/scientist/scream25.ogg') // live
			H.sound_list_laugh = list('sound/voice/scientist/sci_fear1.ogg','sound/voice/scientist/sci_fear2.ogg','sound/voice/scientist/sci_fear3.ogg','sound/voice/scientist/sci_fear4.ogg','sound/voice/scientist/sci_fear5.ogg','sound/voice/scientist/sci_fear6.ogg','sound/voice/scientist/sci_fear7.ogg','sound/voice/scientist/sci_fear8.ogg','sound/voice/scientist/sci_fear9.ogg','sound/voice/scientist/sci_fear10.ogg','sound/voice/scientist/sci_fear11.ogg','sound/voice/scientist/sci_fear12.ogg','sound/voice/scientist/sci_fear13.ogg','sound/voice/scientist/sci_fear14.ogg','sound/voice/scientist/sci_fear15.ogg') // laugh
			H.sound_list_pain =  list('sound/voice/scientist/sci_pain1.ogg','sound/voice/scientist/sci_pain2.ogg','sound/voice/scientist/sci_pain3.ogg','sound/voice/scientist/sci_pain4.ogg','sound/voice/scientist/sci_pain5.ogg') // love
		return

// Phobias - Undetermined Border

/obj/trait/phobia
	name = "Phobias suck"
	desc = "Wow, phobias are no fun! Report this to a coder please."
	unselectable = 1

/obj/trait/phobia/space
	name = "Spacephobia (+1) \[Phobia\]"
	cleanName = "Spacephobia"
	desc = "Being in space scares you. A lot. While in space you might panic or faint."
	id = "spacephobia"
	points = 1
	isPositive = 0

	onLife(var/mob/owner)
		if(!owner.stat && can_act(owner) && istype(owner.loc, /turf/space))
			if(prob(2))
				owner.emote("faint")
				owner.changeStatus("paralysis", 8 SECONDS)
			else if (prob(8))
				owner.emote("scream")
				owner.changeStatus("stunned", 2 SECONDS)

// Stats - Undetermined Border
/*
/obj/trait/athletic
	name = "Athletic (-2) \[Stats\]"
	cleanName = "Athletic"
	desc = "Great stamina! Frail body."
	id = "athletic"
	category = "stats"
	points = -2
	isPositive = 1

	onAdd(var/mob/owner)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.add_stam_mod_max("trait", STAMINA_MAX * 0.1)
			APPLY_MOB_PROPERTY(H, PROP_STAMINA_REGEN_BONUS, "trait", STAMINA_REGEN * 0.1)

/obj/trait/bigbruiser
	name = "Big Bruiser (-2) \[Stats\]"
	cleanName = "Big Bruiser"
	desc = "Stronger punches but higher stamina cost!"
	id = "bigbruiser"
	category = "stats"
	points = -2
	isPositive = 1
*/
//Category: Background.

/obj/trait/immigrant
	name = "Stowaway (+1) \[Background\]"
	cleanName = "Stowaway"
	desc = "You spawn hidden away on-station without an ID, PDA, or entry in NT records."
	id = "immigrant"
	icon_state = "stowaway"
	category = "background"
	points = 1
	isPositive = 0

obj/trait/pilot
	name = "Pilot (0) \[Background\]"
	cleanName = "Pilot"
	desc = "You spawn in a pod off-station with a Space GPS, Emergency Oxygen Tank, Breath Mask and proper protection, but you have no PDA and your pod cannot open wormholes."
	id = "pilot"
	icon_state = "pilot"
	category = "background"
	points = 0
	isPositive = 0

// NO CATEGORY - Grey Border

/obj/trait/obnoxious
	name = "Obnoxious (0)"
	cleanName = "Obnoxious"
	desc = "Your screams are very loud, and extremely funny."
	id = "obnoxious"
	points = 0
	isPositive = 0
	onAdd(var/mob/owner)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.sound_list_scream = list('sound/voice/screams/Tom_Scream.ogg')
		return

/obj/trait/hemo
	name = "Hemophilia (+1)"
	cleanName = "Hemophilia"
	desc = "You bleed more easily and you bleed more."
	id = "hemophilia"
	points = 1
	isPositive = 0

//Flourish felt like this was bloating the traits so I've disabled it for now.
///obj/trait/color_shift
//	name = "Color Shift (0)"
//	cleanName = "Color Shift"
//	desc = "You are more depressing on the outside but more colorful on the inside."
//	id = "color_shift"
//	points = 0
//	isPositive = 1
//
//	onAdd(var/mob/owner)	Not enforcing any of them with onLife because Hemochromia is a multi-mutation thing while Achromia would darken the skin color every tick until it's pitch black.
//		if(owner.bioHolder)
//			owner.bioHolder.AddEffect("achromia", 0, 0, 0, 1)
//			owner.bioHolder.AddEffect("hemochromia_unknown", 0, 0, 0, 1)

/obj/trait/slowmetabolism
	name = "Slow Metabolism (0)"
	cleanName = "Slow Metabolism"
	desc = "Any chemicals in you body deplete much more slowly."
	id = "slowmetabolism"
	points = 0
	isPositive = 1

/obj/trait/alcoholic
	name = "Career alcoholic (0)"
	cleanName = "Career alcoholic"
	desc = "You gain alcohol resistance but your speech is permanently slurred."
	id = "alcoholic"
	icon_state = "beer"
	points = 0
	isPositive = 1

	onAdd(var/mob/owner)
		owner.bioHolder?.AddEffect("resist_alcohol", 0, 0, 0, 1)

/obj/trait/random_allergy
	name = "Allergy (+0)"
	cleanName = "Allergy"
	desc = "You're allergic to... something. You can't quite remember, but how bad could it possibly be?"
	id = "randomallergy"
	points = 0
	isPositive = 0

	var/list/allergic_players = list()

	var/list/allergen_id_list = list("spaceacillin","morphine","teporone","salicylic_acid","calomel","synthflesh","omnizine","saline","anti_rad","smelling_salt",\
	"haloperidol","epinephrine","insulin","silver_sulfadiazine","mutadone","ephedrine","penteticacid","antihistamine","styptic_powder","cryoxadone","atropine",\
	"salbutamol","perfluorodecalin","mannitol","charcoal","antihol","ethanol","iron","mercury","oxygen","plasma","sugar","radium","water","bathsalts","jenkem","crank",\
	"LSD","space_drugs","THC","nicotine","krokodil","catdrugs","triplemeth","methamphetamine","mutagen","neurotoxin","sarin","smokepowder","infernite","phlogiston","fuel",\
	"anti_fart","lube","ectoplasm","cryostylane","oil","sewage","ants","spiders","poo","love","hugs","fartonium","blood","bloodc","vomit","urine","capsaicin","cheese",\
	"coffee","chocolate","chickensoup","salt","grease","badgrease","msg","egg", "milk")

	onAdd(var/mob/owner)
		allergic_players[owner] = pick(allergen_id_list)

	onLife(var/mob/owner)
		if (owner?.reagents?.has_reagent(allergic_players[owner]))
			owner.reagents.add_reagent("histamine", min(1.4 / (owner.reagents.has_reagent("antihistamine") ? 2 : 1), 120-owner.reagents.get_reagent_amount("histamine"))) //1.4 units of histamine per life cycle, halved with antihistamine and capped at 120u

/obj/trait/random_allergy/medical_allergy
	name = "Medical Allergy (+1)"
	cleanName = "Medical Allergy"
	desc = "You're allergic to some medical chemical... but you can't remember which."
	id = "medicalallergy"
	points = 1

	allergen_id_list = list("spaceacillin","morphine","teporone","salicylic_acid","calomel","synthflesh","omnizine","saline","anti_rad","smelling_salt",\
	"haloperidol","epinephrine","insulin","silver_sulfadiazine","mutadone","ephedrine","penteticacid","antihistamine","styptic_powder","cryoxadone","atropine",\
	"salbutamol","perfluorodecalin","mannitol","charcoal","antihol")

/obj/trait/addict
	name = "Addict (+2)"
	cleanName = "Addict"
	desc = "You spawn with a random addiction. Once cured there is a small chance that you will suffer a relapse."
	id = "addict"
	icon_state = "syringe"
	points = 2
	isPositive = 0
	var/selected_reagent = "ethanol"
	var/addictive_reagents = list("bath salts", "lysergic acid diethylamide", "space drugs", "psilocybin", "cat drugs", "methamphetamine")
	var/list/addicted_players = list()

	onAdd(var/mob/owner)
		if(isliving(owner))
			addicted_players[owner] = pick(addictive_reagents)
			selected_reagent = addicted_players[owner]
			addAddiction(owner)

	onLife(var/mob/owner, var/mult) //Just to be safe.
		if(isliving(owner) && probmult(1))
			var/mob/living/M = owner
			selected_reagent = addicted_players[owner]
			for(var/datum/ailment_data/addiction/A in M.ailments)
				if(istype(A, /datum/ailment_data/addiction))
					if(A.associated_reagent == selected_reagent) return
			addAddiction(owner)

	proc/addAddiction(var/mob/owner)
		var/mob/living/M = owner
		var/datum/ailment_data/addiction/AD = new
		AD.associated_reagent = selected_reagent
		AD.last_reagent_dose = world.timeofday
		AD.name = "[selected_reagent] addiction"
		AD.affected_mob = M
		M.ailments += AD

/obj/trait/strongwilled
	name = "Strong willed (-1)"
	cleanName = "Strong willed"
	desc = "You are more resistant to addiction."
	id = "strongwilled"
	icon_state = "nosmoking"
	points = -1
	isPositive = 1

/obj/trait/addictive_personality // different than addict because you just have a general weakness to addictions instead of starting with a specific one
	name = "Addictive Personality (+1)"
	cleanName = "Addictive Personality"
	desc = "You are less resistant to addiction."
	id = "addictive_personality"
	icon_state = "syringe"
	points = 1
	isPositive = 0

/obj/trait/greedy_beast // you will just take a bite out of an unsliced pizza or a cigarette
	name = "Greedy Beast (-1)"
	cleanName = "Greedy Beast"
	desc = "You don't really have any qualms about how you eat stuff. And sometimes what you eat."
	id = "greedy_beast"
	icon_state = "greedybeast"
	points = -1
	isPositive = 0

/obj/trait/organ_connoisseur
	name = "Organ Connoisseur (-1)"
	cleanName = "Organ Connoisseur"
	desc = "You know far more about the valuable innards of your coworkers than you should."
	id = "organ_connoisseur"
	icon_state = "organ"
	points = -1
	isPositive = 1

/obj/trait/clown_disbelief
	name = "Clown Disbelief (0)"
	cleanName = "Clown Disbelief"
	desc = "You refuse to acknowledge that clowns could exist on a space station."
	id = "clown_disbelief"
	icon_state = "clown_disbelief"
	points = 0
	isPositive = 0

	onAdd(mob/owner)
		OTHER_START_TRACKING_CAT(owner, TR_CAT_CLOWN_DISBELIEF_MOBS)
		if(owner.client)
			src.turnOn(owner)
		src.RegisterSignal(owner, COMSIG_MOB_LOGIN, PROC_REF(turnOn))
		src.RegisterSignal(owner, COMSIG_MOB_LOGOUT, PROC_REF(turnOff))
		src.RegisterSignal(owner, COMSIG_ATOM_EXAMINE, PROC_REF(examined))

	proc/turnOn(mob/owner)
		for(var/image/I as anything in global.clown_disbelief_images)
			owner.client.images += I

	proc/examined(mob/owner, mob/examiner, list/lines)
		if(examiner.job == "Clown")
			lines += "<br>[capitalize(he_or_she(owner))] doesn't seem to notice you."

	onRemove(mob/owner)
		OTHER_STOP_TRACKING_CAT(owner, TR_CAT_CLOWN_DISBELIEF_MOBS)
		if(owner.client)
			src.turnOff(owner)
		src.UnregisterSignal(owner, list(COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT, COMSIG_ATOM_EXAMINE))

	proc/turnOff(mob/owner)
		for(var/image/I as anything in global.clown_disbelief_images)
			owner.last_client.images -= I


/obj/trait/unionized
	name = "Unionized (-1)"
	cleanName = "Unionized"
	desc = "You start with a higher paycheck than normal."
	id = "unionized"
	icon_state = "handshake"
	points = -1
	isPositive = 1

/obj/trait/jailbird
	name = "Jailbird (0)"
	cleanName = "Jailbird"
	desc = "You have a criminal record and are currently on the run!"
	id = "jailbird"
	icon_state = "jail"
	points = 0
	isPositive = 0
/*
/obj/trait/clericalerror
	name = "Clerical Error (0)"
	cleanName = "Clerical Error"
	desc = "The name on your starting ID is misspelled."
	id = "clericalerror"
	icon_state = "spellingerror"
	points = 0
	isPositive = 1
*/
/obj/trait/chemresist
	name = "Chem resistant (-2)"
	cleanName = "Chem resistant"
	desc = "You are more resistant to chem overdoses."
	id = "chemresist"
	points = -2
	isPositive = 1

/obj/trait/puritan
	name = "Puritan (+2)"
	cleanName = "Puritan"
	desc = "You can not be cloned. Any attempt will end badly."
	id = "puritan"
	points = 2
	isPositive = 0

/obj/trait/survivalist
	name = "Survivalist (-1)"
	cleanName = "Survivalist"
	desc = "Food will heal you even if you are badly injured."
	id = "survivalist"
	points = -1
	isPositive = 1

/obj/trait/smoker
	name = "Smoker (-1)"
	cleanName = "Smoker"
	desc = "You will not absorb any chemicals from smoking cigarettes."
	id = "smoker"
	icon_state = "smoker"
	points = -1
	isPositive = 1

/obj/trait/nervous
	name = "Nervous (+1)"
	cleanName = "Nervous"
	desc = "Witnessing injuries or violence will sometimes make you freak out."
	id = "nervous"
	icon_state = "nervous"
	points = 1
	isPositive = 0

	onAdd(var/mob/owner)
		..()
		OTHER_START_TRACKING_CAT(owner, TR_CAT_NERVOUS_MOBS)

	onRemove(var/mob/owner)
		..()
		OTHER_STOP_TRACKING_CAT(owner, TR_CAT_NERVOUS_MOBS)

/obj/trait/burning
	name = "Human Torch (+1)"
	cleanName = "Human Torch"
	desc = "Extends the time that you remain on fire for, when burning."
	id = "burning"
	icon_state = "onfire"
	points = 1
	isPositive = 0

/obj/trait/carpenter
	name = "Carpenter (-1)"
	cleanName = "Carpenter"
	desc = "You can construct things more quickly than other people."
	icon_state = "carpenter"
	id = "carpenter"
	points = -1
	isPositive = 1

/obj/trait/kleptomaniac
	name = "Kleptomaniac (+1)"
	cleanName = "Kleptomaniac"
	desc = "You will sometimes randomly pick up nearby items."
	id = "kleptomaniac"
	points = 1
	isPositive = 0

	onLife(var/mob/owner, var/mult)
		if(!owner.stat && can_act(owner) && probmult(9))
			if(!owner.equipped())
				for(var/obj/item/I in view(1, owner))
					if(!I.anchored && isturf(I.loc))
						I.Attackhand(owner)
						if(prob(12))
							owner.emote(pick("grin", "smirk", "chuckle", "smug"))
						break

/obj/trait/clutz
	name = "Clutz (+2)"
	cleanName = "Clutz"
	desc = "When interacting with anything you have a chance to interact with something different instead."
	id = "clutz"
	points = 2
	isPositive = 0

/obj/trait/leftfeet
	name = "Two left feet (+1)"
	cleanName = "Two left feet"
	desc = "Every now and then you'll stumble in a random direction."
	id = "leftfeet"
	points = 1
	isPositive = 0

/obj/trait/scaredshitless
	name = "Scared Shitless (0)"
	cleanName = "Scared Shitless"
	desc = "Literally. When you scream, you fart. Be careful around Bibles!"
	id = "scaredshitless"
	icon_state = "poo"
	points = 0
	isPositive = 0

/obj/trait/allergic
	name = "Hyperallergic (+1)"
	cleanName = "Hyperallergic"
	desc = "You have a severe sensitivity to allergens and are liable to slip into anaphylactic shock upon exposure."
	id = "allergic"
	icon_state = "placeholder"
	points = 1
	isPositive = 0

/obj/trait/allears
	name = "All Ears (0)"
	cleanName="All ears"
	desc = "You lost your headset on the way to work."
	id = "allears"
	points = 0
	isPositive = 0

/obj/trait/atheist
	name = "Atheist (0)"
	cleanName = "Atheist"
	desc = "In this moment, you are euphoric. You cannot receive faith healing, and prayer makes you feel silly."
	id = "atheist"
	points = 0
	isPositive = 0

/obj/trait/lizard
	name = "Reptilian (0) \[Species\]"
	cleanName = "Reptilian"
	icon_state = "lizardT"
	desc = "You are a scaly humanoid reptile, cold-blooded and ssssibilant."
	id = "lizard"
	points = 0
	isPositive = 0
	category = "species"
	mutantRace = /datum/mutantrace/lizard

/obj/trait/cat
	name = "Feline (0) \[Species\]"
	cleanName = "Feline"
	icon_state = "fertT"
	desc = "Normal cat."
	id = "cat" //need cat icon, but for now,
	points = 0
	isPositive = 0
	category = "species"
	mutantRace = /datum/mutantrace/cat

/obj/trait/bird
	name = "Avian (0) \[Species\]"
	cleanName = "Avian"
	icon_state = "birdT"
	desc = "Bird up."
	id = "bird"
	points = 0
	isPositive = 0
	category = "species"
	mutantRace = /datum/mutantrace/birb

/obj/trait/cow
	name = "Bovine (0) \[Species\]"
	cleanName = "Bovine"
	icon_state = "cowT"
	desc = "You are a hummman, always have been, always will be, and any claimmms to the contrary are mmmoooonstrous lies."
	id = "cow"
	points = 0
	isPositive = 0
	category = "species"
	mutantRace = /datum/mutantrace/cow

/obj/trait/fert
	name = "Musteline (0) \[Species\]"
	cleanName = "Musteline"
	icon_state = "fertT"
	desc = "Now everyone will know your stinky secret."
	id = "fert"
	points = 0
	isPositive = 0
	category = "species"
	mutantRace = /datum/mutantrace/fert

/obj/trait/skeleton
	name = "Skeleton (-1) \[Species\]"
	cleanName = "Skeleton"
	icon_state = "skeletonT"
	desc = "Compress all of your skin and flesh into your bones, making you resemble a skeleton. Not as uncomfortable as it sounds."
	id = "skeleton"
	points = -1
	isPositive = 1
	category = "species"
	mutantRace = /datum/mutantrace/skeleton

/obj/trait/roach
	name = "Roach (0) \[Species\]"
	cleanName = "Roach"
	icon_state = "roachT"
	desc = "One space-morning, on the shuttle-ride to the station, you found yourself transformed in your seat into a horrible vermin. A cockroach, specifically."
	id = "roach"
	points = 0
	isPositive = 0
	category = "species"
	mutantRace = /datum/mutantrace/roach

/obj/trait/species_roulette
	name = "Species Roulette (0) \[Species\]"
	cleanName = "Species Roulette"
	icon_state = "anyspeciesT"
	desc = "You might be anything any given shift! Possibly even human!!"
	id = "species_roulette"
	points = 0
	isPositive = 0
	category = "species"

	onAdd(var/mob/owner)
		if(ishuman(owner))
			//skeleton, monkey, and human (null) are rarer
			//also possible are squid and cat
			var/our_pick = pick(prob(100); /datum/mutantrace/lizard, prob(100); /datum/mutantrace/roach, prob(50); /datum/mutantrace/skeleton, prob(100); /datum/mutantrace/fert, prob(50); null, prob(25); /datum/mutantrace/monkey, prob(100); /datum/mutantrace/cow, prob(100); /datum/mutantrace/ithillid, prob(100); /datum/mutantrace/cat, prob(100); /datum/mutantrace/birb)
			if (our_pick)
				var/mob/living/carbon/human/H = owner
				H.set_mutantrace(our_pick)
		return


/obj/trait/teflon_colon
	name = "Non-Stick Colon (-1)"
	cleanName = "Teflon Colon"
	id = "teflon_colon"
	icon_state = "poo"
	desc = "Having eaten crayons all your life, your intestines are now wax-coated, non-stick, high-speed, and low-drag."
	points = -1
	isPositive = 1

	onAdd(var/mob/owner)
		..()
		if(iscarbon(owner))
			var/mob/living/carbon/C = owner
			C.poop_amount += 5

	onRemove(var/mob/owner)
		..()
		if(iscarbon(owner))
			var/mob/living/carbon/C = owner
			C.poop_amount -= 5

/obj/trait/mononym
	name = "Mononym (-1)"
	cleanName = "Mononym"
	id = "mononym"
	icon_state = "spellingerror"
	desc = "Like Cher, Madonna, Gooby, Prince. Uses the first name slot."
	points = -1
	isPositive = 1

/obj/trait/ling_blood //False positive on ling blood tests
	name = "Changeling Blood (0)"
	cleanName = "Changeling Blood"
	id = "ling_blood"
	desc = "So there may have been some changeling involvement in your ancestry. Let's not dwell on it."
	isPositive = FALSE

	onAdd(var/mob/owner)
		..()
		if(isliving(owner))
			var/mob/living/L = owner
			L.blood_id = "bloodc"

/obj/trait/super_slips
	name = "Slipping Hazard (+1)"
	cleanName = "Slipping Hazard"
	id = "super_slips"
	desc = "You never were good at managing yourself slipping."
	points = 1

//Infernal Contract Traits
/obj/trait/hair
	name = "Wickedly Good Hair"
	desc = "Sold your soul for the best hair around"
	id = "contract_hair"
	points = 0
	isPositive = 1
	unselectable = 1

	onAdd(var/mob/owner)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			omega_hairgrownium_grow_hair(H, 1)
		return

	onLife(var/mob/owner) //Just to be safe.
		if(ishuman(owner) && prob(35))
			var/mob/living/carbon/human/H = owner
			omega_hairgrownium_grow_hair(H, 1)

/obj/trait/contractlimbs
	name = "Wacky Waving Limbs"
	desc = "Sold your soul for ever shifting limbs"
	id = "contract_limbs"
	points = 0
	isPositive = 1
	unselectable = 1

	onAdd(var/mob/owner)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			randomize_mob_limbs(H)
		return

	onLife(var/mob/owner) //Just to be safe.
		if(ishuman(owner) && prob(10))
			var/mob/living/carbon/human/H = owner
			randomize_mob_limbs(H)
