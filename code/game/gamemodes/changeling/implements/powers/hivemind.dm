//To get rid of pesky moaners
/mob/proc/changeling_eject_hivemind()
	set category = "Changeling"
	set name = "Hivemind Eject"
	set desc = "Ejects a member of our internal hivemind."

	if(!length(mind.changeling.hivemind))
		to_chat(src, SPAN_WARNING("We don't have any members of our internal hivemind to eject!"))
		return
	var/mob/abstract/hivemind/chosen_hivemind = input("Choose a hivemind member to eject.") as null|anything in mind.changeling.hivemind
	if(!chosen_hivemind)
		to_chat(src, SPAN_NOTICE("We choose against ejecting a member of our internal hivemind."))
		return
	else
		to_chat(src, SPAN_NOTICE("We ejected [chosen_hivemind] from our internal hivemind."))
		chosen_hivemind.ghost() // bye
	return TRUE

/mob/proc/changeling_hivemind_commune()
	set category = "Changeling"
	set name = "Hivemind Commune"
	set desc = "Speak with all members of the hivemind."

	var/message = input(src, "What do you wish to tell your Hivemind?", "Hivemind Commune") as text
	if(!message)
		return

	to_chat(src, "<font color=[COLOR_LING_I_HIVEMIND]><b>[src]</b> says, \"[message]\"</font>") // tell the changeling
	for(var/H in src.mind.changeling.hivemind) // tell the other hiveminds
		to_chat(H, "<font color=[COLOR_LING_I_HIVEMIND]><b>[src]</b> says, \"[message]\"</font>")

	return TRUE