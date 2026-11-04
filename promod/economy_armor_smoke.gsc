// Dedicated validation only. See LICENSE.md.

check( condition, name )
{
	return promod\economy_smoke::check(condition, name);
}

actor()
{
	return promod\economy_items_smoke::actor();
}

setCharges( tester, charges )
{
	entry = tester promod\economy::account();
	entry["armor"] = charges;
	entry["itemsTeam"] = tester.pers["team"];
	tester promod\economy::saveAccount(entry);
}

buyChecks( player, stage )
{
	tester = actor();
	cash = tester promod\economy::cash();
	price = promod\economy::price("armor");
	if (stage == 0)
	{
		check(tester promod\economy_armor::charges() == 0 && price == 100, "armor_starts_empty_full_price");
		result = tester promod\economy::buyArmor();
		check(result["success"] && result["price"] == 100 && result["cash"] == cash - 100 && result["charges"] == 2, "armor_one_purchase_fills_both_charges");
		result = tester promod\economy::buyArmor();
		check(result["status"] == "owned" && !tester promod\economy_armor::canBuy() && tester promod\economy::cash() == cash - 100, "armor_full_vest_no_charge");
		result = tester promod\economy_items::refund("armor");
		check(result["status"] == "refunded" && tester promod\economy_armor::charges() == 0 && tester promod\economy::cash() == cash, "armor_refund_returns_purchase");
		tester notify("menuresponse", "economy", "buy_armor");
		wait 0.1;
		check(tester promod\economy_armor::charges() == 2 && tester promod\economy::cash() == cash - 100, "armor_command_purchase");
		check(tester promod\economy_armor::protectDamage(56, 0, "MOD_RIFLE_BULLET") == 56 &&
			tester promod\economy_armor::charges() == 2, "buy_phase_does_not_consume_armor");
		entry = tester promod\economy::account();
		saved = entry["cash"];
		entry["armor"] = 0;
		entry["cash"] = 99;
		tester promod\economy::saveAccount(entry);
		result = tester promod\economy::buyArmor();
		check(result["status"] == "funds" && result["cash"] == 99 && result["price"] == 100 && result["charges"] == 0, "armor_insufficient_funds_no_charge");
		entry = tester promod\economy::account();
		entry["armor"] = 2;
		entry["cash"] = saved + 100;
		tester promod\economy::saveAccount(entry);
		tester promod\economy::publish();
	}
	if (stage == 1)
	{
		check(tester promod\economy_armor::charges() == 2, "armor_kept_after_surviving_round");
		result = tester promod\economy_items::refund("armor");
		check(result["status"] == "not_refundable" && tester promod\economy_armor::charges() == 2, "kept_armor_not_refundable");
		setCharges(tester, 1);
		check(promod\economy_armor::cost(1) == 50, "armor_refill_half_price");
		result = tester promod\economy::buyArmor();
		check(result["success"] && result["price"] == 50 && tester promod\economy_armor::charges() == 2 && tester promod\economy::cash() == cash - 50, "armor_refill_one_charge");
		result = tester promod\economy_items::refund("armor");
		check(result["status"] == "refunded" && tester promod\economy_armor::charges() == 1 && tester promod\economy::cash() == cash, "armor_refill_refund_restores_one_charge");
		tester promod\economy::buyArmor();
		tester promod\economy::creditCash(50, "armor_test_restore");
		check(tester promod\economy_armor::charges() == 2, "armor_refilled_for_next_checks");
	}
	if (stage == 3)
		check(tester promod\economy_armor::charges() == 0, "armor_lost_on_death_not_carried");
}

stat( player, key )
{
	if (!isDefined(player.pers[key]))
		return 0;
	return player.pers[key];
}

damage( target, attacker, amount, flags, means, hitloc, weapon )
{
	if (!isDefined(weapon)) weapon = "m4_mp";
	before = target.health;
	target maps\mp\gametypes\_globallogic::Callback_PlayerDamage(attacker, attacker, amount, flags,
		means, weapon, target.origin, (1,0,0), hitloc, 0);
	logPrint("ECONOMY_TEST;ARMOR_DAMAGE;" + before + ";" + target.health + ";" + target.maxhealth + ";" +
		target promod\economy_armor::charges() + ";" + flags + ";" + means + ";" + hitloc + ";" + weapon + "\n");
}

liveChecks( player, stage )
{
	tester = actor();
	cash = tester promod\economy::cash();
	result = tester promod\economy::buyArmor();
	check(result["status"] == "closed" && tester promod\economy::cash() == cash, "live_armor_purchase_denied_" + stage);
	if (stage == 2)
	{
		check(tester promod\economy_armor::charges() == 0, "death_clears_armor");
		return;
	}
	if (stage != 0)
		return;
	attacker = undefined;
	mate = undefined;
	for (i = 0; i < level.players.size; i++)
	{
		if (level.players[i].sessionstate != "playing" || level.players[i] == tester)
			continue;
		if (level.players[i].pers["team"] != tester.pers["team"])
			attacker = level.players[i];
		else
			mate = level.players[i];
	}
	if (!check(isDefined(attacker) && isDefined(mate), "armor_damage_attacker"))
		return;
	pen = level.iDFLAGS_PENETRATION;
	check(tester promod\economy_armor::charges() == 2, "armor_live_with_two_charges");
	tester.health = tester.maxhealth;
	taken = stat(tester, "damage_taken");
	done = stat(attacker, "damage_done");
	damage(tester, attacker, 40, 0, "MOD_RIFLE_BULLET", "torso_upper");
	check(tester.health == tester.maxhealth - 28 && tester promod\economy_armor::charges() == 1, "direct_body_hit_halved_consumes_one");
	check(stat(tester, "damage_taken") == taken + 28 && stat(attacker, "damage_done") == done + 28, "armor_damage_stats_match_health");
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, 0, "MOD_RIFLE_BULLET", "head");
	check(tester.health == tester.maxhealth - 56 && tester promod\economy_armor::charges() == 1, "headshot_full_damage_keeps_armor");
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, pen, "MOD_RIFLE_BULLET", "helmet");
	check(tester.health == tester.maxhealth - 56 && tester promod\economy_armor::charges() == 1, "helmet_hit_full_damage_keeps_armor");
	tester.health = tester.maxhealth;
	damage(tester, attacker, 20, pen, "MOD_GRENADE_SPLASH", "none");
	check(tester.health == tester.maxhealth - 20 && tester promod\economy_armor::charges() == 1, "explosion_keeps_armor");
	tester.health = tester.maxhealth;
	damage(tester, attacker, 20, pen, "MOD_MELEE", "torso_upper");
	check(tester.health == tester.maxhealth - 20 && tester promod\economy_armor::charges() == 1, "melee_keeps_armor");
	tester.health = tester.maxhealth;
	// promod_reduced_frag (vote outcome): frags deal 65%, other explosives are unchanged.
	reduced = level.reducedFrag;
	level.reducedFrag = true;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "frag_grenade_mp");
	check(tester.health == tester.maxhealth - 26, "reduced_frag_damage");
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "frag_grenade_short_mp");
	check(tester.health == tester.maxhealth - 26, "reduced_short_frag_damage");
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "c4_mp");
	check(tester.health == tester.maxhealth - 40, "reduced_frag_leaves_c4");
	tester.health = tester.maxhealth;
	level.reducedFrag = false;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "frag_grenade_mp");
	check(tester.health == tester.maxhealth - 40, "normal_frag_damage");
	tester.health = tester.maxhealth;
	level.reducedFrag = reduced;
	ff = level.friendlyfire;
	level.friendlyfire = 0;
	damage(tester, mate, 40, 0, "MOD_RIFLE_BULLET", "torso_upper");
	check(tester.health == tester.maxhealth && tester promod\economy_armor::charges() == 1, "disabled_friendly_fire_keeps_armor");
	level.friendlyfire = ff;
	damage(tester, attacker, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
	check(tester.health == tester.maxhealth - 28 && tester promod\economy_armor::charges() == 0, "wallbang_body_hit_halved_consumes_last");
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, 0, "MOD_RIFLE_BULLET", "torso_upper");
	check(tester.health == tester.maxhealth - 56 && tester promod\economy_armor::charges() == 0, "spent_armor_full_damage");
	// Shotgun pellets of one blast (same attacker, weapon and server time) share one charge.
	setCharges(tester, 2);
	tester.health = tester.maxhealth;
	damage(tester, attacker, 20, 0, "MOD_PISTOL_BULLET", "torso_upper", "winchester1200_mp");
	damage(tester, attacker, 20, 0, "MOD_PISTOL_BULLET", "torso_lower", "winchester1200_mp");
	check(tester.health == tester.maxhealth - 28 && tester promod\economy_armor::charges() == 1, "shotgun_pellets_share_one_charge");
	wait 0.05;
	tester.health = tester.maxhealth;
	damage(tester, attacker, 20, 0, "MOD_PISTOL_BULLET", "torso_upper", "winchester1200_mp");
	check(tester.health == tester.maxhealth - 14 && tester promod\economy_armor::charges() == 0, "next_shotgun_blast_new_charge");
	setCharges(tester, 2);
	tester.health = tester.maxhealth;
	level.friendlyfire = 1;
	damage(tester, mate, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
	check(tester.health == tester.maxhealth - 28 && tester promod\economy_armor::charges() == 1, "enabled_friendly_fire_uses_armor");
	tester.health = tester.maxhealth;
	level.friendlyfire = 2;
	mateHealth = mate.health;
	damage(mate, tester, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
	mate.health = mateHealth;
	check(tester.health == tester.maxhealth - 14 && tester promod\economy_armor::charges() == 0, "reflected_friendly_fire_uses_recipient_armor");
	level.friendlyfire = ff;
	setCharges(tester, 1);
	check(tester promod\economy_armor::protectDamage(1, pen, "MOD_PISTOL_BULLET") == 1 &&
		tester promod\economy_armor::charges() == 0, "armor_integer_damage_minimum");
	// The vest carries into the next round while the tester survives.
	setCharges(tester, 2);
	tester.health = tester.maxhealth;
	tester promod\economy::publish();
}

seedHalf()
{
	tester = actor();
	if (tester promod\economy_armor::charges() < 2)
		tester promod\economy::buyArmor();
	check(tester promod\economy_armor::charges() == 2, "armor_before_halftime");
}

checkHalf()
{
	tester = actor();
	check(tester promod\economy_armor::charges() == 0, "halftime_clears_armor");
}
