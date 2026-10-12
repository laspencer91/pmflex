// Dedicated validation only. See LICENSE.md.

check( condition, name )
{
	return promod\economy_smoke::check(condition, name);
}

actor()
{
	return promod\economy_items_smoke::actor();
}

buyChecks( player, stage )
{
	tester = actor();
	cash = tester promod\economy::cash();
	check(tester promod\economy_armor::charges() == 0, "armor_starts_empty_round_" + stage);
	if (stage == 0 || stage == 1 || stage == 2)
	{
		result = tester promod\economy::buyArmor();
		check(result["success"] && result["price"] == 50 && result["cash"] == cash - 50 && result["charges"] == 1, "armor_first_slot_" + stage);
		tester notify("menuresponse", "economy", "buy_armor");
		wait 0.1;
		check(tester promod\economy_armor::charges() == 2 && tester promod\economy::cash() == cash - 100, "armor_second_slot_command_" + stage);
		result = tester promod\economy::buyArmor();
		check(result["status"] == "owned" && !tester promod\economy_armor::canBuy() &&
			tester promod\economy::cash() == cash - 100, "armor_capacity_no_charge_" + stage);
		check(tester promod\economy_armor::protectDamage(56, level.iDFLAGS_PENETRATION, "MOD_RIFLE_BULLET") == 56 &&
			tester promod\economy_armor::charges() == 2, "buy_phase_does_not_consume_armor_" + stage);
		tester promod\economy::creditCash(100, "armor_test_restore");
	}
	if (stage == 0)
	{
		entry = tester promod\economy::account();
		entry["armor"] = 0;
		entry["cash"] = 49;
		tester promod\economy::saveAccount(entry);
		result = tester promod\economy::buyArmor();
		check(result["status"] == "funds" && result["cash"] == 49 && result["charges"] == 0, "armor_insufficient_funds_no_charge");
		entry["armor"] = 2;
		entry["cash"] = cash;
		tester promod\economy::saveAccount(entry);
		tester promod\economy::publish();
	}
}

damage( target, attacker, amount, flags, means, hitloc, weapon )
{
	if (!isDefined(weapon)) weapon = "m4_mp";
	before = target.health;
	target maps\mp\gametypes\_globallogic::Callback_PlayerDamage(attacker, attacker, amount, flags,
		means, weapon, target.origin, (1,0,0), hitloc, 0);
	logPrint("ECONOMY_TEST;ARMOR_DAMAGE;" + before + ";" + target.health + ";" + target.maxhealth + ";" +
		target promod\economy_armor::charges() + ";" + flags + ";" + means + "\n");
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
	if (stage != 0 && stage != 1)
		return;
	attacker = undefined;
	for (i = 0; i < level.players.size; i++)
		if (level.players[i].sessionstate == "playing" && level.players[i].pers["team"] != tester.pers["team"])
			attacker = level.players[i];
	if (!check(isDefined(attacker), "armor_damage_attacker"))
		return;
	pen = level.iDFLAGS_PENETRATION;
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, 0, "MOD_RIFLE_BULLET", "torso_upper");
	check(tester.health == tester.maxhealth - 56 && tester promod\economy_armor::charges() == 2, "direct_bullet_full_damage_keeps_armor_" + stage);
	tester.health = tester.maxhealth;
	damage(tester, attacker, 20, pen, "MOD_GRENADE_SPLASH", "none");
	check(tester.health == tester.maxhealth - 20 && tester promod\economy_armor::charges() == 2, "explosion_keeps_armor_" + stage);
	tester.health = tester.maxhealth;
	damage(tester, attacker, 20, pen, "MOD_MELEE", "torso_upper");
	check(tester.health == tester.maxhealth - 20 && tester promod\economy_armor::charges() == 2, "melee_keeps_armor_" + stage);
	tester.health = tester.maxhealth;
	// promod_reduced_frag (vote outcome): frags deal 65%, other explosives are unchanged.
	reduced = level.reducedFrag;
	level.reducedFrag = true;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "frag_grenade_mp");
	check(tester.health == tester.maxhealth - 26, "reduced_frag_damage_" + stage);
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "frag_grenade_short_mp");
	check(tester.health == tester.maxhealth - 26, "reduced_short_frag_damage_" + stage);
	tester.health = tester.maxhealth;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "c4_mp");
	check(tester.health == tester.maxhealth - 40, "reduced_frag_leaves_c4_" + stage);
	tester.health = tester.maxhealth;
	level.reducedFrag = false;
	damage(tester, attacker, 40, 0, "MOD_GRENADE_SPLASH", "none", "frag_grenade_mp");
	check(tester.health == tester.maxhealth - 40, "normal_frag_damage_" + stage);
	tester.health = tester.maxhealth;
	level.reducedFrag = reduced;
	ff = level.friendlyfire;
	level.friendlyfire = 0;
	damage(tester, player, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
	check(tester.health == tester.maxhealth && tester promod\economy_armor::charges() == 2, "disabled_friendly_fire_keeps_armor_" + stage);
	level.friendlyfire = ff;
	if (stage == 1)
	{
		taken = tester.pers["damage_taken"];
		done = attacker.pers["damage_done"];
		damage(tester, attacker, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
		check(tester.health == tester.maxhealth - 14 && tester promod\economy_armor::charges() == 1, "first_wall_shot_reduced_consumes_one");
		check(tester.pers["damage_taken"] == taken + 14 && attacker.pers["damage_done"] == done + 14, "armor_damage_stats_match_health");
		tester.health = tester.maxhealth;
		damage(tester, attacker, 40, pen, "MOD_RIFLE_BULLET", "head");
		check(tester.health == tester.maxhealth - 56 && tester promod\economy_armor::charges() == 1, "penetrating_headshot_full_damage_keeps_armor");
		tester.health = tester.maxhealth;
		damage(tester, attacker, 40, pen, "MOD_RIFLE_BULLET", "helmet");
		check(tester.health == tester.maxhealth - 56 && tester promod\economy_armor::charges() == 1, "penetrating_helmet_hit_full_damage_keeps_armor");
		tester.health = tester.maxhealth;
		damage(tester, attacker, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
		check(tester.health == tester.maxhealth - 14 && tester promod\economy_armor::charges() == 0, "second_wall_body_shot_consumes_last_armor");
		tester.health = tester.maxhealth;
		damage(tester, attacker, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
		check(tester.health == tester.maxhealth - 56 && tester promod\economy_armor::charges() == 0, "third_wall_shot_full_damage");
		entry = tester promod\economy::account();
		entry["armor"] = 2;
		tester promod\economy::saveAccount(entry);
		tester.health = tester.maxhealth;
		level.friendlyfire = 1;
		damage(tester, player, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
		check(tester.health == tester.maxhealth - 14 && tester promod\economy_armor::charges() == 1, "enabled_friendly_fire_uses_armor");
		tester.health = tester.maxhealth;
		level.friendlyfire = 2;
		damage(player, tester, 40, pen, "MOD_RIFLE_BULLET", "torso_upper");
		check(tester.health == tester.maxhealth - 7 && tester promod\economy_armor::charges() == 0, "reflected_friendly_fire_uses_recipient_armor");
		level.friendlyfire = ff;
		entry["armor"] = 1;
		tester promod\economy::saveAccount(entry);
		check(tester promod\economy_armor::protectDamage(7, pen, "MOD_PISTOL_BULLET") == 1 &&
			tester promod\economy_armor::charges() == 0, "armor_integer_damage_minimum");
	}
	tester.health = tester.maxhealth;
}

seedHalf()
{
	tester = actor();
	tester promod\economy::buyArmor();
	tester promod\economy::buyArmor();
	check(tester promod\economy_armor::charges() == 2, "armor_before_halftime");
}

checkHalf()
{
	tester = actor();
	check(tester promod\economy_armor::charges() == 0, "halftime_clears_armor");
}
