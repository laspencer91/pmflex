// Single-page loadout prototype. See LICENSE.md.

initPlayer()
{
	self endon("disconnect");
	level endon("restarting");
	self.flatCounts = [];
	self.flatLimits = [];
	self.flatMenuOpen = false;
	self.flatPreviewFrag = 0;
	self.flatPreviewCash = 650;
	self.flatPreviewTransfer = 0;
	self.flatPreviewDemoOwned = false;
	self.flatDemoPending = false;
	if (getDvarInt("ui_flat_rules") && !isDefined(level.flatRulesApplied))
	{
		level.flatRulesApplied = true;
		setDvar("class_assault_limit", 5);
		setDvar("class_specops_limit", 2);
		setDvar("class_sniper_limit", 1);
		setDvar("class_demolitions_limit", 1);
	}
	self setClientDvars("flat_has_class", 0, "flat_status", "Select a class to configure your loadout",
		"flat_team", "");
	for (;;)
	{
		wait 1;
		// Only the countdown is periodic; everything else is sent when it changes.
		if (self.flatMenuOpen && isDefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis"))
			self tick();
	}
}

tick()
{
	liveEconomy = isDefined(game["economy"]) && promod\economy::enabled();
	seconds = buySeconds(liveEconomy);
	if (!isDefined(self.flatBuySecondsSent) || self.flatBuySecondsSent != seconds)
	{
		self.flatBuySecondsSent = seconds;
		self setClientDvar("flat_buy_seconds", seconds);
	}
	if (liveEconomy && (!isDefined(self.flatCashTarget) || self promod\economy::cash() != self.flatCashTarget))
		self displayCash(self promod\economy::cash());
	if (!isDefined(self.flatTeamSeen) || self.flatTeamSeen != teamStamp(self.pers["team"]))
		publishTeamTo(self, self.pers["team"]);
}

buySeconds( liveEconomy )
{
	if (liveEconomy && isDefined(level.economyBuyEnd))
		return int(max(0, (level.economyBuyEnd - getTime()) / 1000.0 + 0.999));
	return 0;
}

// Open menus pick up teammate changes on their next tick, at most once a second.
teamChanged( teamName )
{
	if (!isDefined(level.flatTeamVersion)) level.flatTeamVersion = [];
	if (!isDefined(level.flatTeamVersion[teamName])) level.flatTeamVersion[teamName] = 0;
	level.flatTeamVersion[teamName]++;
}

teamStamp( teamName )
{
	version = 0;
	if (isDefined(level.flatTeamVersion) && isDefined(level.flatTeamVersion[teamName])) version = level.flatTeamVersion[teamName];
	return teamName + ":" + version;
}

publishTeam( teamName )
{
	if (!promod\economy::flatMenuEnabled() || (teamName != "allies" && teamName != "axis"))
		return;
	for (p = 0; p < level.players.size; p++)
		if (isDefined(level.players[p].pers["team"]) && level.players[p].pers["team"] == teamName)
			publishTeamTo(level.players[p], teamName);
}

classState( player, teamName, classType )
{
	state = [];
	state["count"] = game[teamName + "_" + classType + "_count"];
	state["limit"] = getDvarInt("class_" + classType + "_limit");
	allowed = state["count"] < state["limit"];
	if (isDefined(player.pers["class"]) && player.pers["class"] == classType)
		allowed = true;
	if (isDefined(game["economy"]) && !player promod\economy::canSelectClass(classType))
		allowed = false;
	state["allowed"] = int(allowed);
	state["capacity"] = state["count"] + "/" + state["limit"];
	if (state["limit"] == 64)
		state["capacity"] = state["count"] + " / OPEN";
	player.flatCounts[classType] = state["count"];
	player.flatLimits[classType] = state["limit"];
	return state;
}

// Class capacity and teammate cards for one player: one command for the classes, one per card.
publishTeamTo( player, teamName )
{
	if (!promod\economy::flatMenuEnabled() || (teamName != "allies" && teamName != "axis"))
		return;
	if (!isDefined(player.flatCounts))
	{
		player.flatCounts = [];
		player.flatLimits = [];
	}
	player.flatTeamSeen = teamStamp(teamName);
	a = classState(player, teamName, "assault");
	s = classState(player, teamName, "specops");
	d = classState(player, teamName, "demolitions");
	n = classState(player, teamName, "sniper");
	player setClientDvars("flat_assault_count", a["count"], "flat_assault_limit", a["limit"],
		"flat_assault_allowed", a["allowed"], "flat_assault_capacity", a["capacity"],
		"flat_specops_count", s["count"], "flat_specops_limit", s["limit"],
		"flat_specops_allowed", s["allowed"], "flat_specops_capacity", s["capacity"],
		"flat_demolitions_count", d["count"], "flat_demolitions_limit", d["limit"],
		"flat_demolitions_allowed", d["allowed"], "flat_demolitions_capacity", d["capacity"],
		"flat_sniper_count", n["count"], "flat_sniper_limit", n["limit"],
		"flat_sniper_allowed", n["allowed"], "flat_sniper_capacity", n["capacity"]);
	teamIndex = 0;
	for (q = 0; q < level.players.size && teamIndex < 5; q++)
	{
		mate = level.players[q];
		if (!isDefined(mate.pers["team"]) || mate.pers["team"] != teamName)
			continue;
		fragSelected = isDefined(mate.flatPreviewFrag) && mate.flatPreviewFrag;
		if (promod\economy::enabled()) fragSelected = mate promod\economy_items::ownsFrag();
		canGive = mate != player && player.flatPreviewCash >= 50;
		if (promod\economy::enabled()) canGive = mate != player && promod\economy::buying() && player promod\economy::cash() >= 50;
		className = "CHOOSING";
		if (isDefined(mate.pers["class"]))
			className = maps\mp\gametypes\_quickmessages::chooseClassName(mate.pers["class"]);
		cash = "--";
		if (isDefined(mate.flatPreviewCash)) cash = "$" + mate.flatPreviewCash;
		if (isDefined(game["economy"]) && promod\economy::enabled())
		{
			entry = mate promod\economy::account();
			cash = "$" + entry["cash"];
		}
		primary = "";
		attachment = "none";
		utility = "weapon_smokegrenade";
		if (isDefined(mate.pers["class"]) && isDefined(mate.pers[mate.pers["class"]]))
		{
			loadout = mate.pers[mate.pers["class"]];
			if (isDefined(loadout["loadout_primary"])) primary = loadout["loadout_primary"];
			if (isDefined(loadout["loadout_primary_attachment"])) attachment = loadout["loadout_primary_attachment"];
			if (isDefined(loadout["loadout_grenade"]) && loadout["loadout_grenade"] == "flash_grenade") utility = "weapon_flashbang";
		}
		prefix = "flat_mate_" + teamIndex + "_";
		player setClientDvars(prefix + "name", mate.name, prefix + "class", className, prefix + "cash", cash,
			prefix + "exists", 1, prefix + "give", "openscriptmenu flat_loadout give:" + mate donationToken(),
			prefix + "frag", int(fragSelected), prefix + "can_give", int(canGive),
			prefix + "primary", primary, prefix + "attachment", attachment, prefix + "utility", utility);
		teamIndex++;
	}
	while (teamIndex < 5)
	{
		prefix = "flat_mate_" + teamIndex + "_";
		player setClientDvars(prefix + "name", "", prefix + "class", "", prefix + "cash", "",
			prefix + "exists", 0, prefix + "give", "");
		teamIndex++;
	}
}

refresh()
{
	liveEconomy = isDefined(game["economy"]) && promod\economy::enabled();
	if (isDefined(game["economy"]))
		self promod\economy::publish();
	self updatePreviewCash();
	frag = self.flatPreviewFrag;
	if (liveEconomy) frag = int(self promod\economy_items::ownsFrag());
	role = "DEFEND";
	if (self.pers["team"] == game["attackers"])
		role = "ATTACK";
	self.flatBuySecondsSent = buySeconds(liveEconomy);
	self setClientDvars("flat_economy_live", int(liveEconomy), "flat_buy_seconds", self.flatBuySecondsSent,
		"flat_preview_cash", self.flatPreviewCash, "flat_preview_frag", frag, "flat_team", role);
	targetCash = self.flatPreviewCash;
	if (liveEconomy)
	{
		entry = self promod\economy::account();
		targetCash = entry["cash"];
	}
	self displayCash(targetCash);
	publishTeamTo(self, self.pers["team"]);
	if (isDefined(self.pers["class"]))
	{
		classType = self.pers["class"];
		self setClientDvars("flat_has_class", 1, "flat_class_name",
			maps\mp\gametypes\_quickmessages::chooseClassName(classType), "loadout_class", classType);
		self publishPrimaryOptions();
		utility = "weapon_smokegrenade";
		utilityName = "SMOKE";
		if (self.pers[classType]["loadout_grenade"] == "flash_grenade")
		{
			utility = "weapon_flashbang";
			utilityName = "FLASH";
		}
		camos = strTok("camo_none,camo_brockhaurd,camo_bushdweller,camo_blackwhitemarpat,camo_tigerred,camo_stagger,camo_gold", ",");
		labels = strTok("None,Desert,Woodland,Digital,Red Tiger,Blue Tiger,Gold", ",");
		materials = strTok("white,ui_camoskin_brock,ui_camoskin_bshdwl,ui_camoskin_bwmrpt,ui_camoskin_cmdtgr,ui_camoskin_stagger,ui_camoskin_gold", ",");
		camoLabel = "None";
		camoMaterial = "white";
		for (i = 0; i < camos.size; i++)
			if (self.pers[classType]["loadout_camo"] == camos[i])
			{
				camoLabel = labels[i];
				camoMaterial = materials[i];
			}
		self setClientDvars("flat_utility_material", utility, "flat_utility_name", utilityName,
			"flat_tactical_count", 1, "flat_camo_label", camoLabel, "flat_camo_material", camoMaterial);
		self maps\mp\gametypes\_promod::setDvarsFromClass(classType);
	}
	else
		self setClientDvar("flat_has_class", 0);
}

updatePreviewCash()
{
	self.flatPreviewCash = 650 + self.flatPreviewTransfer - promod\economy::price("frag") * self.flatPreviewFrag - 300 * int(self.flatPreviewDemoOwned);
	if (!isDefined(self.pers["class"])) return;
	loadout = self.pers[self.pers["class"]];
	if (loadout["loadout_primary_attachment"] == "silencer") self.flatPreviewCash -= 50;
	if (loadout["loadout_secondary_attachment"] == "silencer") self.flatPreviewCash -= 50;
}

displayCash( target )
{
	if (isDefined(self.flatCashTarget) && self.flatCashTarget == target)
	{
		if (getTime() > self.flatCashStarted + 350)
			self setClientDvars("flat_cash_from", target, "flat_cash_to", target);
		return;
	}
	self notify("flat_cash_changed");
	self.flatCashTarget = target;
	self.flatCashStarted = getTime();
	from = target;
	if (isDefined(self.flatCashShown)) from = self.flatCashShown;
	self setClientDvars("flat_cash_from", from, "flat_cash_to", target);
	if (!isDefined(self.flatCashShown))
	{
		self.flatCashShown = target;
		self setClientDvar("flat_cash_display", target);
		return;
	}
	self thread countCash(target);
}

countCash( target )
{
	self endon("disconnect");
	self endon("flat_cash_changed");
	level endon("restarting");
	start = self.flatCashShown;
	startedAt = getTime();
	while (getTime() < startedAt + 300)
	{
		wait 0.05;
		progress = min(1, (getTime() - startedAt) / 300.0);
		self.flatCashShown = int(start + (target - start) * progress);
		self setClientDvar("flat_cash_display", self.flatCashShown);
	}
	self.flatCashShown = target;
	self setClientDvar("flat_cash_display", target);
}

publishPrimaryOptions()
{
	options = "winchester1200,m1014";
	switch (self.pers["class"])
	{
		case "assault": options = "m16,ak47,m4,g3,g36c,m14,mp44"; break;
		case "specops": options = "mp5,ak74u,uzi"; break;
		case "sniper": options = "m40a3,remington700"; break;
	}
	refs = strTok(options, ",");
	self.flatPrimaryOptions = [];
	allowed = "";
	for (i = 0; i < refs.size; i++)
		if (getDvarInt("weap_allow_" + refs[i]))
		{
			self.flatPrimaryOptions[self.flatPrimaryOptions.size] = refs[i];
			allowed += refs[i] + ",";
		}
	// The rows only change with the class or the weapon rules.
	if (isDefined(self.flatPrimarySent) && self.flatPrimarySent == allowed)
		return;
	self.flatPrimarySent = allowed;
	for (row = 0; row < self.flatPrimaryOptions.size; row++)
	{
		ref = self.flatPrimaryOptions[row];
		self setClientDvars("flat_primary_" + row + "_ref", ref,
			"flat_primary_" + row + "_name", "@" + tableLookup("mp/statstable.csv", 4, ref, 3));
	}
	self setClientDvar("flat_primary_rows", self.flatPrimaryOptions.size);
}

respond( response )
{
	if (response == "closed")
	{
		self.flatMenuOpen = false;
		if (isDefined(self.labElements))
			for (i = 0; i < self.labElements.size; i++)
				self.labElements[i].hideWhenInMenu = false;
		return;
	}
	if (!promod\economy::flatMenuEnabled() || !isDefined(self.pers["team"]) ||
		(self.pers["team"] != "allies" && self.pers["team"] != "axis"))
		return;
	if (response == "refresh")
	{
		self.flatMenuOpen = true;
		if (isDefined(self.labElements))
			for (i = 0; i < self.labElements.size; i++)
				self.labElements[i].hideWhenInMenu = true;
		self refresh();
		return;
	}
	if (response == "open")
	{
		self.flatMenuOpen = true;
		self closeMenu();
		self closeInGameMenu();
		self refresh();
		self openMenu("flat_loadout");
		if (promod\economy::enabled() && !promod\economy::buying())
			self setClientDvar("flat_status", "Buy closed - class and loadout changes apply on your next spawn");
		return;
	}
	if (response == "repeat_buy")
	{
		self promod\repeat_buy::toggle();
		return;
	}
	if (response == "spectate")
	{
		self [[level.killspec]]();
		return;
	}
	if (response == "buy_demolition")
	{
		self respond("select:demolitions");
		return;
	}
	if (response == "money_sounds")
	{
		if (!promod\economy::enabled()) self thread testMoneySounds();
		return;
	}
	if (response == "cancel_demolition")
	{
		if (!self.flatDemoPending) return;
		self.flatDemoPending = false;
		self returnToLoadout("Purchase cancelled");
		return;
	}
	if (response == "confirm_demolition")
	{
		if (!self.flatDemoPending) return;
		self.flatDemoPending = false;
		if (promod\economy::enabled())
		{
			result = self promod\economy::buyDemolition();
			self promod\economy::showPurchase(result);
			if (result["success"])
			{
				self returnToLoadout("Demolition purchased - configure your loadout, then Deploy");
				self playLocalSound("ui_purchase");
			}
			else
			{
				self returnToLoadout("Purchase failed - " + result["status"]);
				self playLocalSound("ui_denied");
			}
			return;
		}
		if (self.flatPreviewCash < 300 || !self maps\mp\gametypes\_promod::verifyClassChoice(self.pers["team"], "demolitions"))
		{
			self playLocalSound("ui_denied");
			self returnToLoadout("Demolition is unavailable, or cash is insufficient");
			return;
		}
		self.flatPreviewDemoOwned = true;
		self maps\mp\gametypes\_promod::setClassChoice("demolitions");
		self returnToLoadout("Demolition selected - configure your loadout, then Deploy");
		self playLocalSound("ui_purchase");
		return;
	}
	if (response == "toggle_tactical")
	{
		if (!isDefined(self.pers["class"])) return;
		grenade = "flash_grenade";
		if (self.pers[self.pers["class"]]["loadout_grenade"] == "flash_grenade") grenade = "smoke_grenade";
		if (!maps\mp\gametypes\_promod::validClass(self.pers["class"], grenade, "loadout_grenade")) return;
		self maps\mp\gametypes\_promod::processLoadoutResponse("loadout_grenade:" + grenade);
		self refresh();
		return;
	}
	if (response == "preview_frag")
	{
		if (!isDefined(self.pers["class"]) || !getDvarInt("weap_allow_frag_grenade")) return;
		if (promod\economy::enabled())
		{
			result = self promod\economy_items::buyFrag();
			self purchaseFeedback(result);
			return;
		}
		if (!self.flatPreviewFrag && self.flatPreviewCash < promod\economy::price("frag"))
		{
			self playLocalSound("ui_denied");
			self setClientDvar("flat_status", "Insufficient cash for Frag");
			return;
		}
		self.flatPreviewFrag = 1 - self.flatPreviewFrag;
		self playLocalSound("mouse_click");
		self refresh();
		self setClientDvar("flat_status", "Frag selection updated");
		return;
	}
	if (response == "buy_armor")
	{
		if (!promod\economy::enabled()) return;
		result = self promod\economy::buyArmor();
		self purchaseFeedback(result);
		return;
	}
	if (response == "refund_frag" || response == "refund_armor" || response == "refund_sniper_penetration")
	{
		if (!promod\economy::enabled())
		{
			if (response == "refund_frag" && self.flatPreviewFrag) self respond("preview_frag");
			return;
		}
		self purchaseFeedback(self promod\economy_items::refund(getSubStr(response, 7)));
		return;
	}
	// Right-click on an equipped attachment unequips it; an unused purchase is then refunded.
	if (response == "refund_silencer" || response == "refund_reflex" || response == "refund_pistol_silencer")
	{
		if (!isDefined(self.pers["class"])) return;
		slot = "primary"; attachment = getSubStr(response, 7); none = "attachment:none";
		if (response == "refund_pistol_silencer") { slot = "secondary"; attachment = "silencer"; none = "pistol_attachment:none"; }
		if (self.pers[self.pers["class"]]["loadout_" + slot + "_attachment"] == attachment) self respond(none);
		return;
	}
	if (response == "buy_sniper_penetration")
	{
		if (!promod\economy::enabled()) return;
		result = self promod\economy::buySniperPenetration();
		self purchaseFeedback(result);
		return;
	}
	if (response == "deploy")
	{
		if (!isDefined(self.pers["class"]))
			return;
		if (promod\economy::buying() && self.sessionstate == "playing")
		{
			if (self promod\economy::loadoutChanged())
				self maps\mp\gametypes\_class::giveLoadout(self.pers["team"], self.pers["class"]);
			self promod\economy::freezeForBuy();
			self thread maps\mp\gametypes\_class::preserveClass(self.pers["class"]);
			self.flatMenuOpen = false;
			self maps\mp\gametypes\_globallogic::closeMenus();
			return;
		}
		self maps\mp\gametypes\_promod::menuAcceptClass("go");
		return;
	}
	tokens = strTok(response, ":");
	if (tokens.size != 2)
		return;
	command = tokens[0];
	value = tokens[1];
	if (command == "give")
	{
		self givePreviewCash(value);
		return;
	}
	if (command == "pick_primary")
	{
		// Resolve only indices from the current server-generated option list.
		found = false;
		if (!isDefined(self.flatPrimaryOptions)) return;
		for (i = 0; i < self.flatPrimaryOptions.size; i++)
			if (value == "" + i)
			{
				value = self.flatPrimaryOptions[i];
				found = true;
				break;
			}
		if (!found) return;
		command = "primary";
	}
	if (command == "select")
	{
		if (value != "assault" && value != "specops" && value != "demolitions" && value != "sniper")
			return;
		if (value == "demolitions" && ((promod\economy::enabled() && !self promod\economy::ownsDemolition()) ||
			(!promod\economy::enabled() && !self.flatPreviewDemoOwned)))
		{
			canBuy = self.flatPreviewCash >= 300 && self maps\mp\gametypes\_promod::verifyClassChoice(self.pers["team"], value);
			if (promod\economy::enabled()) canBuy = self promod\economy::canBuyDemolition();
			if (!canBuy)
			{
				self playLocalSound("ui_denied");
				self setClientDvar("flat_status", "Demolition is unavailable, or cash is insufficient");
				return;
			}
			self.flatDemoPending = true;
			self openMenu("flat_demolition_confirm");
			return;
		}
		if (isDefined(game["economy"]) && !self promod\economy::canSelectClass(value))
		{
			if (value == "demolitions")
			{
				self promod\economy::respond("buy_demolition");
				return;
			}
			self setClientDvar("flat_status", "Class requires a purchase, or your purchased class is locked");
			self playLocalSound("ui_denied");
			self refresh();
			return;
		}
		if (!self maps\mp\gametypes\_promod::verifyClassChoice(self.pers["team"], value))
		{
			self setClientDvar("flat_status", "Class full - choose another class");
			self playLocalSound("ui_denied");
			self refresh();
			logPrint("FLAT_LOADOUT;class_denied;" + value + "\n");
			return;
		}
		self maps\mp\gametypes\_promod::setClassChoice(value);
		self refresh();
		self setClientDvar("flat_status", "Class selected - configure your loadout, then Deploy");
		if (promod\economy::enabled() && !promod\economy::buying())
			self setClientDvar("flat_status", "Class selected - applies on your next spawn");
		self playLocalSound("mouse_click");
		logPrint("FLAT_LOADOUT;class_selected;" + value + "\n");
		return;
	}
	if (!isDefined(self.pers["class"]))
		return;
	classType = self.pers["class"];
	if (command == "primary" || command == "secondary")
	{
		key = "loadout_" + command;
		if (!maps\mp\gametypes\_promod::validClass(classType, value, key))
		{
			self setClientDvar("flat_status", "Weapon unavailable for this class");
			return;
		}
		self maps\mp\gametypes\_promod::processLoadoutResponse(key + ":" + value);
	}
	else if (command == "attachment")
	{
		if (promod\economy::enabled() && value == "reflex" && !self promod\economy_items::canUseRedDot(self promod\economy_items::selectedWeapon()))
		{
			result = self promod\economy_items::buyRedDot();
			self purchaseFeedback(result);
			return;
		}
		if ((classType != "assault" && classType != "specops") ||
			self.pers[classType]["loadout_primary"] == "mp44" ||
			!maps\mp\gametypes\_promod::validClass(classType, value, "loadout_primary_attachment"))
			return;
		if (promod\economy::enabled() && value == "silencer" && !self promod\economy_items::ownsSuppressor("primary"))
		{
			result = self promod\economy_items::buySuppressor("primary");
			if (!result["success"]) { self purchaseFeedback(result); return; }
			self playLocalSound("ui_purchase");
		}
		self maps\mp\gametypes\_promod::processLoadoutResponse("loadout_primary_attachment:" + classType + ":" + value);
	}
	else if (command == "pistol_attachment")
	{
		pistol = self.pers[classType]["loadout_secondary"];
		if (pistol == "deserteagle" || pistol == "deserteaglegold" ||
			!maps\mp\gametypes\_promod::validClass(classType, value, "loadout_secondary_attachment"))
			return;
		if (promod\economy::enabled() && value == "silencer" && !self promod\economy_items::ownsSuppressor("secondary"))
		{
			result = self promod\economy_items::buySuppressor("secondary");
			if (!result["success"]) { self purchaseFeedback(result); return; }
			self playLocalSound("ui_purchase");
		}
		self maps\mp\gametypes\_promod::processLoadoutResponse("loadout_secondary_attachment:pistol:" + value);
	}
	else if (command == "grenade")
	{
		if (!maps\mp\gametypes\_promod::validClass(classType, value, "loadout_grenade"))
			return;
		self maps\mp\gametypes\_promod::processLoadoutResponse("loadout_grenade:" + value);
	}
	else if (command == "camo")
	{
		if (value == "next")
		{
			camos = strTok("camo_none,camo_brockhaurd,camo_bushdweller,camo_blackwhitemarpat,camo_tigerred,camo_stagger,camo_gold", ",");
			for (i = 0; i < camos.size; i++)
				if (self.pers[classType]["loadout_camo"] == camos[i])
				{
					value = camos[(i + 1) % camos.size];
					break;
				}
			primary = self.pers[classType]["loadout_primary"];
			if (value == "camo_gold" && primary != "ak47" && primary != "uzi" && primary != "m1014")
				value = "camo_none";
		}
		if (!maps\mp\gametypes\_promod::validClass(classType, value, "loadout_camo"))
			return;
		primary = self.pers[classType]["loadout_primary"];
		if (value == "camo_gold" && primary != "ak47" && primary != "uzi" && primary != "m1014")
			return;
		self maps\mp\gametypes\_promod::processLoadoutResponse("loadout_camo:" + value);
	}
	else
		return;
	refund = self promod\economy_items::refundUnused();
	self refresh();
	self setClientDvar("flat_status", "Loadout updated");
	if (promod\economy::enabled() && !promod\economy::buying())
		self setClientDvar("flat_status", "Loadout saved - applies on your next spawn");
	if (refund != "") self setClientDvar("flat_status", refund);
	logPrint("FLAT_LOADOUT;updated;" + command + ";" + value + "\n");
}

donationToken()
{
	if (!isDefined(self.flatDonationToken))
	{
		if (!isDefined(game["flatNextDonationToken"])) game["flatNextDonationToken"] = 0;
		game["flatNextDonationToken"]++;
		self.flatDonationToken = "player_" + getDvar("sv_serverid") + "_" + game["flatNextDonationToken"];
	}
	return self.flatDonationToken;
}

givePreviewCash( token )
{
	mate = undefined;
	for (i = 0; i < level.players.size; i++)
		if (isDefined(level.players[i].flatDonationToken) && token == level.players[i].flatDonationToken)
		{
			mate = level.players[i];
			break;
		}
	if (promod\economy::enabled())
	{
		if (!self promod\economy::giveCash(mate))
		{
			self playLocalSound("ui_denied");
			self setClientDvar("flat_status", "Cannot give cash - check teammate, balance and buy phase");
			return;
		}
		self donationFeedback(mate);
		return;
	}
	if (!isDefined(mate) || mate == self || !isDefined(mate.pers["team"]) || mate.pers["team"] != self.pers["team"] ||
		!isDefined(mate.flatPreviewTransfer) || self.flatPreviewCash < 50)
	{
		self playLocalSound("ui_denied");
		return;
	}
	self.flatPreviewTransfer -= 50;
	mate.flatPreviewTransfer += 50;
	self donationFeedback(mate);
}

donationFeedback( mate )
{
	mate refresh();
	self refresh();
	self setClientDvar("flat_status", "Sent $50 to " + mate.name);
	mate setClientDvar("flat_status", "Received $50 from " + self.name);
	self playLocalSound("ui_money_give");
	mate playLocalSound("ui_money_receive");
	logPrint("FLAT_LOADOUT;donation_sounds;ui_money_give;ui_money_receive\n");
}

purchaseFeedback( result )
{
	self promod\economy::showPurchase(result);
	sound = "ui_denied";
	if (result["success"]) sound = "ui_purchase";
	if (result["success"] && result["item"] == "armor") sound = "ui_armor";
	if (result["status"] == "refunded") sound = "ui_money_receive";
	self playLocalSound(sound);
	self refresh();
	if (result["status"] == "inactive") return;
	label = level.economyItemLabels[result["item"]];
	message = label + " / " + result["status"];
	if (result["status"] == "purchased") message = label + " purchased";
	if (result["status"] == "funds") message = label + " costs $" + result["price"] + " / Cash $" + result["cash"];
	if (result["status"] == "owned") message = label + " already owned";
	if (result["status"] == "refunded") message = label + " refunded / Cash $" + result["cash"];
	if (result["status"] == "not_refundable") message = label + " can only be refunded during the buy phase it was bought in";
	if (result["status"] == "closed") message = "Buy closed - purchases are available during the next buy phase";
	self setClientDvar("flat_status", message);
}

returnToLoadout( message )
{
	self.flatMenuOpen = true;
	self refresh();
	self openMenu("flat_loadout");
	self setClientDvar("flat_status", message);
}

testMoneySounds()
{
	self endon("disconnect");
	level endon("restarting");
	self playLocalSound("ui_money_give");
	wait 0.65;
	self playLocalSound("ui_money_receive");
}
