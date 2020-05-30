


// Foam
// Similar to smoke, but spreads out more
// metal foams leave behind a foamed metal wall

//foam effect

/obj/effect/particle_effect/foam
	name = "foam"
	icon_state = "foam"
	opacity = 0
	anchored = 1
	density = 0
	layer = BELOW_MOB_LAYER
	mouse_opacity = 0
	var/amount = 3
	var/expand = 1
	animate_movement = 0
	var/metal = 0


/obj/effect/particle_effect/foam/Initialize(loc, var/ismetal=0)
	..(loc)
	icon_state = "[ismetal ? "m":""]foam"
	metal = ismetal
	playsound(src, 'sound/effects/bubbles2.ogg', 25, 1, 5)
	spawn(3 + metal*3)
		process()
		checkReagents()
	spawn(120)
		processing_objects.Remove(src)
		sleep(30)

		if(metal)
			var/obj/structure/foamedmetal/M = new(src.loc)
			M.metal = metal
			M.updateicon()

		flick("[icon_state]-disolve", src)
		sleep(5)
		qdel(src)


// transfer any reagents to the floor
/obj/effect/particle_effect/foam/proc/checkReagents()
	if(!metal && reagents)
		for(var/atom/A in src.loc.contents)
			if(A == src)
				continue
			reagents.reaction(A, 1, 1)

/obj/effect/particle_effect/foam/process()
	if(--amount < 0)
		return


	for(var/direction in cardinal)


		var/turf/T = get_step(src,direction)
		if(!T)
			continue

		if(!T.Enter(src))
			continue

		var/obj/effect/particle_effect/foam/F = locate() in T
		if(F)
			continue

		F = new(T, metal)
		F.amount = amount
		if(!metal)
			F.create_reagents(10)
			if (reagents)
				for(var/datum/reagent/R in reagents.reagent_list)
					F.reagents.add_reagent(R.id, 1, safety = 1)		//added safety check since reagents in the foam have already had a chance to react

// foam disolves when heated
// except metal foams
/obj/effect/particle_effect/foam/fire_act(exposed_temperature, exposed_volume)
	if(!metal && prob(max(0, exposed_temperature - 475)))
		flick("[icon_state]-disolve", src)

		QDEL_IN(src, 5)


/obj/effect/particle_effect/foam/Crossed(var/atom/movable/AM)
	if(metal)
		return
	if (iscarbon(AM))
		var/mob/living/carbon/C = AM
		C.slip("foam", 5, 2)



//datum effect system

/datum/effect_system/foam_spread
	var/amount = 5				// the size of the foam spread.
	var/list/carried_reagents	// the IDs of reagents present when the foam was mixed
	var/metal = 0				// 0=foam, 1=metalfoam, 2=ironfoam




	set_up(amt=5, loca, var/datum/reagents/carry = null, var/metalfoam = 0)
		amount = round(sqrt(amt / 3), 1)
		if(istype(loca, /turf/))
			location = loca
		else
			location = get_turf(loca)

		carried_reagents = list()
		metal = metalfoam


		// bit of a hack here. Foam carries along any reagent also present in the glass it is mixed
		// with (defaults to water if none is present). Rather than actually transfer the reagents,
		// this makes a list of the reagent ids and spawns 1 unit of that reagent when the foam disolves.


		if(carry && !metal)
			for(var/datum/reagent/R in carry.reagent_list)
				carried_reagents += R.id

	start()
		spawn(0)
			var/obj/effect/particle_effect/foam/F = locate() in location
			if(F)
				F.amount += amount
				return

			F = new(src.location, metal)
			F.amount = amount

			if(!metal)			// don't carry other chemicals if a metal foam
				F.create_reagents(10)

				if(carried_reagents)
					for(var/id in carried_reagents)
						F.reagents.add_reagent(id, 1, null, 1) //makes a safety call because all reagents should have already reacted anyway
				else
					F.reagents.add_reagent("water", 1, safety = 1)




// wall formed by metal foams
// dense and opaque, but easy to break

/obj/structure/foamedmetal
	icon = 'icons/effects/effects.dmi'
	icon_state = "metalfoam"
	density = 1
	opacity = 1 	// changed in New()
	anchored = 1
	name = "foamed metal"
	desc = "A lightweight foamed metal wall."
	var/metal = 1		// 1=aluminum, 2=iron

/obj/structure/foamedmetal/Dispose()
	density = 0
	. = ..()

/obj/structure/foamedmetal/proc/updateicon()
	if(metal == 1)
		icon_state = "metalfoam"
	else
		icon_state = "ironfoam"

/obj/structure/foamedmetal/ex_act(severity)
	qdel(src)

/obj/structure/foamedmetal/bullet_act()
	if(metal==1 || prob(50))
		qdel(src)
	return 1

/obj/structure/foamedmetal/attack_hand(var/mob/user)
	if (prob(75 - metal*25))
		user.visible_message(SPAN_DANGER("[user] smashes through the foamed metal."), SPAN_NOTICE("You smash through the metal foam wall."))
		qdel(src)
	else
		to_chat(user, SPAN_NOTICE(" You hit the metal foam but bounce off it."))
	return

/obj/structure/foamedmetal/attackby(var/obj/item/I, var/mob/user)

	if(prob(I.force*20 - metal*25))
		to_chat(user, SPAN_NOTICE(" You smash through the foamed metal with \the [I]."))
		for(var/mob/O in oviewers(user))
			if ((O.client && !( O.blinded )))
				to_chat(O, SPAN_DANGER("[user] smashes through the foamed metal."))
		qdel(src)
	else
		to_chat(user, SPAN_NOTICE(" You hit the metal foam to no effect."))