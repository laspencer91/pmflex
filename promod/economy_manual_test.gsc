// Local validation only. See LICENSE.md.

enabled()
{
	return getDvarInt("economy_manual_test") && getDvar("net_ip") == "127.0.0.1" &&
		getDvar("dedicated") == "dedicated LAN server" && promod\economy::enabled();
}

findTarget()
{
	for (i = 0; i < level.players.size; i++)
		if (isDefined(level.players[i].pers["economy_manual_target"]))
			return level.players[i];
	return undefined;
}

waitForPlayer()
{
	level endon("game_ended");
	level endon("restarting");
	if (!enabled())
		return;
	for (;;)
	{
		for (i = 0; i < level.players.size; i++)
		{
			player = level.players[i];
			if (!isDefined(player.pers["economy_manual_target"]) && player promod\economy::hasTeam() &&
				isDefined(player.pers["class"]))
				return;
		}
		wait 0.1;
	}
}

run()
{
	level endon("restarting");
	if (!enabled())
		return;
	wait 3;
	target = findTarget();
	if (!isDefined(target))
	{
		deadline = getTime() + 5000;
		while (!isDefined(target) && getTime() < deadline)
		{
			target = addTestClient();
			if (!isDefined(target))
				wait 0.1;
		}
		if (!isDefined(target))
		{
			logPrint("LOCAL_ECONOMY_TEST;FAILED;target_connect\n");
			return;
		}
		target.pers["economy_manual_target"] = true;
		deadline = getTime() + 10000;
		while (!isDefined(target.hasSpawned) && getTime() < deadline)
			wait 0.05;
		if (!isDefined(target.hasSpawned))
		{
			logPrint("LOCAL_ECONOMY_TEST;FAILED;target_spawn\n");
			return;
		}
		target.pers["team"] = "axis";
		target.team = "axis";
		target.sessionteam = "axis";
		target maps\mp\gametypes\_promod::setClassChoice("assault");
		target maps\mp\gametypes\_promod::menuAcceptClass("go");
	}
	level.economyManualTarget = target;
	logPrint("LOCAL_ECONOMY_TEST;READY\n");
	if (getDvarInt("economy_manual_smoke"))
		level thread smoke();
	for (;;)
	{
		if (target.sessionstate == "playing")
		{
			target freezeControls(true);
			target disableWeapons();
			if (!isDefined(level.economyManualSpawnTime) || level.economyManualSpawnTime != target.spawnTime)
			{
				level.economyManualSpawnTime = target.spawnTime;
				if (isDefined(game["economy_manual_origin"]))
					target setOrigin(game["economy_manual_origin"]);
			}
		}
		if (promod\economy::buying() && target promod\economy_armor::canBuy())
		{
			target promod\economy::buyArmor();
			logPrint("LOCAL_ECONOMY_TEST;ARMOR;" + target promod\economy_armor::charges() + "\n");
		}
		wait 0.1;
	}
}

respond( command )
{
	if (!enabled() || !self promod\economy::hasTeam())
		return;
	target = level.economyManualTarget;
	if (!isDefined(target))
	{
		self iPrintLn("Armor target is connecting");
		return;
	}
	if (command == "target_here" && self.sessionstate == "playing")
	{
		game["economy_manual_origin"] = self.origin;
		if (target.sessionstate == "playing")
		{
			target setOrigin(self.origin);
			target.health = target.maxhealth;
		}
		self iPrintLn("Target position saved. Move to the other side of the wall");
	}
	else if (command == "next_round" && !level.gameEnded)
		thread maps\mp\gametypes\_globallogic::endGame("tie", game["strings"]["round_draw"]);
	else if (command == "status")
		self iPrintLn("Target health: " + max(0, target.health) + ". Armor: " + target promod\economy_armor::charges() +
			". Your cash: " + promod\economy::cashText(self promod\economy::cash()) +
			". Sniper penetration: " + int(self promod\economy_penetration::owns()));
}

reportDamage( attacker, damage, flags, hitloc )
{
	if (!enabled() || !isDefined(level.economyManualTarget) || self != level.economyManualTarget ||
		!isDefined(attacker) || !isPlayer(attacker) || attacker == self)
		return;
	type = "Direct hit";
	if (flags & level.iDFLAGS_PENETRATION)
		type = "Wall hit";
	attacker iPrintLn(type + " / " + hitloc + " / damage " + damage + " / health " + max(0, self.health) +
		" / armor " + self promod\economy_armor::charges());
	logPrint("LOCAL_ECONOMY_TEST;HIT;" + int((flags & level.iDFLAGS_PENETRATION) != 0) + ";" + hitloc + ";" + damage + "\n");
}

check( condition, name )
{
	if (!condition)
	{
		level.economyManualFailed = true;
		logPrint("LOCAL_ECONOMY_TEST;FAILED;" + name + "\n");
	}
	else
		logPrint("LOCAL_ECONOMY_TEST;OK;" + name + "\n");
	return condition;
}

smoke()
{
	level.economyManualFailed = false;
	check(game["LAN_MODE"] && !getDvarInt("g_antilag") && !getDvarInt("sv_punkbuster"), "lan_profile_matches_server_checks");
	setDvar("timescale", 5);
	if (isDefined(game["economy_manual_smoke_stage"]) && game["economy_manual_smoke_stage"] == 1)
	{
		deadline = getTime() + 10000;
		while (level.economyManualTarget promod\economy_armor::charges() != 2 && getTime() < deadline)
			wait 0.1;
		check(level.economyManualTarget promod\economy_armor::charges() == 2, "new_round_target_rebuys_armor");
		check(distance(level.economyManualTarget.origin, game["economy_manual_origin"]) < 32, "position_survives_round_restart");
		for (i = 0; i < level.players.size; i++)
			if (isDefined(level.players[i].pers["economy_manual_player"]))
				check(!level.players[i] promod\economy_penetration::owns(), "new_round_upgrade_expired");
		if (!level.economyManualFailed)
			logPrint("LOCAL_ECONOMY_TEST;PASSED\n");
		return;
	}
	player = addTestClient();
	if (!check(isDefined(player), "client_connect"))
		return;
	player.pers["economy_manual_player"] = true;
	deadline = getTime() + 10000;
	while (!isDefined(player.hasSpawned) && getTime() < deadline)
		wait 0.05;
	if (!check(isDefined(player.hasSpawned), "client_spawn"))
		return;
	check(!promod\economy::buying(), "buy_waits_for_player_team");
	player notify("menuresponse", game["menu_team"], "allies");
	deadline = getTime() + 10000;
	while ((!isDefined(player.pers["class"]) || player.sessionstate != "playing") && getTime() < deadline)
		wait 0.1;
	check(isDefined(player.pers["class"]) && player.pers["class"] == "assault" &&
		player.sessionstate == "playing" && player hasWeapon("ak47_mp"), "team_join_defaults_to_playable_assault");
	check(level.economyBuySeconds == 30 && isDefined(level.economyBuyLabel) &&
		level.economyBuyLabel.hideWhenInMenu && level.economyBuyTimer.hideWhenInMenu, "thirty_seconds_and_hidden_buy_hud");
	check(isDefined(player.economyCashHud) && player.economyCashHud.hideWhenInMenu, "player_cash_hud_created");
	player maps\mp\gametypes\_promod::setClassChoice("sniper");
	deadline = getTime() + 10000;
	while ((!promod\economy::buying() || level.economyManualTarget promod\economy_armor::charges() != 2) && getTime() < deadline)
		wait 0.1;
	check(level.economyManualTarget promod\economy_armor::charges() == 2 &&
		level.economyManualTarget promod\economy::cash() == 0, "target_buys_two_with_round_income");
	player notify("menuresponse", "economy", "buy_sniper_penetration");
	wait 0.1;
	check(player promod\economy_penetration::owns() && player promod\economy::cash() == 0, "client_purchase_route");
	deadline = getTime() + 10000;
	while (player.sessionstate != "playing" && getTime() < deadline)
		wait 0.1;
	check(player.sessionstate == "playing", "client_playing");
	player notify("menuresponse", "economy", "local_test:target_here");
	wait 0.1;
	check(isDefined(game["economy_manual_origin"]) && distance(level.economyManualTarget.origin, game["economy_manual_origin"]) < 32, "position_command_route");
	deadline = getTime() + level.economyBuySeconds * 1000 + 10000;
	while (!level.economyLive && getTime() < deadline)
		wait 0.1;
	check(level.economyLive, "live_round");
	level.economyManualTarget maps\mp\gametypes\_globallogic::Callback_PlayerDamage(player, player, 40,
		level.iDFLAGS_PENETRATION, "MOD_RIFLE_BULLET", "m40a3_mp", level.economyManualTarget.origin, (1,0,0), "torso_upper", 0);
	check(level.economyManualTarget.health == level.economyManualTarget.maxhealth - 56 &&
		level.economyManualTarget promod\economy_armor::charges() == 2, "torso_bypass_and_reporting");
	player notify("menuresponse", "economy", "local_test:status");
	wait 0.1;
	game["economy_manual_smoke_stage"] = 1;
	player notify("menuresponse", "economy", "local_test:next_round");
	wait 0.1;
	check(level.gameEnded, "next_round_command_route");
}
