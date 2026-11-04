// See LICENSE.md.

// Armor takes promod_armor_absorb percent (default 50) off the next two body hits from bullets, through a
// wall or not. Headshots, explosives, melee and falls pass through. It lasts until death or until both
// charges are spent.
charges()
{
	if (!promod\economy::enabled() || !self promod\economy::hasTeam())
		return 0;
	entry = self promod\economy::account();
	if (!isDefined(entry["armor"]) || entry["itemsTeam"] != self.pers["team"])
		return 0;
	return entry["armor"];
}

// One purchase fills both charges; with one charge left it refills the spent one for half the price.
cost( charges )
{
	if (charges > 0)
		return int(promod\economy::price("armor") / 2);
	return promod\economy::price("armor");
}

canBuy( charges )
{
	if (!isDefined(charges))
		charges = self charges();
	return self promod\economy::canPurchase() && charges < level.economyArmorCapacity &&
		self promod\economy::cash() >= cost(charges);
}

buy()
{
	blocker = self promod\economy::purchaseBlocker();
	if (blocker != "") return self result(blocker);
	self promod\economy::creditRound();
	before = self charges();
	if (before >= level.economyArmorCapacity)
		return self result("owned");
	price = cost(before);
	if (!self promod\economy::trySpendCash(price, "armor"))
		return self result("funds", price);
	// A purchase always fills the vest, so a buy phase holds at most one refundable purchase.
	entry = self promod\economy::account();
	entry["armorPaid"] = price;
	entry["armorBefore"] = before;
	entry["armorPaidRound"] = game["roundsplayed"];
	entry["armor"] = level.economyArmorCapacity;
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
	self promod\repeat_buy::remember("armor", level.economyArmorCapacity);
	self promod\economy::publish();
	return self result("purchased", price);
}

// Only this buy phase's purchase is refundable: it returns what was paid and the charges held before it.
refund()
{
	entry = self promod\economy::account();
	if (self charges() < 1 || entry["armorPaidRound"] != game["roundsplayed"] || entry["armorPaid"] <= 0)
		return self result("not_refundable");
	paid = entry["armorPaid"];
	entry["armor"] = entry["armorBefore"];
	entry["armorPaid"] = 0;
	self promod\economy::saveAccount(entry);
	self promod\repeat_buy::remember("armor", entry["armor"]);
	result = self promod\economy_items::refundItem("armor", paid);
	result["price"] = paid;
	result["charges"] = entry["armor"];
	return result;
}

result( status, price )
{
	result = self promod\economy::purchaseResult(status, "armor");
	if (!isDefined(price))
		price = cost(self charges());
	result["price"] = price;
	result["charges"] = self charges();
	return result;
}

absorbed( damage )
{
	return int(max(1, int(damage * (100 - level.economyArmorAbsorb) / 100)));
}

protectDamage( damage, flags, meansOfDeath, attacker, weapon, hitloc )
{
	if (!promod\economy::realRound() || !level.economyLive || self.sessionstate != "playing" || damage <= 0 ||
		(flags & level.iDFLAGS_NO_PROTECTION) ||
		(meansOfDeath != "MOD_RIFLE_BULLET" && meansOfDeath != "MOD_PISTOL_BULLET") ||
		(isDefined(hitloc) && (hitloc == "head" || hitloc == "helmet")))
		return damage;
	// The pellets of one shotgun blast share the charge spent by its first pellet.
	if (isDefined(self.economyArmorShotTime) && self.economyArmorShotTime == getTime() && isDefined(attacker) &&
		self.economyArmorShotAttacker == attacker && self.economyArmorShotWeapon == weapon)
		return absorbed(damage);
	if (self charges() < 1)
		return damage;
	entry = self promod\economy::account();
	entry["armor"]--;
	self promod\economy::saveAccount(entry);
	self.economyArmorShotTime = undefined;
	if (isDefined(weapon) && weaponClass(weapon) == "spread" && isDefined(attacker))
	{
		self.economyArmorShotTime = getTime();
		self.economyArmorShotAttacker = attacker;
		self.economyArmorShotWeapon = weapon;
	}
	// Only the HUD charge count changes mid-round; the buy phase publishes the rest.
	self setClientDvar("economy_armor_charges", entry["armor"]);
	return absorbed(damage);
}
