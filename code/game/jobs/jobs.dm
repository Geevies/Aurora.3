var/const/NUM_JOB_DEPTS     = 3 //ENGSEC, MEDSCI and CIVILIAN
var/const/ENGSEC			=(1<<0)

var/const/CAPTAIN			=(1<<0)
var/const/HOS				=(1<<1)
var/const/WARDEN			=(1<<2)
var/const/FORENSICS			=(1<<3)
var/const/OFFICER			=(1<<4)
var/const/CHIEF				=(1<<5)
var/const/ENGINEER			=(1<<6)
var/const/ATMOSTECH			=(1<<7)
var/const/AI				=(1<<8)
var/const/CYBORG			=(1<<9)
var/const/INTERN_SEC		=(1<<10)
var/const/INTERN_ENG		=(1<<11)

var/const/MEDSCI			=(1<<1)

var/const/RD				=(1<<0)
var/const/SCIENTIST			=(1<<1)
var/const/CHEMIST			=(1<<2)
var/const/CMO				=(1<<3)
var/const/DOCTOR			=(1<<4)
var/const/SURGEON			=(1<<5)
var/const/VIROLOGIST		=(1<<6)
var/const/PSYCHIATRIST		=(1<<7)
var/const/ROBOTICIST		=(1<<8)
var/const/XENOBIOLOGIST		=(1<<9)
var/const/MED_TECH			=(1<<10)
var/const/INTERN_MED		=(1<<11)
var/const/INTERN_SCI		=(1<<12)


var/const/CIVILIAN			=(1<<2)

var/const/HOP				= BITFLAG(0)
var/const/BARTENDER			= BITFLAG(1)
var/const/BOTANIST			= BITFLAG(2)
var/const/CHEF				= BITFLAG(3)
var/const/JANITOR			= BITFLAG(4)
var/const/LIBRARIAN			= BITFLAG(5)
var/const/QUARTERMASTER		= BITFLAG(6)
var/const/CARGOTECH			= BITFLAG(7)
var/const/MINER				= BITFLAG(8)
var/const/LAWYER			= BITFLAG(9)
var/const/CHAPLAIN			= BITFLAG(10)
var/const/VISITOR			= BITFLAG(11)
var/const/CONSULAR			= BITFLAG(12)
var/const/JOURNALIST		= BITFLAG(13)
var/const/ASSISTANT			= BITFLAG(14)

var/const/OFFMAP			= BITFLAG(3)

var/const/MERCHANT			= BITFLAG(0)
var/const/MERCHANTASS		= BITFLAG(1)

var/list/command_positions = list(
	"Captain",
	"Head of Personnel",
	"Head of Security",
	"Chief Engineer",
	"Research Director",
	"Chief Medical Officer"
)


var/list/engineering_positions = list(
	"Chief Engineer",
	"Station Engineer",
	"Atmospheric Technician",
	"Engineering Apprentice"
)


var/list/medical_positions = list(
	"Chief Medical Officer",
	"Physician",
	"Surgeon",
	"Psychiatrist",
	"Pharmacist",
	"First Responder",
	"Medical Intern"
)


var/list/science_positions = list(
	"Research Director",
	"Scientist",
	"Roboticist",
	"Xenobiologist",
	"Lab Assistant"
)

//BS12 EDIT
var/list/cargo_positions = list(
	"Quartermaster",
	"Cargo Technician",
	"Shaft Miner"
)

var/list/civilian_positions = list(
	"Head of Personnel",
	"Corporate Liaison",
	"Consular Officer",
	"Bartender",
	"Gardener",
	"Chef",
	"Janitor",
	"Librarian",
	"Corporate Reporter",
	"Chaplain",
	"Assistant",
	"Visitor"
)


var/list/security_positions = list(
	"Head of Security",
	"Warden",
	"Investigator",
	"Security Officer",
	"Security Cadet"
)

var/list/nonhuman_positions = list(
	"AI",
	"Cyborg",
	"pAI",
	"Merchant"
)

/proc/guest_jobbans(var/job)
	return ((job in command_positions) || job == "Corporate Liaison" || job == "Consular Officer")

/proc/get_job_datums()
	var/list/occupations = list()
	var/list/all_jobs = typesof(/datum/job)

	for(var/A in all_jobs)
		var/datum/job/job = new A()
		if(!job)	continue
		occupations += job

	return occupations

/proc/get_alternate_titles(var/job)
	var/list/jobs = get_job_datums()
	var/list/titles = list()

	for(var/datum/job/J in jobs)
		if(J.title == job)
			titles = J.alt_titles

	return titles

//Mahzel : Job preview not added because code don't exist in BS12
