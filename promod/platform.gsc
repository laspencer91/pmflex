// CoD4x servers override this with platform.gsx after loading cp_platform.
enabled() { return getDvarInt("cp_platform_enabled") == 1; }
readyState() { return !enabled(); }
readyTimeout() {}
authorize()
{
    if (getDvarInt("cp_platform_enabled") != 1) return true;
    return false;
}
spawnGuard() { return self authorize(); }
onSideSwitch() {}
emit(payload) {}
shotId()
{
    if (getDvarInt("cp_stats_smoke") && isDefined(self.cpStatsShot)) return self.cpStatsShot;
    return "";
}
