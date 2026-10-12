// Dedicated integration checks; prepared balances restored for the economy suite.
check( condition, name )
{
	return promod\economy_smoke::check(condition, "combined_" + name);
}

run( player )
{
	check(game["LAN_MODE"] && !getDvarInt("sv_punkbuster") && !getDvarInt("g_antilag"), "local_profile_matches_disabled_punkbuster");
	mates = promod\economy_smoke::teammates(player);
	tester = mates[2];
	mate = mates[0];
	original = tester promod\economy::account();
	mateOriginal = mate promod\economy::account();
	tester promod\economy::creditCash(550, "combined_fixture");
	cash = tester promod\economy::cash();
	mateCash = mate promod\economy::cash();
	tester.pers["assault"]["loadout_primary"] = "m4";
	tester.pers["assault"]["loadout_primary_attachment"] = "silencer";
	tester maps\mp\gametypes\_promod::initClassLoadouts();
	check(tester.pers["assault"]["loadout_primary_attachment"] == "none", "unpaid_saved_suppressor_cleared");
	tester promod\flat_loadout::respond("open");
	check(tester.flatMenuOpen, "shortcut_opens");
	tester promod\flat_loadout::respond("closed");
	check(!tester.flatMenuOpen, "escape_closes");
	tester promod\flat_loadout::respond("open");
	check(tester.flatMenuOpen, "shortcut_reopens");
	check(tester.sessionstate == "playing" && isAlive(tester) && tester promod\economy::canPurchase(), "frozen_spawned_player_can_purchase");
	inactivePurchaseChecks(tester);
	tester notify("menuresponse", "changeclass_mw", "loadout_primary_attachment:assault");
	wait 0.1;
	tester notify("menuresponse", "changeclass_mw", "loadout_secondary_attachment:pistol");
	wait 0.1;
	tester notify("menuresponse", "changeclass_mw", "loadout_primary:ak47");
	deadline = getTime() + 2000;
	while (tester.pers["assault"]["loadout_primary"] != "ak47" && getTime() < deadline) wait 0.05;
	check(tester.pers["assault"]["loadout_primary"] == "ak47" && tester.pers["assault"]["loadout_primary_attachment"] == "none", "menu_handler_survives_malformed_attachment");
	tester promod\flat_loadout::respond("primary:m4");
	tester promod\flat_loadout::respond("attachment:silencer");
	check(tester promod\economy::cash() == cash - 50 && tester promod\economy_items::ownsSuppressor("primary") &&
		tester.pers["assault"]["loadout_primary_attachment"] == "silencer", "suppressor_purchase");
	tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
	check(tester hasWeapon("m4_silencer_mp"), "paid_suppressor_native_grant");
	tester promod\flat_loadout::respond("attachment:none");
	check(tester promod\economy::cash() == cash && !tester promod\economy_items::ownsSuppressor("primary"), "suppressor_none_refunds");
	tester promod\flat_loadout::respond("attachment:silencer");
	check(tester promod\economy::cash() == cash - 50 && tester promod\economy_items::ownsSuppressor("primary"), "suppressor_rebuy_after_refund");
	tester promod\flat_loadout::respond("primary:ak47");
	check(tester.pers["assault"]["loadout_primary_attachment"] == "silencer" && tester promod\economy_items::ownsSuppressor("primary") &&
		tester promod\economy::cash() == cash - 50, "suppressor_follows_rifle_change");
	tester promod\flat_loadout::respond("primary:m4");
	tester promod\flat_loadout::respond("attachment:silencer");
	check(tester promod\economy::cash() == cash - 50, "purchased_gun_suppressor_can_be_reequipped");
	tester maps\mp\gametypes\_promod::processLoadoutResponse("loadout_grenade:smoke_grenade,loadout_camo:camo_tigerred");
	check(tester.pers["assault"]["loadout_grenade"] == "smoke_grenade" && tester.pers["assault"]["loadout_camo"] == "camo_tigerred", "bundled_grenade_and_camo_apply");
	pistolSuppressorChecks(tester);
	tester promod\flat_loadout::respond("attachment:reflex");
	check(tester promod\economy::cash() == cash - 100 && tester.pers["assault"]["loadout_primary_attachment"] == "reflex" &&
		!tester promod\economy_items::ownsSuppressor("primary"), "red_dot_purchase_refunds_replaced_suppressor");
	frag = promod\economy::price("frag");
	check(frag == 100, "frag_price_100");
	tester promod\flat_loadout::respond("preview_frag");
	check(tester promod\economy_items::ownsFrag() && tester promod\economy::cash() == cash - 100 - frag, "frag_purchase");
	tester promod\flat_loadout::respond("preview_frag");
	check(tester promod\economy::cash() == cash - 100 - frag, "frag_duplicate_no_charge");
	tester promod\flat_loadout::respond("refund_frag");
	check(!tester promod\economy_items::ownsFrag() && !tester hasWeapon("frag_grenade_mp") && tester promod\economy::cash() == cash - 100, "frag_refund");
	tester promod\flat_loadout::respond("refund_frag");
	check(tester promod\economy::cash() == cash - 100, "frag_double_refund_denied");
	tester promod\flat_loadout::respond("preview_frag");
	check(tester promod\economy_items::ownsFrag() && tester getWeaponAmmoClip("frag_grenade_mp") == 1 && tester promod\economy::cash() == cash - 100 - frag, "frag_rebuy_after_refund");
	check(!tester promod\economy::giveCash(tester), "self_gift_denied");
	tester promod\flat_loadout::respond("give:" + mate promod\flat_loadout::donationToken());
	check(tester promod\economy::cash() == cash - 150 - frag && mate promod\economy::cash() == mateCash + 50, "transfer_conserves_cash");
	staleDonationChecks(tester, mate, mates[1]);
	tester promod\flat_loadout::respond("select:demolitions");
	check(tester.flatDemoPending && tester promod\economy::cash() == cash - 150 - frag, "demo_waits_confirmation");
	spawnTime = tester.spawnTime;
	tester promod\flat_loadout::respond("confirm_demolition");
	// Demolitions cannot use the red dot, so the class change refunds it.
	check(tester promod\economy::ownsDemolition() && tester promod\economy::cash() == cash - 350 - frag &&
		tester.flatMenuOpen && tester.spawnTime == spawnTime, "demo_keeps_menu_without_respawn");
	check(!tester promod\economy_items::ownsRedDot("m4"), "class_change_refunds_unusable_red_dot");
	tester promod\flat_loadout::respond("deploy");
	check(tester.curClass == "demolitions" && !tester.flatMenuOpen && tester.spawnTime == spawnTime, "deploy_applies_without_respawn");
	refundChecks(tester);
	level.economyBuyOpen = false;
	result = tester promod\economy_items::buySuppressor("secondary");
	check(result["status"] == "closed" && !tester promod\economy::giveCash(mate), "closed_phase_denies_spending");
	level.economyBuyOpen = true;
	tester promod\economy::saveAccount(original);
	mate promod\economy::saveAccount(mateOriginal);
	tester maps\mp\gametypes\_promod::setClassChoice("assault");
	tester.pers["assault"]["loadout_primary_attachment"] = "none";
	tester maps\mp\gametypes\_class::giveLoadout("allies", "assault");
	tester promod\economy::freezeForBuy();
	logPrint("COMBINED_TEST;CHECKS_COMPLETED\n");
}

pistolSuppressorChecks(player)
{
	class = player.pers["class"];
	pistol = player.pers[class]["loadout_secondary"];
	cash = player promod\economy::cash();
	player promod\economy::creditCash(50, "pistol_fixture");
	player promod\flat_loadout::respond("secondary:usp");
	player promod\flat_loadout::respond("pistol_attachment:silencer");
	player promod\flat_loadout::respond("secondary:usp");
	check(player.pers[class]["loadout_secondary_attachment"] == "silencer" && player promod\economy::cash() == cash,
		"owned_pistol_suppressor_retained_when_reselecting");
	player promod\flat_loadout::respond("secondary:beretta");
	check(player.pers[class]["loadout_secondary_attachment"] == "silencer" && player promod\economy::cash() == cash, "pistol_suppressor_follows_pistol_change");
	player promod\flat_loadout::respond("secondary:deserteagle");
	check(player.pers[class]["loadout_secondary_attachment"] == "none" && !player promod\economy_items::ownsSuppressor("secondary") &&
		player promod\economy::cash() == cash + 50, "pistol_suppressor_refunded_on_deagle");
	player promod\economy::trySpendCash(50, "pistol_fixture_restore");
	player promod\flat_loadout::respond("secondary:" + pistol);
}

inactivePurchaseChecks(player)
{
	session = player.sessionstate;
	cash = player promod\economy::cash();
	states = strTok("dead,spectator", ",");
	for (i = 0; i < states.size; i++)
	{
		player.sessionstate = states[i];
		frag = player promod\economy::buyFrag();
		redDot = player promod\economy::buyRedDot();
		armor = player promod\economy::buyArmor();
		penetration = player promod\economy::buySniperPenetration();
		suppressor = player promod\economy_items::buySuppressor("primary");
		demo = player promod\economy::buyDemolition();
		check(frag["status"] == "inactive" && redDot["status"] == "inactive" && armor["status"] == "inactive" &&
			penetration["status"] == "inactive" && suppressor["status"] == "inactive" && demo["status"] == "inactive" &&
			player promod\economy::cash() == cash && !player promod\economy::canPurchase(), states[i] + "_purchases_denied_without_spending");
	}
	player.sessionstate = session;
}

staleDonationChecks(sender, recipient, replacement)
{
	token = recipient promod\flat_loadout::donationToken();
	check(getDvar("sv_serverid") != "" && isSubStr(token, "player_" + getDvar("sv_serverid") + "_"), "donation_token_includes_server_epoch");
	cash = sender promod\economy::cash();
	replacementCash = replacement promod\economy::cash();
	team = recipient.pers["team"];
	recipient.pers["team"] = "spectator";
	sender promod\flat_loadout::refresh();
	sender promod\flat_loadout::respond("give:" + token);
	check(sender promod\economy::cash() == cash && replacement promod\economy::cash() == replacementCash,
		"stale_donation_rejected_after_team_change");
	recipient.pers["team"] = team;
	originalToken = recipient.flatDonationToken;
	recipient.flatDonationToken = undefined;
	reconnectedToken = recipient promod\flat_loadout::donationToken();
	sender promod\flat_loadout::respond("give:" + token);
	check(reconnectedToken != token && sender promod\economy::cash() == cash, "stale_donation_rejected_after_connection_replacement");
	recipient.flatDonationToken = originalToken;
	sender promod\flat_loadout::respond("give:1");
	check(sender promod\economy::cash() == cash, "legacy_donation_index_rejected");
	sender promod\flat_loadout::refresh();
}

closedRoundChecks( player )
{
	mates = promod\economy_smoke::teammates(player);
	tester = mates[2];
	cash = tester promod\economy::cash();
	curClass = tester.curClass;
	spawnTime = tester.spawnTime;
	tester promod\flat_loadout::respond("open");
	tester promod\flat_loadout::respond("select:specops");
	check(tester.pers["class"] == "specops" && tester.curClass == curClass && tester.spawnTime == spawnTime,
		"live_class_change_queued_without_respawn");
	tester promod\flat_loadout::respond("attachment:silencer");
	tester promod\flat_loadout::respond("preview_frag");
	tester promod\flat_loadout::respond("buy_armor");
	tester promod\flat_loadout::respond("buy_sniper_penetration");
	check(tester promod\economy::cash() == cash && !tester promod\economy_items::ownsSuppressor("primary") &&
		!tester promod\economy_items::ownsFrag() && tester promod\economy_armor::charges() == 0 &&
		!tester promod\economy_penetration::owns(), "live_menu_purchase_paths_denied");
	tester promod\flat_loadout::respond("select:assault");
	tester promod\flat_loadout::respond("closed");
}

refundChecks( player )
{
	player promod\economy::creditCash(200, "refund_fixture");
	cash = player promod\economy::cash();
	player promod\flat_loadout::respond("buy_armor");
	player promod\flat_loadout::respond("buy_armor");
	player promod\flat_loadout::respond("refund_armor");
	check(player promod\economy_armor::charges() == 1 && player promod\economy::cash() == cash - 50, "armor_refund_one_charge");
	player promod\flat_loadout::respond("refund_armor");
	player promod\flat_loadout::respond("refund_armor");
	check(player promod\economy_armor::charges() == 0 && player promod\economy::cash() == cash, "armor_refund_stops_at_zero");
	entry = player promod\economy::account();
	entry["fragRound"] = game["roundsplayed"] - 1;
	player promod\economy::saveAccount(entry);
	player promod\flat_loadout::respond("refund_frag");
	check(player promod\economy_items::ownsFrag() && player promod\economy::cash() == cash, "carried_frag_not_refundable");
	entry = player promod\economy::account();
	entry["fragRound"] = game["roundsplayed"];
	player promod\economy::saveAccount(entry);
	level.economyBuyOpen = false;
	player promod\flat_loadout::respond("refund_frag");
	level.economyBuyOpen = true;
	check(player promod\economy_items::ownsFrag() && player promod\economy::cash() == cash, "refund_denied_after_buy_closes");
	class = player.pers["class"];
	player.pers["class"] = "sniper";
	player.pers["sniper"]["loadout_primary"] = "m40a3";
	player promod\flat_loadout::respond("buy_sniper_penetration");
	player promod\flat_loadout::respond("refund_sniper_penetration");
	check(!player promod\economy_penetration::owns() && player promod\economy::cash() == cash, "sniper_upgrade_refund");
	player promod\flat_loadout::respond("buy_sniper_penetration");
	player.pers["class"] = class;
	player promod\economy_items::refundUnused();
	check(!player promod\economy_penetration::owns() && player promod\economy::cash() == cash, "class_change_refunds_sniper_upgrade");
}
