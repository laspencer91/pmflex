// Dedicated check for the new selector. See LICENSE.md.
run()
{
	self notify("menuresponse", "flat_loadout", "money_sounds");
	wait 1.2;
	if (getDvarInt("class_assault_limit") != 5 || getDvarInt("class_specops_limit") != 2 ||
		getDvarInt("class_sniper_limit") != 1 || getDvarInt("class_demolitions_limit") != 1) return failed("slot_rules");
	self notify("menuresponse", "flat_loadout", "select:specops");
	wait 0.2;
	if (self.pers["class"] != "specops") return failed("class_selection");
	self notify("menuresponse", "flat_primary_picker", "pick_primary:0");
	wait 0.2;
	self notify("menuresponse", "flat_primary_picker", "primary:g3");
	wait 0.2;
	if (self.pers["specops"]["loadout_primary"] != "mp5") return failed("invalid_weapon");
	self notify("menuresponse", "flat_primary_picker", "pick_primary:999");
	wait 0.2;
	if (self.pers["specops"]["loadout_primary"] != "mp5") return failed("invalid_row");
	self notify("menuresponse", "flat_loadout", "attachment:silencer");
	wait 0.2;
	self notify("menuresponse", "flat_secondary_picker", "secondary:usp");
	wait 0.2;
	self notify("menuresponse", "flat_loadout", "pistol_attachment:silencer");
	wait 0.2;
	self notify("menuresponse", "flat_loadout", "grenade:flash_grenade");
	wait 0.2;
	if (self.pers["specops"]["loadout_primary_attachment"] != "silencer" ||
		self.pers["specops"]["loadout_secondary"] != "usp" ||
		self.pers["specops"]["loadout_secondary_attachment"] != "silencer" ||
		self.pers["specops"]["loadout_grenade"] != "flash_grenade") return failed("inline_loadout");
	self notify("menuresponse", "flat_loadout", "toggle_tactical");
	wait 0.2;
	if (self.pers["specops"]["loadout_grenade"] != "smoke_grenade") return failed("tactical_toggle");
	wait 0.2;
	if (self.flatPreviewCash != 550 || self.flatCashShown != 550) return failed("suppressor_price_preview");
	entry = self promod\economy::account();
	oldCash = entry["cash"];
	self notify("menuresponse", "flat_loadout", "preview_frag");
	wait 0.10;
	if (self.flatPreviewFrag != 1 || self.flatPreviewCash != 450) return failed("frag_preview");
	if (self.flatCashShown <= 450 || self.flatCashShown >= 550) return failed("cash_count_down");
	self notify("menuresponse", "flat_loadout", "preview_frag");
	wait 0.4;
	if (self.flatPreviewFrag != 0 || self.flatPreviewCash != 550 || self.flatCashShown != 550) return failed("preview_refund_count_up");
	entry = self promod\economy::account();
	if (entry["cash"] != oldCash) return failed("preview_account_unchanged");
	setDvar("weap_allow_frag_grenade", 0);
	self notify("menuresponse", "flat_loadout", "preview_frag");
	wait 0.1;
	if (self.flatPreviewFrag != 0) return failed("disabled_frag_preview");
	setDvar("weap_allow_frag_grenade", 1);
	self notify("menuresponse", "flat_loadout", "select:assault");
	wait 0.2;
	if (self.flatPrimaryOptions.size != 7) return failed("all_rifles");
	setDvar("weap_allow_g3", 0);
	self notify("menuresponse", "flat_loadout", "refresh");
	wait 0.2;
	if (self.flatPrimaryOptions.size != 6) return failed("enabled_filter");
	setDvar("weap_allow_g3", 1);
	self notify("menuresponse", "flat_loadout", "select:specops");
	wait 0.2;
	oldCamo = self.pers["specops"]["loadout_camo"];
	self notify("menuresponse", "flat_loadout", "camo:next");
	wait 0.2;
	if (self.pers["specops"]["loadout_camo"] == oldCamo) return failed("camo_cycle");
	// All native camo swatches, including the eligible gold wrap, use this response.
	self notify("menuresponse", "flat_loadout", "primary:uzi");
	wait 0.2;
	self.pers["specops"]["loadout_camo"] = "camo_none";
	for (skin = 0; skin < 7; skin++)
	{
		self notify("menuresponse", "flat_loadout", "camo:next");
		wait 0.1;
	}
	if (self.pers["specops"]["loadout_camo"] != "camo_none") return failed("camo_wrap");
	other = addTestClient();
	if (!isDefined(other)) return failed("second_client");
	deadline = getTime() + 5000;
	while (!isDefined(other.labCards) || !isDefined(other.pers["team"]))
	{
		if (getTime() > deadline) return failed("second_client_init");
		wait 0.05;
	}
	other.pers["isBot"] = true;
	other notify("menuresponse", game["menu_team"], "allies");
	wait 0.3;
	if (!self previewTransferCheck(other)) return false;
	oldLimit = getDvarInt("class_demolitions_limit");
	setDvar("class_demolitions_limit", 1);
	beforeCash = other.flatPreviewCash;
	other notify("menuresponse", "flat_loadout", "select:demolitions");
	wait 0.1;
	if (!other.flatDemoPending || other.flatPreviewCash != beforeCash || (isDefined(other.pers["class"]) && other.pers["class"] == "demolitions")) return failed("confirmation_no_charge");
	other notify("menuresponse", "flat_demolition_confirm", "cancel_demolition");
	wait 0.1;
	other notify("menuresponse", "flat_demolition_confirm", "confirm_demolition");
	wait 0.1;
	if (other.flatDemoPending || other.flatPreviewCash != beforeCash || (isDefined(other.pers["class"]) && other.pers["class"] == "demolitions")) return failed("confirmation_cancel");
	other notify("menuresponse", "flat_loadout", "select:demolitions");
	wait 0.1;
	other notify("menuresponse", "flat_demolition_confirm", "confirm_demolition");
	wait 0.3;
	self notify("menuresponse", "flat_loadout", "select:demolitions");
	wait 0.1;
	self notify("menuresponse", "flat_demolition_confirm", "confirm_demolition");
	wait 0.3;
	if (other.pers["class"] != "demolitions" || self.pers["class"] != "specops" ||
		self.flatCounts["demolitions"] != 1 || self.flatLimits["demolitions"] != 1) return failed("full_class_denied");
	if (other.flatPreviewCash != beforeCash - 300) return failed("confirmation_single_charge");
	other notify("menuresponse", "flat_loadout", "select:demolitions");
	wait 0.1;
	other notify("menuresponse", "flat_demolition_confirm", "confirm_demolition");
	wait 0.2;
	if (!other maps\mp\gametypes\_promod::verifyClassChoice("allies", "demolitions")) return failed("own_class_exception");
	if (other.flatPreviewCash != beforeCash - 300) return failed("owned_demo_no_charge");
	other notify("menuresponse", "flat_loadout", "select:assault");
	wait 0.3;
	if (self.flatCounts["demolitions"] != 0) return failed("slot_release");
	self notify("menuresponse", "flat_loadout", "select:demolitions");
	wait 0.1;
	self notify("menuresponse", "flat_demolition_confirm", "confirm_demolition");
	wait 0.3;
	if (self.pers["class"] != "demolitions" || self.flatCounts["demolitions"] != 1) return failed("slot_reclaim");
	self notify("menuresponse", "flat_loadout", "select:sniper");
	wait 0.2;
	self notify("menuresponse", "flat_loadout", "primary:m40a3");
	wait 0.2;
	self notify("menuresponse", "flat_loadout", "attachment:silencer");
	wait 0.2;
	if (self.pers["sniper"]["loadout_primary_attachment"] != "none") return failed("sniper_attachment_denied");
	setDvar("class_demolitions_limit", oldLimit);
	self maps\mp\gametypes\_promod::updateClassAvailability("allies");
	self notify("menuresponse", "flat_loadout", "deploy");
	wait 0.5;
	if (!self economyCardCheck()) return false;
	logPrint("FLAT_LOADOUT;SMOKE_PASSED;classes;inline_loadout;invalid_weapon;attachments;grenades;camo;two_clients;capacity;own_slot;release;reclaim;deploy;slot_rules;picker_indices;enabled_filter;tactical_toggle;frag_preview;suppressor_price_preview;preview_account_unchanged;disabled_frag_preview;cash_count_down;cash_count_up_interrupted;camo_wrap;economy_card_fixture;demolition_confirmation;preview_transfer\n");
	return true;
}

economyCardCheck()
{
	// A direct fixture checks the new class-card route, not round-income logic.
	oldMode = game["PROMOD_MATCH_MODE"];
	oldReady = game["promod_do_readyup"];
	oldTimeout = game["promod_timeout_called"];
	oldKnife = game["PROMOD_KNIFEROUND"];
	game["PROMOD_MATCH_MODE"] = "match";
	game["promod_do_readyup"] = 0;
	game["promod_timeout_called"] = 0;
	game["PROMOD_KNIFEROUND"] = 0;
	level.economyBuyOpen = true;
	level.economyBuyEnd = getTime() + 5000;
	entry = self promod\economy::account();
	entry["cash"] = 300;
	entry["creditedRound"] = game["roundsplayed"];
	entry["demolitionTeam"] = "";
	self promod\economy::saveAccount(entry);
	previousAppliedClass = self.curClass;
	previousSpawn = self.spawnTime;
	self notify("menuresponse", "flat_loadout", "select:demolitions");
	wait 0.1;
	self notify("menuresponse", "flat_demolition_confirm", "confirm_demolition");
	wait 0.3;
	entry = self promod\economy::account();
	passed = self.pers["class"] == "demolitions" && entry["cash"] == 0 && self promod\economy::ownsDemolition();
	if (!self.flatMenuOpen || self.curClass != previousAppliedClass || self.spawnTime != previousSpawn) passed = false;
	// Refresh also exercises teammate cash against the economy's array ledger.
	self notify("menuresponse", "flat_loadout", "refresh");
	wait 0.2;
	self notify("menuresponse", "flat_loadout", "preview_frag");
	wait 0.1;
	if (self.flatPreviewFrag != 0) passed = false;
	oldTransfer = self.flatPreviewTransfer;
	self promod\flat_loadout::givePreviewCash("1");
	if (self.flatPreviewTransfer != oldTransfer) passed = false;
	game["PROMOD_MATCH_MODE"] = oldMode;
	game["promod_do_readyup"] = oldReady;
	game["promod_timeout_called"] = oldTimeout;
	game["PROMOD_KNIFEROUND"] = oldKnife;
	level.economyBuyOpen = false;
	if (!passed) return failed("economy_card_fixture");
	return true;
}

failed( reason )
{
	logPrint("UI_LAB;SMOKE_FAILED;flat_loadout;" + reason + "\n");
	return false;
}

previewTransferCheck( other )
{
	self promod\flat_loadout::refresh();
	token = other promod\flat_loadout::donationToken();
	senderCash = self.flatPreviewCash;
	recipientCash = other.flatPreviewCash;
	entry = self promod\economy::account();
	ledgerCash = entry["cash"];
	self notify("menuresponse", "flat_loadout", "give:" + token);
	wait 0.2;
	if (self.flatPreviewCash != senderCash - 50 || other.flatPreviewCash != recipientCash + 50) return failed("preview_transfer");
	entry = self promod\economy::account();
	if (entry["cash"] != ledgerCash) return failed("transfer_ledger_unchanged");
	self notify("menuresponse", "flat_loadout", "give:999");
	wait 0.1;
	if (self.flatPreviewCash != senderCash - 50) return failed("transfer_invalid_target");
	self.flatPreviewTransfer -= 1000;
	self promod\flat_loadout::refresh();
	before = self.flatPreviewTransfer;
	self notify("menuresponse", "flat_loadout", "give:" + token);
	wait 0.1;
	if (self.flatPreviewTransfer != before) return failed("transfer_insufficient_cash");
	self.flatPreviewTransfer += 1000;
	self promod\flat_loadout::refresh();
	return true;
}
