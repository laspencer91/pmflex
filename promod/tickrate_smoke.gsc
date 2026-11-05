// Private dedicated-server timing fixture. See LICENSE.md.
run()
{
	level endon("restarting");
	level.tickrateTestFailed = false;
	wait 1;
	network = promod\tickrate::settings();
	check(getDvarInt("sv_fps") == network.fps, "effective_fps");
	expectedFps = getDvarInt("tickrate_test_expected_fps");
	if (expectedFps)
		check(getDvarInt("sv_fps") == expectedFps, "requested_fps");
	checkPolicyRefresh(network.patched);

	timeWaits(20, 0.05, "twenty_short_waits");
	timeWaits(100, 0.05, "plant_wait_chain");
	timeWaits(200, 0.05, "defuse_wait_chain");
	timeWaits(4, 0.25, "four_quarter_waits");

	start = getTime();
	wait 1;
	checkTime(getTime() - start, 1000, "integer_wait");

	flash = spawn("script_origin", (0,0,0));
	start = getTime();
	flash thread maps\mp\_flashgrenades::overlapProtect(1);
	while ((!isDefined(flash.flashDuration) || flash.flashDuration > 0) && getTime() - start < 2000)
		wait 0.01;
	checkTime(getTime() - start, 1000, "flash_protection");
	check(flash.flashDuration == 0, "flash_protection_expired");
	flash thread maps\mp\_flashgrenades::overlapProtect(1);
	wait 0.2;
	check(flash.flashDuration > 0 && flash.flashDuration < 1, "flash_protection_remaining");
	flash notify("strongerFlash");
	flash.flashDuration = 2;
	wait 0.2;
	check(flash.flashDuration == 2, "stronger_flash_cancels_old_protection");
	flash delete();

	if (!level.tickrateTestFailed)
		logPrint("TICKRATE_TEST;PASSED;" + network.fps + "\n");
}

checkPolicyRefresh(patched)
{
	policy = getDvar("sv_volumetricSmoke");
	smokeType = getDvar("smoke_type");
	setDvar("smoke_type", ""); // exercise legacy policy compatibility independently
	setDvar("sv_volumetricSmoke", "v1");
	network = promod\tickrate::settings();
	check(network.smokeDepth, "smoke_policy_enabled");
	setDvar("sv_volumetricSmoke", "");
	network = promod\tickrate::settings();
	check(!network.smokeDepth, "smoke_policy_disabled");
	setDvar("sv_volumetricSmoke", "v1");
	setDvar("smoke_type", "0");
	network = promod\tickrate::settings();
	check(!network.smokeDepth, "stock_smoke_overrides_policy");
	setDvar("smoke_type", "1");
	setDvar("sv_volumetricSmoke", "");
	network = promod\tickrate::settings();
	check(network.smokeDepth, "volume_smoke_defaults_without_tuning");
	setDvar("smoke_type", "2");
	network = promod\tickrate::settings();
	check(!network.smokeDepth, "invalid_smoke_type_keeps_stock");
	setDvar("smoke_type", smokeType);
	setDvar("sv_volumetricSmoke", policy);
	if (!patched) return;

	minRate = getDvar("sv_minRate");
	maxRate = getDvar("sv_maxrate");
	setDvar("sv_minRate", 50000);
	setDvar("sv_maxrate", 60000);
	network = promod\tickrate::settings();
	check(network.rate == 50000, "bandwidth_minimum_refreshed");
	setDvar("sv_maxrate", 40000);
	network = promod\tickrate::settings();
	check(network.rate == 40000, "bandwidth_maximum_refreshed");
	setDvar("sv_maxrate", maxRate);
	setDvar("sv_minRate", minRate);
}

timeWaits(count, seconds, name)
{
	start = getTime();
	for (i = 0; i < count; i++) wait seconds;
	checkTime(getTime() - start, count * seconds * 1000, name);
}

checkTime(actual, expected, name)
{
	logPrint("TICKRATE_TEST;TIME;" + name + ";" + actual + ";" + expected + "\n");
	network = promod\tickrate::settings();
	check(abs(actual - expected) <= network.frameMs, name);
}

check(condition, name)
{
	if (condition) return;
	level.tickrateTestFailed = true;
	logPrint("TICKRATE_TEST;FAILED;" + name + "\n");
}
