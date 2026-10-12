// Dedicated profile-switch validation. See LICENSE.md.
run()
{
	level endon("restarting");
	wait 3;
	setDvar("g_logSync", 1);
	setDvar("timescale", 5);
	if (!isDefined(game["profile_test_stage"]))
	{
		game["profile_test_stage"] = 0;
		game["profile_test_failed"] = false;
		bot = addTestClient();
		if (!check(isDefined(bot), "test_client")) return;
		deadline = getTime() + 10000;
		while (!isDefined(bot.hasSpawned))
		{
			if (!check(getTime() < deadline, "client_ready")) return;
			wait 0.05;
		}
		bot.pers["team"] = "allies";
		bot.team = "allies";
		bot.sessionteam = "allies";
		bot promod\economy::account();
		game["profile_test_id"] = bot.pers["economy_id"];
	}
	player = undefined;
	deadline = getTime() + 10000;
	while (!isDefined(player))
	{
		for (i = 0; i < level.players.size; i++)
			if (isDefined(level.players[i].pers["economy_id"]) && level.players[i].pers["economy_id"] == game["profile_test_id"])
				player = level.players[i];
		if (!check(getTime() < deadline, "player_after_restart")) return;
		wait 0.05;
	}
	stage = game["profile_test_stage"];
	if (stage == 1)
	{
		check(promod\economy::enabled() && game["menu_changeclass_allies"] == "flat_loadout", "enabled_profile_and_menu");
		check(player promod\economy::cash() < 999, "standard_wallet_cleared_on_enable");
		player maps\mp\gametypes\_promod::setClassChoice("assault");
		player maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary:m4,loadout_primary_attachment:assault:none");
		player maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary_attachment:assault:reflex");
		check(player.pers["assault"]["loadout_primary_attachment"] == "none", "economy_unpaid_reflex_rejected");
		entry = player promod\economy::account();
		entry["cash"] = 999;
		entry["frag"] = true;
		entry["armor"] = 2;
		entry["demolitionTeam"] = "allies";
		entry["redDot"] = true;
		entry["itemsTeam"] = "allies";
		entry["itemsRound"] = game["roundsplayed"];
		player promod\economy::saveAccount(entry);
		setDvar("promod_economy", 0);
		check(promod\economy::enabled(), "enable_flag_latched_during_round");
		game["profile_test_stage"] = 2;
		map_restart(true);
		return;
	}
	check(!promod\economy::enabled() && !promod\economy::buying(), "standard_no_buy_window_" + stage);
	check(game["menu_changeclass_allies"] == "changeclass_marines_mw" &&
		game["menu_changeclass_axis"] == "changeclass_opfor_mw" && game["menu_changeclass"] == "changeclass_mw", "stock_menu_mapping_" + stage);
	if (stage == 2)
	{
		entry = player promod\economy::account();
		check(entry["cash"] == 0 && !entry["frag"] && entry["armor"] == 0 && entry["demolitionTeam"] == "", "economy_wallet_and_items_cleared_on_disable");
		check(!promod\economy::flatMenuEnabled(), "stale_flat_flag_cannot_open_preview_in_standard");
		if (!game["profile_test_failed"]) logPrint("PROFILE_TEST;PASSED\n");
		return;
	}
	player notify("menuresponse", "loadout", "open");
	wait 0.1;
	player notify("menuresponse", "changeclass_marines_mw", "demolitions");
	wait 0.1;
	check(player.pers["class"] == "demolitions", "native_free_demo_selection");
	player maps\mp\gametypes\_promod::setClassChoice("assault");
	player maps\mp\gametypes\_promod::menuAcceptClass("go");
	wait 0.5;
	weapons = strTok("m4,ak47,mp5,ak74u", ",");
	for (w = 0; w < weapons.size; w++)
	{
		class = "assault";
		if (w > 1) class = "specops";
		player maps\mp\gametypes\_promod::setClassChoice(class);
		player notify("menuresponse", "changeclass_mw", "loadout_primary:" + weapons[w]);
		wait 0.05;
		player notify("menuresponse", "changeclass_mw", "loadout_primary_attachment:" + class + ":reflex");
		wait 0.05;
		player maps\mp\gametypes\_class::giveLoadout("allies", class);
		check(player hasWeapon(weapons[w] + "_reflex_mp"), "native_free_reflex_" + weapons[w]);
	}
	check(player hasWeapon("frag_grenade_mp"), "standard_free_frag");
	player maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary:uzi");
	player maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary_attachment:specops:reflex");
	check(player.pers["specops"]["loadout_primary_attachment"] == "none", "unsupported_reflex_rejected_and_cleared");
	player maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary:mp5,loadout_primary_attachment:specops:silencer");
	player maps\mp\gametypes\_class::giveLoadout("allies", "specops");
	check(player hasWeapon("mp5_silencer_mp"), "standard_free_suppressor");
	check(player promod\economy::cash() == 0 && !player promod\economy_items::ownsRedDot("mp5"), "free_optics_do_not_create_paid_ownership");
	entry = player promod\economy::account();
	entry["cash"] = 999;
	player promod\economy::saveAccount(entry);
	frag = player promod\economy_items::buyFrag();
	armor = player promod\economy_armor::buy();
	red = player promod\economy_items::buyRedDot("mp5");
	demo = player promod\economy::buyDemolition();
	check(!frag["success"] && !armor["success"] && !red["success"] && !demo["success"], "disabled_purchase_apis_rejected");
	check(!player promod\economy::creditCash(50, "test") && !player promod\economy::trySpendCash(50, "test") &&
		player promod\economy::cash() == 999, "disabled_wallet_writes_rejected");
	setDvar("promod_economy", 1);
	setDvar("ui_flat_loadout", 1);
	setDvar("ui_flat_rules", 1);
	check(!promod\economy::enabled(), "disable_flag_latched_during_round");
	if (game["profile_test_failed"]) return;
	game["profile_test_stage"] = 1;
	map_restart(true);
}

check( condition, name )
{
	if (!condition)
	{
		game["profile_test_failed"] = true;
		logPrint("PROFILE_TEST;FAILED;" + name + "\n");
	}
	else logPrint("PROFILE_TEST;OK;" + name + "\n");
	return condition;
}
