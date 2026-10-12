// Dedicated validation only. See LICENSE.md.

check( condition, name )
{
	return promod\economy_smoke::check(condition, name);
}

actor()
{
	return promod\economy_smoke::findPlayer(game["economy_items_test_id"]);
}

selectWeapon( weapon )
{
	class = "assault";
	if (weapon == "mp5" || weapon == "ak74u")
		class = "specops";
	self maps\mp\gametypes\_promod::setClassChoice(class);
	self.pers[class]["loadout_primary"] = weapon;
	self.pers[class]["loadout_primary_attachment"] = "none";
}

buyChecks( player, stage )
{
	if (stage == 0)
	{
		mates = promod\economy_smoke::teammates(player);
		tester = mates[1];
		game["economy_items_test_id"] = tester.pers["economy_id"];
		initialCash = tester promod\economy::cash();
		tester selectWeapon("m4");
		tester.pers["assault"]["loadout_primary_attachment"] = "reflex";
		tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
		check(!tester hasWeapon("frag_grenade_mp") && !tester hasWeapon("m4_reflex_mp"), "unpaid_items_not_granted");
		result = tester promod\economy::buyRedDot("m4");
		check(result["success"] && result["price"] == 100 && result["cash"] == initialCash - 100 && result["weapon"] == "m4", "red_dot_exact_price");
		tester promod\economy::creditCash(100, "item_test_setup");
		result = tester promod\economy::buyFrag();
		check(result["success"] && result["price"] == 100 && result["cash"] == initialCash - 100 &&
			tester getWeaponAmmoClip("frag_grenade_mp") == 1, "frag_exact_price_and_grant");
		cash = tester promod\economy::cash();
		result = tester promod\economy::buyFrag();
		check(result["status"] == "owned" && tester promod\economy::cash() == cash, "duplicate_frag_no_charge");
		result = tester promod\economy::buyRedDot("m4");
		check(result["status"] == "owned" && tester promod\economy::cash() == cash, "duplicate_red_dot_no_charge");
		result = tester promod\economy::buyRedDot("ak47");
		check(result["status"] == "unavailable" && tester promod\economy::cash() == cash, "unselected_gun_purchase_denied");
		tester selectWeapon("ak47");
		tester.pers["assault"]["loadout_primary_attachment"] = "reflex";
		tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
		check(tester hasWeapon("ak47_reflex_mp"), "red_dot_follows_player_to_supported_gun");
		result = tester promod\economy::buyRedDot("ak47");
		check(result["status"] == "owned" && tester promod\economy::cash() == cash, "red_dot_not_charged_twice_across_guns");
		tester promod\economy::creditCash(300, "item_test_setup");
		guns = strTok("ak47,mp5,ak74u", ",");
		for (i = 0; i < guns.size; i++)
		{
			tester selectWeapon(guns[i]);
			tester.pers[tester.pers["class"]]["loadout_primary_attachment"] = "reflex";
			result = tester promod\economy::buyRedDot(guns[i]);
			tester maps\mp\gametypes\_class::giveLoadout("allies", tester.pers["class"]);
			check((result["success"] || result["status"] == "owned") && tester hasWeapon(guns[i] + "_reflex_mp"), "red_dot_variant_" + guns[i]);
		}
		tester selectWeapon("m4");
		tester.pers["assault"]["loadout_primary_attachment"] = "reflex";
		tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
		check(tester hasWeapon("m4_reflex_mp"), "red_dot_variant_m4");
		restore = initialCash - tester promod\economy::cash();
		if (restore > 0) tester promod\economy::creditCash(restore, "item_test_restore");
		else if (restore < 0) tester promod\economy::trySpendCash(0 - restore, "item_test_restore");
	}
	else
	{
		tester = actor();
		check(!tester promod\economy_items::ownsRedDot("m4") && !tester hasWeapon("m4_reflex_mp"), "red_dot_expires_round_" + stage);
		if (stage == 1)
		{
			check(tester promod\economy_items::ownsFrag() && tester getWeaponAmmoClip("frag_grenade_mp") == 1, "surviving_unused_frag_retained");
			tester promod\economy::creditCash(100, "item_test_setup");
			cash = tester promod\economy::cash();
			tester setWeaponAmmoClip("frag_grenade_mp", 0);
			tester notify("grenade_fire", undefined, "frag_grenade_mp");
			wait 0.3;
			check(!tester promod\economy_items::ownsFrag(), "grenade_event_consumes_purchase");
			tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
			check(!tester hasWeapon("frag_grenade_mp"), "loadout_cannot_refill_used_frag");
			tester notify("menuresponse", "economy", "buy_frag");
			wait 0.1;
			check(tester promod\economy_items::ownsFrag() && tester getWeaponAmmoClip("frag_grenade_mp") == 1 &&
				tester promod\economy::cash() == cash - 100, "frag_command_repurchase");
			tester notify("menuresponse", "economy", "buy_red_dot:m4");
			wait 0.1;
			check(tester promod\economy_items::ownsRedDot("m4") && tester promod\economy::cash() == cash - 200, "red_dot_command_repurchase_next_round");
			tester promod\economy::creditCash(100, "item_test_restore");
		}
		if (stage == 2)
		{
			tester promod\economy::creditCash(50, "item_test_setup");
			result = tester promod\economy::buyRedDot("m4");
			check(result["success"], "red_dot_before_death");
			tester promod\economy::creditCash(50, "item_test_restore");
		}
		if (stage == 3)
		{
			check(!tester promod\economy_items::ownsFrag() && !tester hasWeapon("frag_grenade_mp"), "dead_player_does_not_retain_frag");
			cash = tester promod\economy::cash();
			setDvar("weap_allow_frag_grenade", 0);
			result = tester promod\economy::buyFrag();
			check(result["status"] == "unavailable" && tester promod\economy::cash() == cash, "disabled_frag_no_charge");
			setDvar("weap_allow_frag_grenade", 1);
			tester selectWeapon("m16");
			result = tester promod\economy::buyRedDot("m16");
			check(result["status"] == "unavailable" && tester promod\economy::cash() == cash, "unsupported_gun_no_charge");
			tester selectWeapon("m4");
		}
	}
}

liveChecks( player, stage )
{
	tester = actor();
	if (stage == 0)
	{
		cash = tester promod\economy::cash();
		frag = tester promod\economy::buyFrag();
		sight = tester promod\economy::buyRedDot("m4");
		check(frag["status"] == "closed" && sight["status"] == "closed" && tester promod\economy::cash() == cash, "live_item_purchases_denied");
	}
	if (stage == 2)
	{
		cash = tester promod\economy::cash();
		tester suicide();
		wait 0.2;
		check(!tester promod\economy_items::ownsFrag() && !tester promod\economy_items::ownsRedDot("m4"), "death_removes_purchased_items");
		check(tester promod\economy::cash() == cash, "suicide_no_cash_reward");
	}
	if (stage == 3)
		combatKill(player, false);
}

seedHalfItems()
{
	tester = actor();
	tester selectWeapon("m4");
	tester promod\economy::buyFrag();
	tester promod\economy::buyRedDot("m4");
	check(tester promod\economy_items::ownsFrag() && tester promod\economy_items::ownsRedDot("m4"), "items_before_halftime");
}

checkHalfItems()
{
	tester = actor();
	check(!tester promod\economy_items::ownsFrag() && !tester promod\economy_items::ownsRedDot("m4") &&
		tester promod\economy::cash() == 0, "halftime_clears_items_and_cash");
	mode = game["PROMOD_MATCH_MODE"];
	game["PROMOD_MATCH_MODE"] = "strat";
	tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
	check(tester getWeaponAmmoClip("frag_grenade_mp") == 1, "practice_keeps_free_frag");
	result = tester promod\economy::buyFrag();
	check(result["status"] == "closed" && tester promod\economy::cash() == 0, "practice_no_purchase_charge");
	game["PROMOD_MATCH_MODE"] = mode;
	tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
}

damage( target, attacker, amount )
{
	target maps\mp\gametypes\_globallogic::Callback_PlayerDamage(attacker, attacker, amount, 0,
		"MOD_RIFLE_BULLET", "m4_reflex_mp", target.origin, (1,0,0), "torso_upper", 0);
}

combatKill( player, finalKill )
{
	if (finalKill)
	{
		deadline = getTime() + 10000;
		while (level.inGracePeriod && getTime() < deadline)
			wait 0.1;
		if (!check(!level.inGracePeriod, "combat_after_spawn_grace"))
			return;
	}
	killer = actor();
	assistant = undefined;
	victims = [];
	for (i = 0; i < level.players.size; i++)
	{
		candidate = level.players[i];
		if (candidate.sessionstate != "playing")
			continue;
		if (candidate.pers["team"] != killer.pers["team"])
			victims[victims.size] = candidate;
		else if (candidate != killer && candidate != player)
			assistant = candidate;
	}
	if (!check(isDefined(assistant) && victims.size > 0, "combat_test_players"))
		return;
	if (finalKill)
		for (i = 1; i < victims.size; i++)
		{
			damage(victims[i], killer, 1000);
			wait 0.2;
		}
	victim = victims[0];
	killerCash = killer promod\economy::cash();
	assistCash = assistant promod\economy::cash();
	damage(victim, assistant, 10);
	damage(victim, assistant, 10);
	damage(victim, killer, 1000);
	wait 0.2;
	check(victim.sessionstate == "dead" && killer promod\economy::cash() == killerCash + 50 &&
		assistant promod\economy::cash() == assistCash + 25, "enemy_kill_and_assist_rewards_" + int(finalKill));
	check(!killer promod\economy_combat::awardKill(victim) && !assistant promod\economy_combat::awardAssist(victim, killer), "combat_rewards_once_" + int(finalKill));
	check(!killer promod\economy_combat::awardKill(killer) && !killer promod\economy_combat::awardKill(assistant), "friendly_and_self_rewards_denied");
	if (finalKill)
		check(level.gameEnded, "last_kill_rewards_before_round_end");
}
