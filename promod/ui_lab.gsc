/*
  Promod UI learning pass, added 2026-10-09.
  Licensed under the Promod Modder Ethical Public License; see LICENSE.md.
  Demonstration values are independent of gameplay health, armor, and money.
*/

#include maps\mp\gametypes\_hud_util;

initPlayer()
{
	self endon("disconnect");
	level endon("restarting");
	self.labCounter = 0;
	self.labFill = 0.75;
	self.labAnchor = 0;
	self.labVisible = getDvarInt("ui_lab_hud") || getDvarInt("ui_lab_smoke");
	self.labGap = 12;
	self.labStyle = 0;
	self.labOpacity = 0.9;
	self.labMaterial = "lab_grad_cool";
	self.labMarginPercent = 3;
	if (getDvar("ui_lab_margin_percent") != "")
		self.labMarginPercent = max(1, min(getDvarFloat("ui_lab_margin_percent"), 10));
	self.labElements = [];
	self.labCards = [];
	self setClientDvars("ui_lab_page", 0, "ui_lab_counter", 0,
		"ui_lab_fill", 75, "ui_lab_gap", 12, "ui_lab_anchor", "TOP LEFT",
		"ui_lab_status", "Waiting for an event");
	self setClientDvar("ui_lab_margin_percent", self.labMarginPercent);
	self setClientDvars("ui_lab_material", self.labMaterial, "ui_lab_style_name", "Ocean and violet",
		"ui_lab_opacity", self.labOpacity, "ui_lab_opacity_percent", 90);
	// The stock HUD establishes level.uiParent and level.fontHeight.
	while (!isDefined(level.uiParent) || !isDefined(level.fontHeight))
		wait 0.05;
	self buildPreview();
	self thread revealCards();
	self thread watchSpawns();
}

watchSpawns()
{
	self endon("disconnect");
	level endon("restarting");
	for (;;)
	{
		self waittill("spawned_player");
		self.labCounter++;
		self publish("Player spawn event");
	}
}

// Component factory: one panel owns its title, value, and bar via setParent.
createCard( title, x, y, width, height, accent, iconMaterial, iconWidth )
{
	card = spawnstruct();
	card.width = width;
	card.height = height;
	card.panel = self createIcon("white", width, height);
	card.panel.alpha = 0;
	card.panel.sort = 20;
	card.panel setPoint("TOPLEFT", "TOPLEFT", x, y);
	self registerElement(card.panel);
	card.background = self createIcon(self.labMaterial, width, height);
	card.background setParent(card.panel);
	card.background setPoint("CENTER", "CENTER", 0, 0);
	card.background.alpha = self.labOpacity;
	card.background.sort = 20;
	self registerElement(card.background);
	card.frame = self createIcon("lab_corner_panel", width, height);
	card.frame setParent(card.panel);
	card.frame setPoint("TOPLEFT", "TOPLEFT", 0, 0);
	card.frame.color = (1, 1, 1);
	card.frame.sort = 23;
	self registerElement(card.frame);
	card.glow = self createIcon("lab_glow_panel", width * 2, height * 2);
	card.glow setParent(card.panel);
	card.glow setPoint("CENTER", "CENTER", 0, 0);
	card.glow.color = (1, 1, 1);
	card.glow.alpha = 0.65;
	card.glow.sort = 21;
	self registerElement(card.glow);
	card.icon = self createIcon(iconMaterial, iconWidth, 16);
	card.icon setParent(card.panel);
	card.icon setPoint("TOPLEFT", "TOPLEFT", 10, 12);
	card.icon.color = accent;
	card.icon.sort = 22;
	self registerElement(card.icon);

	card.title = self createFontString("default", 1.4);
	card.title setParent(card.panel);
	card.title setPoint("TOPLEFT", "TOPLEFT", 50, 8);
	card.title.color = accent;
	card.title.sort = 22;
	card.title setText(title);
	self registerElement(card.title);

	card.value = self createFontString("default", 1.7);
	card.value setParent(card.panel);
	card.value setPoint("TOPLEFT", "TOPLEFT", 50, 27);
	card.value.sort = 22;
	self registerElement(card.value);

	card.bar = self createProgress(card.panel, 10, height - 12, width - 20, 5, accent);
	return card;
}

// Background and fill share one origin and height, using the same material.
createProgress( parent, x, y, width, height, accent )
{
	progress = spawnstruct();
	progress.width = width;
	progress.height = height;
	progress.fraction = 0;
	progress.background = self createIcon("white", width, height);
	progress.background.color = (0.12, 0.16, 0.20);
	progress.background.sort = 21;
	progress.background setParent(parent);
	progress.background setPoint("TOPLEFT", "TOPLEFT", x, y);
	self registerElement(progress.background);
	progress.fill = self createIcon("white", width, height);
	progress.fill.color = accent;
	progress.fill.sort = 22;
	progress.fill setParent(progress.background);
	progress.fill setPoint("TOPLEFT", "TOPLEFT", 0, 0);
	self registerElement(progress.fill);
	self updateProgress(progress, 0);
	return progress;
}

updateProgress( progress, fraction )
{
	progress.fraction = max(0, min(fraction, 1));
	pixels = int(max(1, int(progress.width * progress.fraction + 0.5)));
	progress.fill.width = pixels;
	progress.fill setShader("white", pixels, progress.height);
	progress.fill.labAlpha = int(progress.fraction > 0);
	progress.fill.alpha = progress.fill.labAlpha * int(self.labVisible);
}

registerElement( element )
{
	element.foreground = true;
	element.hideWhenInMenu = false;
	element.labAlpha = element.alpha;
	if (!self.labVisible) element.alpha = 0;
	self.labElements[self.labElements.size] = element;
}

buildPreview()
{
	self.labCards[0] = self createCard("EVENT COUNT", 20, 14, 158, 72, (0.35, 0.85, 0.95), "hud_suitcase_bomb", 16);
	self.labCards[1] = self createCard("SAMPLE FILL", 20, 98, 158, 72, (0.95, 0.72, 0.30), "hud_icon_ak47", 32);
	self.labCards[0].value setValue(self.labCounter);
	self updateProgress(self.labCards[0].bar, 0);
	self.labCards[1].value setValue(75);
	self updateProgress(self.labCards[1].bar, self.labFill);
	self.labToast = self createFontString("default", 1.4);
	self.labToast setPoint("TOP", "TOP", 0, 66);
	self.labToast.color = (0.35, 0.85, 0.95);
	self.labToast.glowColor = (1, 1, 1);
	self.labToast.glowAlpha = 0.65;
	self.labToast.sort = 30;
	self.labToast.alpha = 0;
	self registerElement(self.labToast);
	self layoutPreview();
	logPrint("UI_LAB;preview_created;" + self getEntityNumber() + "\n");
}

respond( response )
{
	if (!isDefined(self.labCounter))
		return;
	switch (response)
	{
		case "open":
			self closeMenu();
			self closeInGameMenu();
			self openMenu("ui_lab");
			return;
		case "event":
			self.labCounter++;
			self publish("Manual menu event");
			return;
		case "fill":
			self.labFill -= 0.25;
			if (self.labFill < 0)
				self.labFill = 1;
			self publish("Sample fill changed");
			return;
		case "spacing":
			self.labGap += 8;
			if (self.labGap > 28)
				self.labGap = 4;
			self layoutPreview();
			self setClientDvar("ui_lab_gap", self.labGap);
			return;
		case "anchor":
			self.labAnchor = (self.labAnchor + 1) % 3;
			self layoutPreview();
			return;
		case "margin":
			self.labMarginPercent += 2;
			if (self.labMarginPercent > 7)
				self.labMarginPercent = 3;
			self setClientDvar("ui_lab_margin_percent", self.labMarginPercent);
			self layoutPreview();
			return;
		case "style":
			self.labStyle = (self.labStyle + 1) % 3;
			self applyStyle();
			return;
		case "opacity":
			self.labOpacity -= 0.25;
			if (self.labOpacity < 0.39)
				self.labOpacity = 0.9;
			self setClientDvars("ui_lab_opacity", self.labOpacity,
				"ui_lab_opacity_percent", int(self.labOpacity * 100 + 0.5));
			for (i = 0; i < self.labCards.size; i++)
			{
				background = self.labCards[i].background;
				background.labAlpha = self.labOpacity;
				background.alpha = self.labOpacity * int(self.labVisible);
			}
			return;
		case "reveal":
			self thread revealCards();
			return;
		case "toggle":
			self notify("ui_lab_reveal");
			self.labVisible = !self.labVisible;
			for (i = 0; i < self.labElements.size; i++)
			{
				element = self.labElements[i];
				if (self.labVisible)
					element.alpha = element.labAlpha;
				else
					element.alpha = 0;
			}
			return;
		case "close":
			self closeMenu();
			self closeInGameMenu();
			return;
	}
}

applyStyle()
{
	name = "Ocean and violet";
	self.labMaterial = "lab_grad_cool";
	if (self.labStyle == 1)
	{
		name = "Amber and graphite";
		self.labMaterial = "lab_grad_warm";
	}
	else if (self.labStyle == 2)
	{
		name = "Steel and smoke";
		self.labMaterial = "lab_grad_slate";
	}
	self setClientDvars("ui_lab_material", self.labMaterial, "ui_lab_style_name", name);
	for (i = 0; i < self.labCards.size; i++)
	{
		card = self.labCards[i];
		card.background setShader(self.labMaterial, card.width, card.height);
	}
	self thread revealCards();
}

revealCards()
{
	self notify("ui_lab_reveal");
	self endon("ui_lab_reveal");
	self endon("disconnect");
	level endon("restarting");
	if (!self.labVisible)
		return;
	for (i = 0; i < self.labElements.size; i++)
		self.labElements[i].alpha = 0;
	for (i = 0; i < self.labCards.size; i++)
	{
		card = self.labCards[i];
		card.background setShader(self.labMaterial, 1, 1);
		card.background scaleOverTime(0.28, card.width, card.height);
		card.background fadeOverTime(0.2);
		card.background.alpha = self.labOpacity;
	}
	wait 0.3;
	for (i = 0; i < self.labElements.size; i++)
	{
		element = self.labElements[i];
		element fadeOverTime(0.15);
		element.alpha = element.labAlpha;
	}
	logPrint("UI_LAB;reveal_complete\n");
}

layoutPreview()
{
	anchor = "TOPLEFT";
	x = 20;
	// The vertical HUD canvas is 480 units. Use a configurable percentage.
	margin = int(480 * self.labMarginPercent / 100);
	y = margin;
	anchorName = "TOP LEFT";
	if (self.labAnchor == 1)
	{
		anchor = "TOPRIGHT";
		x = -20;
		anchorName = "TOP RIGHT";
	}
	else if (self.labAnchor == 2)
	{
		anchor = "BOTTOMLEFT";
		y = 0 - margin;
		anchorName = "BOTTOM LEFT";
	}
	for (i = 0; i < self.labCards.size; i++)
	{
		card = self.labCards[i];
		offset = i * (72 + self.labGap);
		if (self.labAnchor == 2)
			offset = 0 - offset;
		card.panel setPoint(anchor, anchor, x, y + offset);
	}
	self setClientDvar("ui_lab_anchor", anchorName);
}

publish( message )
{
	self setClientDvars("ui_lab_counter", self.labCounter,
		"ui_lab_fill", int(self.labFill * 100), "ui_lab_status", message);
	self.labCards[0].value setValue(self.labCounter);
	self updateProgress(self.labCards[0].bar, self.labCounter / 10.0);
	self.labCards[1].value setValue(int(self.labFill * 100));
	self updateProgress(self.labCards[1].bar, self.labFill);
	if (self.labVisible)
		self thread animateToast(message);
	logPrint("UI_LAB;event;" + message + ";counter;" + self.labCounter + "\n");
}

animateToast( message )
{
	self notify("ui_lab_new_toast");
	self endon("ui_lab_new_toast");
	self endon("disconnect");
	level endon("restarting");
	self.labToast setText(message);
	self.labToast setPulseFX(0, 800, 500);
	self.labToast.alpha = 1;
	self.labToast.y = 60;
	self.labToast moveOverTime(0.25);
	self.labToast.y = 66;
	wait 0.8;
	self.labToast fadeOverTime(0.5);
	self.labToast.alpha = 0;
}
