run()
{
    wait 3;
    ids = fixtureIds();
    actors = spawnActors(ids);
    if (!isDefined(actors)) return;
    level.rdyup = false; level.forcedEnd = false; game["PROMOD_KNIFEROUND"] = false;
    game["cpSide0"] = "allies"; game["attackers"] = "allies";
    before = count();
    actors[2] promod\match_stats::damage(actors[0], 20, "MOD_RIFLE_BULLET", "m4_mp", "torso_upper");
    check(count() == before, "buy_damage_excluded");
    game["PROMOD_KNIFEROUND"] = true;
    promod\match_stats::startRound();
    check(!promod\match_stats::live() && count() == before, "knife_excluded");
    game["PROMOD_KNIFEROUND"] = false;
    promod\match_stats::startRound();
    check(count() == before + 2 && promod\match_stats::live(), "match_and_round_start");
    actors[0].cpStatsShot = "life1-command1-weapon1";
    metres = int(distance(actors[0].origin, actors[2].origin) * 0.0254 + 0.5);
    actors[2] promod\match_stats::damage(actors[0], 20, "MOD_RIFLE_BULLET", "m4_mp", "torso_upper", level.iDFLAGS_PENETRATION);
    check(isSubStr(level.matchStatsEvents[count() - 1], ",\"penetration\":true,\"distanceM\":" + metres), "damage_wallbang_distance");
    actors[3] promod\match_stats::damage(actors[0], 10, "MOD_RIFLE_BULLET", "m4_mp", "torso_lower");
    check(isSubStr(level.matchStatsEvents[count() - 1], ",\"penetration\":false,\"distanceM\":"), "damage_without_flags");
    actors[2].attackers = []; actors[2].attackers[0] = actors[1];
    actors[2] promod\match_stats::death(actors[0], "MOD_HEAD_SHOT", "m4_mp");
    last = level.matchStatsEvents[count() - 1];
    check(isSubStr(last, "\"headshot\":true") && isSubStr(last, ids[1]), "headshot_assist_snapshot");
    check(isSubStr(last, ",\"penetration\":true,\"distanceM\":" + metres), "death_uses_killing_hit");
    before = count();
    actors[2] promod\match_stats::death(actors[0], "MOD_HEAD_SHOT", "m4_mp");
    check(count() == before, "duplicate_death_ignored");
    actors[3] promod\match_stats::death(undefined, "MOD_FALLING", "none");
    last = level.matchStatsEvents[count() - 1];
    check(!isSubStr(last, "killerId") && !isSubStr(last, "penetration"), "world_death_recorded");
    actors[0] promod\match_stats::plant("A");
    before = count(); actors[0] promod\match_stats::plant("A");
    check(count() == before, "duplicate_plant_ignored");
    promod\match_stats::endRound("allies", "detonate");
    check(!promod\match_stats::live(), "round_closed");
    actors[0] promod\match_stats::disconnected();
    actors[0] promod\match_stats::connected();
    game["cpSide0"] = "axis"; game["attackers"] = "allies";
    for (i = 0; i < actors.size; i++) actors[i] promod\match_stats::spawned();
    promod\match_stats::startRound();
    check(isSubStr(level.matchStatsEvents[count() - 1], "\"attackerSlot\":1"), "halftime_logical_slot");
    actors[2] promod\match_stats::plant("B");
    actors[0] promod\match_stats::defuse();
    promod\match_stats::endRound("axis", "defuse");
    promod\match_stats::complete("axis");
    before = count();
    actors[0] promod\match_stats::disconnected();
    check(count() == before && game["matchStats"]["round"] == 2, "completion_freezes_reporting");
    for (i = 0; i < level.matchStatsEvents.size; i++) logPrint("CP_STATS;EVENT;" + level.matchStatsEvents[i] + "\n");
    if (!isDefined(level.cpStatsFailed)) logPrint("CP_STATS;SMOKE_PASSED\n");
}

fixtureIds()
{
    return strTok("11111111-1111-4111-8111-111111111111;22222222-2222-4222-8222-222222222222;33333333-3333-4333-8333-333333333333;44444444-4444-4444-8444-444444444444", ";");
}

// Four playing test clients, two per logical slot, with fixture account identities; undefined on failure.
spawnActors(ids)
{
    actors = [];
    for (i = 0; i < 4; i++)
    {
        bot = addTestClient();
        if (!check(isDefined(bot), "test_client")) return undefined;
        deadline = getTime() + 10000;
        while (!isDefined(bot.hasSpawned) && getTime() < deadline) wait 0.05;
        if (!check(isDefined(bot.hasSpawned), "client_connected")) return undefined;
        team = "allies";
        if (i >= 2) team = "axis";
        bot.pers["team"] = team; bot.team = team; bot.sessionteam = team;
        bot.pers["cpId"] = ids[i]; bot.pers["cpSlot"] = int(i >= 2);
        bot maps\mp\gametypes\_promod::setClassChoice("assault");
        bot maps\mp\gametypes\_promod::menuAcceptClass("go");
        deadline = getTime() + 10000;
        while (bot.sessionstate != "playing" && getTime() < deadline) wait 0.05;
        if (!check(bot.sessionstate == "playing", "actor_spawned")) return undefined;
        actors[i] = bot;
    }
    return actors;
}

count()
{
    if (!isDefined(level.matchStatsEvents)) return 0;
    return level.matchStatsEvents.size;
}

check(condition, name)
{
    if (!condition) { level.cpStatsFailed = true; logPrint("CP_STATS;SMOKE_FAILED;" + name + "\n"); return false; }
    logPrint("CP_STATS;PASS;" + name + "\n");
    return true;
}
