// Offline interface. Managed CoD4x servers load private match_stats.gsx instead.
enabled() { return false; }
live() { return false; }
init()
{
    level.matchStatsPrivateReady = false;
    if (getDvarInt("cp_stats_stub_probe")) logPrint("CP_STATS;PUBLIC_STUB_LOADED\n");
    if (promod\platform::enabled()) logPrint("CP_STATS;PRIVATE_OVERLAY_REQUIRED\n");
}
connected() {}
disconnected() {}
spawned() {}
startRound() {}
endRound(winner, reason) {}
complete(winner) {}
damage(attacker, amount, cause, weapon, location, flags) {}
death(attacker, cause, weapon) {}
plant(site) {}
defuse() {}
hqCaptured() {}
hqDestroyed() {}
hqCycleEnd() {}
hqMode() { return false; }
account() { return undefined; }
