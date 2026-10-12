// Optional runtime check, added 2026-10-09. See LICENSE.md.
// Enabled only by +set ui_lab_smoke 1 on the dedicated smoke server.
run()
{
	level endon("restarting");
	wait 3;
	// comp::main resets logging options; enable flushing after initialization.
	setDvar("g_logSync", 1);
	setDvar("logfile", 2);
	bot = addTestClient();
	if (!isDefined(bot))
	{
		logPrint("UI_LAB;SMOKE_FAILED;no_test_client\n");
		return;
	}
	deadline = getTime() + 10000;
	while (!isDefined(bot.labCards) || bot.labCards.size < 2)
	{
		if (getTime() > deadline)
		{
			logPrint("UI_LAB;SMOKE_FAILED;preview_timeout\n");
			return;
		}
		wait 0.05;
	}
	if (bot.labCards[0].title.parent != bot.labCards[0].panel ||
		bot.labCards[0].icon.parent != bot.labCards[0].panel ||
		bot.labCards[1].icon.parent != bot.labCards[1].panel)
	{
		logPrint("UI_LAB;SMOKE_FAILED;parent_link\n");
		return;
	}
	// Use the same menuresponse path as the in-game buttons and key binds.
	bot notify("menuresponse", "ui_lab", "event");
	wait 0.2;
	bot notify("menuresponse", "ui_lab", "fill");
	wait 0.2;
	bot notify("menuresponse", "ui_lab", "spacing");
	wait 0.2;
	bot notify("menuresponse", "ui_lab", "anchor");
	wait 0.2;
	bot notify("menuresponse", "ui_lab", "anchor");
	wait 0.2;
	bot notify("menuresponse", "ui_lab", "toggle");
	wait 0.2;
	if (bot.labVisible || bot.labCards[0].background.alpha != 0 || bot.labCards[0].frame.alpha != 0)
	{
		logPrint("UI_LAB;SMOKE_FAILED;hide\n");
		return;
	}
	bot notify("menuresponse", "ui_lab", "toggle");
	wait 0.2;
	if (bot.labCounter != 1 || bot.labFill != 0.5 || bot.labGap != 20 ||
		bot.labAnchor != 2 || !bot.labVisible || bot.labCards[1].bar.fraction != 0.5)
	{
		logPrint("UI_LAB;SMOKE_FAILED;state\n");
		return;
	}
	for (i = 0; i < bot.labCards.size; i++)
	{
		bar = bot.labCards[i].bar;
		if (bar.fill.x != bar.background.x || bar.fill.y != bar.background.y ||
			bar.fill.height != bar.background.height || bar.fill.horzAlign != bar.background.horzAlign ||
			bar.fill.vertAlign != bar.background.vertAlign)
		{
			logPrint("UI_LAB;SMOKE_FAILED;bar_alignment\n");
			return;
		}
	}
	bot promod\ui_lab::updateProgress(bot.labCards[1].bar, 0);
	if (bot.labCards[1].bar.fill.alpha != 0)
	{
		logPrint("UI_LAB;SMOKE_FAILED;empty_bar\n");
		return;
	}
	bot promod\ui_lab::updateProgress(bot.labCards[1].bar, 1);
	if (bot.labCards[1].bar.fill.width != bot.labCards[1].bar.background.width)
	{
		logPrint("UI_LAB;SMOKE_FAILED;full_bar\n");
		return;
	}
	bot promod\ui_lab::updateProgress(bot.labCards[1].bar, 0.5);
	bot notify("menuresponse", "ui_lab", "style");
	wait 0.6;
	if (bot.labStyle != 1 || bot.labMaterial != "lab_grad_warm" ||
		bot.labCards[0].background.width != 158 || bot.labCards[0].background.height != 72 ||
		bot.labCards[0].frame.alpha != 1 || bot.labCards[0].title.alpha != 1)
	{
		logPrint("UI_LAB;SMOKE_FAILED;style_reveal\n");
		return;
	}
	bot notify("menuresponse", "ui_lab", "style");
	wait 0.6;
	if (bot.labStyle != 2 || bot.labMaterial != "lab_grad_slate")
	{
		logPrint("UI_LAB;SMOKE_FAILED;slate_style\n");
		return;
	}
	bot notify("menuresponse", "ui_lab", "style");
	wait 0.6;
	if (bot.labStyle != 0 || bot.labMaterial != "lab_grad_cool")
	{
		logPrint("UI_LAB;SMOKE_FAILED;style_wrap\n");
		return;
	}
	bot notify("menuresponse", "ui_lab", "opacity");
	wait 0.2;
	if (bot.labCards[0].background.alpha < 0.64 || bot.labCards[0].background.alpha > 0.66)
	{
		logPrint("UI_LAB;SMOKE_FAILED;opacity\n");
		return;
	}
	bot notify("menuresponse", "ui_lab", "reveal");
	wait 0.6;
	if (bot.labCards[0].background.alpha < 0.64 || bot.labCards[0].background.alpha > 0.66 ||
		bot.labCards[1].background.width != 158 || bot.labCards[1].background.height != 72)
	{
		logPrint("UI_LAB;SMOKE_FAILED;replay\n");
		return;
	}
	bot notify("menuresponse", "ui_lab", "margin");
	wait 0.2;
	if (bot.labMarginPercent != 5 || bot.labCards[0].panel.y != -24)
	{
		logPrint("UI_LAB;SMOKE_FAILED;margin\n");
		return;
	}
	bot.pers["isBot"] = true;
	while (!isDefined(bot.pers) || !isDefined(bot.pers["team"]))
		wait 0.05;
	bot notify("menuresponse", game["menu_team"], "allies");
	wait 0.5;
	classResponse = "assault";
	if (getDvarInt("ui_flat_loadout")) classResponse = "select:assault";
	bot notify("menuresponse", game["menu_changeclass_allies"], classResponse);
	wait 0.5;
	deployResponse = "go";
	if (getDvarInt("ui_flat_loadout")) deployResponse = "deploy";
	bot notify("menuresponse", game["menu_changeclass"], deployResponse);
	wait 2;
	if (bot.labCounter < 2)
	{
		logPrint("UI_LAB;SMOKE_FAILED;spawn_event\n");
		return;
	}
	if (getDvarInt("ui_flat_loadout"))
		if (!bot promod\flat_loadout_smoke::run()) return;
	setDvar("ui_lab_smoke", 0);
	hidden = addTestClient();
	if (!isDefined(hidden))
	{
		logPrint("UI_LAB;SMOKE_FAILED;hidden_client\n");
		return;
	}
	deadline = getTime() + 5000;
	while (!isDefined(hidden.labCards) || hidden.labCards.size < 2)
	{
		if (getTime() > deadline)
		{
			logPrint("UI_LAB;SMOKE_FAILED;hidden_preview_init\n");
			return;
		}
		wait 0.05;
	}
	if (hidden.labVisible)
	{
		logPrint("UI_LAB;SMOKE_FAILED;default_hud_visible\n");
		return;
	}
	for (i = 0; i < hidden.labElements.size; i++)
		if (hidden.labElements[i].alpha != 0)
		{
			logPrint("UI_LAB;SMOKE_FAILED;default_hud_alpha\n");
			return;
		}
	logPrint("UI_LAB;DEFAULT_HUD_HIDDEN\n");
	logPrint("UI_LAB;SMOKE_PASSED;cards;menu_events;fill;spacing;anchors;visibility;spawn;bar_alignment;empty_bar;full_bar;margin;icons;styles;opacity;reveal\n");
}
