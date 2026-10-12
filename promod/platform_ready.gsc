waiting(expected, identities, readiness)
{
    if (!expected.size) return -1;
    count = 0;
    for (i = 0; i < expected.size; i++)
    {
        found = false;
        for (j = 0; j < identities.size; j++)
        {
            if (identities[j] == expected[i] && readiness[j]) found = true;
        }
        if (!found) count++;
    }
    return count;
}

countdown(previous, ready, now)
{
    if (!ready) return 0;
    if (!previous) return now + 5000;
    return previous;
}

expired(start, now) { return now - start >= 600000; }

smoke()
{
    expected = []; identities = []; readiness = [];
    expected[0] = "verified-a|0"; expected[1] = "verified-b|1";
    identities[0] = expected[0]; readiness[0] = true;
    check(waiting(expected, identities, readiness) == 1, "missing_player");
    identities[1] = "outsider|1"; readiness[1] = true;
    check(waiting(expected, identities, readiness) == 1, "outsider_cannot_fill_slot");
    identities[1] = expected[1]; readiness[1] = false;
    check(waiting(expected, identities, readiness) == 1, "unready_player");
    readiness[1] = true;
    check(waiting(expected, identities, readiness) == 0, "whole_roster_ready");
    identities[1] = "";
    check(waiting(expected, identities, readiness) == 1, "lost_identity");
    empty = [];
    check(waiting(empty, identities, readiness) == -1, "unavailable_roster");
    first = countdown(0, true, 100);
    check(first == 5100 && countdown(first, true, 200) == first, "five_second_countdown");
    check(countdown(first, false, 300) == 0, "countdown_cancels");
    check(countdown(0, true, 400) == 5400, "countdown_restarts_in_full");
    check(!expired(100, 600099) && expired(100, 600100), "ten_minute_deadline");
    if (!isDefined(level.cpReadySmokeFailed)) logPrint("CP_READY;SMOKE_PASSED\n");
}

check(condition, name)
{
    if (!condition) { level.cpReadySmokeFailed = true; logPrint("CP_READY;SMOKE_FAILED;" + name + "\n"); return; }
    logPrint("CP_READY;PASS;" + name + "\n");
}
