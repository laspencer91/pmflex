// See LICENSE.md.

charges()
{
	if (!promod\economy::enabled() || !self promod\economy::hasTeam())
		return 0;
	entry = self promod\economy::account();
	if (!self promod\economy_items::itemsCurrent(entry) || !isDefined(entry["armor"]))
		return 0;
	return entry["armor"];
}

canBuy()
{
	return self promod\economy::canPurchase() &&
		self charges() < level.economyArmorCapacity && self promod\economy::canAfford("armor");
}

buy()
{
	blocker = self promod\economy::purchaseBlocker();
	if (blocker != "") return self result(blocker);
	self promod\economy::creditRound();
	if (self charges() >= level.economyArmorCapacity)
		return self result("owned");
	if (!self promod\economy::trySpendCash(promod\economy::price("armor"), "armor"))
		return self result("funds");
	entry = self promod\economy::account();
	entry["armor"] = self charges() + 1;
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
	self promod\repeat_buy::remember("armor", entry["armor"]);
	self promod\economy::publish();
	return self result("purchased");
}

refund()
{
	if (self charges() < 1) return self result("not_refundable");
	entry = self promod\economy::account();
	entry["armor"] = self charges() - 1;
	self promod\economy::saveAccount(entry);
	self promod\repeat_buy::remember("armor", entry["armor"]);
	result = self promod\economy_items::refundItem("armor");
	result["charges"] = entry["armor"];
	return result;
}

result( status )
{
	result = self promod\economy::purchaseResult(status, "armor");
	result["charges"] = self charges();
	return result;
}

protectDamage( damage, flags, meansOfDeath, attacker, weapon, hitloc )
{
	if (!promod\economy::realRound() || !level.economyLive || self.sessionstate != "playing" || damage <= 0 ||
		!(flags & level.iDFLAGS_PENETRATION) || (flags & level.iDFLAGS_NO_PROTECTION) ||
		(meansOfDeath != "MOD_RIFLE_BULLET" && meansOfDeath != "MOD_PISTOL_BULLET") ||
		self charges() < 1)
		return damage;
	if (isDefined(attacker) && isPlayer(attacker) && attacker != self &&
		attacker promod\economy_penetration::bypassesArmor(weapon, hitloc))
		return damage;
	entry = self promod\economy::account();
	entry["armor"]--;
	self promod\economy::saveAccount(entry);
	self promod\economy::publish();
	return int(max(1, damage * level.economyArmorDamageScale));
}
