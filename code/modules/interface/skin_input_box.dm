/client/proc/create_input_window(id, title, accept_verb, cancel_verb, force=FALSE, show=TRUE, background_color=null)
	if(winexists(src, id))
		if(force)
			//Delete all clientside objects that are part of the window
			winset(src, "[id]_macro_returnup", "parent=none")
			winset(src, "[id]_macro_return", "parent=none")
			winset(src, "[id]_macro_escape", "parent=none")
			winset(src, "persist_[id]_macro", "parent=none")
			winset(src, id, "parent=none")
		else
			return
	// Create a macro set for handling enter presses
	winclone(src, "input_box_macro", "persist_[id]_macro")
	winset(src, "[id]_macro_returnup", "parent=persist_[id]_macro;name=Return+UP;command=\".winset \\\"[id].is-visible=false\\\"\"")
	// Return+UP allows us to close the window after typing in a command, pressing enter and releasing enter.
	// Can't use just Return for this, because when there's text in the box Return is handled by BYOND and doesn't run the macro.
	// Create the actual window and set its title and macro set
	winclone(src, "input_box", id)
	winset(src, id, "title=\"[title]\";macro=persist_[id]_macro")
	if(accept_verb)
		winset(src, "[id].input", "command=\"[accept_verb] \\\"\"")
		winset(src, "[id].accept", "command=\".winset \\\"command=\\\"[accept_verb] \\\\\\\"\[\[[id].input.text as escaped\]\]\\\";[id].is-visible=false\\\";[id].input.text=\\\"\\\"\"") //Invokes the accept verb using the inputted text, and hides the window.
	if(cancel_verb)
		//All of these close the window and invoke the cancel verb, as well as clear the input box of all text. The second arg is the method of which the window was closed.
		winset(src, "[id].cancel", "command=\".winset \\\"command=\\\"[cancel_verb]\\\";[id].is-visible=false\\\";[id].input.text=\\\"\\\"\"")
		winset(src, "[id]_macro_return", "parent=persist_[id]_macro;name=Return;command=\".winset \\\"command=\\\"[cancel_verb]\\\";[id].is-visible=false\\\";[id].input.text=\\\"\\\"\"")
		winset(src, "[id]_macro_escape", "parent=persist_[id]_macro;name=Escape;command=\".winset \\\"command=\\\"[cancel_verb]\\\";[id].is-visible=false\\\";[id].input.text=\\\"\\\"\"")
		winset(src, id, "on-close=\"[cancel_verb]\"") //Invokes the cancel verb if you close the window
	else
		//Hides the window and does nothing else.
		winset(src, "[id].cancel", "command=\".winset \\\"[id].is-visible=false\\\";[id].input.text=\\\"\\\"\"")
		winset(src, "[id]_macro_return", "parent=persist_[id]_macro;name=Return;command=\".winset \\\"[id].is-visible=false\\\"\"")
		winset(src, "[id]_macro_escape", "parent=persist_[id]_macro;name=Escape;command=\".winset \\\"[id].is-visible=false\\\";[id].input.text=\\\"\\\"\"")
	if(background_color)
		winset(src, "[id]", "background-color=\"[background_color]\"")
	//Window scaling!
	//BYOND doesn't scale the window by DPI scaling, so it'll appear too big/too small with DPI scaling other than the one it was based on
	//This code uses the title bar to figure out what DPI scaling is being used and resize the window based on that
	//Figure out the DPI scaling based on the titlebar size of the window, based on outer-inner height
	var/window_data = params2list(winget(src, id, "outer-size;inner-size"))
	var/window_innersize = splittext(window_data["inner-size"], "x")
	var/window_outersize = splittext(window_data["outer-size"], "x")
	var/titlebarHeight = text2num(window_outersize[2])-text2num(window_innersize[2])

	// 514 numbers
	//Known titlebar heights for DPI scaling:
	//win7:  100%-28, 125%-33, 150%-39
	//win10: 100%-29, 125%-35, 150%-40
	//win11: 100%-29, 125%-35, 150%-40

	//Known window sizes for DPI scaling: (Win7)
	//100%: 302x86,  font 7
	//125%: 402x106, font 8
	//150%: 503x133, font 8

	// 515 numbers
	//Known titlebar heights for DPI scaling:
	//win11: 100%-39, 125%-47, 150%-56

	var/scaling = FALSE
	//Those are the default values for the window
	var/window_width  = 202
	var/window_height = 56
	var/font_size = 8
	//The values used here were sampled from BYOND in practice, I couldn't find a formula that would describe them
	if (byond_version < 515)
		switch(titlebarHeight)
			if(30 to 37)
				scaling = 1.25
				window_width  = 402
				window_height = 106
				font_size = 8
			if(37 to 42)
				scaling = 1.5
				window_width  = 503
				window_height = 133
				font_size = 8
	else
		switch(titlebarHeight)
			if(40 to 50)
				scaling = 1.25
				window_width  = 402
				window_height = 106
				font_size = 8
			if(50 to INFINITY)
				scaling = 1.5
				window_width  = 503
				window_height = 133
				font_size = 8
	if(scaling)
		winset(src, null, "[id].size=[window_width]x[window_height];[id].input.font-size=[font_size];[id].accept.font-size=[font_size];[id].cancel.font-size=[font_size]")
	//End window scaling
	//Center the window on the main window
	//The window size is hardcoded to be 410x133, taken from skin.dmf
	var/mainwindow_data = params2list(winget(src, "mainwindow", "pos;outer-size;size;inner-size;is-maximized"))
	var/mainwindow_pos = splittext(mainwindow_data["pos"], ",")
	var/mainwindow_size = splittext(mainwindow_data["size"], "x")
	var/mainwindow_innersize = splittext(mainwindow_data["inner-size"], "x")
	var/mainwindow_outersize = splittext(mainwindow_data["outer-size"], "x")
	var/maximized = (mainwindow_data["is-maximized"] == "true")
	if(!maximized)
		//If the window is anchored (for example win+right), is-maximized is false but pos is no longer reliable
		//In that case, compare inner-size and size to guess if it's actually anchored
		maximized = text2num(mainwindow_size[1]) != text2num(mainwindow_innersize[1])\
			|| abs(text2num(mainwindow_size[2]) - text2num(mainwindow_innersize[2])) > 30
	var/target_x
	var/target_y
	// If the window is maximized or anchored, pos is the last position when the window was free-floating
	if(maximized)
		target_x = text2num(mainwindow_outersize[1])/2-window_width/2
		target_y = text2num(mainwindow_outersize[2])/2-window_height/2
	else
		target_x = text2num(mainwindow_pos[1])+text2num(mainwindow_outersize[1])/2-window_width/2
		target_y = text2num(mainwindow_pos[2])+text2num(mainwindow_outersize[2])/2-window_height/2
	winset(src, id, "pos=[target_x],[target_y]")
	//End centering
	if(show)
		//Show the window and focus on the textbox
		winshow(src, id, TRUE)
		winset(src, "[id].input", "focus=true")

///Presets for standard windows
var/list/input_window_presets =  list(
	"say" = list("saywindow", "say \\\"text\\\"", ".say", ".cancel_typing say", "#dfd6d6"),
	"radiosay" = list("radiosaywindow", "main channel radio", "say_main_radio", ".cancel_typing say"),
	"whisper" = list("whisperwindow", "whisper (text)", "whisper", ".cancel_typing whisper", "#dfd6d6"),
	"me"  = list("mewindow",  "me (text)",        ".me",  ".cancel_typing me"),
	"radiochannelsay" = list("radiochannelsaywindow", "radio channel radio", "say_radio_channel", ".cancel_typing radiochannelsay"),
	"ooc" = list("oocwindow", "OOC", "ooc", null, "#688eff"),
	"looc" = list("loocwindow", "LOOC", "looc", null, "#92a9ee"),
	"mooc" = list("oocwindow", "OOC", "ooc", null, "#30b9a0"), //For mentors lord help me
	"mlooc" = list("loocwindow", "LOOC", "looc", null, "#68afa2"),
	"aooc" = list("oocwindow", "OOC", "ooc", null, "#f78de7"), //Admins need presets too!!
	"alooc" = list("loocwindow", "LOOC", "looc", null, "#dd9ef6")
)
/client/proc/create_preset_input_window(name, force=FALSE, show=TRUE)
	var/arglist = input_window_presets[name]
	var/color = null
	if(length(arglist) >= 5)
		color = arglist[5]
	create_input_window(arglist[1], arglist[2], arglist[3], arglist[4], background_color=color, force=force, show=show)
//Those verbs are used by the hotkeys to ensure the window is created when you try to use it
/client/verb/init_say()
	set name = ".init_say"
	set hidden = TRUE
	create_preset_input_window("say")

/client/verb/init_radiosay()
	set name = ".init_radiosay"
	set hidden = TRUE
	create_preset_input_window("radiosay")

/client/verb/init_radiochannelsay()
	set name = ".init_radiochannelsay"
	set hidden = TRUE
	create_preset_input_window("radiochannelsay")

/client/verb/init_me()
	set name = ".init_me"
	set hidden = TRUE
	create_preset_input_window("me")

/client/verb/init_whisper()
	set name = ".init_whisper"
	set hidden = TRUE
	create_preset_input_window("whisper")

/client/verb/init_looc()
	set name = ".init_looc"
	set hidden = TRUE
	if(src.is_mentor())
		create_preset_input_window("mlooc", show=FALSE)
	else if(src?.holder && !src.stealth)
		create_preset_input_window("alooc", show=FALSE)
	else
		create_preset_input_window("looc", show=FALSE)

/client/verb/init_ooc()
	set name = ".init_ooc"
	set hidden = TRUE
	if(src.is_mentor())
		create_preset_input_window("mooc", show=FALSE)
		//Admin check
	else if(src?.holder && !src.stealth)
		create_preset_input_window("aooc", show=FALSE)
	else
		create_preset_input_window("ooc", show=FALSE)

//Verb available to the user in case something in the window breaks
/client/verb/fix_chatbox()
	set name = "Fix chatbox"
	var/preset = input(src, "Which chat window do you want to recreate?", "Fix chatbox") as null|anything in input_window_presets
	if(!preset)
		return
	create_preset_input_window(preset, force=TRUE)

//Create the windows for say and me ahead of time
/client/New()
	. = ..()
	if(src) //In case the client was deleted while New was running
		//Mentor OOC boxes have different colors
		if(src.is_mentor())
			create_preset_input_window("mlooc", show=FALSE)
			create_preset_input_window("mooc", show=FALSE)
		else if(src?.holder && !src.stealth)
			create_preset_input_window("alooc", show=FALSE)
			create_preset_input_window("aooc", show=FALSE)
		else
			create_preset_input_window("looc", show=FALSE)
			create_preset_input_window("ooc", show=FALSE)


		create_preset_input_window("whisper", show=FALSE)
		create_preset_input_window("radiosay", show=FALSE)
		create_preset_input_window("radiochannelsay", show=FALSE)
		create_preset_input_window("say", show=FALSE)
		create_preset_input_window("me", show=FALSE)
