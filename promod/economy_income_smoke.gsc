// Dedicated validation only. See LICENSE.md.
// The economy suite runs with the legacy amounts set on the command line; these checks cover the defaults,
// the cash cap and the round-result money by setting the rules directly and restoring them afterwards.

check( condition, name )
{
	return promod\economy_smoke::check(condition, name);
}

run( player )
{
	defaultChecks();
	capChecks(player);
	roundResultChecks();
}

defaultChecks()
{
	names = strTok("promod_econ_start,promod_econ_round_pay,promod_econ_kill,promod_econ_assist,promod_econ_objective,promod_econ_win,promod_econ_loss,promod_econ_loss_step,promod_econ_loss_max,promod_econ_cap,promod_armor_absorb,promod_price_armor,promod_price_frag,promod_price_reddot,promod_price_suppressor,promod_price_demolition", ",");
	saved = [];
	for (i = 0; i < names.size; i++)
	{
		saved[i] = getDvar(names[i]);
		setDvar(names[i], "");
	}
	promod\economy::setupRules();
	check(level.economyStartCash == 50 && promod\economy::reward("round") == 50 && promod\economy::reward("kill") == 25 &&
		promod\economy::reward("assist") == 25 && promod\economy::reward("plant") == 50 && promod\economy::reward("defuse") == 50,
		"income_defaults");
	check(promod\economy::reward("win") == 100 && promod\economy::reward("loss") == 25 && level.economyLossStep == 25 &&
		level.economyLossMax == 100 && level.economyCap == 500, "round_result_and_cap_defaults");
	check(promod\economy::price("armor") == 100 && level.economyArmorAbsorb == 50 && promod\economy::price("frag") == 100 &&
		promod\economy::price("red_dot") == 100 && promod\economy::price("suppressor") == 50 && promod\economy::price("demolition") == 300,
		"price_defaults");
	setDvar("promod_econ_cap", -5);
	setDvar("promod_armor_absorb", 250);
	promod\economy::setupRules();
	check(level.economyCap == 0 && level.economyArmorAbsorb == 100, "settings_clamped_to_range");
	for (i = 0; i < names.size; i++)
		setDvar(names[i], saved[i]);
	promod\economy::setupRules();
}

capChecks( player )
{
	mates = promod\economy_smoke::teammates(player);
	mate = mates[0];
	cash = player promod\economy::cash();
	mateCash = mate promod\economy::cash();
	level.economyCap = cash + 30;
	check(player promod\economy::creditCash(50, "kill") == 30 && player promod\economy::cash() == cash + 30, "income_stops_at_cap");
	check(!player promod\economy::creditCash(10, "kill") && player promod\economy::cash() == cash + 30, "no_income_at_cap");
	check(player promod\economy::creditCash(20, "refund_test", true) == 20 && player promod\economy::cash() == cash + 50, "refund_ignores_cap");
	player promod\economy::trySpendCash(50, "cap_test_restore");
	level.economyCap = mateCash + 49;
	check(!player promod\economy::giveCash(mate) && player promod\economy::cash() == cash && mate promod\economy::cash() == mateCash,
		"gift_refused_over_recipient_cap");
	level.economyCap = mateCash + 50;
	if (player promod\economy::cash() >= 50)
		check(player promod\economy::giveCash(mate) && mate promod\economy::cash() == mateCash + 50, "gift_allowed_up_to_cap");
	level.economyCap = 0;
	if (mate promod\economy::cash() > mateCash)
	{
		mate promod\economy::trySpendCash(50, "cap_test_restore");
		player promod\economy::creditCash(50, "cap_test_restore");
	}
	check(player promod\economy::cash() == cash && mate promod\economy::cash() == mateCash, "cap_checks_restored");
}

paid( before, alliesPay, axisPay )
{
	for (i = 0; i < level.players.size; i++)
	{
		player = level.players[i];
		expected = before[player.pers["economy_id"]];
		if (player.pers["team"] == "allies") expected += alliesPay;
		if (player.pers["team"] == "axis") expected += axisPay;
		if (player promod\economy::cash() != expected)
			return false;
	}
	return true;
}

result( winner, alliesPay, axisPay, alliesStreak, axisStreak, name )
{
	before = promod\economy_smoke::cashSnapshot();
	game["economy"]["objectiveRounds"]["result"] = undefined;
	promod\economy::awardRoundResult(winner);
	check(paid(before, alliesPay, axisPay) && game["economy"]["lossStreak"]["allies"] == alliesStreak &&
		game["economy"]["lossStreak"]["axis"] == axisStreak, name);
}

roundResultChecks()
{
	rewards = level.economyRewards;
	step = level.economyLossStep;
	lossMax = level.economyLossMax;
	cap = level.economyCap;
	live = level.economyLive;
	original = promod\economy_smoke::cashSnapshot();
	level.economyRewards["win"] = 100;
	level.economyRewards["loss"] = 25;
	level.economyLossStep = 25;
	level.economyLossMax = 100;
	level.economyCap = 0;
	check(promod\economy::lossPay(0) == 25 && promod\economy::lossPay(1) == 25 && promod\economy::lossPay(2) == 50 &&
		promod\economy::lossPay(3) == 75 && promod\economy::lossPay(4) == 100 && promod\economy::lossPay(9) == 100, "loss_pay_grows_to_max");
	level.economyLive = true;
	promod\economy::resetLossStreaks();
	result("allies", 100, 25, 0, 1, "win_and_first_loss_money");
	before = promod\economy_smoke::cashSnapshot();
	promod\economy::awardRoundResult("allies");
	check(paid(before, 0, 0), "round_result_paid_once");
	result("allies", 100, 50, 0, 2, "second_loss_in_a_row");
	result("allies", 100, 75, 0, 3, "third_loss_in_a_row");
	result("allies", 100, 100, 0, 4, "loss_money_capped");
	result("allies", 100, 100, 0, 5, "loss_money_stays_capped");
	result("axis", 25, 100, 1, 0, "win_resets_streak");
	result("tie", 25, 25, 1, 0, "tie_pays_loss_without_streak");
	level.economyLive = false;
	result("allies", 0, 0, 1, 0, "no_round_result_before_live");
	promod\economy::resetLossStreaks();
	game["economy"]["objectiveRounds"]["result"] = undefined;
	for (i = 0; i < level.players.size; i++)
	{
		entry = level.players[i] promod\economy::account();
		entry["cash"] = original[level.players[i].pers["economy_id"]];
		level.players[i] promod\economy::saveAccount(entry);
		level.players[i] promod\economy::publish();
	}
	level.economyRewards = rewards;
	level.economyLossStep = step;
	level.economyLossMax = lossMax;
	level.economyCap = cap;
	level.economyLive = live;
}
