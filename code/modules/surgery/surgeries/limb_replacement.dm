/datum/surgery/augmentation
	name = "Augmentation"
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/clamp,
		/datum/surgery_step/retract,
		/datum/surgery_step/saw,
		/datum/surgery_step/replace_limb,
	)
	target_mobtypes = list(/mob/living/carbon/human)

/datum/surgery_step/replace_limb
	name = "Replace limb"
	implements = list(
		/obj/item/bodypart = 80,
	)
	time = 3.2 SECONDS
	surgery_flags = SURGERY_INCISED | SURGERY_RETRACTED | SURGERY_BROKEN
	skill_min = SKILL_LEVEL_JOURNEYMAN
	skill_median = SKILL_LEVEL_MASTER
	/// The point at which the limb's attachment wound isn't added.
	var/skill_no_wound = SKILL_LEVEL_LEGENDARY
	/// A multiplier used to increase wound damage and bleed while at the minimum skill level.
	var/const/unskilled_wound_multiplier = 1.5

/datum/surgery_step/replace_limb/preop(mob/user, mob/living/target, target_zone, obj/item/tool, datum/intent/intent)
	var/obj/item/bodypart/aug = tool
	if(!istype(aug) || aug.status != BODYPART_ROBOTIC)
		to_chat(user, span_warning("That's not an augment, silly!"))
		return FALSE
	if(aug.body_zone != target_zone)
		to_chat(user, span_warning("[tool] isn't the right type for [parse_zone(target_zone)]."))
		return FALSE
	var/obj/item/bodypart/existing = target.get_bodypart(check_zone(target_zone))
	if(!existing)
		user.visible_message(span_notice("[user] looks for [target]'s [parse_zone(user.zone_selected)]."),
							span_notice("I look for [target]'s [parse_zone(user.zone_selected)]..."))
		return FALSE
	display_results(user, target, span_notice("I begin to augment [target]'s [parse_zone(user.zone_selected)]..."),
		span_notice("[user] begins to augment [target]'s [parse_zone(user.zone_selected)] with [aug]."),
		span_notice("[user] begins to augment [target]'s [parse_zone(user.zone_selected)]."))
	return TRUE

/datum/surgery_step/replace_limb/success(mob/user, mob/living/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/bodypart/existing = target.get_bodypart(check_zone(target_zone))
	if(existing)
		var/obj/item/bodypart/bodypart = tool
		if(istype(bodypart) && user.temporarilyRemoveItemFromInventory(bodypart))
			if(bodypart.replace_limb(target, special = TRUE))
				var/skill_level = user.mind?.get_skill_level(skill_used)
				if(bodypart.attach_wound && skill_level < skill_no_wound)
					var/datum/wound/attachment_wound = bodypart.add_wound(bodypart.attach_wound)
					if(skill_level <= skill_min) // at the minimum skill level the wound is extra nasty
						attachment_wound.whp *= unskilled_wound_multiplier
						attachment_wound.bleed_rate *= unskilled_wound_multiplier
		display_results(user, target, span_notice("I successfully augment [target]'s [parse_zone(target_zone)]."),
			span_notice("[user] successfully augments [target]'s [parse_zone(target_zone)] with [bodypart]!"),
			span_notice("[user] successfully augments [target]'s [parse_zone(target_zone)]!"))
		log_combat(user, target, "augmented", addition="by giving him new [parse_zone(target_zone)] INTENT: [uppertext(user.a_intent?.name)]")
	else
		to_chat(user, span_warning("[target] has no organic [parse_zone(target_zone)] there!"))
	return TRUE
