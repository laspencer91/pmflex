// See LICENSE.md.
#include maps\mp\gametypes\_hud_util;

setupRules()
{
	level.economyBuySeconds = configuredBuySeconds();
	level.economyArmorCapacity = 2;
	level.economyArmorDamageScale = 0.25;
	level.economyPrices = [];
	level.economyPrices["demolition"] = 300;
	level.economyPrices["frag"] = 100;
	level.economyPrices["red_dot"] = 100;
	level.economyPrices["armor"] = 50;
	level.economyPrices["sniper_penetration"] = 150;
	level.economyPrices["suppressor"] = 50;
	level.economyItemLabels = [];
	level.economyItemLabels["demolition"] = "Demolition";
	level.economyItemLabels["frag"] = "Frag";
	level.economyItemLabels["red_dot"] = "Red dot";
	level.economyItemLabels["armor"] = "Armor charge";
	level.economyItemLabels["sniper_penetration"] = "Sniper armor penetration";
	level.economyItemLabels["suppressor"] = "Suppressor";
	level.economyRewards = [];
	level.economyRewards["round"] = 100;
	level.economyRewards["plant"] = 50;
	level.economyRewards["defuse"] = 50;
	level.economyRewards["kill"] = 50;
	level.economyRewards["assist"] = 25;
	level.economyRewardLabels = [];
	level.economyRewardLabels["round"] = "Round income";
	level.economyRewardLabels["plant"] = "Team plant";
	level.economyRewardLabels["defuse"] = "Team defuse";
	level.economyRewardLabels["kill"] = "Kill";
	level.economyRewardLabels["assist"] = "Assist";
}

price( item )
{
	return level.economyPrices[item];
}

reward( event )
{
	return level.economyRewards[event];
}

enabled()
{
	return isDefined(level.economyEnabled) && level.economyEnabled && level.gametype == "sd" &&
		isDefined(game["PROMOD_MATCH_MODE"]) && game["PROMOD_MATCH_MODE"] != "strat";
}

flatMenuEnabled()
{
	return getDvarInt("ui_flat_loadout") && (enabled() || game["PROMOD_MATCH_MODE"] == "strat");
}

realRound()
{
	return enabled() && !game["promod_do_readyup"] && !game["promod_timeout_called"] &&
		!game["PROMOD_KNIFEROUND"] && !level.gameEnded;
}

buying()
{
	return realRound() && level.economyBuyOpen && getTime() < level.economyBuyEnd;
}

purchaseEligible()
{
	return self hasTeam() && self.sessionstate == "playing" && isAlive(self);
}

canPurchase()
{
	return buying() && self purchaseEligible();
}

purchaseBlocker()
{
	if (!buying() || !self hasTeam()) return "closed";
	if (!self purchaseEligible()) return "inactive";
	return "";
}

resetMatch()
{
	nextId = 0;
	if (isDefined(game["economy"]))
		nextId = game["economy"]["nextId"];
	game["economy"] = [];
	game["economy"]["accounts"] = [];
	game["economy"]["nextId"] = nextId;
	game["economy"]["halfResetRound"] = -1;
	game["economy"]["objectiveRounds"] = [];
	game["economy"]["enabledProfile"] = enabled();
}

init()
{
	setupRules();
	if (getDvar("promod_economy") == "") setDvar("promod_economy", 0);
	if (getDvar("promod_standard_red_dots") == "") setDvar("promod_standard_red_dots", 0);
	// Profile changes take effect at map initialization, not during a round.
	level.economyEnabled = getDvarInt("promod_economy") != 0;
	level.standardRedDots = getDvarInt("promod_standard_red_dots") != 0;
    if (getDvar("promod_red_dots") != "")
        level.standardRedDots = getDvarInt("promod_red_dots") != 0;
    // promod_red_dots 1 (vote outcome): free red dots in every mode; economy otherwise sells them.
    level.redDotsFree = getDvarInt("promod_red_dots") != 0;
    // promod_reduced_frag 1 (vote outcome): frag grenades deal 65% damage.
    level.reducedFrag = getDvarInt("promod_reduced_frag") != 0;
	if (!isDefined(game["economy"]) || !isDefined(game["economy"]["enabledProfile"]) ||
		game["economy"]["enabledProfile"] != enabled())
		resetMatch();
	level.economyPrepared = false;
	level.economyBuyOpen = false;
	level.economyBuyEnd = 0;
	level.economyLive = false;
	if (getDvarInt("repeat_smoke")) level thread promod\repeat_buy_smoke::run();
	if (getDvarInt("profile_smoke")) level thread promod\profile_smoke::run();
	if (getDvarInt("economy_manual_test"))
		level thread promod\economy_manual_test::run();
	if (getDvarInt("economy_smoke"))
	{
		setDvar("g_logSync", 1);
		logPrint("ECONOMY_TEST;INIT;" + getDvar("dedicated") + "\n");
		if (isSubStr(getDvar("dedicated"), "dedicated") || getDvar("dedicated") == "1" || getDvar("dedicated") == "2")
			level thread promod\economy_smoke::run();
	}
}

account()
{
	if (!isDefined(self.pers["economy_id"]))
	{
		guid = self getGuid();
		if (guid == "" || guid == "0" || isSubStr(guid, "bot"))
		{
			game["economy"]["nextId"]++;
			guid = "session_" + game["economy"]["nextId"];
		}
		self.pers["economy_id"] = guid;
	}
	id = self.pers["economy_id"];
	if (!isDefined(game["economy"]["accounts"][id]))
	{
		entry = [];
		entry["cash"] = 0;
		entry["repeatBuyRound"] = -1;
		entry["creditedRound"] = -1;
		entry["demolitionTeam"] = "";
		entry["frag"] = false;
		entry["fragRound"] = -1;
		entry["redDot"] = false;
		entry["suppressors"] = promod\economy_items::noSuppressors();
		entry["armor"] = 0;
		entry["sniperPenetration"] = false;
		entry["itemsRound"] = -1;
		entry["itemsTeam"] = "";
		game["economy"]["accounts"][id] = entry;
	}
	return game["economy"]["accounts"][id];
}

saveAccount( entry )
{
	game["economy"]["accounts"][self.pers["economy_id"]] = entry;
}

cash()
{
	entry = self account();
	return entry["cash"];
}

creditCash( amount, reason )
{
	if (!enabled() || !self hasTeam() || !isDefined(amount) || amount <= 0 || amount != int(amount))
		return false;
	entry = self account();
	entry["cash"] += amount;
	self saveAccount(entry);
	logPrint("ECONOMY;credit;" + reason + ";" + self.pers["economy_id"] + ";" + amount + ";" + entry["cash"] + "\n");
	return true;
}

trySpendCash( amount, reason )
{
	if (!enabled() || !self hasTeam() || !isDefined(amount) || amount <= 0 || amount != int(amount))
		return false;
	entry = self account();
	if (entry["cash"] < amount)
		return false;
	entry["cash"] -= amount;
	self saveAccount(entry);
	logPrint("ECONOMY;debit;" + reason + ";" + self.pers["economy_id"] + ";" + amount + ";" + entry["cash"] + "\n");
	return true;
}

canAfford( item )
{
	cost = price(item);
	return isDefined(cost) && cost > 0 && self cash() >= cost;
}

giveCash( recipient )
{
	if (!buying() || !isDefined(recipient) || recipient == self || !self hasTeam() ||
		!recipient hasTeam() || recipient.pers["team"] != self.pers["team"])
		return false;
	self account();
	recipient account();
	if (self.pers["economy_id"] == recipient.pers["economy_id"]) return false;
	if (!self trySpendCash(50, "donation")) return false;
	recipient creditCash(50, "donation");
	self publish();
	recipient publish();
	return true;
}

cashText( amount )
{
	return "^2$" + amount + "^7";
}

awardReward( event )
{
	if (!realRound() || !level.economyLive || !self creditCash(reward(event), event))
		return false;
	self iPrintLn(level.economyRewardLabels[event] + ": +" + cashText(reward(event)));
	self publish();
	return true;
}

hasTeam()
{
	return isDefined(self.pers["team"]) && (self.pers["team"] == "allies" || self.pers["team"] == "axis");
}

ownsDemolition()
{
	if (!enabled() || !self hasTeam())
		return false;
	entry = self account();
	return entry["demolitionTeam"] == self.pers["team"];
}

canSelectClass( classType )
{
	if (!enabled())
		return true;
	if (self ownsDemolition())
		return classType == "demolitions";
	return classType != "demolitions";
}

demolitionAvailable( team )
{
	if (getDvarInt("class_demolitions_limit") < 1)
		return false;
	ids = getArrayKeys(game["economy"]["accounts"]);
	for (i = 0; i < ids.size; i++)
		if (game["economy"]["accounts"][ids[i]]["demolitionTeam"] == team)
			return false;
	return true;
}

canBuyDemolition()
{
	if (!self canPurchase() || self ownsDemolition())
		return false;
	return self canAfford("demolition") && demolitionAvailable(self.pers["team"]);
}

// Three batched commands, four with a team; each is a few hundred characters.
publish()
{
	pref = self promod\repeat_buy::preferences();
	repeatLabel = "AUTO-REBUY: OFF";
	if (pref["enabled"]) repeatLabel = "AUTO-REBUY: ON";
	entry = self account();
	self updateCashHud(entry["cash"]);
	canBuy = buying() && self hasTeam();
	available = false;
	if (enabled() && self hasTeam())
		available = demolitionAvailable(self.pers["team"]);
	self setClientDvars("economy_repeat_enabled", int(pref["enabled"]), "economy_repeat_label", repeatLabel,
		"economy_cash", entry["cash"], "economy_buy_open", int(canBuy), "economy_purchase_allowed", int(self canPurchase()),
		"economy_demolition_owned", int(self ownsDemolition()), "economy_demolition_available", int(available),
		"economy_demolition_price", price("demolition"), "economy_armor_price", price("armor"),
		"economy_armor_charges", self promod\economy_armor::charges(), "economy_armor_capacity", level.economyArmorCapacity,
		"economy_can_buy_armor", int(self promod\economy_armor::canBuy()));
	self setClientDvars("economy_sniper_penetration_price", price("sniper_penetration"),
		"economy_sniper_penetration_owned", int(self promod\economy_penetration::owns()),
		"economy_sniper_penetration_supported", int(self promod\economy_penetration::eligible()),
		"economy_can_buy_sniper_penetration", int(self promod\economy_penetration::canBuy()),
		"economy_frag_price", price("frag"), "economy_frag_owned", int(self promod\economy_items::ownsFrag()),
		"economy_can_buy_frag", int(self promod\economy_items::canBuyFrag()), "economy_frag_refundable", int(self promod\economy_items::fragRefundable()));
	weapon = self promod\economy_items::selectedWeapon();
	redDot = int(self promod\economy_items::canUseRedDot(weapon));
	redDotLabel = "$" + price("red_dot");
	if (promod\economy_items::redDotsFree()) redDotLabel = "";
	// Also carries publishReflexChoice()'s values.
	self setClientDvars("economy_red_dot_price", price("red_dot"), "economy_red_dot_weapon", weapon,
		"economy_red_dot_owned", redDot, "economy_red_dot_supported", int(self promod\economy_items::redDotEligible(weapon)),
		"economy_can_buy_red_dot", int(self promod\economy_items::canBuyRedDot()),
		"economy_red_dot_free", int(promod\economy_items::redDotsFree()), "economy_red_dot_label", redDotLabel,
		"attach_allow_assault_reflex", redDot, "attach_allow_specops_reflex", redDot,
		"economy_suppressor_price", price("suppressor"),
		"economy_suppressor_primary_owned", int(self promod\economy_items::ownsSuppressor("primary")),
		"economy_suppressor_secondary_owned", int(self promod\economy_items::ownsSuppressor("secondary")));
	if (enabled() && self hasTeam())
		self setClientDvar(self.pers["team"] + "_allow_demolitions", self demolitionAccess());
	if (self hasTeam())
		promod\flat_loadout::teamChanged(self.pers["team"]);
}

demolitionAccess()
{
	return int(self ownsDemolition() || self canBuyDemolition());
}

// Class changes only move the Demolition slot; everything else in publish() is per player.
publishDemolitionAccess( team )
{
	for (p = 0; p < level.players.size; p++)
	{
		player = level.players[p];
		if (player hasTeam() && player.pers["team"] == team)
			player setClientDvar(team + "_allow_demolitions", player demolitionAccess());
	}
}

// CoD4x test clients report GUID "0"; stock ones report "" and a "bot<N>" name (local LAN humans also report "").
isTestClient()
{
	guid = self getGuid();
	if (guid == "0" || isSubStr(guid, "bot"))
		return true;
	return guid == "" && getSubStr(self.name, 0, 3) == "bot";
}

updateCashHud(amount)
{
	if (!enabled())
	{
		if (isDefined(self.economyCashHud))
			self.economyCashHud destroy();
		return;
	}
	if (!isDefined(self.economyCashHud))
	{
		self.economyCashHud = self createFontString("objective", 1.6);
		self.economyCashHud setPoint("TOPRIGHT", "TOPRIGHT", -18, 18);
		self.economyCashHud.color = (0.65, 0.9, 0.55);
		self.economyCashHud.hideWhenInMenu = true;
	}
	self.economyCashHud setText("$" + amount);
}

// Client dvars survive server changes; the HUD armor icon must not show a previous server's charges.
clearStaleHud()
{
	if (!enabled())
		self setClientDvar("economy_armor_charges", 0);
}

publishAll()
{
	for (p = 0; p < level.players.size; p++)
		level.players[p] publish();
}

creditRound()
{
	if (!realRound() || !self hasTeam() || !level.economyBuyOpen)
		return;
	self promod\economy_items::prepareRound();
	entry = self account();
	if (entry["creditedRound"] == game["roundsplayed"])
		return;
	entry["creditedRound"] = game["roundsplayed"];
	self saveAccount(entry);
	self creditCash(reward("round"), "round");
	self publish();
	self iPrintLn("Cash: " + cashText(self cash()));
}

assignFallback()
{
	self assignAvailableClass("sniper,specops,assault");
}

assignAvailableClass(classList)
{
	if (!self hasTeam())
		return;
	classes = strTok(classList, ",");
	for (c = 0; c < classes.size; c++)
	{
		classType = classes[c];
		if (self maps\mp\gametypes\_promod::verifyClassChoice(self.pers["team"], classType))
		{
			self maps\mp\gametypes\_promod::setClassChoice(classType);
			return;
		}
	}
	self.pers["class"] = undefined;
	self.class = undefined;
	self setClientDvar("loadout_curclass", "");
}

ensureClass()
{
	if (!enabled())
		return;
	if (!isDefined(self.pers["class"]))
		self assignAvailableClass("assault,specops,sniper");
	else if (self.pers["class"] == "demolitions" && !self ownsDemolition())
		self assignFallback();
}

classChanged()
{
	if (!enabled())
		return;
	self creditRound();
	self promod\economy_items::carryAttachments();
	self promod\economy_items::refundUnused();
	self publish();
}

freezeForBuy()
{
	if (enabled() && level.economyPrepared && !level.economyLive && self.sessionstate == "playing")
	{
		self freezeControls(true);
	}
}

openBuyMenu()
{
	if (!buying() || !self hasTeam())
		return;
	if (self.sessionstate != "playing" || !isDefined(self.spawnTime) || getTime() < self.spawnTime + 500)
		return;
	if (isDefined(self.economyMenuRound) && self.economyMenuRound == game["roundsplayed"])
		return;
	self.economyMenuRound = game["roundsplayed"];
	// Test clients never answer "closed", so their menu would stay open all round.
	if (self isTestClient())
		return;
	self closeMenu();
	self closeInGameMenu();
	if (flatMenuEnabled())
	{
		self.flatMenuOpen = true;
		self promod\flat_loadout::refresh();
	}
	self openMenu(game["menu_changeclass_" + self.pers["team"]]);
	logPrint("ECONOMY;buy_menu_open;" + self.pers["economy_id"] + ";" + game["menu_changeclass_" + self.pers["team"]] + "\n");
}

loadoutApplied()
{
	if (!enabled())
		return;
	if (!isDefined(self.economyLoadoutGeneration)) self.economyLoadoutGeneration = 0;
	self.economyLoadoutGeneration++;
	self.economyLoadoutClass = self.curClass;
	self.economyLoadout = self.pers[self.curClass];
	self.economyLoadoutFrag = self promod\economy_items::ownsFrag();
}

loadoutChanged()
{
	if (!isDefined(self.economyLoadoutClass) || self.economyLoadoutClass != self.pers["class"])
		return true;
	if (!isDefined(self.economyLoadoutFrag) || self.economyLoadoutFrag != self promod\economy_items::ownsFrag())
		return true;
	keys = strTok("loadout_primary,loadout_secondary,loadout_primary_attachment,loadout_secondary_attachment,loadout_grenade,loadout_camo", ",");
	for (i = 0; i < keys.size; i++)
	{
		previous = self.economyLoadout[keys[i]];
		current = self.pers[self.pers["class"]][keys[i]];
		if (isDefined(previous) != isDefined(current))
			return true;
		if (isDefined(previous) && previous != current)
			return true;
	}
	return false;
}

// promod_buy_seconds (server config): buy phase length in seconds, limited to 10-60. Unset means 30.
// Read at the start of every buy phase, so an rcon change applies from the next round.
configuredBuySeconds()
{
	if (getDvar("promod_buy_seconds") == "")
		return 30;
	return int(min(60, max(10, getDvarInt("promod_buy_seconds"))));
}

buyPhase()
{
	if (getDvarInt("economy_manual_test"))
		promod\economy_manual_test::waitForPlayer();
	if (!realRound() || isDefined(game["roundMillisecondsAlreadyPassed"]))
		return;
	level endon("game_ended");
	level endon("restarting");
	level.economyBuySeconds = configuredBuySeconds();
	level.economyPrepared = true;
	level.economyBuyOpen = true;
	level.economyBuyEnd = getTime() + level.economyBuySeconds * 1000;
	level.economyBuyLabel = createServerFontString("objective", 1.5);
	level.economyBuyLabel.hideWhenInMenu = true;
	level.economyBuyLabel setPoint("CENTER", "CENTER", 0, -60);
	level.economyBuyLabel setText("Buy Phase / [{openscriptmenu loadout open}] Buy / Esc Close");
	level.economyBuyTimer = createServerTimer("objective", 1.4);
	level.economyBuyTimer.hideWhenInMenu = true;
	level.economyBuyTimer setPoint("CENTER", "CENTER", 0, -45);
	level.economyBuyTimer setTimer(level.economyBuySeconds);
	publishAll();
	while (getTime() < level.economyBuyEnd)
	{
		for (p = 0; p < level.players.size; p++)
		{
			player = level.players[p];
			player ensureClass();
			player creditRound();
			player freezeForBuy();
			player promod\repeat_buy::attempt();
			player openBuyMenu();
		}
		wait 0.1;
	}
	closeBuyPhase();
	for (p = 0; p < level.players.size; p++)
	{
		player = level.players[p];
		if (player.sessionstate == "playing" && isDefined(player.pers["class"]) && player loadoutChanged())
			player maps\mp\gametypes\_class::giveLoadout(player.pers["team"], player.pers["class"]);
		if (player hasTeam())
		{
			player.flatMenuOpen = false;
			player maps\mp\gametypes\_globallogic::closeMenus();
		}
	}
}

closeBuyPhase()
{
	level.economyBuyOpen = false;
	if (isDefined(level.economyBuyLabel))
		level.economyBuyLabel destroyElem();
	if (isDefined(level.economyBuyTimer))
		level.economyBuyTimer destroyElem();
	if (enabled())
		publishAll();
}

startRound()
{
	if (!realRound())
		return;
	level.economyLive = true;
	for (p = 0; p < level.players.size; p++)
	{
		if (level.players[p].sessionstate != "playing")
			continue;
		level.players[p] freezeControls(false);
		level.players[p] enableWeapons();
	}
}

awardObjective( objective )
{
	if (!realRound() || !level.economyLive)
		return;
	if (objective == "plant" && level.bombPlanted)
		team = game["attackers"];
	else if (objective == "defuse" && level.bombDefused)
		team = game["defenders"];
	else
		return;
	if (isDefined(game["economy"]["objectiveRounds"][objective]) &&
		game["economy"]["objectiveRounds"][objective] == game["roundsplayed"])
		return;
	game["economy"]["objectiveRounds"][objective] = game["roundsplayed"];
	for (p = 0; p < level.players.size; p++)
	{
		player = level.players[p];
		if (!player hasTeam() || player.pers["team"] != team)
			continue;
		player awardReward(objective);
	}
	publishAll();
	logPrint("ECONOMY;" + objective + "_reward;" + team + ";" + game["roundsplayed"] + "\n");
}

buyDemolition()
{
	blocker = self purchaseBlocker();
	if (blocker != "") return self purchaseResult(blocker, "demolition");
	if (self ownsDemolition())
		return self purchaseResult("owned", "demolition");
	if (!demolitionAvailable(self.pers["team"]))
		return self purchaseResult("unavailable", "demolition");
	self creditRound();
	if (!self trySpendCash(price("demolition"), "demolition"))
		return self purchaseResult("funds", "demolition");
	entry = self account();
	entry["demolitionTeam"] = self.pers["team"];
	self saveAccount(entry);
	self maps\mp\gametypes\_promod::setClassChoice("demolitions");
	publishAll();
	logPrint("ECONOMY;demolition_bought;" + self.pers["economy_id"] + ";" + entry["cash"] + "\n");
	return self purchaseResult("purchased", "demolition");
}

buySniperPenetration()
{
	return self promod\economy_penetration::buy();
}

buyArmor()
{
	return self promod\economy_armor::buy();
}

buyFrag()
{
	return self promod\economy_items::buyFrag();
}

buyRedDot( weapon )
{
	return self promod\economy_items::buyRedDot(weapon);
}

purchaseResult( status, item )
{
	result = [];
	result["success"] = status == "purchased";
	result["status"] = status;
	result["item"] = item;
	result["price"] = price(item);
	result["cash"] = self cash();
	return result;
}

showPurchase( result )
{
	label = level.economyItemLabels[result["item"]];
	switch (result["status"])
	{
		case "closed":
			message = "Purchases are available during the buy phase";
			break;
		case "inactive":
			message = "Wait for spawn - purchases require an alive player";
			break;
		case "owned":
			message = "You already own " + label;
			break;
		case "unavailable":
			message = label + " is unavailable";
			break;
		case "funds":
			message = label + " costs " + cashText(result["price"]) + ". Cash: " + cashText(result["cash"]);
			break;
		case "purchased":
			message = label + " purchased. Cash: " + cashText(result["cash"]);
			break;
		case "refunded":
			message = label + " refunded. Cash: " + cashText(result["cash"]);
			break;
		case "not_refundable":
			message = label + " can only be refunded during the buy phase it was bought in";
			break;
		default:
			message = "Purchase unavailable";
			break;
	}
	self iPrintLn(message);
}

respond( response )
{
	if (!enabled())
		return;
	tokens = strTok(response, ":");
	if (response == "repeat_buy")
		self promod\repeat_buy::toggle();
	else if (response == "buy_demolition")
	{
		result = self buyDemolition();
		self showPurchase(result);
		if (result["success"])
		{
			self maps\mp\gametypes\_promod::menuAcceptClass("go");
			self freezeForBuy();
		}
	}
	else if (response == "buy_sniper_penetration")
		self showPurchase(self buySniperPenetration());
	else if (response == "buy_armor")
		self showPurchase(self buyArmor());
	else if (response == "buy_frag")
		self showPurchase(self buyFrag());
	else if (response == "buy_red_dot")
		self showPurchase(self buyRedDot());
	else if (tokens.size == 2 && tokens[0] == "buy_red_dot")
		self showPurchase(self buyRedDot(tokens[1]));
	else if (tokens.size == 2 && tokens[0] == "local_test")
		self promod\economy_manual_test::respond(tokens[1]);
	else if (response == "status")
		self iPrintLn("Cash: " + cashText(self cash()) + ". Demolition: " + cashText(price("demolition")));
	self publish();
}

releaseDemolition()
{
	entry = self account();
	if (entry["demolitionTeam"] == "")
		return false;
	entry["demolitionTeam"] = "";
	self saveAccount(entry);
	return true;
}

onDeath()
{
	if (enabled())
	{
		self promod\economy_items::clear();
		self publish();
	}
	if (!realRound() || !level.economyLive || !self releaseDemolition())
		return;
	self assignFallback();
	publishAll();
	logPrint("ECONOMY;demolition_lost;" + self.pers["economy_id"] + ";" + self.pers["class"] + "\n");
}

onDisconnect()
{
	if (enabled())
	{
		self promod\economy_items::clear();
		self releaseDemolition();
	}
}

onTeamChanged()
{
	if (!enabled())
		return;
	entry = self account();
	if (!self hasTeam() || (entry["itemsTeam"] != "" && entry["itemsTeam"] != self.pers["team"]))
		self promod\economy_items::clear();
	if (entry["demolitionTeam"] != "" && entry["demolitionTeam"] != self.pers["team"])
		self releaseDemolition();
	self ensureClass();
	self classChanged();
}

resetHalf()
{
	if (!enabled() || game["PROMOD_KNIFEROUND"] || game["economy"]["halfResetRound"] == game["roundsplayed"])
		return;
	game["economy"]["halfResetRound"] = game["roundsplayed"];
	ids = getArrayKeys(game["economy"]["accounts"]);
	for (i = 0; i < ids.size; i++)
	{
		entry = game["economy"]["accounts"][ids[i]];
		entry["cash"] = 0;
		entry["creditedRound"] = -1;
		entry["demolitionTeam"] = "";
		entry["frag"] = false;
		entry["redDot"] = false;
		entry["armor"] = 0;
		entry["sniperPenetration"] = false;
		entry["itemsRound"] = -1;
		entry["itemsTeam"] = "";
		game["economy"]["accounts"][ids[i]] = entry;
	}
	for (p = 0; p < level.players.size; p++)
		level.players[p] ensureClass();
	publishAll();
	logPrint("ECONOMY;halftime_reset\n");
}
