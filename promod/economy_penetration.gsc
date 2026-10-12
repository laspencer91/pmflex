// See LICENSE.md.

eligible()
{
	if (!self promod\economy::hasTeam() || !isDefined(self.pers["class"]) || self.pers["class"] != "sniper")
		return false;
	weapon = self promod\economy_items::selectedWeapon();
	return (weapon == "m40a3" || weapon == "remington700") && getDvarInt("weap_allow_" + weapon);
}

owns()
{
	if (!promod\economy::enabled() || !self promod\economy::hasTeam())
		return false;
	entry = self promod\economy::account();
	return self promod\economy_items::itemsCurrent(entry) && isDefined(entry["sniperPenetration"]) && entry["sniperPenetration"];
}

canBuy()
{
	return self promod\economy::canPurchase() && self eligible() && !self owns() &&
		self promod\economy::canAfford("sniper_penetration");
}

buy()
{
	blocker = self promod\economy::purchaseBlocker();
	if (blocker != "") return self promod\economy::purchaseResult(blocker, "sniper_penetration");
	self promod\economy::creditRound();
	if (!self eligible())
		return self promod\economy::purchaseResult("unavailable", "sniper_penetration");
	if (self owns())
		return self promod\economy::purchaseResult("owned", "sniper_penetration");
	if (!self promod\economy::trySpendCash(promod\economy::price("sniper_penetration"), "sniper_penetration"))
		return self promod\economy::purchaseResult("funds", "sniper_penetration");
	entry = self promod\economy::account();
	entry["sniperPenetration"] = true;
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
	self promod\repeat_buy::remember("attachment", "sniper_penetration");
	self promod\economy::publish();
	return self promod\economy::purchaseResult("purchased", "sniper_penetration");
}

refund()
{
	if (!self owns()) return self promod\economy::purchaseResult("not_refundable", "sniper_penetration");
	entry = self promod\economy::account();
	entry["sniperPenetration"] = false;
	self promod\economy::saveAccount(entry);
	pref = self promod\repeat_buy::preferences();
	if (pref["attachment"] == "sniper_penetration") self promod\repeat_buy::remember("attachment", "none");
	return self promod\economy_items::refundItem("sniper_penetration");
}

bypassesArmor( weapon, hitloc )
{
	return isDefined(weapon) && isDefined(hitloc) && self owns() && (weapon == "m40a3_mp" || weapon == "remington700_mp") &&
		(hitloc == "torso_upper" || hitloc == "torso_lower");
}
