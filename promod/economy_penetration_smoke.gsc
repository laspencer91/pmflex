// Dedicated validation only. See LICENSE.md.

check( condition, name )
{
	return promod\economy_smoke::check(condition, name);
}

actor()
{
	return promod\economy_items_smoke::actor();
}

selectSniper( weapon )
{
	self maps\mp\gametypes\_promod::setClassChoice("sniper");
	self.pers["sniper"]["loadout_primary"] = weapon;
}

buyChecks( player, stage )
{
	buyer = actor();
	check(!buyer promod\economy_penetration::owns(), "sniper_penetration_empty_round_" + stage);
	if (stage > 2)
		return;
	cash = buyer promod\economy::cash();
	class = buyer.pers["class"];
	result = buyer promod\economy::buySniperPenetration();
	check(result["status"] == "unavailable" && buyer promod\economy::cash() == cash, "non_sniper_purchase_denied_" + stage);
	buyer selectSniper("m40a3");
	price = promod\economy::price("sniper_penetration");
	original = cash;
	entry = buyer promod\economy::account();
	entry["cash"] = price - 1;
	buyer promod\economy::saveAccount(entry);
	result = buyer promod\economy::buySniperPenetration();
	check(result["status"] == "funds" && result["cash"] == price - 1 && !buyer promod\economy_penetration::owns(), "sniper_penetration_funds_denied_" + stage);
	// The upgrade costs more than one round's income: fund it here and restore the balance at the end.
	cash = original + price;
	entry["cash"] = cash;
	buyer promod\economy::saveAccount(entry);
	setDvar("weap_allow_m40a3", 0);
	result = buyer promod\economy::buySniperPenetration();
	check(result["status"] == "unavailable" && result["cash"] == cash, "disabled_sniper_purchase_denied_" + stage);
	setDvar("weap_allow_m40a3", 1);
	buyer notify("menuresponse", "economy", "buy_sniper_penetration");
	wait 0.1;
	check(buyer promod\economy_penetration::owns() && buyer promod\economy::cash() == cash - 150 &&
		price == 150, "sniper_penetration_command_exact_price_" + stage);
	result = buyer promod\economy::buySniperPenetration();
	check(result["status"] == "owned" && result["cash"] == cash - 150 && !buyer promod\economy_penetration::canBuy(), "duplicate_sniper_penetration_no_charge_" + stage);
	buyer maps\mp\gametypes\_promod::setClassChoice(class);
	check(!buyer promod\economy_penetration::owns() && buyer promod\economy::cash() == cash, "class_change_refunds_sniper_penetration_" + stage);
	entry = buyer promod\economy::account();
	entry["cash"] = original;
	buyer promod\economy::saveAccount(entry);
}

grantUpgrade()
{
	entry = self promod\economy::account();
	entry["sniperPenetration"] = true;
	entry["itemsRound"] = game["roundsplayed"];
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
}

setArmor( count )
{
	entry = self promod\economy::account();
	entry["armor"] = count;
	entry["itemsRound"] = game["roundsplayed"];
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
}

damage( victim, attacker, amount, flags, weapon, hitloc )
{
	victim maps\mp\gametypes\_globallogic::Callback_PlayerDamage(attacker, attacker, amount, flags,
		"MOD_RIFLE_BULLET", weapon, victim.origin, (1,0,0), hitloc, 0);
}

liveChecks( player, stage )
{
	buyer = actor();
	cash = buyer promod\economy::cash();
	result = buyer promod\economy::buySniperPenetration();
	check(result["status"] == "closed" && result["cash"] == cash, "live_sniper_penetration_purchase_denied_" + stage);
	if (stage == 2)
	{
		check(!buyer promod\economy_penetration::owns(), "death_clears_sniper_penetration");
		return;
	}
	if (stage != 1)
		return;
	victim = undefined;
	for (i = 0; i < level.players.size; i++)
		if (level.players[i].sessionstate == "playing" && level.players[i].pers["team"] != buyer.pers["team"])
			victim = level.players[i];
	if (!check(isDefined(victim), "sniper_penetration_damage_target"))
		return;
	// Leaving the sniper class refunds the upgrade, so the bypass checks own it directly.
	buyer grantUpgrade();
	pen = level.iDFLAGS_PENETRATION;
	weapons = strTok("m40a3_mp,remington700_mp", ",");
	for (i = 0; i < weapons.size; i++)
	{
		locations = strTok("torso_upper,torso_lower,left_arm_upper,right_arm_lower,left_hand,right_leg_upper,left_leg_lower,right_foot,neck", ",");
		for (j = 0; j < locations.size; j++)
		{
			victim setArmor(2);
			victim.health = victim.maxhealth;
			damage(victim, buyer, 40, pen, weapons[i], locations[j]);
			bypass = j < 2;
			expected = 14;
			charges = 1;
			if (bypass)
			{
				expected = 56;
				charges = 2;
			}
			check(victim.health == victim.maxhealth - expected && victim promod\economy_armor::charges() == charges,
				"sniper_penetration_location_" + weapons[i] + "_" + locations[j]);
		}
	}
	victim setArmor(2);
	victim.health = victim.maxhealth;
	damage(victim, buyer, 40, pen, "m4_mp", "torso_upper");
	check(victim.health == victim.maxhealth - 14 && victim promod\economy_armor::charges() == 1, "sniper_upgrade_cannot_bypass_with_rifle");
	victim setArmor(2);
	victim.health = victim.maxhealth;
	damage(victim, buyer, 40, 0, "m40a3_mp", "torso_upper");
	check(victim.health == victim.maxhealth - 56 && victim promod\economy_armor::charges() == 2, "sniper_direct_hit_full_damage_no_consumption");
	victim setArmor(0);
	victim.health = victim.maxhealth;
	damage(victim, buyer, 40, pen, "m40a3_mp", "left_hand");
	check(victim.health == victim.maxhealth - 56, "unarmored_limb_full_damage");
	entry = buyer promod\economy::account();
	entry["sniperPenetration"] = false;
	buyer promod\economy::saveAccount(entry);
	victim setArmor(2);
	victim.health = victim.maxhealth;
	damage(victim, buyer, 80, pen, "m40a3_mp", "torso_upper");
	check(victim.health == victim.maxhealth - 28 && victim promod\economy_armor::charges() == 1, "unpaid_sniper_torso_armor_stops_lethal_hit");
	entry["sniperPenetration"] = true;
	buyer promod\economy::saveAccount(entry);
	victim setArmor(2);
	victim.health = victim.maxhealth;
	damage(victim, buyer, 80, pen, "m40a3_mp", "torso_upper");
	wait 0.2;
	check(victim.sessionstate == "dead", "paid_sniper_torso_allows_lethal_hit");
}

seedHalf()
{
	buyer = actor();
	class = buyer.pers["class"];
	buyer selectSniper("remington700");
	if (buyer promod\economy::cash() < promod\economy::price("sniper_penetration"))
		buyer promod\economy::creditCash(promod\economy::price("sniper_penetration"), "penetration_fixture");
	result = buyer promod\economy::buySniperPenetration();
	check(result["success"] && buyer promod\economy_penetration::owns(), "sniper_penetration_before_halftime");
	buyer maps\mp\gametypes\_promod::setClassChoice(class);
	buyer grantUpgrade();
}

checkHalf()
{
	buyer = actor();
	check(!buyer promod\economy_penetration::owns(), "halftime_clears_sniper_penetration");
}
