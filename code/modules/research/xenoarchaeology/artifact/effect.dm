
//override procs in children as necessary
/datum/artifact_effect
	var/effecttype = "unknown"		//purely used for admin checks ingame, not needed any more
	var/effect = EFFECT_TOUCH
	var/effectrange = 4
	var/trigger = TRIGGER_TOUCH
	var/atom/holder
	var/activated = 0
	var/chargelevel = 0
	var/chargelevelmax = 10
	var/artifact_id = ""
	var/effect_type = 0

//0 = Unknown / none detectable
//1 = Concentrated energy
//2 = Intermittent psionic wavefront
//3 = Electromagnetic energy
//4 = Particle field
//5 = Organically reactive exotic particles
//6 = Interdimensional/bluespace? phasing
//7 = Atomic synthesis

/datum/artifact_effect/New(var/atom/location)
	..()
	holder = location
	effect = rand(2,MAX_EFFECT)
	trigger = rand(0,MAX_TRIGGER)

	//this will be replaced by the excavation code later, but it's here just in case
	artifact_id = "[pick("kappa","sigma","antaeres","beta","omicron","iota","epsilon","omega","gamma","delta","tau","alpha")]-[rand(100,999)]"

	//random charge time and distance
	switch(pick(100;1, 50;2, 25;3))
		if(1)
			//short range, short charge time
			chargelevelmax = rand(3, 20)
			effectrange = rand(1, 3)
		if(2)
			//medium range, medium charge time
			chargelevelmax = rand(15, 40)
			effectrange = rand(5, 15)
		if(3)
			//large range, long charge time
			chargelevelmax = rand(20, 60)
			effectrange = rand(15, 20)

/datum/artifact_effect/Destroy(force)
	holder = null

	. = ..()

/datum/artifact_effect/proc/ToggleActivate(var/reveal_toggle = 1)
	//so that other stuff happens first
	spawn(0)
		if(activated)
			activated = 0
		else
			activated = 1
		if(reveal_toggle && holder)
			if(istype(holder, /obj/machinery/artifact))
				var/obj/machinery/artifact/A = holder
				A.icon_state = "ano[A.icon_num][activated]"
			var/display_msg
			if(activated)
				display_msg = pick("momentarily glows brightly!","distorts slightly for a moment!","flickers slightly!","vibrates!","shimmers slightly for a moment!")
			else
				display_msg = pick("grows dull!","fades in intensity!","suddenly becomes very still!","suddenly becomes very quiet!")
			var/atom/toplevelholder = holder
			while(!istype(toplevelholder.loc, /turf))
				toplevelholder = toplevelholder.loc
			toplevelholder.visible_message("<span class='warning'>[icon2html(toplevelholder, viewers(get_turf(toplevelholder)))] [toplevelholder] [display_msg]</span>")

/datum/artifact_effect/proc/DoEffectTouch(var/mob/living/user)
/datum/artifact_effect/proc/DoEffectAura(var/atom/holder)
/datum/artifact_effect/proc/DoEffectPulse(var/atom/holder)
/datum/artifact_effect/proc/UpdateMove()

/datum/artifact_effect/process()
	if(chargelevel < chargelevelmax)
		chargelevel++

	if(activated)
		if(effect == EFFECT_AURA)
			DoEffectAura()
		else if(effect == EFFECT_PULSE && chargelevel >= chargelevelmax)
			chargelevel = 0
			DoEffectPulse()

//returns 0..1, with 1 being no protection and 0 being fully protected
/proc/GetAnomalySusceptibility(var/mob/living/carbon/human/H)
	if(!H || !istype(H))
		return 1

	//anomaly suits give best protection, but excavation suits are almost as good
	if(istype(H.back,/obj/item/rig/hazmat))
		var/obj/item/rig/hazmat/rig = H.back
		if(rig.suit_is_deployed() && !rig.offline)
			return 0 //<- Maximum level of protection achieved.

	var/protected = 0

	if(istype(H.wear_suit,/obj/item/clothing/suit/hazmat/anomaly))
		protected += 0.6
	else if(istype(H.wear_suit,/obj/item/clothing/suit/space/anomaly))
		protected += 0.5

	if(istype(H.head,/obj/item/clothing/head/hazmat/anomaly))
		protected += 0.3
	else if(istype(H.head,/obj/item/clothing/head/helmet/space/anomaly))
		protected += 0.2

	//latex gloves and science goggles also give a bit of bonus protection
	if(istype(H.gloves,/obj/item/clothing/gloves/latex/nitrile))
		protected += 0.1
	/*
	If you have Anomaly Suit, Anomaly Hood, Latex Gloves AND Science Goggles, you will have
		0.6 + 0.3 + 0.1 + 0.1 = 1.1
	maximum protection level. The CLAMP01 instruction make sure that "protected" will be
	always in 0..1 range boundaries.
	*/
	if(istype(H.glasses,/obj/item/clothing/glasses/science))
		protected += 0.1 //<- In case of full not-Anomaly clothing, you'll have 0.5 + 0.2 + 0.1 + 0.1 = 0.9 maximum protection level.

	//As said before, in case of a value of 1.1, "protected" will be setted to 1.
	protected = CLAMP01(protected)

	return 1 - protected
