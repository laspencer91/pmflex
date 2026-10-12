// See LICENSE.md.

prepareRound()
{
	if (!promod\economy::realRound())
		return;
	entry = self promod\economy::account();
	if (entry["itemsRound"] == game["roundsplayed"])
		return;
	entry["itemsRound"] = game["roundsplayed"];
	entry["redDot"] = false;
	entry["armor"] = 0;
	entry["sniperPenetration"] = false;
	entry["suppressors"] = noSuppressors();
	self promod\economy::saveAccount(entry);
	classes = strTok("assault,specops,demolitions,sniper", ",");
	for (i = 0; i < classes.size; i++)
		if (isDefined(self.pers[classes[i]]))
		{
			self.pers[classes[i]]["loadout_primary_attachment"] = "none";
			self.pers[classes[i]]["loadout_secondary_attachment"] = "none";
		}
}

noSuppressors()
{
	suppressors = [];
	suppressors["primary"] = false;
	suppressors["secondary"] = false;
	return suppressors;
}

clear()
{
	entry = self promod\economy::account();
	entry["frag"] = false;
	entry["redDot"] = false;
	entry["armor"] = 0;
	entry["sniperPenetration"] = false;
	entry["suppressors"] = noSuppressors();
	entry["itemsTeam"] = "";
	self promod\economy::saveAccount(entry);
}

endRound()
{
	if (!promod\economy::enabled())
		return;
	for (i = 0; i < level.players.size; i++)
		if (level.players[i].sessionstate != "playing")
			level.players[i] clear();
}

ownsFrag()
{
	if (!promod\economy::enabled() || !self promod\economy::hasTeam())
		return false;
	entry = self promod\economy::account();
	return entry["frag"] && entry["itemsTeam"] == self.pers["team"];
}

canBuyFrag()
{
	return self promod\economy::canPurchase() &&
		getDvarInt("weap_allow_frag_grenade") && !self ownsFrag() && self promod\economy::canAfford("frag");
}

grantFrag()
{
	if (!self ownsFrag() || !getDvarInt("weap_allow_frag_grenade") || self.sessionstate != "playing" ||
		(isDefined(level.strat_over) && !level.strat_over) || game["PROMOD_KNIFEROUND"])
		return;
	weapon = "frag_grenade_mp";
	if (level.hardcoreMode)
		weapon = "frag_grenade_short_mp";
	self giveWeapon(weapon);
	self setWeaponAmmoClip(weapon, 1);
	self switchToOffhand(weapon);
	self.economyLoadoutFrag = true;
}

buyFrag()
{
	blocker = self promod\economy::purchaseBlocker();
	if (blocker != "") return self promod\economy::purchaseResult(blocker, "frag");
	if (!getDvarInt("weap_allow_frag_grenade"))
		return self promod\economy::purchaseResult("unavailable", "frag");
	if (self ownsFrag())
		return self promod\economy::purchaseResult("owned", "frag");
	self promod\economy::creditRound();
	if (!self promod\economy::trySpendCash(promod\economy::price("frag"), "frag"))
		return self promod\economy::purchaseResult("funds", "frag");
	entry = self promod\economy::account();
	entry["frag"] = true;
	entry["fragRound"] = game["roundsplayed"];
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
	self promod\repeat_buy::remember("frag", true);
	self grantFrag();
	self promod\economy::publish();
	return self promod\economy::purchaseResult("purchased", "frag");
}

watchGrenadeFire()
{
	if (!promod\economy::enabled())
		return;
	self endon("death");
	self endon("disconnect");
	for (;;)
	{
		self waittill("grenade_fire", grenade, weapon);
		self onGrenadeFire(weapon);
	}
}

onGrenadeFire( weapon )
{
	if (!promod\economy::realRound() || (weapon != "frag_grenade_mp" && weapon != "frag_grenade_short_mp"))
		return;
	self clearFrag();
	self promod\economy::publish();
}

clearFrag()
{
	entry = self promod\economy::account();
	entry["frag"] = false;
	self promod\economy::saveAccount(entry);
	self.economyLoadoutFrag = false;
}

selectedWeapon()
{
	if (!isDefined(self.pers["class"]) || !isDefined(self.pers[self.pers["class"]]))
		return "";
	weapon = self.pers[self.pers["class"]]["loadout_primary"];
	if (!isDefined(weapon))
		return "";
	return weapon;
}

supportsRedDot( weapon )
{
	return weapon == "m4" || weapon == "ak47" || weapon == "mp5" || weapon == "ak74u";
}

redDotEligible( weapon )
{
	if (!self promod\economy::hasTeam() || !supportsRedDot(weapon) || weapon != self selectedWeapon())
		return false;
	return getDvarInt("weap_allow_" + weapon) &&
		maps\mp\gametypes\_promod::verifyWeaponChoice(weapon, self.pers["class"]);
}

ownsRedDot( weapon )
{
	if (!promod\economy::enabled() || !self promod\economy::hasTeam() || !supportsRedDot(weapon))
		return false;
	entry = self promod\economy::account();
	return self itemsCurrent(entry) && entry["redDot"];
}

redDotsFree()
{
	return isDefined(level.redDotsFree) && level.redDotsFree;
}

canUseRedDot( weapon )
{
	if (redDotsFree()) return self redDotEligible(weapon);
	if (promod\economy::enabled()) return self ownsRedDot(weapon);
	return level.standardRedDots && self redDotEligible(weapon);
}

canBuyRedDot()
{
	weapon = self selectedWeapon();
	return !redDotsFree() && self promod\economy::canPurchase() && self redDotEligible(weapon) &&
		!self ownsRedDot(weapon) && self promod\economy::canAfford("red_dot");
}

buyRedDot( weapon )
{
	if (!isDefined(weapon))
		weapon = self selectedWeapon();
	if (redDotsFree()) return self redDotResult("unavailable", weapon);
	blocker = self promod\economy::purchaseBlocker();
	if (blocker != "") return self redDotResult(blocker, weapon);
	self prepareRound();
	if (!self redDotEligible(weapon))
		return self redDotResult("unavailable", weapon);
	if (self ownsRedDot(weapon))
		return self redDotResult("owned", weapon);
	self promod\economy::creditRound();
	if (!self promod\economy::trySpendCash(promod\economy::price("red_dot"), "red_dot"))
		return self redDotResult("funds", weapon);
	entry = self promod\economy::account();
	entry["redDot"] = true;
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
	self equipAttachment("primary", "reflex");
	self promod\repeat_buy::remember("attachment", "reflex");
	self refundUnused();
	self promod\economy::publish();
	return self redDotResult("purchased", weapon);
}

redDotResult( status, weapon )
{
	result = self promod\economy::purchaseResult(status, "red_dot");
	result["weapon"] = weapon;
	return result;
}

attachmentWeapon( slot )
{
	if (!isDefined(self.pers["class"]) || (slot != "primary" && slot != "secondary")) return "";
	return self.pers[self.pers["class"]]["loadout_" + slot];
}

suppressorEligible( slot )
{
	weapon = self attachmentWeapon(slot);
	if (!self promod\economy::hasTeam() || !isDefined(weapon) || weapon == "") return false;
	class = self.pers["class"];
	if (slot == "primary")
		return (class == "assault" || class == "specops") && weapon != "mp44" &&
			getDvarInt("attach_allow_" + class + "_silencer");
	return weapon != "deserteagle" && weapon != "deserteaglegold" && getDvarInt("attach_allow_pistol_silencer");
}

ownsSuppressor( slot )
{
	if (!promod\economy::enabled() || !self suppressorEligible(slot)) return false;
	entry = self promod\economy::account();
	return self itemsCurrent(entry) && entry["suppressors"][slot];
}

buySuppressor( slot )
{
	blocker = self promod\economy::purchaseBlocker();
	if (blocker != "") return self promod\economy::purchaseResult(blocker, "suppressor");
	self prepareRound();
	if (!self suppressorEligible(slot)) return self promod\economy::purchaseResult("unavailable", "suppressor");
	if (self ownsSuppressor(slot)) return self promod\economy::purchaseResult("owned", "suppressor");
	self promod\economy::creditRound();
	if (!self promod\economy::trySpendCash(promod\economy::price("suppressor"), "suppressor"))
		return self promod\economy::purchaseResult("funds", "suppressor");
	entry = self promod\economy::account();
	entry["suppressors"][slot] = true;
	if (slot == "primary") self promod\repeat_buy::remember("attachment", "silencer");
	entry["itemsTeam"] = self.pers["team"];
	self promod\economy::saveAccount(entry);
	self promod\economy::publish();
	return self promod\economy::purchaseResult("purchased", "suppressor");
}

itemsCurrent( entry )
{
	return entry["itemsRound"] == game["roundsplayed"] && entry["itemsTeam"] == self.pers["team"];
}

fragRefundable()
{
	if (!self ownsFrag() || self promod\economy::purchaseBlocker() != "") return false;
	entry = self promod\economy::account();
	return entry["fragRound"] == game["roundsplayed"];
}

refundItem( item )
{
	self promod\economy::creditCash(promod\economy::price(item), "refund_" + item);
	return self promod\economy::purchaseResult("refunded", item);
}

// Buy-phase refunds: full price, only for items bought this round.
refund( item )
{
	blocker = self promod\economy::purchaseBlocker();
	if (blocker != "") return self promod\economy::purchaseResult(blocker, item);
	if (item == "armor") return self promod\economy_armor::refund();
	if (item == "sniper_penetration") return self promod\economy_penetration::refund();
	if (item != "frag") return self promod\economy::purchaseResult("unavailable", item);
	if (!self fragRefundable()) return self promod\economy::purchaseResult("not_refundable", "frag");
	self clearFrag();
	self takeWeapon("frag_grenade_mp");
	self takeWeapon("frag_grenade_short_mp");
	self promod\repeat_buy::remember("frag", false);
	return self refundItem("frag");
}

// Bought attachments follow the player to a class whose weapon can take them.
carryAttachments()
{
	if (!promod\economy::enabled() || !isDefined(self.pers["class"]) || !self promod\economy::hasTeam()) return;
	entry = self promod\economy::account();
	if (!self itemsCurrent(entry)) return;
	loadout = self.pers[self.pers["class"]];
	if (loadout["loadout_primary_attachment"] == "none")
	{
		if (entry["suppressors"]["primary"] && self suppressorEligible("primary"))
			self equipAttachment("primary", "silencer");
		else if (entry["redDot"] && self redDotEligible(self selectedWeapon()))
			self equipAttachment("primary", "reflex");
	}
	if (loadout["loadout_secondary_attachment"] == "none" && entry["suppressors"]["secondary"] && self suppressorEligible("secondary"))
		self equipAttachment("secondary", "silencer");
}

equipAttachment( slot, attachment )
{
	key = "loadout_" + slot + "_attachment";
	self.pers[self.pers["class"]][key] = attachment;
	self setClientDvar(key, attachment);
}

// During buy, anything bought this round that the loadout cannot use or no longer selects is refunded.
// Callers publish the new cash.
refundUnused()
{
	if (!promod\economy::enabled() || !isDefined(self.pers["class"]) || self promod\economy::purchaseBlocker() != "")
		return "";
	entry = self promod\economy::account();
	if (!self itemsCurrent(entry)) return "";
	loadout = self.pers[self.pers["class"]];
	refunds = [];
	slots = strTok("primary,secondary", ",");
	for (i = 0; i < slots.size; i++)
		if (entry["suppressors"][slots[i]] && (!self suppressorEligible(slots[i]) || loadout["loadout_" + slots[i] + "_attachment"] != "silencer"))
		{
			entry["suppressors"][slots[i]] = false;
			refunds[refunds.size] = "suppressor";
		}
	if (entry["redDot"] && (!supportsRedDot(self selectedWeapon()) || loadout["loadout_primary_attachment"] != "reflex"))
	{
		entry["redDot"] = false;
		refunds[refunds.size] = "red_dot";
	}
	if (entry["sniperPenetration"] && !self promod\economy_penetration::eligible())
	{
		entry["sniperPenetration"] = false;
		refunds[refunds.size] = "sniper_penetration";
	}
	if (!refunds.size) return "";
	self promod\economy::saveAccount(entry);
	message = "";
	for (i = 0; i < refunds.size; i++)
	{
		self refundItem(refunds[i]);
		if (message != "") message += ", ";
		message += level.economyItemLabels[refunds[i]];
	}
	message += " refunded. Cash: " + promod\economy::cashText(self promod\economy::cash());
	self playLocalSound("ui_money_receive");
	self iPrintLn(message);
	return message;
}
