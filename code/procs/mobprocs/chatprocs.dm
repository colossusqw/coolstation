/mob/proc/say()
	return

/mob/proc/whisper(message, forced=FALSE)
	return

/mob/verb/whisper_verb(message as text)
	set name = "Whisper"
	cancel_typing("whisperwindow")
	return src.whisper(message)


/mob/verb/say_verb(message as text)
	set name = "Say"

	if (!message)
		return
	if (client && url_regex?.Find(message) && !client.holder)
		boutput(src, "<span class='notice'><b>Web/BYOND links are not allowed in ingame chat.</b></span>")
		boutput(src, "<span class='alert'>&emsp;<b>\"[message]</b>\"</span>")
		return

	say(message)
	#ifdef SECRETS_ENABLED
	check_say(message, src)
	#endif
	if (!dd_hasprefix(message, "*")) // if this is an emote it is logged in emote
		logTheThing("say", src, null, "SAY: [html_encode(message)] [log_loc(src)]")
		//logit("say", 0, src, " said ", message)

/mob/verb/say_radio()
	set name = "say_radio"
	set hidden = 1

/mob/verb/say_main_radio(msg as text)
	set name = "say_main_radio"
	set hidden = 1

/mob/say_main_radio(msg as text)
	set name = "say_main_radio"
	set desc = "Speaking on the main radio frequency"
	set hidden = 1
	cancel_typing("radiochannelsay")
	var/client/client = src.client
	if(isAI(src) && !src.client)
	//AI eye is sending the message
		client = usr.client
	if (client.preferences.auto_capitalization)
		var/i = 1
		while (copytext(msg, i, i+1) == " ")
			i++
		msg = capitalize(copytext(msg, i))
	src.say_verb(";" + msg)

/mob/proc/setup_radio_box()
	if(isnull(src.client) || !src.ears || !istype(src.ears, /obj/item/device/radio))
		return

	var/prefix = winget(client, "radiochannelsaywindow.input", "command")
	var/obj/item/device/radio/headset = src.ears
	var/list/s_freqs = headset.secure_frequencies
	var/regex/R = new(@":([^\s]*)", "g")
	R.Find(prefix)

	//Box has been set up with a channel we have
	if(R.match in s_freqs || R.match == ":" || R.match == ";")
		return

	//No secure channels
	if(!(istype(s_freqs) && length(s_freqs)))
		var/color = default_frequency_color(R_FREQ_DEFAULT)
		var/title = "[format_frequency(R_FREQ_DEFAULT)] - "\
		+ (headset_channel_lookup["[R_FREQ_DEFAULT]"])
		open_radio_input(";", title, color, open_window=FALSE)
		return

	//Last case- the window isn't setup with a secure channel, but we have them
	var/first_freq = s_freqs[s_freqs[1]]
	var/color = default_frequency_color(first_freq)
	var/title = "[format_frequency(first_freq)] - "\
	+ (headset_channel_lookup["[first_freq]"] ? headset_channel_lookup["[first_freq]"] : "(Unknown)")
	open_radio_input("[":" + s_freqs[1] ]", title, color, open_window=FALSE)

/mob/proc/open_radio_input(token as text, title as text, color, open_window=TRUE)
	//Some of the radio channels are way too bright
	var/list/colorOverrides = list(
		RADIOC_SECURITY = "#ac2e2e",
		RADIOC_RESEARCH = "#9e6fdd",
		RADIOC_STANDARD = "#aaaa55",
		RADIOC_CIVILIAN = "#8d2d7a",
		RADIOC_OTHER = "#aaaa55"

	)
	if(color in colorOverrides)
		color = colorOverrides[color]

	if(!color)
		color ="#aaaa55"
	var/client/client = src.client
	if(isAI(src) && !src.client)
		client = usr.client
	winset(client, "radiochannelsaywindow", "background-color=\"[color]\"")
	winset(client, "radiochannelsaywindow", "title=\"Speaking on [title]\"")
	winset(client, "radiochannelsaywindow.input", "command=\"say_radio_channel \\\"[token] \"")
	winset(client, "radiochannelsaywindow.accept", "command=\".winset \\\"command=\\\"say_radio_channel \\\\\\\"[token]\[\[radiochannelsaywindow.input.text as escaped\]\]\\\";radiochannelsaywindow.is-visible=false\\\";radiochannelsaywindow.input.text=\\\"\\\"\"")
	if(open_window) winset(client, "radiochannelsaywindow", "is-visible=true")
	if(open_window) winset(client, "radiochannelsaywindow.input", "focus=true")

	SPAWN_DBG(3 SECONDS)
		//The channel selector sends us the Return+UP when we press enter so we have to turn this off
		//But let's turn it back on after a moment so we won't usually be affected by latency just to close the window
		winset(client, "radiochannelsaywindow_macro_returnup", "is-disabled=false" )

/mob/verb/say_radio_channel(msg as text)
	set name = "say_radio_channel"
	set hidden = 1

/mob/say_radio_channel(msg as text)
	set name = "say_radio_channel"
	set desc = "Speaking on radio channel"
	set hidden = 1
	var/client/client = src.client
	//AI eye is sending the message
	if(isAI(src) && !src.client)
		client = usr.client
	winset(client, "radiochannelsaywindow", "is-visible=false")
	//Don't usr why I need this here
	cancel_typing("radiochannelsay")
	if (client.preferences.auto_capitalization)
		var/i = 1
		while (copytext(msg, i, i+1) == " ")
			i++
		msg = capitalize(copytext(msg, i))
	src.say_verb(msg)

/mob/living/say_radio()
	set name = "say_radio"
	set hidden = 1

	if (isAI(src))
		var/mob/living/silicon/ai/A = src
		var/list/choices = list()
		var/list/channels = list()
		var/list/frequencies = list()
		var/list/radios = list(A.radio1, A.radio2, A.radio3)

		for (var/i = 1, i <= radios.len, i++)
			var/obj/item/device/radio/R = radios[i]
			var/channel_name

			if (!istype(R, /obj/item/device/radio/headset/command/ai))
				// Skip the AI headset (radio 3) because it reads the first char as a channel.
				// Honestly this should probably be fixed in some other way, but, effort.
				channel_name = "[format_frequency(R.frequency)] - " + (headset_channel_lookup["[R.frequency]"] ? headset_channel_lookup["[R.frequency]"] : "(Unknown)")
				choices += channel_name
				frequencies[channel_name] = R.frequency
				channels[channel_name] = ":[i]"

			if (istype(R.secure_frequencies) && length(R.secure_frequencies))
				for (var/sayToken in R.secure_frequencies)
					channel_name = "[format_frequency(R.secure_frequencies[sayToken])] - " + (headset_channel_lookup["[R.secure_frequencies[sayToken]]"] ? headset_channel_lookup["[R.secure_frequencies[sayToken]]"] : "(Unknown)")
					choices += channel_name
					frequencies[channel_name] = R.secure_frequencies[sayToken]
					channels[channel_name] = ":[i][sayToken]"

		if (A.robot_talk_understand)
			var/channel_name = "* - Robot Talk"
			channels[channel_name] = ":s"
			choices += channel_name

		var/choice = 0
		if (choices.len == 1)
			choice = choices[1]
		else
			choice = input("", "Select Radio and Channel", null) as null|anything in choices
		if (!choice)
			return

		var/token = channels[choice]
		if (!token)
			boutput(src, "Somehow '[choice]' didn't match anything. Welp. Probably busted.")

		var/choice_index = choices.Find(choice)
		var/color = default_frequency_color(frequencies[frequencies[choice_index]])
		open_radio_input(token, choice, color)


	else if (src.ears && istype(src.ears, /obj/item/device/radio))
		var/obj/item/device/radio/R = src.ears
		var/token = ""
		var/list/choices = list()
		choices += "[ headset_channel_lookup["[R.frequency]"] ? headset_channel_lookup["[R.frequency]"] : "???" ]: \[[format_frequency(R.frequency)]]"

		if (istype(R.secure_frequencies) && length(R.secure_frequencies))
			for (var/sayToken in R.secure_frequencies)
				choices += "[ headset_channel_lookup["[R.secure_frequencies["[sayToken]"]]"] ? headset_channel_lookup["[R.secure_frequencies["[sayToken]"]]"] : "???" ]: \[[format_frequency(R.secure_frequencies["[sayToken]"])]]"

		if (src.robot_talk_understand)
			choices += "Robot Talk: \[***]"


		var/choice = 0
		if (choices.len == 1)
			choice = choices[1]
		else
			choice = input("", "Select Radio Channel", null) as null|anything in choices
		if (!choice)
			return

		var/color = "#aaaa55"
		var/choice_index = choices.Find(choice)
		if (choice_index == 1)
			token = ";"
		else if (choice == "Robot Talk: \[***]")
			token = ":s"
		else
			token = ":" + R.secure_frequencies[choice_index - 1]
			color = default_frequency_color(R.secure_frequencies[R.secure_frequencies[choice_index - 1]])

		open_radio_input(token, choice, color)

	else
		boutput(src, "<span class='notice'>You must put a headset on your ear slot to speak on the radio.</span>")

// ghosts now can emote now too so vOv
/*	if (isliving(src))
		if (copytext(message, 1, 2) != "*") // if this is an emote it is logged in emote
			logTheThing("say", src, null, "SAY: [message]")
	else logTheThing("say", src, null, "SAY: [message]")
*/
/mob/verb/me_verb(message as text)
	set name = "Me"

	if (src.client && !src.client.holder && url_regex?.Find(message))
		boutput(src, "<span class='notice'><b>Web/BYOND links are not allowed in ingame chat.</b></span>")
		boutput(src, "<span class='alert'>&emsp;<b>\"[message]</b>\"</span>")
		return

	src.emote(message, 1)

/mob/verb/me_verb_hotkey(message as text)
	set name = "me_hotkey"
	set hidden = 1

	if (src.client && !src.client.holder && url_regex?.Find(message)) //we still do this check just in case they access the hidden emote
		boutput(src, "<span class='notice'><b>Web/BYOND links are not allowed in ingame chat.</b></span>")
		boutput(src, "<span class='alert'>&emsp;<b>\"[message]</b>\"</span>")
		return

	src.emote(message,2)

/* ghost emotes wooo also the logging is already taken care of in the emote() procs vOv
	if (isliving(src) && isalive(src))
		src.emote(message, 1)
		logTheThing("say", src, null, "EMOTE: [message]")
	else
		boutput(src, "<span class='notice'>You can't emote when you're dead! How would that even work!?</span>")
*/
/mob/proc/try_render_chat_to_admin(client/C, message)
	if (C.holder && C.deadchat && !C.player_mode)
		if (src.mind)
			message = "<span class='adminHearing' data-ctx='[C.chatOutput.getContextFlags()]'>[message]</span>"
		boutput(C, message)
		return 1

/mob/proc/say_dead(var/message, wraith = 0)
	var/name = src.real_name
	var/alt_name = ""

	if (!deadchat_allowed)
		boutput(usr, "<b>Deadchat is currently disabled.</b>")
		return

	message = trim(copytext(html_encode(sanitize(message)), 1, MAX_MESSAGE_LEN))
	if (!message)
		return

	if (ishuman(src) && src.name != src.real_name)
		if (src:wear_id && src:wear_id:registered && src:wear_id:registered != src.real_name)
			alt_name = " (as [src:wear_id:registered])"
		else if (!src:wear_id)
			alt_name = " (as Unknown)"

	else if (isobserver(src))
		name = "Ghost"
		alt_name = " ([src.real_name])"
	else if (ispoltergeist(src))
		name = "Poltergeist"
		alt_name = " ([src.real_name])"
	else if (iswraith(src))
		name = "Wraith"
		alt_name = " ([src.real_name])"

	else if (!ishuman(src))
		name = src.name

	if(src?.client?.preferences.auto_capitalization)
		message = capitalize(message)

#ifdef DATALOGGER
	game_stats.ScanText(message)
#endif

	message = src.say_quote(message)
	//logTheThing("say", src, null, "SAY: [message]")

	var/rendered = "<span class='game deadsay'><span class='prefix'>DEAD:</span> <span class='name' data-ctx='\ref[src.mind]'>[name]<span class='text-normal'>[alt_name]</span></span> <span class='message'>[message]</span></span>"
	//logit( "chat", 0, "([name])", src, message )
	for (var/client/C)
		if (C.deadchatoff) continue
		if (!C.mob) continue
		var/mob/M = C.mob
		if (istype(M, /mob/new_player)) continue

		if(try_render_chat_to_admin(C, rendered))
			continue

		if (istype(M,/mob/dead/target_observer/hivemind_observer)) continue
		if (istype(M,/mob/dead/target_observer/mentor_mouse_observer)) continue

		if (isdead(M) || iswraith(M) || isghostdrone(M) || isVRghost(M) || inafterlifebar(M) || istype(M, /mob/living/seanceghost))
			boutput(M, rendered)

//changeling hivemind say
/mob/proc/say_hive(var/message, var/datum/abilityHolder/changeling/hivemind_owner)
	var/name = src.real_name
	var/alt_name = ""

	if (!hivemind_owner)
		return

	//i guess this caused some real ugly text huh
	//message = trim(copytext(html_encode(sanitize(message)), 1, MAX_MESSAGE_LEN))
	if (!message)
		return

	if (istype(src, /mob/living/critter/changeling/handspider))
		name = src.real_name
		alt_name = " (HANDSPIDER)"
	else if (istype(src, /mob/living/critter/changeling/eyespider))
		name = src.real_name
		alt_name = " (EYESPIDER)"
	else if (istype(src, /mob/living/critter/changeling/legworm))
		name = src.real_name
		alt_name = " (LEGWORM)"
	else if(!hivemind_owner.master)
		//Standard behaviour
		if (src == hivemind_owner.owner)
			name = src.name
			alt_name = " (MASTER)"
	else
		//Someone else is controlling stuff
		if (src == hivemind_owner.owner)
			name = hivemind_owner.original_controller_real_name
			alt_name = " (CONTROLLER)"
		else if (src == hivemind_owner.master)
			name = src.name
			alt_name = " (MASTER)"

#ifdef DATALOGGER
	game_stats.ScanText(message)
#endif

	message = src.say_quote(message)
	//logTheThing("say", src, null, "SAY: [message]")

	var/rendered = "<span class='hivesay'><span class='prefix'>HIVEMIND:</span> <span class='name' data-ctx='\ref[src.mind]'>[name]<span class='text-normal'>[alt_name]</span></span> <span class='message'>[message]</span></span>"

	//show to hivemind
	for (var/client/C in clients)
		try_render_chat_to_admin(C, rendered)
	for (var/mob/M in (hivemind_owner.hivemind + hivemind_owner.owner))
		if (M.client?.holder && M.client.deadchat && !M.client.player_mode) continue
		if (isdead(M) || istype(M,/mob/living/critter/changeling) || (M == hivemind_owner.owner))
			boutput(M, rendered)

//vampire thrall say
/mob/proc/say_thrall(var/message, var/datum/abilityHolder/vampire/owner)
	var/name = src.real_name
	var/alt_name = ""

	if (!owner)
		return

	if (!message)
		return

	if (isvampire(src))
		name = src.real_name
		alt_name = " (DRACULA)"
	else if (isvampiricthrall(src))
		name = src.real_name
		alt_name = " (THRALL)"

#ifdef DATALOGGER
	game_stats.ScanText(message)
#endif

	message = src.say_quote(message)
	//logTheThing("say", src, null, "SAY: [message]")

	var/rendered = "<span class='thrallsay'><span class='prefix'>GHOULSPEAK:</span> <span class='name' data-ctx='\ref[src.mind]'>[name]<span class='text-normal'>[alt_name]</span></span> <span class='message'>[message]</span></span>"

	//show to ghouls
	for (var/client/C in clients)
		try_render_chat_to_admin(C, rendered)
	for (var/mob/M in (owner.thralls + owner.owner))
		if ((M.client?.holder && M.client.deadchat && !M.client.player_mode)) continue
		boutput(M, rendered)
/*
//kudzu hivemind say
/mob/proc/say_kudzu(var/message, var/datum/abilityHolder/kudzu/owner)
	var/name = src.real_name
	var/alt_name = ""

	if (!owner)
		return

	if (!message)
		return

#ifdef DATALOGGER
	game_stats.ScanText(message)
#endif
	logTheThing("diary", src, null, "(KUDZU): [message]", "hivesay")

	message = src.say_quote(message)
	//logTheThing("say", src, null, "SAY: [message]")

	var/rendered = "<span class='game kudzusay'><span class='prefix'><small>KUDZUSPEAK:</small></span> <span class='name' data-ctx='\ref[src.mind]'>[name]<span class='text-normal'>[alt_name]</span></span> <span class='message'>[message]</span></span>"


	//show message to admins (Follow rules of their deadchat toggle)
	for (var/client/C)
		if (!C.mob) continue
		if (try_render_chat_to_admin(C, rendered)) continue
		if (istype(C.mob.abilityHolder, /datum/abilityHolder/kudzu))
			boutput(C, rendered)
		//////////////////////////////////
*/
/mob/proc/say_understands(var/mob/other, var/forced_language)
	if (isdead(src))
		return 1
//	else if (istype(other, src.type) || istype(src, other.type))
//		return 1
	var/L = other.say_language
	if (forced_language)
		L = forced_language
	if (understands_language(L))
		return 1
	return 0
	/*if (isrobot(other) || isAI(other) || (ismonkey(other) && src.bioHolder.HasEffect("monkey_speak")))
		return 1
	else
		. = 0
		. += ismonkey(src) ? 1 : 0
		. += ismonkey(other) ? 1 : 0
		if (. == 1)
			return monkeysspeakhuman
		else
			return 1
	return 0*/

/mob/proc/say_quote(var/text, var/special = 0)
	var/ending = copytext(text, length(text))
	var/speechverb = speechverb_say
	var/loudness = 0
	var/font_accent = null
	var/style = ""
	var/first_quote = " \""
	var/second_quote = "\""

	if (ending == "?")
		speechverb = speechverb_ask
	else if (ending == "!")
		speechverb = speechverb_exclaim
	if (src.stuttering)
		speechverb = speechverb_stammer
	for (var/datum/ailment_data/A in src.ailments)
		if (istype(A.master, /datum/ailment/disease/berserker))
			if (A.stage > 1)
				speechverb = "roars"
	if ((src.reagents && src.reagents.get_reagent_amount("ethanol") > 30))
		speechverb = "slurs"
	if (src.bioHolder)
		if (src.bioHolder.HasEffect("loud_voice"))
			speechverb = "bellows"
			loudness += 1
		if (src.bioHolder.HasEffect("quiet_voice"))
			speechverb = "murmurs"
			loudness -= 1
		if (src.bioHolder.HasEffect("unintelligable"))
			speechverb = "splutters"
		if (src.bioHolder.HasEffect("accent_comic"))
			font_accent = "Comic Sans MS"

		if (src.bioHolder && src.bioHolder.genetic_stability < 50)
			speechverb = "gurgles"

	if (src.get_brain_damage() >= 60)
		speechverb = pick("says","stutters","mumbles","slurs")

	if (src.speech_void)
		text = voidSpeak(text)

	if (src.singing || (src.bioHolder && src.bioHolder.HasEffect("accent_elvis")))
		// use note icons instead of normal quotes
		var/note_type = src.singing & BAD_SINGING ? "notebad" : "note"
		var/note_img = "<img class=\"icon misc\" style=\"position: relative; bottom: -3px; \" src=\"[resource("images/radio_icons/[note_type].png")]\">"
		if (src.singing & LOUD_SINGING)
			first_quote = "[note_img][note_img]"
			second_quote = first_quote
		else
			first_quote = note_img
			second_quote = note_img
		// select singing adverb
		var/adverb = ""
		if (src.singing & BAD_SINGING)
			adverb = pick("dissonantly", "flatly", "unmelodically", "tunelessly")
		else if (src.traitHolder?.hasTrait("nervous"))
			adverb = pick("nervously", "tremblingly", "falteringly")
		else if (src.singing & LOUD_SINGING && !src.traitHolder?.hasTrait("smoker"))
			adverb = pick("loudly", "deafeningly", "noisily")
		else if (src.singing & SOFT_SINGING)
			adverb = pick("softly", "gently")
		else if (src.mind?.assigned_role == "Musician")
			adverb = pick("beautifully", "tunefully", "sweetly")
		else if (src.bioHolder?.HasEffect("accent_scots"))
			adverb = pick("sorrowfully", "sadly", "tearfully")
		// select singing verb
		if (src.traitHolder?.hasTrait("smoker"))
			speechverb = "rasps"
			if ((singing & LOUD_SINGING))
				speechverb = "sings Tom Waits style"
		else if (src.traitHolder?.hasTrait("french") && rand(2) < 1)
			speechverb = "sings [pick("Charles Trenet", "Serge Gainsborough", "Edith Piaf")] style"
		else if (src.bioHolder?.HasEffect("accent_swedish"))
			speechverb = "sings disco style"
		else if (src.bioHolder?.HasEffect("accent_scots"))
			speechverb = pick("laments", "sings", "croons", "intones", "sobs", "bemoans")
		else if (src.bioHolder?.HasEffect("accent_brummie"))
			speechverb = "raps"
		else if (src.singing & SOFT_SINGING)
			speechverb = pick("hums", "lullabies")
		else
			speechverb = pick("sings", pick("croons", "intones", "warbles"))
		if (adverb != "")
		// combine adverb and verb
			speechverb = "[adverb] [speechverb]"
		// add style for singing
		text = "<i>[text]</i>"
		style = "color:thistle;"

	if (special)
		if (special == "gasp_whisper")
			speechverb = speechverb_gasp
			loudness -= 1

	// hi cirr here i feel this should be relative for weak mobs
	var/health_percentage = (src.health/(max(1, src.max_health))) * 100 // prevent div/0 errors from stopping people talking
	// better to inaccurately not gasp than be silenced by runtimes
	if (health_percentage <= 20)
		speechverb = speechverb_gasp
	if (isdead(src) || isobserver(src))
		speechverb = pick("moans","wails","laments")
		if (prob(5))
			speechverb = "grumps"

	if (text == "" || !text)
		return speechverb

	if(style)
		style = " style=\"[style]\""
	if (loudness > 0)
		return "[speechverb],[first_quote][font_accent ? "<font face='[font_accent]'>" : null]<big><strong><b [style? style : ""]>[text]</b></strong></big>[font_accent ? "</font>" : null][second_quote]"
	else if (loudness < 0)
		return "[speechverb],[first_quote][font_accent ? "<font face='[font_accent]'>" : null]<small [style? style : ""]>[text]</small>[font_accent ? "</font>" : null][second_quote]"
	else
		return "[speechverb],[first_quote][font_accent ? "<font face='[font_accent]'>" : null]<span [style? style : ""]>[text]</span>[font_accent ? "</font>" : null][second_quote]"

/*
This is a little messy, but
act: a string that gets indexed into a big list of emotes, like "scream" and "flip". That indexing will happen on the child, so it's not used here
voluntary:
emoteTarget: a thing that only humans have so far, but it's an atom that the emote gets acted upon ("src hugs emoteTarget!")
actual_emote: the datum that this base code acts on. A child of /mob should supply this in an override.
param: Uhhh I think this is related to targeted emotes? I'm not sure
*/
/mob/proc/emote(var/act, var/voluntary = 0, var/emoteTarget = null, datum/emote/actual_emote, param = null)
	var/list/what_have_we_done = null

	var/m_type = MESSAGE_VISIBLE
	var/custom = 0 //Sorry, gotta make this for chat groupings.
	var/maptext_out = 0
	var/message = null

	if (istype(actual_emote))
		if (!emote_check(voluntary, actual_emote.return_cooldown(src, voluntary), 1, !(actual_emote.possible_while_dead)))
			return
		what_have_we_done= actual_emote.enact(src, voluntary, param)
	if (islist(what_have_we_done))
		message = what_have_we_done[1]
		maptext_out = what_have_we_done[2]
		m_type = what_have_we_done[3] //visible or audible emote
		if (length(what_have_we_done) > 3) //(I'm not changing the returns on ~130 emotes that don't even fucking use it)
			custom = what_have_we_done[4] //emote grouping 4 custom emotes
	else
		src.show_text("Unusable emote '[act]'. 'Me help' for a list.", "blue")
		return

	if (!message)
		return

	var/image/chat_maptext/chat_text = null
	if (maptext_out && !ON_COOLDOWN(src, "emote maptext", 0.5 SECONDS))
		//make maptext if appropriate
		if (speechpopups && src.chat_text)
			chat_text = make_chat_maptext(src, maptext_out, "color: #C2BEBE;" + src.speechpopupstyle, alpha = 140)
			if(chat_text)
				chat_text.measure(src.client)
				for(var/image/chat_maptext/I in src.chat_text.lines)
					if(I != chat_text)
						I.bump_up(chat_text.measured_height)

	logTheThing("say", src, null, "EMOTE: [message]")
	act = lowertext(act)
	if (m_type & MESSAGE_VISIBLE)
		for (var/mob/O in viewers(src, null))
			O.show_message("<span class='emote'>[message]</span>", m_type, group = "[src]_[act]_[custom]", assoc_maptext = chat_text)
	else if (m_type & MESSAGE_AUDIBLE)
		for (var/mob/O in hearers(src, null))
			O.show_message("<span class='emote'>[message]</span>", m_type, group = "[src]_[act]_[custom]", assoc_maptext = chat_text)
	else if (!isturf(src.loc))
		var/atom/A = src.loc
		for (var/mob/O in A.contents)
			O.show_message("<span class='emote'>[message]</span>", m_type, group = "[src]_[act]_[custom]", assoc_maptext = chat_text)

/mob/proc/emote_check(var/voluntary = 1, var/time = 10, var/admin_bypass = 1, var/dead_check = 1)
	if (src.emote_allowed)
		if (dead_check && isdead(src))
			src.emote_allowed = 0
			return 0
		if (world.time >= (src.last_emote_time + src.last_emote_wait))
			if (!no_emote_cooldowns && !(src.client && (src.client.holder && admin_bypass) && !src.client.player_mode) && voluntary)
				src.emote_allowed = 0
				src.last_emote_time = world.time
				src.last_emote_wait = time
				SPAWN_DBG(time)
					src.emote_allowed = 1
			return 1
		else
			return 0
	else
		return 0

/mob/proc/listen_ooc()
	set name = "(Un)Mute OOC"
	set desc = "Mute or Unmute Out Of Character chat."

	if (src.client)
		src.client.preferences.listen_ooc = !src.client.preferences.listen_ooc
		if (src.client.preferences.listen_ooc)
			boutput(src, "<span class='notice'>You are now listening to messages on the OOC channel.</span>")
		else
			boutput(src, "<span class='notice'>You are no longer listening to messages on the OOC channel.</span>")

/mob/verb/ooc(msg as text)
	set name = "OOC"
	if (IsGuestKey(src.key))
		boutput(src, "You are not authorized to communicate over these channels.")
		return
	if (oocban_isbanned(src))
		boutput(src, "You are currently banned from using OOC and LOOC, you may appeal at https://forum.coolstation.space/index.php")
		return

	msg = trim(copytext(html_encode(msg), 1, MAX_MESSAGE_LEN))
	if (!msg)
		return
	else if (!src.client.preferences.listen_ooc)
		return
	else if (!ooc_allowed && !src.client.holder)
		boutput(usr, "OOC is currently disabled. For gameplay questions, try <a href='byond://winset?command=mentorhelp'>mentorhelp</a>.")
		return
	else if (!dooc_allowed && !src.client.holder && (src.client.deadchat != 0))
		boutput(usr, "OOC for dead mobs has been turned off.")
		return
	else if (src.client && src.client.ismuted())
		boutput(usr, "You are currently muted and cannot talk in OOC.")
		return
	else if (findtext(msg, "byond://") && !src.client.holder)
		boutput(src, "<B>Advertising other servers is not allowed.</B>")
		logTheThing("admin", src, null, "has attempted to advertise in OOC.")
		logTheThing("diary", src, null, "has attempted to advertise in OOC.", "admin")
		message_admins("[key_name(src)] has attempted to advertise in OOC.")
		return

	logTheThing("diary", src, null, ": [msg]", "ooc")

#ifdef DATALOGGER
	game_stats.ScanText(msg)
#endif

	for (var/client/C in clients)
		// DEBUGGING
		if (!C.preferences)
			logTheThing("debug", null, null, "[C] (\ref[C]): client.preferences is null")

		if (C.preferences && !C.preferences.listen_ooc)
			continue

		var ooc_class = ""
		var display_name = src.key

		if (src.client.stealth || src.client.alt_key)
			if (!C.holder)
				display_name = src.client.fakekey
			else
				display_name += " (as [src.client.fakekey])"

		if (src.client.holder && (!src.client.stealth || C.holder))
			if (src.client.holder.level == LEVEL_BABBY)
				ooc_class = "gfartooc"
			else
				ooc_class = "adminooc"
		else if (src.client.is_mentor() && !src.client.stealth)
			ooc_class = "mentorooc"

		var/rendered = "<span class=\"ooc [ooc_class]\"><span class=\"prefix\">OOC:</span> <span class=\"name\" data-ctx='\ref[src.mind]'>[display_name]:</span> <span class=\"message\">[msg]</span></span>"

		if (C.holder)
			rendered = "<span class='adminHearing' data-ctx='[C.chatOutput.getContextFlags()]'>[rendered]</span>"

		boutput(C, rendered)

	logTheThing("ooc", src, null, "OOC: [msg]")

/mob/proc/listen_looc()
	set name = "(Un)Mute LOOC"
	set desc = "Mute or Unmute Local Out Of Character chat."

	if (src.client)
		src.client.preferences.listen_looc = !src.client.preferences.listen_looc
		if (src.client.preferences.listen_looc)
			boutput(src, "<span class='notice'>You are now listening to messages on the LOOC channel.</span>")
		else
			boutput(src, "<span class='notice'>You are no longer listening to messages on the LOOC channel.</span>")

/mob/verb/looc(msg as text)
	set name = "LOOC"
	if (IsGuestKey(src.key))
		boutput(src, "You are not authorized to communicate over these channels.")
		return
	if (oocban_isbanned(src))
		boutput(src, "You are currently banned from using OOC and LOOC, you may appeal at https://forum.coolstation.space/index.php")
		return

	msg = trim(copytext(html_encode(sanitize(msg)), 1, MAX_MESSAGE_LEN))
	if (!msg)
		return
	else if (!src.client.preferences.listen_looc)
		return
	else if (!looc_allowed && !src.client.holder)
		boutput(usr, "LOOC is currently disabled.")
		return
	else if (!dooc_allowed && !src.client.holder && (src.client.deadchat != 0))
		boutput(usr, "LOOC for dead mobs has been turned off.")
		return
	else if (src.client && src.client.ismuted())
		boutput(usr, "You are currently muted and cannot talk in LOOC.")
		return
	else if (findtext(msg, "byond://") && !src.client.holder)
		boutput(src, "<B>Advertising other servers is not allowed.</B>")
		logTheThing("admin", src, null, "has attempted to advertise in LOOC.")
		logTheThing("diary", src, null, "has attempted to advertise in LOOC.", "admin")
		message_admins("[key_name(src)] has attempted to advertise in LOOC.")
		return

	logTheThing("diary", src, null, ": [msg]", "ooc")

#ifdef DATALOGGER
	game_stats.ScanText(msg)
#endif

	var/list/recipients = list()

	for (var/mob/M in range(LOOC_RANGE))
		if (!M.client)
			continue
		if (M.client.preferences && !M.client.preferences.listen_looc)
			continue
		recipients += M.client

	for (var/client/C)
		if (!C.mob) continue
		var/mob/M = C.mob

		if (M.client in recipients)
			continue
		if (M.client.holder && !M.client.only_local_looc && !M.client.player_mode)
			recipients += M.client

	for (var/client/C in recipients)
		// DEBUGGING
		if (!C.preferences)
			logTheThing("debug", null, null, "[C] (\ref[C]): client.preferences is null")

		if (C.preferences && !C.preferences.listen_ooc)
			continue

		var looc_class = ""
		var display_name = src.key

		if (src.client.stealth || src.client.alt_key)
			if (!C.holder)
				display_name = src.client.fakekey
			else
				display_name += " (as [src.client.fakekey])"

		if (src.client.holder && (!src.client.stealth || C.holder))
			if (src.client.holder.level == LEVEL_BABBY)
				looc_class = "gfartlooc"
			else
				looc_class = "adminlooc"
		else if (src.client.is_mentor() && !src.client.stealth)
			looc_class = "mentorlooc"

		var/rendered = "<span class=\"looc [looc_class]\"><span class=\"prefix\">LOOC:</span> <span class=\"name\" data-ctx='\ref[src.mind]'>[display_name]:</span> <span class=\"message\">[msg]</span></span>"

		if (C.holder)
			rendered = "<span class='adminHearing' data-ctx='[C.chatOutput.getContextFlags()]'>[rendered]</span>"

		boutput(C, rendered)

	logTheThing("ooc", src, null, "LOOC: [msg]")

/mob/proc/heard_say(var/mob/other)
	return

/mob/proc/lastgasp(allow_dead=FALSE)
	set waitfor = FALSE
	return

/mob/proc/item_attack_message(var/mob/T, var/obj/item/S, var/d_zone, var/devastating = 0, var/armor_blocked = 0)
	if (d_zone)
		if(armor_blocked)
			return "<span class='alert'><B>[src] attacks [T] in the [d_zone] with [S], but [T]'s armor blocks it!</B></span>"
		else
			T.lastgasp()
			return "<span class='alert'><B>[src] attacks [T] in the [d_zone] with [S][devastating ? " and lands a devastating hit!" : "!"]</B></span>"
	else
		if(armor_blocked)
			return "<span class='alert'><B>[src] attacks [T] with [S], but [T]'s armor blocks it!</B></span>"
		else
			T.lastgasp()
			return "<span class='alert'><B>[src] attacks [T] with [S] [devastating ? "and lands a devastating hit!" : "!"]</B></span>"

/mob/proc/get_age_pitch_for_talk()
	if (!src.bioHolder || !src.bioHolder.age) return
	var/modifier = 30
	if (src.reagents && src.reagents.has_reagent("helium"))
		modifier += 30
	if (deep_farting)
		modifier -= 120
	if (modifier == 0)
		modifier = 1
	return 1.0 + (0.5*(modifier - src.bioHolder.age)/80) + ((src.gender == MALE) ? 0.1 : 0.3)

/mob/proc/get_age_pitch()
	if (!src.bioHolder || !src.bioHolder.age) return
	var/modifier = 30
	if (src.reagents && src.reagents.has_reagent("helium"))
		modifier += 30
	if (deep_farting)
		modifier -= 120
	if (modifier == 0)
		modifier = 1
#ifdef APRIL_FOOLS
	return -(1.0 + 0.5*(modifier - src.bioHolder.age)/80 + rand(-15,15)/100) // backwards ::)
#else
	if (random_emotesounds == 0)
		return 1.0 + 0.5*(modifier - src.bioHolder.age)/80
	return 1.0 + 0.5*(modifier - src.bioHolder.age)/80 + rand(-15,15)/100

#endif
/mob/proc/understands_language(var/langname)
	if (langname == say_language)
		return 1
	if (langname == "english" || !langname)
		return 1
	if (langname == "monkey" && (monkeysspeakhuman || (bioHolder?.HasEffect("monkey_speak"))))
		return 1
	return 0

/mob/proc/get_language_id(var/forced_language = null)
	var/language = say_language
	if (forced_language)
		language = forced_language
	return language

/mob/proc/process_language(var/message, var/forced_language = null)
	// Separate the radio prefix (if it exists) and message so the language can't destroy the prefix
	var/prefixAndMessage = separate_radio_prefix_and_message(message)
	var/prefix = prefixAndMessage[1]
	message = prefixAndMessage[2]

	var/datum/language/L = languages.language_cache[get_language_id(forced_language)]
	if (!L)
		L = languages.language_cache["english"]

	return prefix + L.get_messages(message)

/mob/proc/get_special_language(var/secure_mode)
	return null

/mob/proc/see(message)
	if (!isalive(src))
		return 0
	boutput(src, message)
	return 1

/mob/proc/show_viewers(message)
	for(var/mob/M in AIviewers())
		M.see(message)

/mob/verb/toggle_auto_capitalization()
	set desc = "Toggles auto capitalization of chat messages"
	set name = "Toggle Auto Capitalization"

	if (!usr.client)
		return

	usr.client.preferences.auto_capitalization = !usr.client.preferences.auto_capitalization
	boutput(usr, "<span class='notice'>[usr.client.preferences.auto_capitalization ? "Now": "No Longer"] auto capitalizing messages.</span>")

/mob/dead/verb/togglelocaldeadchat()
	set desc = "Toggle whether you can hear all chat while dead or just local chat"
	set name = "Toggle Deadchat Range"
	set category = "Ghost"

	if (!usr.client) //How could this even happen?
		return

	usr.client.preferences.local_deadchat = !usr.client.preferences.local_deadchat
	boutput(usr, "<span class='notice'>[usr.client.preferences.local_deadchat ? "Now" : "No longer"] hearing local chat only.</span>")

/mob/dead/verb/toggle_ghost_radio()
	set desc = "Toggle whether you can hear radio chatter while dead"
	set name = "Toggle Ghost Radio"
	set category = "Ghost"

	if (!usr.client) //How could this even happen?
		return

	usr.client.mute_ghost_radio = !usr.client.mute_ghost_radio
	boutput(usr, "<span class='notice'>[usr.client.mute_ghost_radio ? "No longer" : "Now"] hearing radio as a ghost.</span>")

/mob/verb/toggleflyingchat()
	set desc = "Toggle seeing what people say over their heads"
	set name = "Toggle Flying Chat"

	if (!usr.client) //How could this even happen?
		return

	usr.client.preferences.flying_chat_hidden = !usr.client.preferences.flying_chat_hidden
	boutput(usr, "<span class='notice'>[usr.client.preferences.flying_chat_hidden ? "No longer": "Now"] seeing flying chat.</span>")

/mob/proc/show_message(msg, type, alt, alt_type, group = "", var/just_maptext, var/image/chat_maptext/assoc_maptext = null)
	if (!src.client)
		return

	// We have procs to check for this stuff, you know. Ripped out a bunch of duplicate code, which also fixed earmuffs (Convair880).
	var/check_failed = FALSE
	if (type)
		if ((type & 1) && !src.sight_check(1))
			check_failed = TRUE
			if (!alt)
				return
			else
				msg = alt
				type = alt_type
		if ((type & 2) && !src.hearing_check(1))
			check_failed = TRUE
			if (!alt)
				return
			else
				msg = alt
				type = alt_type
			if ((type & 1) && !src.sight_check(1))
				return

	if (!just_maptext && (isunconscious(src) || src.sleeping || src.getStatusDuration("paralysis")))
		if (prob(20))
			boutput(src, "<I>... You can almost hear something ...</I>")
			if (isliving(src))
				for (var/mob/dead/target_observer/observer in src:observers)
					boutput(observer, "<I>... You can almost hear something ...</I>")
	else
		if(!just_maptext)
			boutput(src, msg, group)

		var/psychic_link = src.get_psychic_link()
		if (ismob(psychic_link))
			boutput(psychic_link, msg, group)

		if(!check_failed)
			if(assoc_maptext && src.client && !src.client.preferences?.flying_chat_hidden)
				assoc_maptext.show_to(src.client)

			if (isliving(src))
				for (var/mob/dead/target_observer/observer in src:observers)
					if(!just_maptext)
						boutput(observer, msg, group)
					if(assoc_maptext && observer.client && !observer.client.preferences.flying_chat_hidden)
						assoc_maptext.show_to(observer.client)

// Show a message to all mobs in sight of this one
// This would be for visible actions by the src mob
// message is the message output to anyone who can see e.g. "[src] does something!"
// self_message (optional) is what the src mob sees  e.g. "You do something!"
// blind_message (optional) is what blind people will hear e.g. "You hear something!"

/mob/visible_message(var/message, var/self_message, var/blind_message, var/group = "")
	for (var/mob/M in AIviewers(src))
		if (!M.client)
			continue
		var/msg = message
		if (self_message && M == src)
			M.show_message(self_message, 1, self_message, 2, group)
		else
			M.show_message(msg, 1, blind_message, 2, group)

// Show a message to all mobs in sight of this atom
// Use for objects performing visible actions
// message is output to anyone who can see, e.g. "The [src] does something!"
// blind_message (optional) is what blind people will hear e.g. "You hear something!"
/atom/proc/visible_message(var/message, var/blind_message, var/group = "")
	for (var/mob/M in AIviewers(src))
		if (!M.client)
			continue
		M.show_message(message, 1, blind_message, 2, group)

// for things where there are three parties that should recieve different messages (specifically made for surgery):
// viewer_message, the thing visible to everyone except specified targets
// first_message, the thing visible to first_target
// second_message, the thing visible to second_target
// blind_message (optional) is what blind people will hear e.g. "You hear something!"
/mob/proc/tri_message(var/viewer_message, var/first_target, var/first_message, var/second_target, var/second_message, var/blind_message)
	for (var/mob/M in AIviewers(src))
		if (!M.client)
			continue
		var/msg = viewer_message
		if (first_message && M == first_target)
			msg = first_message
		if (second_message && M == second_target && M != first_target)
			msg = second_message
		M.show_message(msg, 1, blind_message, 2)
		//DEBUG_MESSAGE("<b>[M] recieves message: &quot;[msg]&quot;</b>")

// it was about time we had this instead of just visible_message()
/atom/proc/audible_message(var/message, var/alt, var/alt_type, var/group = "", var/just_maptext, var/image/chat_maptext/assoc_maptext = null)
	for (var/mob/M in all_hearers(null, src))
		if (!M.client)
			continue
		M.show_message(message, 2, alt, alt_type, group, just_maptext, assoc_maptext)

/mob/audible_message(var/message, var/self_message, var/alt, var/alt_type, var/group = "", var/just_maptext, var/image/chat_maptext/assoc_maptext = null)
	for (var/mob/M in all_hearers(null, src))
		if (!M.client)
			continue
		var/msg = message
		if (self_message && M==src)
			msg = self_message
		M.show_message(msg, 2, alt, alt_type, group, just_maptext, assoc_maptext)


// FLOCKSAY
//#define FLOCK_SPEAKER_SYSTEM 1
//#define FLOCK_SPEAKER_ADMIN 2
//#define FLOCK_SPEAKER_FLOCKMIND 3
//#define FLOCK_SPEAKER_FLOCKTRACE 4
//#define FLOCK_SPEAKER_NPC 5

/proc/flock_speak(var/mob/speaker, var/message as text, var/datum/flock/flock, var/speak_as_admin=0)

	var/client/C = null
	if(speaker)
		C = speaker.client

	var/name = ""
	var/is_npc = 0
	var/is_flockmind = istype(speaker, /mob/living/intangible/flock/flockmind)
	if(!speak_as_admin)
		if(speaker)
			message = speaker.say_quote(message)
		else // system message
			message = gradientText("#3cb5a3", "#124e43", "\"[message]\"")
			message = "alerts, [message]"
		if(istype(speaker, /mob/living/critter/flock/drone))
			var/mob/living/critter/flock/drone/F = speaker
			if(F.is_npc)
				name = "Drone [F.real_name]"
				is_npc = 1
			else if(F.controller)
				name = "[F.controller.real_name]"
				if(istype(F.controller, /mob/living/intangible/flock/flockmind))
					is_flockmind = 1
		else if(speaker) // not set yet
			name = speaker.real_name // final catch

	var/rendered = ""
	var/flockmindRendered = ""
	var/siliconrendered = ""
	var/class = "flocksay"
	if(is_flockmind)
		class = "flocksay flockmindsay"
	if(is_npc)
		class = "flocksay flocknpc"
	if(isnull(speaker))
		class = "flocksay bold italics"
		name = "\[SYSTEM\]"

	if(C?.holder && speak_as_admin) // for admin verb flocksay
		// admin mode go
		var/show_other_key = 0
		if (C.stealth || C.alt_key)
			show_other_key = 1
		rendered = "<span class='game [class]'><span class='bold'></span><span class='name'>ADMIN([show_other_key ? C.fakekey : C.key])</span> informs, <span class='message'>\"[message]\"</span></span>"
		flockmindRendered = rendered // no need for URLs
	else
		rendered = "<span class='game [class]'><span class='bold'>\[[flock ? flock.name : "--.--"]\] </span><span class='name' [speaker ? "data-ctx='\ref[speaker.mind]'" : ""]>[name]</span> <span class='message'>[message]</span></span>"
		flockmindRendered = "<span class='game [class]'><span class='bold'>\[[flock ? flock.name : "--.--"]\] </span><span class='name'>[flock ? "<a href='byond://?src=\ref[flock.flockmind];origin=\ref[speaker]'>[name]</a>" : "[name]"]</span> <span class='message'>[message]</span></span>"
		siliconrendered = "<span class='game [class]'><span class='bold'>\[[flock ? flockBasedGarbleText(flock.name, -30, flock) : "--.--"]\] </span><span class='name' [speaker ? "data-ctx='\ref[speaker.mind]'" : ""]>[flockBasedGarbleText(name, -20, flock)]</span> <span class='message'>[flockBasedGarbleText(message, 0, flock)]</span></span>"

	for (var/client/CC)
		if (!CC.mob) continue
		if(istype(CC.mob, /mob/new_player))
			continue
		var/mob/M = CC.mob

		var/thisR = ""

		if((isflock(M)) || (M.client.holder && !M.client.player_mode) || (isobserver(M) && !(istype(M, /mob/dead/target_observer/hivemind_observer))))
			thisR = rendered
		if(flock?.snooping && M.client && M.robot_talk_understand)
			thisR = siliconrendered
		if(istype(M, /mob/living/intangible/flock/flockmind) && !(istype(speaker, /mob/living/intangible/flock/flockmind)) && M:flock == flock)
			thisR = flockmindRendered
		if ((istype(M, /mob/dead/observer)||M.client.holder) && speaker?.mind)
			thisR = "<span class='adminHearing' data-ctx='[M.client.chatOutput.getContextFlags()]'>[thisR]</span>"
		if(thisR != "")
			M.show_message(thisR, 2)
