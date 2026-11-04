// Engine timing contract; ordinary servers retain Promod's network defaults.
// See LICENSE.md.
settings()
{
	result = spawnStruct();
	result.patched = false;
	result.highRate = false;
	result.fps = 20;
	result.frameMs = 50;
	result.snaps = 30;
	result.rate = 25000;
	// Soft smoke edges (r_zfeather) stay forced off unless the engine reports the v1 smoke policy.
	policy = strTok(getDvar("sv_volumetricSmoke"), " ");
	result.smokeDepth = policy.size > 0 && policy[0] == "v1";
	frameMs = getDvarInt("sv_tickrate_active_ms");
	if (getDvarInt("sv_tickrate_protocol") != 1 || (frameMs != 10 && frameMs != 50))
		return result;

	result.patched = true;
	result.highRate = frameMs < 50;
	result.fps = int(1000 / frameMs);
	result.frameMs = frameMs;
	result.snaps = result.fps;
	result.rate = max(result.rate, min(100000, getDvarInt("sv_minRate")));
	maxRate = getDvarInt("sv_maxrate"); // 0 is unlimited; the engine floors client rates at 2500
	if (maxRate >= 2500)
		result.rate = min(result.rate, maxRate);
	return result;
}
