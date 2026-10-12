// Headquarters recorder fixtures (g_gametype koth): capture, destroy, respawn, cycle end, half end and a tied total.
run()
{
    wait 3;
    ids = promod\match_stats_smoke::fixtureIds();
    actors = promod\match_stats_smoke::spawnActors(ids);
    if (!isDefined(actors)) return;
    level.rdyup = false; level.forcedEnd = false; game["PROMOD_KNIFEROUND"] = false;
    game["cpSide0"] = "allies";
    game["teamScores"]["allies"] = 0; game["teamScores"]["axis"] = 0;
    check(promod\match_stats::hqMode(), "koth_gametype");

    before = count();
    promod\match_stats::startRound();
    start = level.matchStatsEvents[count() - 2];
    check(count() == before + 2 && promod\match_stats::live(), "match_and_half_start");
    check(isSubStr(start, "\"gametype\":\"koth\"") && isSubStr(start, "\"promodMode\":\"flex_hq2v2\""), "match_start_profile");
    check(!isSubStr(last(), "attackerSlot"), "half_start_without_attacker");

    actors[0] promod\match_stats::hqCaptured();
    check(isSubStr(last(), "\"type\":\"hq_capture\"") && isSubStr(last(), ids[0]) && level.matchStatsHqHolder == 0, "capture");
    actors[2] promod\match_stats::death(actors[0], "MOD_RIFLE_BULLET", "m4_mp");
    actors[2] promod\match_stats::spawned();
    check(isSubStr(last(), "\"type\":\"spawn\"") && isSubStr(last(), "\"lifeId\":2"), "respawn_recorded");
    actors[2] promod\match_stats::hqDestroyed();
    check(isSubStr(last(), "\"type\":\"hq_destroy\"") && isSubStr(last(), ids[2]), "destroy");
    promod\match_stats::hqCycleEnd();
    check(isSubStr(last(), "\"type\":\"hq_cycle_end\",\"holderSlot\":0"), "cycle_end");
    before = count(); promod\match_stats::hqCycleEnd();
    check(count() == before, "cycle_end_once");

    // A capture still held when the half ends closes its cycle before the half record.
    actors[1] promod\match_stats::hqCaptured();
    game["teamScores"]["allies"] = 30; game["teamScores"]["axis"] = 10;
    promod\match_stats::endRound("allies", "time");
    check(isSubStr(level.matchStatsEvents[count() - 2], "\"type\":\"hq_cycle_end\",\"holderSlot\":0"), "half_closes_cycle");
    check(isSubStr(last(), "\"type\":\"half_end\",\"half\":1,\"score\":[30,10]") && !promod\match_stats::live(), "first_half_end");
    before = count(); actors[3] promod\match_stats::spawned();
    check(count() == before, "no_spawn_between_halves");

    // Halftime as _globallogic does it: sides, team scores and logical side 0 all swap.
    for (i = 0; i < actors.size; i++)
    {
        team = "axis";
        if (actors[i].pers["team"] == "axis") team = "allies";
        setTeam(actors[i], team);
    }
    game["teamScores"]["allies"] = 10; game["teamScores"]["axis"] = 30; game["cpSide0"] = "axis";
    promod\match_stats::startRound();
    actors[2] promod\match_stats::hqCaptured();
    check(level.matchStatsHqHolder == 1, "halftime_logical_slot");
    game["teamScores"]["allies"] = 30;
    promod\match_stats::endRound("tie", "time");
    check(isSubStr(last(), "\"type\":\"half_end\",\"half\":2,\"score\":[30,30]"), "tied_half_recorded");
    promod\match_stats::complete("tie");
    check(isSubStr(last(), "\"endedReason\":\"completed\",\"winningSlot\":null"), "tie_is_completed_draw");
    before = count();
    actors[0] promod\match_stats::hqCaptured();
    check(count() == before, "completion_freezes_reporting");
    for (i = 0; i < level.matchStatsEvents.size; i++) logPrint("CP_STATS;EVENT;" + level.matchStatsEvents[i] + "\n");
    if (!isDefined(level.cpStatsFailed)) logPrint("CP_STATS;HQ_SMOKE_PASSED\n");
}

setTeam(bot, team)
{
    bot.pers["team"] = team; bot.team = team; bot.sessionteam = team;
}

last()
{
    return level.matchStatsEvents[count() - 1];
}

count()
{
    return promod\match_stats_smoke::count();
}

check(condition, name)
{
    return promod\match_stats_smoke::check(condition, name);
}
