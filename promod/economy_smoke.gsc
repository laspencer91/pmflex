// Dedicated validation only. See LICENSE.md.
run()
{
	level endon("restarting");
	wait 3;
	setDvar("logfile", 2);
	setDvar("g_logSync", 1);
	setDvar("timescale", 5);
	if (!isDefined(game["economy_test_stage"]))
	{
		game["economy_test_stage"] = 0;
		game["economy_test_failed"] = false;
		for (i = 0; i < 6; i++)
		{
			bot = undefined;
			deadline = getTime() + 5000;
			while (!isDefined(bot) && getTime() < deadline)
			{
				bot = addTestClient();
				if (!isDefined(bot))
					wait 0.1;
			}
			if (!check(isDefined(bot), "test_client"))
				return;
			deadline = getTime() + 10000;
			while (!isDefined(bot.hasSpawned))
			{
				if (!check(getTime() < deadline, "client_connect"))
					return;
				wait 0.05;
			}
			team = "allies";
			if (i >= 4)
				team = "axis";
			bot.pers["team"] = team;
			bot.team = team;
			bot.sessionteam = team;
			bot maps\mp\gametypes\_promod::setClassChoice("assault");
			bot maps\mp\gametypes\_promod::menuAcceptClass("go");
			if (i == 0)
				game["economy_test_id"] = bot.pers["economy_id"];
		}
	}
	deadline = getTime() + 15000;
	player = undefined;
	while (!isDefined(player) || !level.economyBuyOpen)
	{
		if (!check(getTime() < deadline, "buy_phase"))
			return;
		player = findPlayer(game["economy_test_id"]);
		wait 0.05;
	}
	entry = player.pers["economy_id"];
	stage = game["economy_test_stage"];
	if (stage == 4)
	{
		waitLive();
		promod\economy_items_smoke::combatKill(player, true);
		checkNewMatch(player);
		return;
	}
	promod\economy_items_smoke::buyChecks(player, stage);
	deadline = getTime() + 2000;
	while (!isDefined(player.economyMenuRound) && getTime() < deadline) wait 0.05;
	check(player promod\economy::isTestClient() && !(isDefined(player.flatMenuOpen) && player.flatMenuOpen), "test_client_buy_menu_not_held_" + stage);
	promod\economy_armor_smoke::buyChecks(player, stage);
	promod\economy_penetration_smoke::buyChecks(player, stage);
	if (getDvarInt("combined_smoke") && stage == 0) promod\combined_smoke::run(player);
	check(isDefined(player.economyMenuRound) && player.economyMenuRound == game["roundsplayed"], "buy_selector_opened_" + stage);
	logPrint("ECONOMY_TEST;STATE;" + stage + ";" + game["roundsplayed"] + ";" + game["economy"]["accounts"][entry]["cash"] + ";" + game["economy"]["accounts"][entry]["creditedRound"] + "\n");
	check(game["economy"]["accounts"][entry]["cash"] == (stage + 1) * 100 || stage == 3, "round_income_" + stage);
	player promod\economy::creditRound();
	if (stage < 3)
		check(game["economy"]["accounts"][entry]["cash"] == (stage + 1) * 100, "income_once_" + stage);
	if (stage == 0)
	{
		check(promod\economy::price("demolition") == 300 && promod\economy::reward("round") == 100, "server_rules");
		check(level.economyBuySeconds == 30 && level.economyBuyEnd - getTime() <= 30000, "default_buy_seconds");
		setDvar("promod_buy_seconds", 5);
		low = promod\economy::configuredBuySeconds();
		setDvar("promod_buy_seconds", 90);
		high = promod\economy::configuredBuySeconds();
		check(low == 10 && high == 60 && level.economyBuySeconds == 30, "buy_seconds_limited_and_current_phase_kept");
		// The next buy phase reads the new length.
		setDvar("promod_buy_seconds", 15);
		check(promod\economy::cashText(50) == "^2$50^7", "cash_amount_color_format");
		check(!player promod\economy::trySpendCash(101, "test") && player promod\economy::cash() == 100, "overspend_preserves_balance");
		check(!player promod\economy::trySpendCash(0, "test") && !player promod\economy::trySpendCash(-1, "test") &&
			!player promod\economy::creditCash(-1, "test") && !player promod\economy::creditCash(0.5, "test"), "invalid_cash_changes_rejected");
		check(!player promod\economy::canAfford("unknown"), "unknown_item_not_affordable");
		check(player promod\economy::creditCash(25, "test") && player promod\economy::cash() == 125, "wallet_credit_persists");
		check(player promod\economy::trySpendCash(25, "test") && player promod\economy::cash() == 100, "wallet_debit_persists");
		rejected = player promod\economy::buyDemolition();
		check(!rejected["success"] && rejected["status"] == "funds" && rejected["cash"] == 100 && rejected["price"] == 300, "structured_purchase_failure");
		check(!player promod\economy::canBuyDemolition(), "unfunded_demo_button_locked");
		player setClientDvar("economy_cash", 999999);
		player notify("menuresponse", "economy", "buy_demolition");
		player notify("menuresponse", "changeclass_marines_mw", "demolitions");
		wait 0.2;
		check(game["economy"]["accounts"][entry]["cash"] == 100 && game["economy"]["accounts"][entry]["demolitionTeam"] == "" && player.pers["class"] == "assault", "unfunded_and_free_selection_denied");
		player maps\mp\gametypes\_promod::setClassChoice("demolitions");
		check(player.pers["class"] == "assault", "direct_selection_denied");
		check(!player maps\mp\gametypes\_promod::verifyClassChoice("allies", "bad_class"), "invalid_class_denied");
	}
	if (stage < 2)
	{
		weapon = "";
		spawnTime = 0;
		loadoutGeneration = 0;
		if (stage == 1)
		{
			check(level.economyBuySeconds == 15 && level.economyBuyEnd - getTime() <= 15000, "configured_buy_seconds_next_phase");
			setDvar("promod_buy_seconds", "");
			weapon = "m4_mp";
			player.pers["assault"]["loadout_primary"] = "m4";
			player.pers["assault"]["loadout_primary_attachment"] = "none";
			check(player promod\economy::loadoutChanged(), "changed_loadout_detected");
			player maps\mp\gametypes\_class::giveLoadout("allies", "assault");
			player promod\economy::freezeForBuy();
			player switchToWeapon(weapon);
			wait 0.5;
			check(player getCurrentWeapon() == weapon, "buy_phase_retains_current_weapon");
			player setWeaponAmmoClip(weapon, 7);
			spawnTime = player.spawnTime;
			loadoutGeneration = player.economyLoadoutGeneration;
			if (getDvarInt("combined_smoke")) logPrint("COMBINED_TEST;ammo_before;" + player getWeaponAmmoClip(weapon) + ";" + player getWeaponAmmoStock(weapon) + "\n");
		}
		waitLive();
		if (getDvarInt("combined_smoke") && stage == 0) promod\combined_smoke::closedRoundChecks(player);
		if (getDvarInt("combined_smoke") && stage == 1)
			logPrint("COMBINED_TEST;ammo_after;" + player getWeaponAmmoClip(weapon) + ";" + player getWeaponAmmoStock(weapon) + "\n");
		promod\economy_items_smoke::liveChecks(player, stage);
		promod\economy_armor_smoke::liveChecks(player, stage);
		promod\economy_penetration_smoke::liveChecks(player, stage);
		if (stage == 0)
			check(!player promod\economy::awardReward("unknown") && player promod\economy::cash() == 100, "unknown_reward_rejected");
		if (stage == 1)
		{
			check(player.spawnTime == spawnTime && player.economyLoadoutGeneration == loadoutGeneration && player hasWeapon(weapon), "unchanged_loadout_not_reissued");
		}
		if (game["economy_test_failed"])
			return;
		finishRound(stage + 1);
		return;
	}
	if (stage == 2)
	{
		mates = teammates(player);
		competitor = mates[0];
		if (competitor.pers["economy_id"] == game["economy_items_test_id"])
			competitor = mates[1];
		check(player promod\economy::canBuyDemolition(), "funded_demo_button_enabled");
		player notify("menuresponse", "changeclass_marines_mw", "demolitions");
		competitor notify("menuresponse", "economy", "buy_demolition");
		wait 0.2;
		first = player promod\economy::ownsDemolition();
		second = competitor promod\economy::ownsDemolition();
		check(int(first) + int(second) == 1, "single_demolition_owner");
		check(!competitor promod\economy::canBuyDemolition(), "claimed_demo_button_locked");
		if (second)
		{
			loser = player;
			player = competitor;
			competitor = loser;
		}
		entry = player.pers["economy_id"];
		other = competitor.pers["economy_id"];
		game["economy_test_id"] = player.pers["economy_id"];
		check(game["economy"]["accounts"][entry]["cash"] == 0 && game["economy"]["accounts"][other]["cash"] == 300, "atomic_charge");
		player notify("menuresponse", "economy", "buy_demolition");
		wait 0.1;
		check(game["economy"]["accounts"][entry]["cash"] == 0, "duplicate_buy_free");
		duplicate = player promod\economy::buyDemolition();
		check(!duplicate["success"] && duplicate["status"] == "owned", "structured_purchase_owned");
		player maps\mp\gametypes\_promod::setClassChoice("assault");
		check(player.pers["class"] == "demolitions", "owner_locked");
		check(!player maps\mp\gametypes\_promod::verifyClassChoice("allies", "sniper"), "owner_choice_locked");
		waitLive();
		promod\economy_items_smoke::liveChecks(player, stage);
		promod\economy_armor_smoke::liveChecks(player, stage);
		promod\economy_penetration_smoke::liveChecks(player, stage);
		check(player.curClass == "demolitions" && !player promod\economy::loadoutChanged(), "purchased_loadout_applied");
		competitor promod\economy::buyDemolition();
		check(game["economy"]["accounts"][other]["cash"] == 300, "live_buy_denied");
		if (game["economy_test_failed"])
			return;
		finishRound(3);
		return;
	}
	check(game["economy"]["accounts"][entry]["cash"] == 100 && player promod\economy::ownsDemolition() && player.pers["class"] == "demolitions", "survives_round_restart");
	waitLive();
	promod\economy_items_smoke::liveChecks(player, stage);
	promod\economy_armor_smoke::liveChecks(player, stage);
	promod\economy_penetration_smoke::liveChecks(player, stage);
	for (i = 0; i < level.players.size; i++)
		level.players[i] freezeControls(true);
	player suicide();
	wait 0.2;
	check(game["economy"]["accounts"][entry]["demolitionTeam"] == "" && player.pers["class"] == "sniper" && player.sessionstate != "playing", "real_death_scope_no_respawn");
	check(game["economy"]["accounts"][entry]["cash"] == 100, "death_preserves_cash");
	mates = teammates(player);
	player claimForCheck();
	mates[0] maps\mp\gametypes\_promod::setClassChoice("sniper");
	player promod\economy::onDeath();
	check(player.pers["class"] == "specops", "scope_full_smg_fallback");
	player claimForCheck();
	mates[1] maps\mp\gametypes\_promod::setClassChoice("specops");
	mates[2] maps\mp\gametypes\_promod::setClassChoice("specops");
	player promod\economy::onDeath();
	check(player.pers["class"] == "assault", "scope_smg_full_assault_fallback");
	player.pers["class"] = "demolitions";
	player.class = "demolitions";
	player promod\economy::ensureClass();
	check(player.pers["class"] == "assault", "stale_saved_class_rejected");
	player claimForCheck();
	player promod\economy::onDisconnect();
	check(game["economy"]["accounts"][entry]["demolitionTeam"] == "" && game["economy"]["accounts"][entry]["cash"] == 100, "disconnect_releases_slot");
	player promod\economy::ensureClass();
	level.economyBuyOpen = true;
	level.economyBuyEnd = getTime() + 10000;
	game["economy"]["accounts"][entry]["cash"] = 300;
	setDvar("class_demolitions_limit", 0);
	player promod\economy::buyDemolition();
	check(game["economy"]["accounts"][entry]["cash"] == 300 && game["economy"]["accounts"][entry]["demolitionTeam"] == "", "disabled_class_no_charge");
	setDvar("class_demolitions_limit", 1);
	promod\economy_items_smoke::seedHalfItems();
	promod\economy_armor_smoke::seedHalf();
	promod\economy_penetration_smoke::seedHalf();
	level.economyBuyOpen = false;
	beforePlant = cashSnapshot();
	level.sdBomb.safeOrigin = level.sdBomb.visuals[0].origin;
	level thread maps\mp\gametypes\sd::bombPlanted(level.bombZones[0], mates[0]);
	wait 0.1;
	checkReward(beforePlant, game["attackers"], "plant_rewards_attackers_including_dead");
	promod\economy::awardObjective("plant");
	checkReward(beforePlant, game["attackers"], "plant_reward_once");
	player claimForCheck();
	game["roundsplayed"] = level.roundSwitch;
	maps\mp\gametypes\_globallogic::checkRoundSwitch();
	check(game["economy"]["accounts"][entry]["cash"] == 0 && game["economy"]["accounts"][entry]["demolitionTeam"] == "" && player.pers["class"] != "demolitions", "halftime_resets_cash_and_owner");
	promod\economy_items_smoke::checkHalfItems();
	promod\economy_armor_smoke::checkHalf();
	promod\economy_penetration_smoke::checkHalf();
	level.economyBuyOpen = true;
	level.economyBuyEnd = getTime() + 10000;
	player promod\economy::creditRound();
	player promod\economy::creditRound();
	check(game["economy"]["accounts"][entry]["cash"] == 100, "new_half_income_once");
	promod\economy::resetHalf();
	check(game["economy"]["accounts"][entry]["cash"] == 100, "halftime_once");
	game["roundsplayed"]++;
	game["PROMOD_KNIFEROUND"] = 1;
	player promod\economy::creditRound();
	check(game["economy"]["accounts"][entry]["cash"] == 100, "knife_no_income");
	game["PROMOD_KNIFEROUND"] = 0;
	game["promod_do_readyup"] = true;
	player promod\economy::creditRound();
	check(game["economy"]["accounts"][entry]["cash"] == 100, "readyup_no_income");
	game["promod_do_readyup"] = false;
	game["promod_timeout_called"] = true;
	player promod\economy::creditRound();
	check(game["economy"]["accounts"][entry]["cash"] == 100, "timeout_no_income");
	game["promod_timeout_called"] = false;
	mode = game["PROMOD_MATCH_MODE"];
	game["PROMOD_MATCH_MODE"] = "strat";
	check(player promod\economy::canSelectClass("demolitions"), "practice_not_locked");
	game["PROMOD_MATCH_MODE"] = mode;
	player claimForCheck();
	player notify("menuresponse", game["menu_team"], "autoassign");
	wait 0.2;
	check(player.pers["team"] == "axis" && game["economy"]["accounts"][entry]["demolitionTeam"] == "", "autoassign_releases_slot");
	player claimForCheck();
	player notify("menuresponse", game["menu_team"], "shoutcast");
	wait 0.2;
	check(player.pers["team"] == "spectator" && game["economy"]["accounts"][entry]["demolitionTeam"] == "", "spectator_releases_slot");
	player.pers["team"] = "allies";
	player.team = "allies";
	player claimForCheck();
	player.pers["team"] = "axis";
	player.team = "axis";
	player promod\economy::onTeamChanged();
	check(game["economy"]["accounts"][entry]["demolitionTeam"] == "", "team_change_releases_slot");
	beforeDefuse = cashSnapshot();
	game["economy_test_stage"] = 4;
	level thread maps\mp\gametypes\sd::bombDefused();
	wait 0.1;
	checkReward(beforeDefuse, game["defenders"], "defuse_rewards_defenders");
	promod\economy::awardObjective("defuse");
	checkReward(beforeDefuse, game["defenders"], "defuse_reward_once");
	return;
}

checkNewMatch( player )
{
	entry = player.pers["economy_id"];
	nextId = game["economy"]["nextId"];
	promod\economy::resetMatch();
	player promod\economy::account();
	check(game["economy"]["accounts"][entry]["cash"] == 0, "new_match_zero_cash");
	newBot = addTestClient();
	if (!check(isDefined(newBot), "new_match_test_client"))
		return;
	deadline = getTime() + 10000;
	while (!isDefined(newBot.hasSpawned))
	{
		if (getTime() >= deadline)
		{
			check(false, "new_match_client_connect");
			return;
		}
		wait 0.05;
	}
	newBot promod\economy::account();
	check(game["economy"]["nextId"] > nextId, "new_match_session_ids_not_reused");
	for (i = 0; i < level.players.size; i++)
		if (level.players[i] != newBot)
			check(newBot.pers["economy_id"] != level.players[i].pers["economy_id"], "separate_player_wallets");
	if (!game["economy_test_failed"])
		logPrint("ECONOMY_TEST;PASSED\n");
}

check( condition, name )
{
	if (!condition)
	{
		game["economy_test_failed"] = true;
		logPrint("ECONOMY_TEST;FAILED;" + name + "\n");
		return false;
	}
	logPrint("ECONOMY_TEST;OK;" + name + "\n");
	return true;
}

cashSnapshot()
{
	result = [];
	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		entry = player promod\economy::account();
		result[player.pers["economy_id"]] = entry["cash"];
	}
	return result;
}

checkReward( before, team, name )
{
	valid = true;
	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		entry = player promod\economy::account();
		expected = before[player.pers["economy_id"]] + 50 * int(player.pers["team"] == team);
		if (entry["cash"] != expected)
			valid = false;
	}
	check(valid, name);
}

findPlayer( id )
{
	for (i = 0; i < level.players.size; i++)
		if (isDefined(level.players[i].pers["economy_id"]) && level.players[i].pers["economy_id"] == id)
			return level.players[i];
	return undefined;
}

teammates( player )
{
	result = [];
	for (i = 0; i < level.players.size; i++)
		if (level.players[i] != player && level.players[i].pers["team"] == player.pers["team"])
			result[result.size] = level.players[i];
	return result;
}

claimForCheck()
{
	entry = self.pers["economy_id"];
	game["economy"]["accounts"][entry]["demolitionTeam"] = self.pers["team"];
	self maps\mp\gametypes\_promod::setClassChoice("demolitions");
}

waitLive()
{
	deadline = getTime() + level.economyBuySeconds * 1000 + 10000;
	while (!level.economyLive)
	{
		if (getTime() >= deadline)
		{
			check(false, "live_deadline");
			return;
		}
		wait 0.1;
	}
	check(!level.economyBuyOpen, "buy_closed_before_live");
}

finishRound( nextStage )
{
	game["economy_test_stage"] = nextStage;
	maps\mp\gametypes\sd::sd_endGame("allies", game["strings"]["round_draw"]);
}
