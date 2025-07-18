#define OVERRIDE_ARM_L 1
#define OVERRIDE_ARM_R 2
#define OVERRIDE_LEG_R 4
#define OVERRIDE_LEG_L 8

/// mutant races: cheap way to add new "types" of mobs
/datum/mutantrace
	var/name = null				// used for identification in diseases, clothing, etc
	/// The mutation associted with the mutantrace. Saurian genetics for lizards, for instance
	var/race_mutation = null
	/// The mutant's own appearanceholder, modified to suit our target appearance
	var/datum/appearanceHolder/AH
	/// The mutant's original appearanceholder, from before they were a mutant, to restore their old appearance
	var/datum/appearanceHolder/origAH
	var/override_eyes = 1
	var/override_hair = 1
	var/override_beard = 1
	var/override_detail = 1
	var/override_skintone = 1
	var/override_attack = 1		 // set to 1 to override the limb attack actions. Mutantraces may use the limb action within custom_attack(),
								// but they must explicitly specify if they're overriding via this var
	var/override_language = null // set to a language ID to replace the language of the human
	var/understood_languages = list() // additional understood languages (in addition to override_language if set, or english if not)
	/** Mutant Appearance Flags - used to modify how the mob is drawn
	*
	* For a purely static-icon mutantrace (drawn from a single, non-chunked image), use:
	*
	* (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_NO_EYES | HAS_NO_HEAD | USES_STATIC_ICON)
	*
	* NOT_DIMORPHIC tells the sprite builder not to use any female sprites or vars. If you remove this, make sure there's a torso_f and groin_f in the mutant's DMI!
	*
	* HAS_NO_SKINTONE, HAS_NO_EYES, HAS_NO_HEAD each prevent the renderer from trying to colorize the player's body or apply hair / eyes. They tend to be baked in.
	*
	* USES_STATIC_IMAGE tells the renderer to skip most of the body-sprite assembly stuff, since our sprite is already fully assembled
	*
	* To make a dismemberable mutant, here's an example from lizard:
	*
	* (NOT_DIMORPHIC | HAS_HUMAN_EYES | BUILT_FROM_PIECES | HAS_EXTRA_DETAILS | FIX_COLORS | SKINTONE_USES_PREF_COLOR_1 | HAS_SPECIAL_HAIR)
	*
	* SKINTONE_USES_PREF_COLOR_1 tells the renderer that the skintone will come from the appearanceholder's first customization color
	*
	* HAS_HUMAN_EYES tells the head builder to render their eyes
	*
	* HAS_EXTRA_DETAILS tells the sprite builder to apply whatever's defined in their mob_detail_1 vars to their sprite
	*
	* FIX_COLORS clamps the RGB values of the customization colors betwen 50 and 190. Keeps them from getting too dark or oversaturated
	*
	* HAS_SPECIAL_HAIR tells the hair renderer to display the sprites stored iin the head's special hair, which can be defined here (through the appearanceholder)
	*
	* BUILT_FROM_PIECES is important, it tells the renderer to assemble the mutant from a set of separate pieces, like a human
	* this allows them to apppear to be missing limbs when dismembered. Check out lizard.dmi for an example of how it should be set up.
	*
	* SEE: appearance.dm for more flags and details!
	*/
	var/mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_NO_EYES | HAS_NO_HEAD | USES_STATIC_ICON)

	/// if TRUE, allows human diseases and dna injectors to affect this mutantrace
	var/human_compatible = TRUE
	/// if FALSE, can only wear clothes if listed in [/obj/item/clothing/var/compatible_species]
	var/uses_human_clothes = TRUE
	/// set to an icon to have human.update_clothing() look through its icon_states for matching things
	var/clothing_icon_override = null
	/// if TRUE, only understood by others of this mutantrace
	var/exclusive_language = FALSE
	/// overrides normal voice message if defined (and others don't understand us, ofc)
	var/voice_message = null
	var/voice_name = "human"
	/// Should robots arrest these by default?
	var/jerk = 0
	/// Should stable mutagen not copy from this mutant?
	var/dna_mutagen_banned = TRUE

	/// This is used for static icons if the mutant isn't built from pieces
	/// For chunked mutantraces this must still point to a valid full-body image to generate a staticky sprite for ghostdrones.
	var/icon = 'icons/mob/genetics.dmi'
	var/icon_state = "blank_c"
	/// The icon used to render their eyes
	var/eye_icon = 'icons/mob/human_hair.dmi'
	/// The state used to render their eyes
	var/eye_state = "eyes"

	/// If the mutant uses a non-human head, this'll tell the head builder which head to build
	var/special_head = null
	/// If our mutant has a female variant, it'll use this head instead
	var/special_head_f = null
	/// The icon_state of the head we're using
	var/special_head_state = "head"
	/// If our mutant has a female variant, it'll use this head image instead
	var/special_head_state_f = null
	/// The icon of the head, body, and limbs we're using
	var/mutant_folder = 'icons/mob/genetics.dmi'
	/// Swaps out the entries in the mob's organ_holder with these (hopefully) organs
	/// Format: ("entry_in_organholder's_organlist", /obj/item/organ/path)
	var/list/mutant_organs = list()
	/// If our mutant has a female variant that has different organs, these will be used instead
	var/list/mutant_organs_f = null

	var/head_offset = 0 // affects pixel_y of clothes
	var/hand_offset = 0
	var/body_offset = 0
	var/arm_offset = 0
	/// affects pixel_y of the legs and stump, in case the mutant has a non-human length torsocrotch
	var/leg_offset = 0
	/// affects pixel_y of eyes if they're different from normal head-placement. darn anime monkey eyes
	/// If 0, it inherits that of the head offset. Otherwise, it applies as normal
	/// So, it should typically be something like head_offset +/- a few pixels
	var/eye_offset = 0

	var/list/limb_list = list()
	var/r_limb_arm_type_mutantrace = null // Should we get custom arms? Dispose() replaces them with normal human arms.
	var/l_limb_arm_type_mutantrace = null
	var/r_limb_leg_type_mutantrace = null
	var/l_limb_leg_type_mutantrace = null

	var/r_limb_arm_type_mutantrace_f = null // Should we get custom arms? Dispose() replaces them with normal human arms.
	var/l_limb_arm_type_mutantrace_f = null
	var/r_limb_leg_type_mutantrace_f = null
	var/l_limb_leg_type_mutantrace_f = null

	//This stuff is for robot_parts, the stuff above is for human_parts
	var/r_robolimb_arm_type_mutantrace = null // Should we get custom arms? Dispose() replaces them with normal human arms.
	var/l_robolimb_arm_type_mutantrace = null
	var/r_robolimb_leg_type_mutantrace = null
	var/l_robolimb_leg_type_mutantrace = null

	/// Replace both arms regardless of mob status (new and dispose).
	var/ignore_missing_limbs = 0

	var/firevuln = 1 //Scales damage, just like critters.
	var/brutevuln = 1
	var/toxvuln = 1

	var/list/typevulns

	/// ignores suffocation from being underwater + moves at full speed underwater
	var/aquatic = 0
	var/needs_oxy = 1

	var/voice_override = 0
	var/step_override = null

	var/mob/living/carbon/human/mob = null	// ...is this the owner?

	var/anchor_to_floor = 0

	/// Special Hair is anything additional that's supposed to be stuck to the mob's head
	/// Can be anything, honestly. Used for lizard head things and cow horns
	/// Will only show up if the mob's appearance flag includes HAS_SPECIAL_HAIR
	var/special_hair_1_icon
	/// The "_f" vars are applied for female variants, if the appearance flags don't have NOT_DIMORPHIC
	var/special_hair_1_icon_f
	/// State to be used. Human hairstyles must be defined by their icon state, not hairstyle name!
	var/special_hair_1_state
	var/special_hair_1_state_f
	/// Which preference entry to colorize this from.
	/// CUST_1 to use the appearanceholder's custom_first_color, and so on. Make null for just "#FFFFFF"
	var/special_hair_1_color = CUST_1
	var/special_hair_1_color_f
	/// Which layer should this hair appear? Defaults to the normal hair-layer
	var/special_hair_1_layer = MOB_HAIR_LAYER2
	var/special_hair_1_layer_f = MOB_HAIR_LAYER2
	/// The image to be inserted into the mob's appearanceholder's customization_second
	var/special_hair_2_icon
	var/special_hair_2_icon_f
	var/special_hair_2_state
	var/special_hair_2_state_f
	var/special_hair_2_color = CUST_2
	var/special_hair_2_color_f
	var/special_hair_2_layer = MOB_HAIR_LAYER2
	var/special_hair_2_layer_f = MOB_HAIR_LAYER2
	/// The image to be inserted into the mob's appearanceholder's customization_third
	var/special_hair_3_icon
	var/special_hair_3_icon_f
	var/special_hair_3_state
	var/special_hair_3_state_f
	var/special_hair_3_color = CUST_3
	var/special_hair_3_color_f
	var/special_hair_3_layer = MOB_HAIR_LAYER2
	var/special_hair_3_layer_f = MOB_HAIR_LAYER2

	/// These details will show up layered just in front of the mob's skin
	/// The image to be inserted into the mob's appearanceholder's mob_detail_1
	var/detail_1_icon
	var/detail_1_icon_f
	var/detail_1_state
	var/detail_1_state_f
	var/detail_1_color = CUST_1
	var/detail_1_color_f

	/// These details will show up layered between the backpack and the outer suit
	/// The image to be inserted into the mob's appearanceholder's mob_oversuit_1
	/// Will only show up if the mob's appearance flag includes HAS_O
	var/detail_oversuit_1_icon
	var/detail_oversuit_1_icon_f
	var/detail_oversuit_1_state
	var/detail_oversuit_1_state_f
	var/detail_oversuit_1_color = CUST_1
	var/detail_oversuit_1_color_f

	var/datum/movement_modifier/movement_modifier

	var/decomposes = TRUE

	var/list/emote_overrides = null

	/// List of 0 to 3 strings representing the names for the color channels
	/// used in the character creator. For vanilla humans (or HAS_HUMAN_HAIR)
	/// this is list("Bottom Detail", "Mid Detail", "Top Detail").
	var/list/color_channel_names = list()

	proc/say_filter(var/message)
		return message

	proc/say_verb()
		return "says"

	// custom attacks, should return attack_hand by default or bad things will happen!!
	// ^--- Outdated, please use limb datums instead if possible.
	proc/custom_attack(atom/target)
		return target.Attackhand(mob)

	// vision modifier (see_mobs, etc i guess)
	proc/sight_modifier()
		return

	proc/onLife(var/mult = 1)	//Called every Life cycle of our mob
		return

	/// Called when our mob dies.  Returning a true value will short circuit the normal death proc right before deathgasp/headspider/etc
	proc/onDeath(gibbed)
		return

	New(var/mob/living/carbon/human/M)
		..() // Cant trust not-humans with a mutantrace, they just runtime all over the place
		if(ishuman(M) && M?.bioHolder?.mobAppearance)
			if (movement_modifier)
				APPLY_MOVEMENT_MODIFIER(M, movement_modifier, src.type)
			if (!needs_oxy)
				APPLY_MOB_PROPERTY(M, PROP_BREATHLESS, src.type)
			src.AH = M.bioHolder?.mobAppearance // i mean its called appearance holder for a reason
			if(!(src.mutant_appearance_flags & NOT_DIMORPHIC))
				MakeMutantDimorphic(M)
			AppearanceSetter(M, "set")
			LimbSetter(M, "set")
			organ_mutator(M, "set")
			src.limb_list.Add(l_limb_arm_type_mutantrace, r_limb_arm_type_mutantrace, l_limb_leg_type_mutantrace, r_limb_leg_type_mutantrace)
			src.mob = M
			var/list/obj/item/clothing/restricted = list(mob.w_uniform, mob.shoes, mob.wear_suit)
			for(var/obj/item/clothing/W in restricted)
				if (istype(W,/obj/item/clothing))
					if(W.compatible_species.Find(src.name) || (src.uses_human_clothes && W.compatible_species.Find("human")))
						continue
					mob.u_equip(W)
					boutput(mob, "<span class='alert'><B>You can no longer wear the [W.name] in your current state!</B></span>")
					if (W)
						W.set_loc(mob.loc)
						W.dropped(mob)
						W.layer = initial(W.layer)
			M.update_colorful_parts()



			SPAWN_DBG(2.5 SECONDS) // Don't remove.
				if (M?.organHolder?.skull)
					M.assign_gimmick_skull() // For hunters (Convair880).
			if (movement_modifier) // down here cus it causes runtimes
				APPLY_MOVEMENT_MODIFIER(M, movement_modifier, src.type)
		else
			qdel(src)
		return

	disposing()
		if (mob)
			mob.mutantrace = null
			mob.set_face_icon_dirty()
			mob.set_body_icon_dirty()

			if (movement_modifier)
				REMOVE_MOVEMENT_MODIFIER(mob, movement_modifier, src.type)
			if (needs_oxy)
				REMOVE_MOB_PROPERTY(mob, PROP_BREATHLESS, src.type)

			var/list/obj/item/clothing/restricted = list(mob.w_uniform, mob.shoes, mob.wear_suit)
			for (var/obj/item/clothing/W in restricted)
				if (istype(W,/obj/item/clothing))
					if (W.compatible_species.Find("human"))
						continue
					mob.u_equip(W)
					boutput(mob, "<span class='alert'><B>You can no longer wear the [W.name] in your current state!</B></span>")
					if (W)
						W.set_loc(mob.loc)
						W.dropped(mob)
						W.layer = initial(W.layer)
			if (ishuman(mob))
				var/mob/living/carbon/human/H = mob
				AppearanceSetter(H, "reset")
				MutateMutant(H, "reset")
				organ_mutator(H, "reset")
				LimbSetter(H, "reset")
				qdel(src.limb_list)

				H.set_face_icon_dirty()
				H.set_body_icon_dirty()
				H.update_colorful_parts()

				SPAWN_DBG(2.5 SECONDS) // Don't remove.
					if (H?.organHolder?.skull) // check for H.organHolder as well so we don't get null.skull runtimes
						H.assign_gimmick_skull() // We might have to update the skull (Convair880).

			if (movement_modifier) // causes runtimes, so its down here now
				REMOVE_MOVEMENT_MODIFIER(mob, movement_modifier, src.type)

			mob.set_clothing_icon_dirty()
			src.mob = null

		..()
		return

	proc/AppearanceSetter(var/mob/living/carbon/human/H, var/mode as text)
		if(!ishuman(H) || !(H?.bioHolder?.mobAppearance) || !src.AH)
			return // please dont call set_mutantrace on a non-human non-appearanceholder

		switch(mode)
			if("set")	// upload everything, the appearance flags'll determine what gets used
				src.origAH = new/datum/appearanceHolder
				src.origAH.CopyOther(AH) // backup the old appearanceholder

				AH.mob_appearance_flags = src.mutant_appearance_flags
				AH.customization_first_offset_y = src.head_offset
				AH.customization_second_offset_y = src.head_offset
				AH.customization_third_offset_y = src.head_offset

				AH.special_hair_1_icon = src.special_hair_1_icon
				AH.special_hair_1_state = src.special_hair_1_state
				AH.special_hair_1_color_ref = src.special_hair_1_color
				AH.special_hair_1_layer = src.special_hair_1_layer
				AH.special_hair_1_offset_y = src.head_offset

				AH.special_hair_2_icon = src.special_hair_2_icon
				AH.special_hair_2_state = src.special_hair_2_state
				AH.special_hair_2_color_ref = src.special_hair_2_color
				AH.special_hair_2_layer = src.special_hair_2_layer
				AH.special_hair_2_offset_y = src.head_offset

				AH.special_hair_3_icon = src.special_hair_3_icon
				AH.special_hair_3_state = src.special_hair_3_state
				AH.special_hair_3_color_ref = src.special_hair_3_color
				AH.special_hair_3_layer = src.special_hair_1_layer
				AH.special_hair_3_offset_y = src.head_offset

				AH.mob_detail_1_icon = src.detail_1_icon
				AH.mob_detail_1_state = src.detail_1_state
				AH.mob_detail_1_color_ref = src.detail_1_color
				AH.mob_detail_1_offset_y = src.body_offset

				AH.mob_oversuit_1_icon = src.detail_oversuit_1_icon
				AH.mob_oversuit_1_state = src.detail_oversuit_1_state
				AH.mob_oversuit_1_color_ref = src.detail_oversuit_1_color
				AH.mob_oversuit_1_offset_y = src.body_offset

				AH.mob_head_offset = src.head_offset
				AH.mob_hand_offset = src.hand_offset
				AH.mob_body_offset = src.body_offset
				AH.mob_leg_offset = src.leg_offset
				AH.mob_arm_offset = src.arm_offset

				if (src.mutant_appearance_flags & FIX_COLORS)	// mods the special colors so it doesnt mess things up if we stop being special
					AH.customization_first_color = fix_colors(AH.customization_first_color)
					AH.customization_second_color = fix_colors(AH.customization_second_color)
					AH.customization_third_color = fix_colors(AH.customization_third_color)

				AH.s_tone_original = AH.s_tone
				if(src.mutant_appearance_flags & SKINTONE_USES_PREF_COLOR_1)
					AH.s_tone = AH.customization_first_color
				else if(src.mutant_appearance_flags & SKINTONE_USES_PREF_COLOR_2)
					AH.s_tone = AH.customization_second_color
				else if(src.mutant_appearance_flags & SKINTONE_USES_PREF_COLOR_3)
					AH.s_tone = AH.customization_third_color
				else
					AH.s_tone = AH.s_tone_original

				AH.mutant_race = src
				AH.body_icon = src.mutant_folder
				AH.body_icon_state = src.icon_state
				AH.e_icon = src.eye_icon
				AH.e_state = src.eye_state
				AH.e_offset_y = src.eye_offset ? src.eye_offset : src.head_offset

				AH.UpdateMob()
			if("reset")
				var/still_should_have_this_funky_skintone = null // Hulk and such still require us to be a funky color
				if(H.bioHolder.HasOneOfTheseEffects("hulk", "albinism", "blankman", "melanism", "achromia"))
					still_should_have_this_funky_skintone = AH.s_tone
				AH.CopyOther(src.origAH)
				if(still_should_have_this_funky_skintone)
					AH.s_tone = still_should_have_this_funky_skintone
				AH.mob_appearance_flags = HUMAN_APPEARANCE_FLAGS
				AH.body_icon = 'icons/mob/human.dmi'
				AH.mutant_race = null
				AH.customization_first_offset_y = 0
				AH.customization_second_offset_y = 0
				AH.customization_third_offset_y = 0
				AH.mob_head_offset = 0
				AH.mob_hand_offset = 0
				AH.mob_body_offset = 0
				AH.mob_arm_offset = 0
				AH.mob_leg_offset = 0
				AH.e_offset_y = 0 // Fun fact, monkey eyes are right at nipple height
				AH.mob_oversuit_1_offset_y = 0
				AH.mob_detail_1_offset_y = 0
				AH.special_hair_3_offset_y = 0
				AH.special_hair_2_offset_y = 0
				AH.special_hair_1_offset_y = 0
				AH.UpdateMob()
				qdel(origAH)


	proc/LimbSetter(var/mob/living/carbon/human/L, var/mode as text)
		if(!ishuman(L) || !L.organHolder || !L.limbs)
			return // you and what army

		switch(mode)
			if("set")
				//////////////ARMS//////////////////
				if (src.r_limb_arm_type_mutantrace)
					if ((L.limbs.r_arm && !(L.limbs.r_arm.limb_is_transplanted || L.limbs.r_arm.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/arm/limb = new src.r_limb_arm_type_mutantrace(L)
						if (istype(limb))
							qdel(L.limbs.r_arm)
							limb.quality = 0.5
							L.limbs.r_arm = limb
							limb.holder = L
							limb.remove_stage = 0

				if (src.l_limb_arm_type_mutantrace)
					if ((L.limbs.l_arm && !(L.limbs.l_arm.limb_is_transplanted || L.limbs.l_arm.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/arm/limb = new src.l_limb_arm_type_mutantrace(L)
						if (istype(limb))
							qdel(L.limbs.l_arm)
							limb.quality = 0.5
							L.limbs.l_arm = limb
							limb.holder = L
							limb.remove_stage = 0

				//////////////LEGS//////////////////
				if (src.r_limb_leg_type_mutantrace)
					if ((L.limbs.r_leg && !(L.limbs.r_leg.limb_is_transplanted || L.limbs.r_leg.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/leg/limb = new src.r_limb_leg_type_mutantrace(L)
						if (istype(limb))
							qdel(L.limbs.r_leg)
							limb.quality = 0.5
							L.limbs.r_leg = limb
							limb.holder = L
							limb.remove_stage = 0

				if (src.l_limb_leg_type_mutantrace)
					if ((L.limbs.l_leg && !(L.limbs.l_leg.limb_is_transplanted || L.limbs.l_leg.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/leg/limb = new src.l_limb_leg_type_mutantrace(L)
						if (istype(limb))
							qdel(L.limbs.l_leg)
							limb.quality = 0.5
							L.limbs.l_leg = limb
							limb.holder = L
							limb.remove_stage = 0

				//////////////HEAD//////////////////
				if (src.special_head)
					L.organHolder?.head?.MakeMutantHead(src.special_head, src.mutant_folder, src.special_head_state)

			if ("reset")
				// And the other way around (Convair880).
				if (src.r_limb_arm_type_mutantrace)
					if ((L.limbs.r_arm && !(L.limbs.r_arm.limb_is_transplanted || L.limbs.r_arm.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/arm/limb = new /obj/item/parts/human_parts/arm/right(L)
						if (istype(limb))
							qdel(L.limbs.r_arm)
							limb.quality = 0.5
							L.limbs.r_arm = limb
							limb.holder = L
							limb.remove_stage = 0

				if (src.l_limb_arm_type_mutantrace)
					if ((L.limbs.l_arm && !(L.limbs.l_arm.limb_is_transplanted || L.limbs.l_arm.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/arm/limb = new /obj/item/parts/human_parts/arm/left(L)
						if (istype(limb))
							qdel(L.limbs.l_arm)
							limb.quality = 0.5
							L.limbs.l_arm = limb
							limb.holder = L
							limb.remove_stage = 0

				//////////////LEGS//////////////////
				if (src.r_limb_leg_type_mutantrace)
					if ((L.limbs.r_leg && !(L.limbs.r_leg.limb_is_transplanted || L.limbs.r_leg.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/leg/limb = new /obj/item/parts/human_parts/leg/right(L)
						if (istype(limb))
							qdel(L.limbs.r_leg)
							limb.quality = 0.5
							L.limbs.r_leg = limb
							limb.holder = L
							limb.remove_stage = 0

				if (src.l_limb_leg_type_mutantrace)
					if ((L.limbs.l_leg && !(L.limbs.l_leg.limb_is_transplanted || L.limbs.l_leg.limb_is_unnatural)) || src.ignore_missing_limbs == 1)
						var/obj/item/parts/human_parts/leg/limb = new /obj/item/parts/human_parts/leg/left(L)
						if (istype(limb))
							qdel(L.limbs.l_leg)
							limb.quality = 0.5
							L.limbs.l_leg = limb
							limb.holder = L
							limb.remove_stage = 0
				//////////////HEAD//////////////////
				L.organHolder?.head?.MakeMutantHead(HEAD_HUMAN, 'icons/mob/human_head.dmi', "head")

	proc/organ_mutator(var/mob/living/carbon/human/O, var/mode as text, var/drop_tail)
		if(!ishuman(O) || !(O?.organHolder))
			return // hard to mess with someone's organs if they can't have any

		var/datum/organHolder/OHM = O.organHolder

		switch(mode)
			if("set")
				if(!src.mutant_organs.len)
					return // All done!
				else
					for(var/mutorgan in src.mutant_organs)
						if (mutorgan == "tail") // Not everyone has a tail. So just force it in
							if (OHM.tail)
								var/obj/item/organ/tail/organ_drop = OHM.tail
								organ_drop.donor = null // Humanizing tail-havers made them clumsy otherwise
								OHM.drop_organ("tail")
								if (!drop_tail)
									qdel(organ_drop)
						else if(mutorgan == "butt") // butts arent organs
							var/obj/item/clothing/head/butt/org = OHM.get_organ(mutorgan)
							if(!org || istype(org, /obj/item/clothing/head/butt/cyberbutt)) // No free butts, keep your robutt too
								continue
						else // everything else is an organ, though
							var/obj/item/organ/org = OHM.get_organ(mutorgan)
							if (!org || org.robotic) // No free organs, trade-ins only, keep ur robotic stuff
								continue
						var/obj/item/organ_get = src.mutant_organs[mutorgan]
						OHM.receive_organ(new organ_get(O, OHM), mutorgan, 0, 1)
					return
			if("reset") // Make everything mutant back into stock-ass human
				if(!src.mutant_organs.len)
					return // All done!
				if (OHM.tail) // mutant to human, drop the tail. Unless you're a changer, then your butt just eats it
					var/obj/organ_drop = OHM.tail
					OHM.drop_organ("tail")
					if (!drop_tail)
						qdel(organ_drop)
				else
					for(var/mutorgan in src.mutant_organs)
						if(mutorgan == "butt") // butts arent organs
							var/obj/item/clothing/head/butt/org = OHM.get_organ(mutorgan)
							if(!org || istype(org, /obj/item/clothing/head/butt/cyberbutt)) // No free butts, keep your robutt too
								continue
						else // everything else is an organ, though
							var/obj/item/organ/org = OHM.get_organ(mutorgan)
							if (!org || org.robotic) // No free organs, trade-ins only, keep ur robotic stuff
								continue
						var/obj/item/organ_get = OHM.organ_type_list[mutorgan] // organ_type_list holds all the default human-ass organs
						OHM.receive_organ(new organ_get(O, OHM), mutorgan, 0, 1)
					return

	/// Applies or removes the bioeffect associated with the mutantrace
	proc/MutateMutant(var/mob/living/carbon/human/H, var/mode as text)
		if (!H || !mode || !race_mutation)
			return
		var/datum/bioEffect/mutantrace/mr = src.race_mutation
		switch (mode)
			if ("set")
				if(!H.bioHolder.HasEffect(initial(mr.id)))
					H.bioHolder.AddEffect(initial(mr.id), 0, 0, 0, 1)
			if ("reset")
				if(H.bioHolder.HasEffect(initial(mr.id)))
					H.bioHolder.RemoveEffect(initial(mr.id))

	/// Copies over female variants of mutant heads and organs
	proc/MakeMutantDimorphic(var/mob/living/carbon/human/H)
		if(!src.AH || !ishuman(H)) return

		if(src.AH.gender == FEMALE)
			if(src.special_head_f)
				src.special_head = src.special_head_f
			if(src.special_head_state_f)
				src.special_head_state = src.special_head_state_f
			if(src.mutant_organs_f)
				src.mutant_organs =  src.mutant_organs_f

			if(src.r_limb_arm_type_mutantrace_f)
				src.r_limb_arm_type_mutantrace = src.r_limb_arm_type_mutantrace_f
			if(src.l_limb_arm_type_mutantrace_f)
				src.l_limb_arm_type_mutantrace = src.l_limb_arm_type_mutantrace_f
			if(src.r_limb_leg_type_mutantrace_f)
				src.r_limb_leg_type_mutantrace = src.r_limb_leg_type_mutantrace_f
			if(src.l_limb_leg_type_mutantrace_f)
				src.l_limb_leg_type_mutantrace = src.l_limb_leg_type_mutantrace_f

			if(src.special_hair_1_icon_f)
				src.special_hair_1_icon = src.special_hair_1_icon_f
			if(src.special_hair_1_state_f)
				src.special_hair_1_state = src.special_hair_1_state_f
			if(src.special_hair_1_color_f)
				src.special_hair_1_color = src.special_hair_1_color_f
			if(src.special_hair_1_layer_f)
				src.special_hair_1_layer = src.special_hair_1_layer_f

			if(src.special_hair_2_icon_f)
				src.special_hair_2_icon = src.special_hair_2_icon_f
			if(src.special_hair_2_state_f)
				src.special_hair_2_state = src.special_hair_2_state_f
			if(src.special_hair_2_color_f)
				src.special_hair_2_color = src.special_hair_2_color_f
			if(src.special_hair_2_layer_f)
				src.special_hair_2_layer = src.special_hair_2_layer_f

			if(src.special_hair_3_icon_f)
				src.special_hair_3_icon = src.special_hair_3_icon_f
			if(src.special_hair_3_state_f)
				src.special_hair_3_state = src.special_hair_3_state_f
			if(src.special_hair_3_color_f)
				src.special_hair_3_color = src.special_hair_3_color_f
			if(src.special_hair_3_layer_f)
				src.special_hair_3_layer = src.special_hair_3_layer_f

			if(src.detail_1_icon_f)
				src.detail_1_icon = src.detail_1_icon_f
			if(src.detail_1_state_f)
				src.detail_1_state = src.detail_1_state_f
			if(src.detail_1_color_f)
				src.detail_1_color = src.detail_1_color_f

			if(src.detail_oversuit_1_icon_f)
				src.detail_oversuit_1_icon = src.detail_oversuit_1_icon_f
			if(src.detail_oversuit_1_state_f)
				src.detail_oversuit_1_state = src.detail_oversuit_1_state_f
			if(src.detail_oversuit_1_color_f)
				src.detail_oversuit_1_color = src.detail_oversuit_1_color_f

/datum/mutantrace/blob // podrick's july assjam submission, it's pretty cute
	name = "blob"
	icon = 'icons/mob/blob_ambassador.dmi'
	mutant_folder = 'icons/mob/blob_ambassador.dmi'
	icon_state = "blob"
	human_compatible = 0
	uses_human_clothes = 0
	hand_offset = -1
	body_offset = -8
	voice_override = "bloop"
	firevuln = 1.5
	typevulns = list("cut" = 1.25, "stab" = 0.5, "blunt" = 0.75)

	say_verb()
		return pick("burbles", "gurgles", "blurbs", "gloops")

/datum/mutantrace/flubber
	name = "flubber"
	icon = 'icons/mob/flubber.dmi'
	mutant_folder = 'icons/mob/flubber.dmi'
	icon_state = "flubber"
	uses_human_clothes = 0
	head_offset = -7
	voice_override = "bloop"

	movement_modifier = /datum/movement_modifier/flubber

	//override_static = 1

	jerk = 0 //flubber is a good goo person

	New()
		..()
		if (mob)
			RegisterSignal(mob, COMSIG_MOVABLE_MOVED, PROC_REF(flub))

	sight_modifier()
		mob.see_in_dark = SEE_DARK_FULL

	proc/flub()
		playsound(mob, "sound/misc/boing/[rand(1,6)].ogg", 20, 1 )
		animate(mob, time = 1, pixel_y = 16, easing = ELASTIC_EASING)
		animate(time = 1, pixel_y = 0, easing = ELASTIC_EASING)

	say_filter(var/message)
		return pick("Wooo!!", "Whopeee!!", "Boing!!", "Čapaš!!")

	onLife(var/mult = 1)
		if (!isdead(mob))
			mob.reagents.add_reagent("flubber", 10) //change "flubber" to whatever flubber is in code obviously

		if (mob.health < mob.max_health && mob.health>0) //you can kill flubber with extreme measures
			mob.full_heal()

	onDeath(gibbed)
		var/turf/T = get_turf(mob)
		T.fluid_react_single("flubber", 500)
		mob.gib()


	say_verb()
		return "flubbers"

/datum/mutantrace/flashy
	name = "flashy"
	icon = 'icons/mob/flashy.dmi'
	icon_state = "body_m"
	mutant_appearance_flags = (HAS_NO_SKINTONE | HAS_HUMAN_HAIR | HEAD_HAS_OWN_COLORS | HAS_HUMAN_EYES | WEARS_UNDERPANTS | BUILT_FROM_PIECES)
	override_attack = 0
	mutant_folder = 'icons/mob/flashy.dmi'
	special_head = HEAD_FLASHY
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/flashy/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/flashy/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/flashy/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/flashy/left
	dna_mutagen_banned = FALSE


/datum/mutantrace/virtual
	name = "virtual"
	icon = 'icons/mob/virtual.dmi'
	icon_state = "body_m"
	override_attack = 0
	mutant_folder = 'icons/mob/virtual.dmi'
	special_head = HEAD_VIRTUAL
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/virtual/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/virtual/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/virtual/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/virtual/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_HUMAN_HAIR | HAS_HUMAN_EYES | BUILT_FROM_PIECES)


	New(var/mob/living/carbon/human/H)
		..()
		if(ishuman(mob))
			mob.blood_color = pick("#FF0000","#FFFF00","#00FF00","#00FFFF","#0000FF","#FF00FF")
			var/datum/abilityHolder/virtual/A = H.get_ability_holder(/datum/abilityHolder/virtual)
			if (A && istype(A))
				return
			var/datum/abilityHolder/virtual/W = H.add_ability_holder(/datum/abilityHolder/virtual)
			W.addAbility(/datum/targetable/virtual/logout)
//for sure didnt steal code from ww. no siree

/datum/mutantrace/blank
	name = "blank"
	icon_state = "blank"
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_HUMAN_HAIR | HAS_NO_EYES | HAS_NO_HEAD | WEARS_UNDERPANTS | USES_STATIC_ICON)
	override_attack = 0

/datum/mutantrace/grey
	name = "grey"
	icon_state = "grey"
	voice_name = "grey"
	voice_message = "hums"

	exclusive_language = 1
	jerk = 1
	var/original_blood_color = null

	New(var/mob/living/carbon/human/M)
		..()
		emote_overrides = grey_emotes
		if(ishuman(mob))
			original_blood_color = mob.blood_color
			mob.blood_color = "#000000"

	disposing()
		if(ishuman(mob))
			if(!isnull(original_blood_color))
				mob.blood_color = original_blood_color
		original_blood_color = null
		..()

	sight_modifier()
		mob.sight |= SEE_MOBS
		mob.see_in_dark = SEE_DARK_FULL
		mob.see_invisible = 3

/datum/mutantrace/lizard
	name = "lizard"
	icon = 'icons/mob/lizard.dmi'
	icon_state = "body_m"
	override_attack = 0
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_EYES | BUILT_FROM_PIECES | HAS_EXTRA_DETAILS | FIX_COLORS | SKINTONE_USES_PREF_COLOR_1 | HAS_SPECIAL_HAIR | TORSO_HAS_SKINTONE | WEARS_UNDERPANTS)
	voice_override = "lizard"
	special_head = HEAD_LIZARD
	special_head_state = "head"
	eye_state = "eyes_lizard"
	mutant_organs = list("tail" = /obj/item/organ/tail/lizard,
	"left_eye" = /obj/item/organ/eye/lizard,
	"right_eye" = /obj/item/organ/eye/lizard)
	mutant_folder = 'icons/mob/lizard.dmi'
	special_hair_1_icon = 'icons/mob/lizard.dmi'
	special_hair_1_state = "head-detail_1"
	special_hair_1_color = CUST_3
	special_hair_1_layer = MOB_HAIR_LAYER1
	special_hair_1_layer_f = MOB_HAIR_LAYER1
	detail_1_icon = 'icons/mob/lizard.dmi'
	detail_1_state = "lizard_detail-1"
	detail_1_color = CUST_2
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/lizard/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/lizard/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/lizard/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/lizard/left
	race_mutation = /datum/bioEffect/mutantrace // Most mutants are just another form of lizard, didn't you know?
	clothing_icon_override = 'icons/mob/lizard_clothes.dmi'
	color_channel_names = list("Episcutus", "Ventral Aberration", "Sagittal Crest")
	dna_mutagen_banned = FALSE

	New(var/mob/living/carbon/human/H)
		..()
		if(ishuman(H))
			H.give_lizard_powers()
			H.AddComponent(/datum/component/consume/organpoints, /datum/abilityHolder/lizard)
			H.AddComponent(/datum/component/consume/can_eat_inedible_organs)
			H.mob_flags |= SHOULD_HAVE_A_TAIL

			H.update_face()
			H.update_body()
			H.update_clothing()
			H.thermoregulation_mult = 0.004
			H.base_body_temp = T0C + 38

	sight_modifier()
		mob.see_in_dark = SEE_DARK_HUMAN + 1
		mob.see_invisible = 1

	proc/replacement_s(s, blank, next_letter)
		if(isUpper(s) && !isUpper(next_letter))
			return capitalize(stutter("ss") + next_letter)
		if(isUpper(s) && isUpper(next_letter))
			return stutter("SS") + next_letter
		if(!isUpper(s))
			return stutter("ss") + next_letter
		else
			return stutter("ss") + next_letter


	say_filter(var/message)
		var/static/regex/s_catch = regex(@"(s)(.?)","gi")
		return s_catch.Replace(message, /datum/mutantrace/lizard/proc/replacement_s)

	disposing()
		if(ishuman(mob))
			var/mob/living/carbon/human/L = mob
			var/datum/component/C = L.GetComponent(/datum/component/consume/organpoints)
			C?.RemoveComponent(/datum/component/consume/organpoints)
			var/datum/component/D = L.GetComponent(/datum/component/consume/can_eat_inedible_organs)
			D?.RemoveComponent(/datum/component/consume/can_eat_inedible_organs)
			L.remove_lizard_powers()
			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
			mob.thermoregulation_mult = initial(mob.thermoregulation_mult)
			mob.base_body_temp = initial(mob.base_body_temp)
		. = ..()

	say_verb()
		return "hisses"



/datum/mutantrace/zombie
	name = "zombie"
	icon_state = "zombie"
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_HUMAN_HAIR | HAS_NO_EYES | HAS_NO_HEAD | USES_STATIC_ICON | HEAD_HAS_OWN_COLORS)
	jerk = 1
	needs_oxy = 0
	movement_modifier = /datum/movement_modifier/zombie
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/right/zombie
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/left/zombie
	var/strain = 0

	//this is terrible, but I do anyway.
	can_infect/bubs
		strain = 1

	can_infect/spitter
		strain = 2

	can_infect/normal
		strain = -1

	New(var/mob/living/carbon/human/M)
		..()
		emote_overrides = zombie_emotes
		if(ishuman(mob))
			src.add_ability(mob)
			M.is_zombie = 1
			M.max_health += 100
			M.health = max(M.max_health, M.health)

			if (strain == 1)
				make_bubs(M)
			else if (strain == 2)
				make_spitter(M)
			else if (strain == 0 && prob(30))	//chance to be one or the other
				strain = rand(1,2)
				if(strain == 1) //Bubs
					make_bubs(M)
				if(strain == 2) // spitter ranged zombie
					make_spitter(M)

			M.add_stam_mod_max("zombie", 100)
			APPLY_MOB_PROPERTY(M, PROP_STAMINA_REGEN_BONUS, "zombie", -5)

			SHOW_ZOMBIE_TIPS(M)

	proc/make_bubs(var/mob/living/carbon/human/M)
		M.bioHolder.AddEffect("strong")
		M.bioHolder.AddEffect("mattereater")
		M.Scale(1.15, 1.15) //Fat bioeffect doesn't exist anymore, so they're just bigger now.
		M.max_health += 150
		M.health = max(M.max_health, M.health)

	proc/make_spitter(var/mob/living/carbon/human/M)
		M.max_health -= 45
		M.health = max(M.max_health, M.health)
		M.Scale(1, 0.9)
		M.add_sm_light("glowy", list(94, 209, 31, 175))
		M.bioHolder.AddEffect("shoot_limb")
		M.bioHolder.AddEffect("acid_bigpuke")
		boutput(M, "<h2><span class='alert'><B>You're a spitter zombie, check your BIOEFFECTS for your POWERS!</B></span></h2>")

	onLife(var/mult = 1)
		..()

		mob.HealDamage("All", 2*mult, 2*mult)
		if (strain == 1)
			mob.HealDamage("All", 1*mult, 1*mult)
		else if (strain == 2 && prob(5))//spitter, then regrow their arms possibly
			mob.limbs.mend(1)

	disposing()
		if (ishuman(mob))
			mob.remove_stam_mod_max("zombie")
			REMOVE_MOB_PROPERTY(mob, PROP_STAMINA_REGEN_BONUS, "zombie")
		..()

	proc/add_ability(var/mob/living/carbon/human/H)
		return

	sight_modifier()
		mob.sight |= SEE_MOBS
		mob.see_in_dark = SEE_DARK_FULL
		mob.see_invisible = 0

	say_filter(var/message)
		return pick("Urgh...", "Brains...", "Hungry...", "Kill...")

	onDeath(gibbed)
		if(gibbed)
			return
		mob.show_message("<span class='notice'>You can feel your flesh re-assembling. You will rise once more. (This will take about one minute.)</span>")
		SPAWN_DBG(45 SECONDS)
			if (mob)
				if (!mob.organHolder.brain || !mob.organHolder.skull || !mob.organHolder.head)
					mob.show_message("<span class='notice'>You fail to rise, your brain has been destroyed.</span>")
				else
					// ha ha nope. Instead we copy paste a bunch of shit from full_heal but leave out select bits such as : limb regeneration, reagent clearing
					//mob.full_heal()

					mob.HealDamage("All", 100000, 100000)
					mob.drowsyness = 0
					mob.stuttering = 0
					mob.losebreath = 0
					mob.delStatus("paralysis")
					mob.delStatus("stunned")
					mob.delStatus("weakened")
					mob.delStatus("slowed")
					mob.delStatus("radiation")
					mob.change_eye_blurry(-INFINITY)
					mob.take_eye_damage(-INFINITY)
					mob.take_eye_damage(-INFINITY, 1)
					mob.take_ear_damage(-INFINITY)
					mob.take_ear_damage(-INFINITY, 1)
					mob?.organHolder?.brain?.unbreakme()
					mob.take_brain_damage(-120)
					mob.health = mob.max_health
					if (mob.stat > 1)
						setalive(mob)

					mob.remove_ailments()
					mob.take_toxin_damage(-INFINITY)
					mob.take_oxygen_deprivation(-INFINITY)
					mob.change_misstep_chance(-INFINITY)

					mob.blinded = 0
					mob.bleeding = 0
					mob.blood_volume = 500

					if (!mob.organHolder)
						mob.organHolder = new(mob)
					mob.organHolder.create_organs()

					if (mob.get_stamina() != (STAMINA_MAX + mob.get_stam_mod_max()))
						mob.set_stamina(STAMINA_MAX + mob.get_stam_mod_max())

					mob.update_body()
					mob.update_face()


					mob.emote("scream")
					mob.visible_message("<span class='alert'><B>[mob]</B> rises from the dead!</span>")

					if (strain == 0 && prob(25))	//chance to be one or the other
						strain = rand(1,2)
						if(strain == 1) //Bubs
							make_bubs(mob)
						if(strain == 2) // spitter ranged zombie
							make_spitter(mob)

		return 1

/datum/mutantrace/zombie/can_infect

	add_ability(var/mob/living/carbon/human/H)
		var/datum/abilityHolder/critter/C = H.add_ability_holder(/datum/abilityHolder/critter) //lol
		C.transferOwnership(H)
		C.addAbility(/datum/targetable/critter/zombify)

	disposing()
		if (ishuman(mob))
			var/mob/living/carbon/human/H = mob
			H.abilityHolder.removeAbility(/datum/targetable/critter/zombify)
		..()

/datum/mutantrace/vampiric_thrall
	name = "vampiric thrall"
	icon = 'icons/mob/vampiric_thrall.dmi'
	icon_state = "body_m"
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_HUMAN_HAIR | HAS_HUMAN_EYES | BUILT_FROM_PIECES | HEAD_HAS_OWN_COLORS | WEARS_UNDERPANTS)
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/vampiric_thrall/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/vampiric_thrall/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/vampiric_thrall/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/vampiric_thrall/left
	mutant_folder = 'icons/mob/vampiric_thrall.dmi'
	special_head = HEAD_VAMPTHRALL
	jerk = 1

	var/blood_points = 0
	var/const/blood_decay = 0.5
	var/cleanable_tally = 0
	var/const/blood_to_health_scalar = 0.5 //200 blood = 100 health

	New(var/mob/living/carbon/human/M)
		..()
		emote_overrides = zombie_emotes
		if(ishuman(mob))
			src.add_ability(mob)
			M.add_stam_mod_max("vampiric_thrall", 100)
			//APPLY_MOB_PROPERTY(M, PROP_STAMINA_REGEN_BONUS, "vampiric_thrall", 15)

	disposing()
		if (ishuman(mob))
			mob.remove_stam_mod_max("vampiric_thrall")
			//REMOVE_MOB_PROPERTY(mob, PROP_STAMINA_REGEN_BONUS, "vampiric_thrall")
		..()

	proc/add_ability(var/mob/living/carbon/human/H)
		H.make_vampiric_thrall()

	onLife(var/mult = 1)
		..()

		if (mob.bleeding)
			blood_points -= blood_decay * mob.bleeding

		var/prev_blood = blood_points
		blood_points -= blood_decay * mult
		blood_points = max(0,blood_points)
		cleanable_tally += (prev_blood - blood_points)
		if (cleanable_tally > 20)
			make_cleanable(/obj/decal/cleanable/tracked_reagents/blood,get_turf(mob))
			cleanable_tally = 0

		mob.max_health = blood_points * blood_to_health_scalar
		mob.max_health = (max(20,mob.max_health))

	onDeath(gibbed)
		var/datum/abilityHolder/vampiric_thrall/abil = mob.get_ability_holder(/datum/abilityHolder/vampiric_thrall)
		if (abil)
			if (abil.master)
				abil.master.remove_thrall(mob)
			else
				remove_insurgent_status(mob)
		..()

/datum/mutantrace/skeleton
	name = "skeleton"
	icon = 'icons/mob/skeleton.dmi'
	mutant_folder = 'icons/mob/skeleton.dmi'
	icon_state = "skeleton"
	voice_override = "skelly"
	mutant_organs = list("tail" = /obj/item/organ/tail/bone,
	"left_eye" = /obj/item/organ/eye/skeleton,
	"right_eye" = /obj/item/organ/eye/skeleton,
	"butt" = /obj/item/clothing/head/butt/skeleton)
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_NO_EYES | BUILT_FROM_PIECES | HEAD_HAS_OWN_COLORS | WEARS_UNDERPANTS)
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/skeleton/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/skeleton/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/skeleton/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/skeleton/left
	special_head = HEAD_SKELETON
	decomposes = FALSE
	race_mutation = /datum/bioEffect/mutantrace/skeleton
	dna_mutagen_banned = FALSE

	New(var/mob/living/carbon/human/M)
		..()
		if(ishuman(M))
			M.mob_flags |= IS_BONER
			M.blood_id = "calcium"
			all_blood_reagents |= "calcium"
			M.mob_flags |= SHOULD_HAVE_A_TAIL

	disposing()
		if (ishuman(mob))
			mob.mob_flags &= ~IS_BONER
			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
		. = ..()


/*
/datum/mutantrace/ape
	name = "ape"
	icon_state = "ape"
*/

/datum/mutantrace/nostalgic
	name = "Homo nostalgius"
	icon_state = "oldhuman"
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_SKINTONE | HAS_NO_EYES | HAS_NO_HEAD | USES_STATIC_ICON)
	override_attack = 0


/datum/mutantrace/abomination
	name = "abomination"
	icon_state = "abomination"
	human_compatible = 0
	uses_human_clothes = 0
	jerk = 1
	brutevuln = 0.2
	override_attack = 0
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/right/abomination
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/left/abomination
	ignore_missing_limbs = 1 //OVERRIDE_ARM_L | OVERRIDE_ARM_R
	anchor_to_floor = 1
	movement_modifier = /datum/movement_modifier/abomination

	var/last_drain = 0
	var/drains_dna_on_life = 1
	var/ruff_tuff_and_ultrabuff = 1

	New(var/mob/living/carbon/human/M)
		emote_overrides = abomination_emotes
		if(ruff_tuff_and_ultrabuff && ishuman(M))
			M.add_stam_mod_max("abomination", 100)
			APPLY_MOB_PROPERTY(M, PROP_STAMINA_REGEN_BONUS, "abomination", 100)
			M.add_stun_resist_mod("abomination", 1000)
			APPLY_MOB_PROPERTY(M, PROP_CANTSPRINT, src)
		last_drain = world.time
		return ..(M)

	disposing()
		if(mob)
			mob.remove_stam_mod_max("abomination")
			REMOVE_MOB_PROPERTY(mob, PROP_STAMINA_REGEN_BONUS, "abomination")
			mob.remove_stun_resist_mod("abomination")
			REMOVE_MOB_PROPERTY(mob, PROP_CANTSPRINT, src)
		return ..()


	onLife(var/mult = 1)
		//Bringing it more in line with how it was before it got broken (in a hilarious fashion)
		if (ruff_tuff_and_ultrabuff && !(mob.getStatusDuration("burning") && prob(90))) //Are you a macho abomination or not?
			mob.delStatus("disorient")
			mob.drowsyness = 0
			mob.change_misstep_chance(-INFINITY)
			mob.delStatus("slowed")
			mob.stuttering = 0
			changeling_super_heal_step(mob, mult = mult)

		if (drains_dna_on_life) //Do you continuously lose DNA points when in this form?
			var/datum/abilityHolder/changeling/C = mob.get_ability_holder(/datum/abilityHolder/changeling)

			if(!C)
				mob.show_text("<I><B>You cannot hold this form!</B></I>", "red")
				mob.revert_from_horror_form()

			if (C?.points)
				if (last_drain + 30 <= world.time)
					C.points = max(0, C.points - (1 * mult))

				switch (C.points)
					if (-INFINITY to 0)
						mob.show_text("<I><B>We cannot hold this form!</B></I>", "red")
						mob.revert_from_horror_form()
					if (5)
						mob.show_text("<I><B>Our DNA stockpile is almost depleted!</B></I>", "red")
					if (10)
						mob.show_text("<I><B>We cannot maintain this form much longer!</B></I>", "red")
		return

	say_filter(var/message)
		return pick("We are one...", "Join with us...", "Sssssss...")

	say_verb()
		return "screeches"

/datum/mutantrace/abomination/admin //This will not revert to human form
	drains_dna_on_life = 0

/datum/mutantrace/abomination/admin/weak //This also does not get any of the OnLife effects
	ruff_tuff_and_ultrabuff = 0

/datum/mutantrace/werewolf
	name = "werewolf"
	icon = 'icons/mob/werewolf.dmi'
	icon_state = "body_m"
	human_compatible = 0
	uses_human_clothes = 0
	var/original_name
	jerk = 1
	override_attack = 0
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/werewolf/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/werewolf/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/werewolf/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/werewolf/left
	ignore_missing_limbs = 1 // heck it, just regenerate your limbs, you shambling dogbomination
	var/old_client_color = null
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_NO_EYES | BUILT_FROM_PIECES | HEAD_HAS_OWN_COLORS)
	mutant_folder = 'icons/mob/werewolf.dmi'
	clothing_icon_override = 'icons/mob/werewolf_clothes.dmi'
	special_head = HEAD_WEREWOLF
	mutant_organs = list("tail" = /obj/item/organ/tail/wolf)

	//head_offset = 5
	//hand_offset = 3
	//arm_offset = 3

	New()
		..()
		emote_overrides = werewolf_emotes
		if (ishuman(mob))
			mob.AddComponent(/datum/component/consume/organheal)
			mob.AddComponent(/datum/component/consume/can_eat_inedible_organs, 1) // can also eat heads
			mob.mob_flags |= SHOULD_HAVE_A_TAIL
			mob.add_stam_mod_max("werewolf", 40) // Gave them a significant stamina boost, as they're melee-orientated (Convair880).
			APPLY_MOB_PROPERTY(mob, PROP_STAMINA_REGEN_BONUS, "werewolf", 9) //mbc : these increase as they feast now. reduced!
			mob.add_stun_resist_mod("werewolf", 40)
			mob.max_health += 50
			health_update_queue |= mob
			src.original_name = mob.real_name
			mob.real_name = "werewolf"

			mob.bioHolder.AddEffect("protanopia", null, null, 0, 1)
			mob.bioHolder.AddEffect("accent_scoob_nerf", null, null, 0, 1)
			mob.bioHolder.AddEffect("regenerator_wolf", null, null, 0, 1)

	disposing()
		if (ishuman(mob))
			var/datum/component/C = mob.GetComponent(/datum/component/consume/organheal)
			C?.RemoveComponent(/datum/component/consume/organheal)
			var/datum/component/D = mob.GetComponent(/datum/component/consume/can_eat_inedible_organs)
			D?.RemoveComponent(/datum/component/consume/can_eat_inedible_organs)
			mob.remove_stam_mod_max("werewolf")
			REMOVE_MOB_PROPERTY(mob, PROP_STAMINA_REGEN_BONUS, "werewolf")
			mob.remove_stun_resist_mod("werewolf")
			mob.max_health -= 50
			health_update_queue |= mob
			mob.bioHolder.RemoveEffect("protanopia")
			mob.bioHolder.RemoveEffect("accent_scoob_nerf")
			mob.bioHolder.RemoveEffect("regenerator_wolf")

			if (!isnull(src.original_name))
				mob.real_name = src.original_name

			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
		. = ..()

	sight_modifier()
		if (ishuman(mob))
			mob.sight |= SEE_MOBS
			mob.see_in_dark = SEE_DARK_FULL
			mob.see_invisible = 2
		return

	// Werewolves (being a melee-focused role) are quite buff.
	onLife(var/mult = 1)
		if (mob && ismob(mob))
			if (mob.drowsyness)
				mob.drowsyness = max(0, mob.drowsyness - 2)
			if (mob.misstep_chance)
				mob.change_misstep_chance(-10 * mult)
			if (mob.getStatusDuration("slowed"))
				mob.changeStatus("slowed", -2 SECONDS * mult)

		return

	say_verb()
		return "snarls"

	say_filter(var/message)
		return message

/datum/mutantrace/hunter
	name = "hunter"
	icon = 'icons/mob/hunter.dmi'
	icon_state = "full"
	human_compatible = 0
	jerk = 1
	override_attack = 0
	mutant_folder = 'icons/mob/hunter.dmi'
	special_head = HEAD_HUNTER //heh
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/hunter/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/hunter/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/hunter/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/hunter/left
	ignore_missing_limbs = 0
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_NO_EYES | BUILT_FROM_PIECES | HEAD_HAS_OWN_COLORS)

	// Gave them a minor stamina boost (Convair880).
	New(var/mob/living/carbon/human/M)
		. = ..()
		if(ishuman(M))
			M.add_stam_mod_max("hunter", 50)
			APPLY_MOB_PROPERTY(M, PROP_STAMINA_REGEN_BONUS, "hunter", 10)

	disposing()
		if(ishuman(mob))
			mob.remove_stam_mod_max("hunter")
			REMOVE_MOB_PROPERTY(mob, PROP_STAMINA_REGEN_BONUS, "hunter")
		return ..()

	sight_modifier()
		mob.see_in_dark = SEE_DARK_FULL
		return

	say_verb()
		return "snarls"


/datum/mutantrace/ithillid
	name = "ithillid"
	icon = 'icons/mob/ithillid.dmi'
	icon_state = "body_m"
	jerk = 0
	override_attack = 0
	aquatic = 1
	voice_override = "blub"
	mutant_folder = 'icons/mob/ithillid.dmi'
	special_head = HEAD_ITHILLID
	special_hair_1_icon = 'icons/mob/ithillid.dmi'
	special_hair_1_state = "head_detail_1"
	special_hair_1_color = null
	special_hair_1_layer = MOB_HAIR_LAYER1
	special_hair_1_layer_f = MOB_HAIR_LAYER1
	race_mutation = /datum/bioEffect/mutantrace/ithillid
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/ithillid/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/ithillid/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/ithillid/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/ithillid/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_NO_EYES | BUILT_FROM_PIECES | HAS_SPECIAL_HAIR | HEAD_HAS_OWN_COLORS | WEARS_UNDERPANTS)
	dna_mutagen_banned = FALSE

	say_verb()
		return "glubs"

/datum/mutantrace/monkey
	name = "monkey"
	icon = 'icons/mob/monkey.dmi'
	mutant_folder = 'icons/mob/monkey.dmi'
	icon_state = "monkey"
	eye_state = "eyes_monkey"
	head_offset = -8
	hand_offset = -2
	body_offset = -7
	leg_offset = -4
	arm_offset = -8
	human_compatible = TRUE
	special_head = HEAD_MONKEY
	special_head_state = "head"
	exclusive_language = 1
	voice_message = "chimpers"
	voice_name = "monkey"
	override_language = "monkey"
	understood_languages = list("english")
	clothing_icon_override = 'icons/mob/monkey_clothes.dmi'
	race_mutation = /datum/bioEffect/mutantrace/monkey
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/monkey/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/monkey/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/monkey/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/monkey/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_HUMAN_EYES | BUILT_FROM_PIECES | HEAD_HAS_OWN_COLORS)
	var/had_tablepass = 0
	var/table_hide = 0
	mutant_organs = list("tail" = /obj/item/organ/tail/monkey)
	dna_mutagen_banned = FALSE

	New(var/mob/living/carbon/human/M)
		. = ..()
		emote_overrides = monkey_emotes
		if(ishuman(M))
			M.add_stam_mod_max("monkey", -50)
			M.mob_flags |= SHOULD_HAVE_A_TAIL

	disposing()
		if (ishuman(mob))
			mob.remove_stam_mod_max("monkey")
			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
		. = ..()

	say_verb()
		return "chimpers"

	custom_attack(atom/target) // Fixed: monkeys can click-hide under every table now, not just the parent type. Also added beds (Convair880).
		if(istype(target, /obj/machinery/optable/))
			do_table_hide(target)
		if(istype(target, /obj/stool/bed/))
			do_table_hide(target)
		return target.Attackhand(mob)

	proc
		do_table_hide(obj/target)
			step(mob, get_dir(mob, target))
			if (mob.loc == target.loc)
				if (table_hide)
					table_hide = 0
					mob.layer = MOB_LAYER
					mob.visible_message("[mob] crawls on top of [target]!")
				else
					table_hide = 1
					mob.layer = target.layer - 0.01
					mob.visible_message("[mob] hides under [target]!")

/datum/mutantrace/monkey/seamonkey
	name = "sea monkey"
	icon = 'icons/mob/monkey.dmi'
	mutant_folder = 'icons/mob/seamonkey.dmi'
	icon_state = "seamonkey"
	special_head = HEAD_SEAMONKEY
	special_head_state = "head"
	aquatic = 1
	race_mutation = /datum/bioEffect/mutantrace/seamonkey
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/seamonkey/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/seamonkey/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/seamonkey/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/seamonkey/left
	mutant_organs = list("tail" = /obj/item/organ/tail/monkey/seamonkey)

/datum/mutantrace/martian
	name = "martian"
	icon_state = "martian"
	human_compatible = 0
	uses_human_clothes = 0
	override_language = "martian"



/datum/mutantrace/stupidbaby
	name = "stupid alien baby"
	icon_state = "stupidbaby"
	human_compatible = 0
	uses_human_clothes = 0
	jerk = 1

	New()
		..()
		if(ishuman(mob))
			mob.real_name = pick("a", "ay", "ey", "eh", "e") + pick("li", "lee", "lhi", "ley", "ll") + pick("n", "m", "nn", "en")
			if(prob(50))
				mob.real_name = uppertext(mob.real_name)
			mob.bioHolder.AddEffect("clumsy")
			mob.take_brain_damage(80)
			mob.stuttering = 120
			mob.contract_disease(/datum/ailment/disability/clumsy,null,null,1)

/datum/mutantrace/premature_clone
	name = "premature clone"
	icon = 'icons/mob/human.dmi'
	mutant_folder = 'icons/mob/human.dmi'
	icon_state = "mutant3"
	human_compatible = 1
	uses_human_clothes = 1
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_SKINTONE | HAS_HUMAN_HAIR | HAS_HUMAN_EYES | HAS_NO_HEAD | USES_STATIC_ICON)
	dna_mutagen_banned = FALSE


	New()
		..()
		if(ishuman(mob))
			if (isitem(mob.l_hand))
				var/obj/item/toDrop = mob.l_hand
				mob.u_equip(toDrop)
				if (toDrop)
					toDrop.layer = initial(toDrop.layer)
					toDrop.set_loc(mob.loc)

			if (mob.limbs && mob.limbs.l_arm)
				mob.limbs.l_arm.delete()

	say_verb()
		return "gurgles"

	onDeath(gibbed)
		if(gibbed)
			return
		SPAWN_DBG(2 SECONDS)
			if (ishuman(mob))
				mob.visible_message("<span class='alert'><B>[mob]</B> starts convulsing violently!</span>", "You feel as if your body is tearing itself apart!")
				mob.changeStatus("weakened", 15 SECONDS)
				mob.make_jittery(1000)
				sleep(rand(40, 120))
				mob.gib()

// some new simple gimmick junk

/datum/mutantrace/gross
	name = "mutilated"
	icon_state = "gross"
	override_attack = 0


	say_verb()
		return "shrieks"

/datum/mutantrace/faceless
	name = "humanoid"
	icon_state = "faceless"
	override_attack = 0


	say_verb()
		return "murmurs"

/datum/mutantrace/cyclops
	name = "cyclops"
	icon_state = "cyclops"
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_HUMAN_HAIR | HAS_NO_EYES | HAS_NO_HEAD | WEARS_UNDERPANTS | USES_STATIC_ICON)


/datum/mutantrace/roach
	name = "roach"
	icon = 'icons/mob/roach.dmi'
	icon_state = "body_m"
	override_attack = 0
	voice_override = "roach"
	race_mutation = /datum/bioEffect/mutantrace/roach
	mutant_organs = list("tail" = /obj/item/organ/tail/roach)
	mutant_folder = 'icons/mob/roach.dmi'
	special_head = HEAD_ROACH
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/roach/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/roach/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/roach/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/roach/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_EYES | BUILT_FROM_PIECES | FIX_COLORS | HAS_SPECIAL_HAIR | TORSO_HAS_SKINTONE | WEARS_UNDERPANTS)
	eye_state = "eyes_roach"
	typevulns = list("blunt" = 1.5, "crush" = 1.5)
	dna_mutagen_banned = FALSE

	New(mob/living/carbon/human/M)
		. = ..()
		if(ishuman(M))
			M.mob_flags |= SHOULD_HAVE_A_TAIL
		APPLY_MOB_PROPERTY(M, PROP_RADPROT, src, 100)

	say_verb()
		return "clicks"

	sight_modifier()
		mob.see_in_dark = SEE_DARK_HUMAN + 1
		mob.see_invisible = 1

	disposing()
		if(ishuman(mob))
			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
		if(mob)
			REMOVE_MOB_PROPERTY(mob, PROP_RADPROT, src)
		. = ..()

/datum/mutantrace/cat // god imagine gatekeeping this shit
	name = "cat"
	icon = 'icons/mob/cat.dmi'
	icon_state = "body_m"
	// jerk = 1 // why the fuck was this 1
	override_attack = 0
	voice_override = "cat"
	firevuln = 1.5 // very flammable catthings
	race_mutation = /datum/bioEffect/mutantrace/cat
	mutant_organs = list("tail" = /obj/item/organ/tail/cat)
	mutant_folder = 'icons/mob/cat.dmi'
	special_head = HEAD_CAT
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/cat/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/cat/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/cat/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/cat/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_EYES | HAS_SPECIAL_HAIR | BUILT_FROM_PIECES | FIX_COLORS | TORSO_HAS_SKINTONE | SKINTONE_USES_PREF_COLOR_1 | HAS_EXTRA_DETAILS | WEARS_UNDERPANTS)
	dna_mutagen_banned = FALSE

	special_hair_1_icon = 'icons/mob/cat.dmi'
	special_hair_1_state = "head_detail" //eyes and pink parts
	special_hair_1_color = null
	/*special_hair_2_icon = 'icons/mob/cat.dmi'
	special_hair_2_state = "head_detail_banditmask"
	special_hair_2_color = CUST_1 //bottom: base color
	special_hair_3_icon = 'icons/mob/cat.dmi'
	special_hair_3_state = "head_detail_noseears"
	special_hair_3_color = CUST_3*/ //top
	detail_1_icon = 'icons/mob/cat.dmi'
	detail_1_state = "chest_detail_altcolor" //counter-shading
	detail_1_color = CUST_2 //middle

	New(mob/living/carbon/human/M)
		. = ..()
		if(ishuman(M))
			M.mob_flags |= SHOULD_HAVE_A_TAIL

	say_verb()
		return "meows"

	sight_modifier()
		mob.see_in_dark = SEE_DARK_HUMAN + 1
		mob.see_invisible = 1

	disposing()
		if(ishuman(mob))
			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
		. = ..()


/datum/mutantrace/amphibian
	name = "amphibian"
	icon = 'icons/mob/amphibian.dmi'
	icon_state = "body_m"
	firevuln = 1.3
	brutevuln = 0.7
	human_compatible = 0
	uses_human_clothes = 1
	aquatic = 1
	voice_name = "amphibian"
	jerk = 0
	head_offset = 0
	hand_offset = -3
	body_offset = -3
	movement_modifier = /datum/movement_modifier/amphibian
	var/original_blood_color = null
	mutant_folder = 'icons/mob/amphibian.dmi'
	special_head = HEAD_FROG
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/amphibian/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/amphibian/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/amphibian/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/amphibian/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_NO_EYES | BUILT_FROM_PIECES | HEAD_HAS_OWN_COLORS)


	say_verb()
		return "croaks"

	proc/replacement_r(r, blank, next_letter)
		if(isUpper(r) && !isUpper(next_letter))
			return capitalize(stutter("rrr") + next_letter)
		if(isUpper(r) && isUpper(next_letter))
			return stutter("RRR") + next_letter
		if(!isUpper(r))
			return stutter("rr") + next_letter
		else
			return stutter("rr") + next_letter


	say_filter(var/message)
		var/static/regex/r_catch = regex(@"(r)(.?)","gi")
		return r_catch.Replace(message, /datum/mutantrace/amphibian/proc/replacement_r)


	New(var/mob/living/carbon/human/M)
		..()
		emote_overrides = amphibian_emotes
		if(ishuman(mob))
			original_blood_color = mob.blood_color
			mob.blood_color = "#22EE99"
			M.bioHolder.AddEffect("mattereater")
			M.bioHolder.AddEffect("jumpy")
			M.bioHolder.AddEffect("vowelitis")
			M.bioHolder.AddEffect("accent_brummie")


	disposing()
		if(ishuman(mob))
			if(!isnull(original_blood_color))
				mob.blood_color = original_blood_color
				mob.bioHolder.RemoveEffect("mattereater")
				mob.bioHolder.RemoveEffect("jumpy")
				mob.bioHolder.RemoveEffect("vowelitis")
				mob.bioHolder.RemoveEffect("accent_brummie")
		original_blood_color = null
		..()

/*
/datum/mutantrace/kudzu
	name = "kudzu"
	icon = 'icons/mob/kudzu.dmi'
	icon_state = "kudzu-w"
	human_compatible = 0
	uses_human_clothes = 0
	var/original_name
	jerk = 1 //Not really, but NT doesn't really like treehuggers
	aquatic = 1
	needs_oxy = 0 //get their nutrients from the kudzu
	understood_languages = list("english", "kudzu")
	movement_modifier = /datum/movement_modifier/kudzu
	mutant_folder = 'icons/mob/human.dmi' // vOv
	mutant_organs = list(\
		"left_eye"=/obj/item/organ/eye/synth,\
		"right_eye"=/obj/item/organ/eye/synth,\
		"heart"=/obj/item/organ/heart/synth,\
		"appendix"=/obj/item/organ/appendix/synth,\
		"intestines"=/obj/item/organ/intestines/synth,\
		"left_kidney"=/obj/item/organ/kidney/synth/left,\
		"right_kidney"=/obj/item/organ/kidney/synth/right,\
		"liver"=/obj/item/organ/liver/synth,\
		"left_lung"=/obj/item/organ/lung/synth/left,\
		"right_lung"=/obj/item/organ/lung/synth/right,\
		"pancreas"=/obj/item/organ/pancreas/synth,\
		"spleen"=/obj/item/organ/spleen/synth,\
		"stomach"=/obj/item/organ/stomach/synth,\
		"butt"=/obj/item/clothing/head/butt/synth) //dont be mean to the kudzupeople
	special_hair_1_icon = 'icons/mob/kudzu.dmi'
	special_hair_1_state = "kudzu_hair"
	special_hair_1_color = null
	detail_1_icon = 'icons/mob/kudzu.dmi'
	detail_1_state = "kudzu_torso"
	detail_1_color = null
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/kudzu/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/kudzu/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/kudzu/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/kudzu/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_SKINTONE | TORSO_HAS_SKINTONE | HAS_HUMAN_HAIR | HAS_HUMAN_EYES | HAS_SPECIAL_HAIR | HAS_EXTRA_DETAILS | BUILT_FROM_PIECES)
	override_attack = 1

	custom_attack(atom/target)
		if(ishuman(target))
			mob.visible_message("<span class='alert'><B>[mob]</B> waves its limbs at [target] threateningly!</span>")
		else
			return target.Attackhand(mob)

	say_verb()
		return "rasps"

	New(var/mob/living/carbon/human/H)
		..(H)
		SPAWN_DBG(0)	//ugh
			if(ishuman(mob))
				H.setStatus("maxhealth-", null, -50)
				H.add_stam_mod_max("kudzu", -100)
				APPLY_MOB_PROPERTY(H, PROP_STAMINA_REGEN_BONUS, "kudzu", -5)
				H.bioHolder.AddEffect("xray", magical=1)
				H.abilityHolder = new /datum/abilityHolder/kudzu(H)
				H.abilityHolder.owner = H
				H.abilityHolder.addAbility(/datum/targetable/kudzu/guide)
				H.abilityHolder.addAbility(/datum/targetable/kudzu/growth)
				H.abilityHolder.addAbility(/datum/targetable/kudzu/seed)
				H.abilityHolder.addAbility(/datum/targetable/kudzu/heal_other)
				H.abilityHolder.addAbility(/datum/targetable/kudzu/stealth)
				H.abilityHolder.addAbility(/datum/targetable/kudzu/kudzusay)
				H.abilityHolder.addAbility(/datum/targetable/kudzu/vine_appendage)


	disposing()
		if(ishuman(mob))
			var/mob/living/carbon/human/H = mob
			if(H.abilityHolder)
				H.abilityHolder.removeAbility(/datum/targetable/kudzu/guide)
				H.abilityHolder.removeAbility(/datum/targetable/kudzu/growth)
				H.abilityHolder.removeAbility(/datum/targetable/kudzu/seed)
				H.abilityHolder.removeAbility(/datum/targetable/kudzu/heal_other)
				H.abilityHolder.removeAbility(/datum/targetable/kudzu/stealth)
				H.abilityHolder.removeAbility(/datum/targetable/kudzu/kudzusay)
				H.abilityHolder.removeAbility(/datum/targetable/kudzu/vine_appendage)
			H.remove_stam_mod_max("kudzu")
			REMOVE_MOB_PROPERTY(H, PROP_STAMINA_REGEN_BONUS, "kudzu")
		return ..()
/* Commented out as this bypasses restricted Z checks. We will just lazily give them xray genes instead
	// vision modifier (see_mobs, etc i guess)
	sight_modifier()
		mob.sight |= SEE_TURFS
		mob.sight |= SEE_MOBS
		mob.sight |= SEE_OBJS
		mob.see_in_dark = SEE_DARK_FULL
*/
	//Should figure out what I'm doing with this and the onLife in the abilityHolder one day. I'm thinking, maybe move it all to the abilityholder, but idk, composites are weird.
	onLife(var/mult = 1)
		if (!mob.abilityHolder)
			mob.abilityHolder = new /datum/abilityHolder/kudzu(mob)

		var/datum/abilityHolder/kudzu/KAH = mob.abilityHolder
		var/round_mult = max(1, floor((mult)))
		var/turf/T = get_turf(mob)
		//if on kudzu, get nutrients for later use. If at max nutrients. Then heal self.
		if (T && T.temp_flags & HAS_KUDZU)
			if (KAH.points < KAH.MAX_POINTS)
				KAH.points += round_mult
			else
				//at max points, so heal
				mob.take_toxin_damage(-round_mult)
				mob.HealDamage("All", round_mult, round_mult)
				if (prob(7) && mob.find_ailment_by_type(/datum/ailment/malady/flatline))
					mob.cure_disease_by_path(/datum/ailment/malady/heartfailure)
					mob.cure_disease_by_path(/datum/ailment/malady/flatline)

		else
			//nutrients for a bit of grace period
			if (KAH.points > 0)
				KAH.points -= 10
			else
				//do effects from not being on kudzu here.
				mob.take_toxin_damage(2 * round_mult)
				mob.changeStatus("slowed", 3 SECONDS)
				// random_brute_damage(mob, 2 * mult)
				if (prob(30))
					mob.changeStatus("weakened", 3 SECONDS)

		return
*/
/datum/mutantrace/cow
	name = "cow"
	icon = 'icons/mob/cow.dmi'
	icon_state = "body_m"
	human_compatible = TRUE
	uses_human_clothes = FALSE
	override_attack = 0
	voice_override = "cow"
	step_override = "footstep"
	race_mutation = /datum/bioEffect/mutantrace/cow
	mutant_organs = list("tail" = /obj/item/organ/tail/cow,
	"left_eye" = /obj/item/organ/eye/cow,
	"right_eye" = /obj/item/organ/eye/cow)
	mutant_folder = 'icons/mob/cow.dmi'
	special_head = HEAD_COW
	special_hair_1_icon = 'icons/mob/cow.dmi'
	special_hair_1_state = "head-detail1"
	special_hair_1_color = CUST_1
	special_hair_2_icon = 'icons/mob/cow.dmi'
	special_hair_2_state = "cow_over_suit"
	special_hair_2_color = null
	special_hair_2_layer = MOB_OVERMASK_LAYER
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/cow/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/cow/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/cow/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/cow/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_NO_SKINTONE | HAS_HUMAN_EYES | BUILT_FROM_PIECES | HAS_EXTRA_DETAILS | HAS_OVERSUIT_DETAILS | HAS_SPECIAL_HAIR | HEAD_HAS_OWN_COLORS | WEARS_UNDERPANTS)
	color_channel_names = list("Horn Detail", "Hoof Detail")
	eye_state = "eyes-cow"
	dna_mutagen_banned = FALSE

	New(var/mob/living/carbon/human/H)
		..()
		emote_overrides = cow_emotes
		if(ishuman(mob))
			mob.update_face()
			mob.update_body()
			mob.update_clothing()
			mob.mob_flags |= SHOULD_HAVE_A_TAIL
			mob.kickMessage = "stomps"
			mob.traitHolder?.addTrait("hemophilia")

			H.blood_id = "milk"
			all_blood_reagents |= "milk"
			H.blood_color = "FFFFFF"


	disposing()
		if (ishuman(mob))
			var/mob/living/carbon/human/H = mob
			H.blood_id = initial(H.blood_id)
			H.blood_color = initial(H.blood_color)
			if (H.mob_flags & SHOULD_HAVE_A_TAIL)
				H.mob_flags &= ~SHOULD_HAVE_A_TAIL
			H.kickMessage = initial(H.kickMessage)
			H.traitHolder?.removeTrait("hemophilia")
		. = ..()

	proc/replacement_m(m, blank, next_letter)
		if(isUpper(m) && !isUpper(next_letter))
			return capitalize(stutter("mm") + next_letter)
		if(isUpper(m) && isUpper(next_letter))
			return stutter("MM") + next_letter
		if(!isUpper(m))
			return stutter("mm") + next_letter
		else
			return stutter("mm") + next_letter

	proc/replacement_human(human, blank, plural)
		var/first = copytext(human,1,2)
		var/second = copytext(human,2,3)
		if(isUpper(first) && isUpper(second))
			return "HUMAN" + capitalize(plural)
		if(isUpper(first) && !isUpper(second))
			return "Human" + plural
		else
			return "human" + plural

	say_filter(var/message)
		var/static/regex/m_catch = regex(@"(m)(.?)","gi")
		var/static/regex/human_catch = regex(@"(cow)(s?)","gi")
		message = human_catch.Replace(message, /datum/mutantrace/cow/proc/replacement_human)
		return m_catch.Replace(message, /datum/mutantrace/cow/proc/replacement_m)

	proc/release_milk() //copy pasted some piss code, im sorry
		var/obj/item/storage/toilet/toilet = locate() in mob.loc
		var/obj/item/reagent_containers/glass/beaker = locate() in mob.loc

		var/can_output = 0
		if (ishuman(mob))
			var/mob/living/carbon/human/H = mob
			if (H.blood_volume > 0)
				can_output = 1

		if (!can_output)
			.= "<B>[mob]</B> strains, but fails to output milk!"
		else if (toilet && (mob.buckled != null))
			for (var/obj/item/storage/toilet/T in mob.loc)
				.= "<B>[mob]</B> dispenses milk into the toilet. What a waste."
				T.clogged += 0.10
				break
		else if (beaker)
			.= pick("<B>[mob]</B> takes aim and dispenses some milk into the beaker.", "<B>[mob]</B> takes aim and dispenses milk into the beaker!", "<B>[mob]</B> fills the beaker with milk!")
			transfer_blood(mob, beaker, 10)
		else
			var/obj/item/reagent_containers/milk_target = mob.equipped()
			if(istype(milk_target) && milk_target.reagents && milk_target.reagents.total_volume < milk_target.reagents.maximum_volume && milk_target.is_open_container())
				.= ("<span class='alert'><B>[mob] dispenses milk into [milk_target].</B></span>")
				playsound(mob, "sound/misc/pourdrink.ogg", 50, 1)
				transfer_blood(mob, milk_target, 10)
				return

			// possibly change the text colour to the gray emote text
			.= (pick("<B>[mob]</B> milk fall out.", "<B>[mob]</B> makes a milk puddle on the floor."))

			var/turf/T = get_turf(mob)
			bleed(mob, 10, T)
			T.react_all_cleanables()


/datum/mutantrace/chicken
	name = "Chicken"
	icon_state = "chicken_m"
	human_compatible = 1
	jerk = 0
	race_mutation = /datum/bioEffect/mutantrace/chicken
	mutant_folder = 'icons/mob/chicken.dmi'
	special_head = HEAD_CHICKEN
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/chicken/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/chicken/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_PARTIAL_SKINTONE | HAS_NO_EYES | BUILT_FROM_PIECES | HEAD_HAS_OWN_COLORS | TORSO_HAS_SKINTONE | WEARS_UNDERPANTS)

	New()
		..()
		emote_overrides = chicken_emotes

/datum/mutantrace/birb
	name = "Birb"
	icon = 'icons/mob/birb.dmi'
	icon_state = "body_m"
	override_attack = 0
	voice_override = "bird"
	race_mutation = /datum/bioEffect/mutantrace/birb
	mutant_organs = list("tail" = /obj/item/organ/tail/feathers)
	mutant_folder = 'icons/mob/birb.dmi'
	special_head = HEAD_BIRD
	special_head_state = "head"
	eye_state = "eyes_bird"
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/bird/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/bird/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/bird/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/bird/left
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_EYES | HAS_SPECIAL_HAIR | BUILT_FROM_PIECES | FIX_COLORS | TORSO_HAS_SKINTONE | SKINTONE_USES_PREF_COLOR_1 | HAS_EXTRA_DETAILS | WEARS_UNDERPANTS)
	dna_mutagen_banned = FALSE

	special_hair_2_icon = 'icons/mob/birb.dmi'
	special_hair_2_state = "head_detail"
	special_hair_2_color = CUST_2

	special_hair_3_icon = 'icons/mob/birb.dmi'
	special_hair_3_state = "head_detail_beak"
	special_hair_3_color = SKIN_TONE

	detail_1_icon = 'icons/mob/birb.dmi'
	detail_1_state = "chest_detail_fluff"
	detail_1_color = CUST_2

	New(mob/living/carbon/human/M)
		. = ..()
		if(ishuman(M))
			M.mob_flags |= SHOULD_HAVE_A_TAIL

	say_verb()
		return "coos" //I used pidgeon noises sorry
		//return "squawks"

	sight_modifier()
		mob.see_in_dark = SEE_DARK_HUMAN + 1
		mob.see_invisible = 1

	disposing()
		if(ishuman(mob))
			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
		. = ..()




/datum/mutantrace/fert
	name = "ferret"
	icon = 'icons/mob/fert.dmi'
	icon_state = "body_m"
	override_attack = 0
	mutant_appearance_flags = (NOT_DIMORPHIC | HAS_HUMAN_EYES | BUILT_FROM_PIECES | HAS_EXTRA_DETAILS | FIX_COLORS | SKINTONE_USES_PREF_COLOR_1 | HAS_SPECIAL_HAIR | TORSO_HAS_SKINTONE | WEARS_UNDERPANTS)
	voice_override = "fert"
	special_head = HEAD_FERT
	special_head_state = "head"
	mutant_organs = list("tail" = /obj/item/organ/tail/fert)
	mutant_folder = 'icons/mob/fert.dmi'
	special_hair_1_icon = 'icons/mob/fert.dmi'
	special_hair_1_state = "head_detail_altcolor"
	special_hair_1_color = CUST_2 //middle
	special_hair_2_icon = 'icons/mob/fert.dmi'
	special_hair_2_state = "head_detail_banditmask"
	special_hair_2_color = CUST_1 //bottom: base color
	special_hair_3_icon = 'icons/mob/fert.dmi'
	special_hair_3_state = "head_detail_noseears"
	special_hair_3_color = CUST_3 //top
	detail_1_icon = 'icons/mob/fert.dmi'
	detail_1_state = "chest_detail_altcolor" //counter-shading
	detail_1_color = CUST_2 //middle
	r_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/fert/right
	l_limb_arm_type_mutantrace = /obj/item/parts/human_parts/arm/mutant/fert/left
	r_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/fert/right
	l_limb_leg_type_mutantrace = /obj/item/parts/human_parts/leg/mutant/fert/left
	race_mutation = /datum/bioEffect/mutantrace/fert
	clothing_icon_override = 'icons/mob/fert_clothes.dmi'
	color_channel_names = list("Base Coat", "Alternate Color", "Nose and Ears")
	dna_mutagen_banned = FALSE

	//thanks for the sprites and hard work, Cet!!

	New(var/mob/living/carbon/human/H)
		..()
		emote_overrides = fert_emotes
		if(ishuman(H))
			H.bioHolder.AddEffect("stinky")
			//H.bioHolder.AddEffect("clumsy") //better handled with a cooldown power: lets a ferretperson move and act faster for a limited time...
			//but they're extra clumsy while it's active and they're weakened for a few seconds and a little slow for the duration of the cooldown?
			H.mob_flags |= SHOULD_HAVE_A_TAIL

			H.update_face()
			H.update_body()
			H.update_clothing()

	disposing()
		if(ishuman(mob))
			//var/mob/living/carbon/human/L = mob
			//L.bioHolder.RemoveEffect("stinky") //that stink doesn't wash off so easily
			mob.mob_flags &= ~SHOULD_HAVE_A_TAIL
			mob.base_body_temp = initial(mob.base_body_temp)
		. = ..()

	say_verb()
		return "dooks"

#undef OVERRIDE_ARM_L
#undef OVERRIDE_ARM_R
#undef OVERRIDE_LEG_R
#undef OVERRIDE_LEG_L
