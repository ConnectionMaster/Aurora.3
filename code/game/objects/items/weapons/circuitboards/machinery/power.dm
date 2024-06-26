#ifndef T_BOARD
#error T_BOARD macro is not defined but we need it!
#endif

/obj/item/circuitboard/smes
	name = T_BOARD("superconductive magnetic energy storage")
	build_path = /obj/machinery/power/smes/buildable
	board_type = "machine"
	origin_tech = list(TECH_POWER = 6, TECH_ENGINEERING = 4)
	req_components = list("/obj/item/smes_coil" = 1, "/obj/item/stack/cable_coil" = 30)

/obj/item/circuitboard/batteryrack
	name = T_BOARD("battery rack PSU")
	build_path = /obj/machinery/power/smes/batteryrack
	board_type = "machine"
	origin_tech = list(TECH_POWER = 3, TECH_ENGINEERING = 2)
	req_components = list("/obj/item/cell" = 3)

/obj/item/circuitboard/ghettosmes
	name = T_BOARD("makeshift PSU")
	desc = "An APC circuit repurposed into some power storage device controller."
	build_path = /obj/machinery/power/smes/batteryrack/makeshift
	board_type = "machine"
	req_components = list("/obj/item/cell" = 3)

/obj/item/circuitboard/ghettosmes/attackby(obj/item/attacking_item, mob/user)
	if(attacking_item.ismultitool())
		var/obj/item/module/power_control/new_circuit = new /obj/item/module/power_control(get_turf(src))
		to_chat(user, SPAN_NOTICE("You modify \the [src] into an APC power control module."))
		qdel(src)
		user.put_in_hands(new_circuit)
