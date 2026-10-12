// Dedicated repeat-purchase and tactical persistence checks. See LICENSE.md.
check( condition, name )
{
	if (!condition)
	{
		game["repeat_test_failed"] = true;
		logPrint("REPEAT_TEST;FAILED;" + name + "\n");
	}
	else logPrint("REPEAT_TEST;OK;" + name + "\n");
	return condition;
}

fixture( player, weapon, attachment, frag, armor, cash, carriedFrag )
{
	class = "assault";
	if (weapon == "uzi" || weapon == "mp5") class = "specops";
	if (weapon == "m40a3") class = "sniper";
	player maps\mp\gametypes\_promod::setClassChoice(class);
	player maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary:" + weapon + ",loadout_primary_attachment:" + class + ":none");
	player promod\economy_items::clear();
	entry = player promod\economy::account();
	entry["cash"] = cash;
	entry["creditedRound"] = game["roundsplayed"];
	entry["repeatBuyRound"] = -1;
	entry["itemsRound"] = game["roundsplayed"];
	entry["itemsTeam"] = player.pers["team"];
	entry["frag"] = carriedFrag;
	player promod\economy::saveAccount(entry);
	pref = player promod\repeat_buy::preferences();
	pref["enabled"] = true;
	pref["attachment"] = attachment;
	pref["frag"] = frag;
	pref["armor"] = armor;
	player.pers["repeat_buy"] = pref;
}

run()
{
	level endon("restarting");
	wait 3;
	setDvar("g_logSync", 1);
	setDvar("timescale", 5);
	if (!isDefined(game["repeat_test_stage"]))
	{
		game["repeat_test_stage"] = 0;
		game["repeat_test_failed"] = false;
		player = addTestClient();
		if (!check(isDefined(player), "test_client")) return;
		deadline = getTime() + 10000;
		while (!isDefined(player.hasSpawned))
		{
			if (!check(getTime() < deadline, "client_ready")) return;
			wait 0.05;
		}
		player.pers["team"] = "allies";
		player.team = "allies";
		player.sessionteam = "allies";
		player maps\mp\gametypes\_promod::setClassChoice("assault");
		player maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary:m4,loadout_grenade:smoke_grenade");
		player maps\mp\gametypes\_promod::menuAcceptClass("go");
		wait 0.6;
		game["repeat_test_id"] = player.pers["economy_id"];
		pref = player promod\repeat_buy::preferences();
		check(!pref["enabled"], "off_by_default");
		player promod\economy_items::buyRedDot();
		player promod\economy::creditCash(promod\economy::price("frag"), "repeat_fixture");
		player promod\economy_items::buyFrag();
		player promod\economy::creditCash(50, "repeat_fixture");
		player promod\economy_armor::buy();
		pref = player promod\repeat_buy::preferences();
		check(pref["attachment"] == "reflex" && pref["frag"] && pref["armor"] == 1, "successful_manual_buys_remembered");
		player notify("menuresponse", "flat_loadout", "repeat_buy");
		wait 0.1;
		pref = player promod\repeat_buy::preferences();
		check(pref["enabled"] && player promod\economy::cash() == 0, "menu_toggle_saves_next_round_without_spending");
		player promod\economy_items::onGrenadeFire("frag_grenade_mp");
		if (game["repeat_test_failed"]) return;
		player promod\economy::creditCash(promod\economy::price("frag"), "repeat_fixture");
		game["repeat_test_stage"] = 1;
		game["roundsplayed"]++;
		map_restart(true);
		return;
	}
	player = undefined;
	deadline = getTime() + 10000;
	while (!isDefined(player) || !isDefined(player.spawnTime) || getTime() < player.spawnTime + 600)
	{
		for (i = 0; i < level.players.size; i++)
			if (isDefined(level.players[i].pers["economy_id"]) && level.players[i].pers["economy_id"] == game["repeat_test_id"])
				player = level.players[i];
		if (!check(getTime() < deadline, "player_after_restart")) return;
		wait 0.05;
	}
	pref = player promod\repeat_buy::preferences();
	check(pref["enabled"] && pref["attachment"] == "reflex" && pref["frag"] && pref["armor"] == 1, "preferences_survive_round_restart_and_partial_budget");
	check(player promod\economy::cash() == 0 && player promod\economy_items::ownsRedDot("m4") &&
		player promod\economy_items::ownsFrag() && player promod\economy_armor::charges() == 0, "automatic_next_round_attachment_then_frag_before_armor");
	player maps\mp\gametypes\_class::giveLoadout("allies", "assault");
	check(player hasWeapon("m4_reflex_mp") && player hasWeapon("frag_grenade_mp") &&
		player hasWeapon("smoke_grenade_mp") && player.pers["assault"]["loadout_grenade"] == "smoke_grenade", "native_paid_equipment_and_tactical_choice_retained");
	player promod\economy::creditCash(75, "repeat_fixture");
	player promod\repeat_buy::attempt();
	check(player promod\economy::cash() == 75 && player promod\economy_armor::charges() == 0, "no_retry_after_later_cash_transfer");
	fixture(player, "m4", "reflex", true, 1, 150, true);
	player promod\repeat_buy::attempt();
	check(player promod\economy::cash() == 0 && player promod\economy_items::ownsRedDot("m4") &&
		player promod\economy_armor::charges() == 1 && player promod\economy_items::ownsFrag(), "carried_frag_not_charged_again");
	fixture(player, "uzi", "reflex", true, 1, 50 + promod\economy::price("frag"), false);
	player promod\repeat_buy::attempt();
	check(player promod\economy::cash() == 0 && !player promod\economy_items::ownsRedDot("uzi") &&
		player promod\economy_items::ownsFrag() && player promod\economy_armor::charges() == 1, "incompatible_attachment_skipped_without_debit");
	fixture(player, "m4", "silencer", true, 1, 50 + promod\economy::price("frag"), false);
	player promod\repeat_buy::attempt();
	check(player promod\economy::cash() == 0 && player promod\economy_items::ownsSuppressor("primary") &&
		!player promod\economy_items::ownsRedDot("m4") && player.pers["assault"]["loadout_primary_attachment"] == "silencer" &&
		player promod\economy_items::ownsFrag(), "suppressor_is_one_attachment_purchase");
	fixture(player, "m40a3", "sniper_penetration", true, 1, promod\economy::price("sniper_penetration"), false);
	player promod\repeat_buy::attempt();
	frag = player promod\economy_items::buyFrag();
	check(player promod\economy::cash() == 0 && player promod\economy_penetration::owns() &&
		!player promod\economy_items::ownsFrag() && player promod\economy_armor::charges() == 0 && frag["status"] == "funds", "sniper_upgrade_uses_its_price_and_frag_reports_funds");
	fixture(player, "m4", "reflex", true, 2, 40, false);
	player promod\repeat_buy::attempt();
	pref = player promod\repeat_buy::preferences();
	check(player promod\economy::cash() == 40 && !player promod\economy_items::ownsFrag() && pref["armor"] == 2, "unfunded_items_skip_without_erasing_preferences");
	fixture(player, "m4", "none", false, 2, 50, false);
	player promod\repeat_buy::attempt();
	pref = player promod\repeat_buy::preferences();
	check(player promod\economy_armor::charges() == 1 && player promod\economy::cash() == 0 && pref["armor"] == 2, "partial_armor_keeps_requested_count");
	fixture(player, "m4", "reflex", true, 1, 100, false);
	level.economyBuyOpen = false;
	player promod\repeat_buy::attempt();
	check(player promod\economy::cash() == 100 && !player promod\economy_items::ownsRedDot("m4"), "closed_phase_cannot_repeat");
	level.economyBuyOpen = true;
	game["promod_do_readyup"] = true;
	player promod\repeat_buy::attempt();
	check(player promod\economy::cash() == 100, "readyup_cannot_repeat");
	game["promod_do_readyup"] = false;
	level.economyEnabled = false;
	player promod\repeat_buy::attempt();
	check(player promod\economy::cash() == 100, "standard_mode_cannot_repeat");
	level.economyEnabled = true;
	player promod\repeat_buy::toggle();
	player promod\repeat_buy::attempt();
	pref = player promod\repeat_buy::preferences();
	check(!pref["enabled"] && player promod\economy::cash() == 100, "opt_out_stops_repeat");
	pref["enabled"] = true;
	player.pers["repeat_buy"] = pref;
	promod\economy::resetHalf();
	pref = player promod\repeat_buy::preferences();
	check(pref["enabled"] && pref["attachment"] == "reflex" && pref["frag"] && pref["armor"] == 1 &&
		player promod\economy::cash() == 0 && !player promod\economy_items::ownsFrag() &&
		player.pers["assault"]["loadout_grenade"] == "smoke_grenade", "halftime_clears_cash_and_items_but_keeps_preferences_and_tactical");
	if (!game["repeat_test_failed"]) logPrint("REPEAT_TEST;PASSED\n");
}
