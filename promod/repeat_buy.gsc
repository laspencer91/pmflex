// Server-side repeat preferences; purchased ownership stays in the economy ledger.
preferences()
{
	if (!isDefined(self.pers["repeat_buy"]))
	{
		pref = [];
		pref["enabled"] = false;
		pref["attachment"] = "none";
		pref["frag"] = false;
		pref["armor"] = 0;
		self.pers["repeat_buy"] = pref;
	}
	return self.pers["repeat_buy"];
}

remember( item, value )
{
	if (!promod\economy::enabled() || (isDefined(self.economyAutoBuying) && self.economyAutoBuying)) return;
	pref = self preferences();
	pref[item] = value;
	self.pers["repeat_buy"] = pref;
}

toggle()
{
	if (!promod\economy::enabled() || !self promod\economy::hasTeam() || !isDefined(self.pers["class"])) return;
	pref = self preferences();
	pref["enabled"] = !pref["enabled"];
	if (pref["enabled"])
	{
		pref["attachment"] = self.pers[self.pers["class"]]["loadout_primary_attachment"];
		if (pref["attachment"] == "reflex" && !self promod\economy_items::canUseRedDot(self promod\economy_items::selectedWeapon()))
			pref["attachment"] = "none";
		if (pref["attachment"] == "silencer" && !self promod\economy_items::ownsSuppressor("primary"))
			pref["attachment"] = "none";
		if (self promod\economy_penetration::owns()) pref["attachment"] = "sniper_penetration";
		pref["frag"] = self promod\economy_items::ownsFrag();
		pref["armor"] = self promod\economy_armor::charges();
		entry = self promod\economy::account();
		entry["repeatBuyRound"] = game["roundsplayed"];
		self promod\economy::saveAccount(entry);
	}
	self.pers["repeat_buy"] = pref;
	self publish();
	message = "Auto-rebuy off";
	if (pref["enabled"]) message = "Auto-rebuy on: from next round, re-buys weapon upgrade > Frag > armor";
	self setClientDvar("flat_status", message);
	self iPrintLn(message);
}

publish()
{
	pref = self preferences();
	label = "AUTO-REBUY: OFF";
	if (pref["enabled"]) label = "AUTO-REBUY: ON";
	self setClientDvars("economy_repeat_enabled", int(pref["enabled"]), "economy_repeat_label", label);
}

note( summary, label, result )
{
	if (summary != "") summary += " / ";
	status = "skipped: unavailable";
	if (result["status"] == "purchased") status = "bought";
	if (result["status"] == "owned") status = "owned";
	if (result["status"] == "funds") status = "skipped: cash";
	if (result["status"] == "closed") status = "skipped: buy closed";
	if (result["status"] == "inactive") status = "skipped: wait for spawn";
	return summary + label + " " + status;
}

attempt()
{
	if (!promod\economy::buying() || !self promod\economy::hasTeam() ||
		!isDefined(self.pers["class"]) || self.sessionstate != "playing" ||
		!isDefined(self.spawnTime) || getTime() < self.spawnTime + 500) return;
	pref = self preferences();
	if (!pref["enabled"]) return;
	entry = self promod\economy::account();
	if (isDefined(entry["repeatBuyRound"]) && entry["repeatBuyRound"] == game["roundsplayed"]) return;
	entry["repeatBuyRound"] = game["roundsplayed"];
	self promod\economy::saveAccount(entry);
	self.economyAutoBuying = true;
	summary = "";
	attachment = pref["attachment"];
	if (attachment == "reflex" && promod\economy_items::redDotsFree())
	{
		// Free red dots are never bought; keep the attachment when the weapon allows it.
		if (self promod\economy_items::canUseRedDot(self promod\economy_items::selectedWeapon()))
			self maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary_attachment:" + self.pers["class"] + ":reflex");
	}
	else if (attachment == "reflex" || attachment == "silencer")
	{
		result = undefined;
		if (attachment == "reflex") result = self promod\economy_items::buyRedDot();
		else result = self promod\economy_items::buySuppressor("primary");
		if (result["success"] || result["status"] == "owned")
			self maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary_attachment:" + self.pers["class"] + ":" + attachment);
		label = "Red dot";
		if (attachment == "silencer") label = "Suppressor";
		summary = note(summary, label, result);
	}
	else if (attachment == "sniper_penetration")
		summary = note(summary, "Sniper upgrade", self promod\economy_penetration::buy());
	if (pref["frag"]) summary = note(summary, "Frag", self promod\economy_items::buyFrag());
	target = int(min(pref["armor"], level.economyArmorCapacity));
	for (i = 0; i < target; i++)
	{
		if (self promod\economy_armor::charges() >= target) break;
		result = self promod\economy_armor::buy();
		if (!result["success"])
		{
			summary = note(summary, "Armor", result);
			break;
		}
	}
	if (target > 0 && self promod\economy_armor::charges() > 0)
	{
		if (summary != "") summary += " / ";
		summary += "Armor " + self promod\economy_armor::charges() + "/" + target;
	}
	self.economyAutoBuying = false;
	if (summary == "") summary = "No paid items saved";
	summary = "Auto-rebuy: " + summary;
	self setClientDvar("flat_status", summary);
	self iPrintLn(summary);
	logPrint("ECONOMY;repeat_buy;" + self.pers["economy_id"] + ";" + summary + "\n");
}
