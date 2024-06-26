//DNA machine
/obj/machinery/dnaforensics
	name = "DNA analyzer"
	desc = "A high tech machine that is designed to read DNA samples properly."
	icon = 'icons/obj/forensics.dmi'
	icon_state = "dnaopen"
	anchored = 1
	density = 1

	var/obj/item/forensics/swab/bloodsamp = null
	var/closed = 0
	var/scanning = 0
	var/scanner_progress = 0
	var/scanner_rate = 2.50
	var/last_process_worldtime = 0
	var/report_num = 0

/obj/machinery/dnaforensics/attackby(obj/item/attacking_item, mob/user)

	if(bloodsamp)
		to_chat(user, "<span class='warning'>There is already a sample in the machine.</span>")
		return

	if(closed)
		to_chat(user, "<span class='warning'>Open the cover before inserting the sample.</span>")
		return

	var/obj/item/forensics/swab/swab = attacking_item
	if(istype(swab) && swab.is_used())
		user.unEquip(attacking_item)
		src.bloodsamp = swab
		swab.forceMove(src)
		to_chat(user, "<span class='notice'>You insert \the [attacking_item] into \the [src].</span>")
	else
		to_chat(user, "<span class='warning'>\The [src] only accepts used swabs.</span>")
		return

/obj/machinery/dnaforensics/ui_interact(mob/user, ui_key = "main",var/datum/nanoui/ui = null)
	if(stat & (NOPOWER)) return
	if(user.stat || user.restrained()) return
	var/list/data = list()
	data["scan_progress"] = round(scanner_progress)
	data["scanning"] = scanning
	data["bloodsamp"] = (bloodsamp ? bloodsamp.name : "")
	data["bloodsamp_desc"] = (bloodsamp ? (bloodsamp.desc ? bloodsamp.desc : "No information on record.") : "")
	data["lidstate"] = closed

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data)
	if (!ui)
		ui = new(user, src, ui_key, "dnaforensics.tmpl", "QuikScan DNA Analyzer", 540, 326)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/dnaforensics/Topic(href, href_list)

	if(..()) return 1

	if(stat & (NOPOWER))
		return 0 // don't update UIs attached to this object

	if(href_list["scanItem"])
		if(scanning)
			scanning = 0
		else
			if(bloodsamp)
				if(closed == 1)
					scanner_progress = 0
					scanning = 1
					to_chat(usr, "<span class='notice'>Scan initiated.</span>")
					update_icon()
				else
					to_chat(usr, "<span class='notice'>Please close sample lid before initiating scan.</span>")
			else
				to_chat(usr, "<span class='warning'>Insert an item to scan.</span>")

	if(href_list["ejectItem"])
		if(bloodsamp)
			bloodsamp.forceMove(src.loc)
			bloodsamp = null

	if(href_list["toggleLid"])
		toggle_lid()

	return 1

/obj/machinery/dnaforensics/process()
	if(scanning)
		if(!bloodsamp || bloodsamp.loc != src)
			bloodsamp = null
			scanning = 0
		else if(scanner_progress >= 100)
			complete_scan()
			return
		else
			//calculate time difference
			var/deltaT = (world.time - last_process_worldtime) * 0.1
			scanner_progress = min(100, scanner_progress + scanner_rate * deltaT)
	last_process_worldtime = world.time

/obj/machinery/dnaforensics/proc/complete_scan()
	visible_message(SPAN_NOTICE("[icon2html(src, viewers(get_turf(src)))] makes an insistent chime."), range = 2)
	update_icon()
	if(bloodsamp)
		var/obj/item/paper/P = new()
		var/pname = "[src] report #[++report_num]"
		var/info
		P.stamped = list(/obj/item/stamp)
		P.overlays = list("paper_stamped")
		//dna data itself
		var/data = "No scan information available."
		if(bloodsamp.dna != null)
			data = "Spectometric analysis on provided sample has determined the presence of [length(bloodsamp.dna)] string\s of DNA.<br><br>"
			for(var/blood in bloodsamp.dna)
				if(bloodsamp.dna[blood])
					data += "<b>Blood type:</b> [bloodsamp.dna[blood]]<br>"
				data += "<b>DNA:</b> [blood]<br><br>"
		else
			data += "No DNA found.<br>"
		info = "<b><font size=\"4\">[src] analysis report #[report_num]</font></b><HR>"
		info += "<b>Scanned item:</b> [bloodsamp.name]<br><br>" + data
		P.set_content_unsafe(pname, info)
		print(P, user = usr)
		scanning = 0
		update_icon()
	return

/obj/machinery/dnaforensics/attack_ai(mob/user as mob)
	if(!ai_can_interact(user))
		return
	ui_interact(user)

/obj/machinery/dnaforensics/attack_hand(mob/user as mob)
	ui_interact(user)

/obj/machinery/dnaforensics/verb/toggle_lid()
	set category = "Object"
	set name = "Toggle Lid"
	set src in oview(1)

	if(usr.stat || !isliving(usr))
		return

	if(scanning)
		to_chat(usr, "<span class='warning'>You can't do that while [src] is scanning!</span>")
		return

	closed = !closed
	src.update_icon()

/obj/machinery/dnaforensics/update_icon()
	..()
	if(!(stat & NOPOWER) && scanning)
		icon_state = "dnaworking"
	else if(closed)
		icon_state = "dnaclosed"
	else
		icon_state = "dnaopen"
