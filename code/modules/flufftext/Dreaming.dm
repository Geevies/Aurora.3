
var/list/dreams = list(
	"an ID card","a bottle","a familiar face","a crewmember","a toolbox","a security officer","the captain",
	"voices from all around","deep space","a doctor","the engine","a traitor","an ally","darkness",
	"light","a scientist","a monkey","a catastrophe","a loved one","a gun","warmth","freezing","the sun",
	"a hat","the Luna","a ruined station","a planet","phoron","air","the medical bay","the bridge","blinking lights",
	"a blue light","an abandoned laboratory","NanoTrasen","mercenaries","blood","healing","power","respect",
	"riches","space","a crash","happiness","pride","a fall","water","flames","ice","melons","flying","the eggs","money",
	"the head of personnel","the head of security","a chief engineer","a research director","a chief medical officer",
	"the detective","the warden","a member of the internal affairs","a station engineer","the janitor","atmospheric technician",
	"the quartermaster","a cargo technician","the botanist","a shaft miner","the psychologist","the chemist","the geneticist",
	"the chemist","the roboticist","the chef","the bartender","the chaplain","the librarian","a mouse","an ert member",
	"a beach","the holodeck","a smokey room","a voice","the cold","a mouse","an operating table","the bar","the rain","a skrell",
	"a unathi","a tajaran","the ai core","the mining station","the research station","a beaker of strange liquid"
	)

/mob/living/carbon/proc/handle_dreams()
	if(client && prob(5))
		to_chat(src, "<span class='notice'><i>... [pick(dreams)] ...</i></span>")
