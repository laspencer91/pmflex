// PromodFlex S&D ruleset fixture (promod_mode flex_snd12, cp_flexsnd_smoke 1): drives real round ends through
// sd_endGame/_globallogic::endGame with jumped scores. Its stage survives map restarts in cp_flexsnd_stage.
run()
{
	level endon( "restarting" );
	waittillframeend;
	setDvar( "g_logSync", 1 );
	stage = getDvarInt( "cp_flexsnd_stage" );
	logPrint( "CP_FLEXSND;STAGE;" + stage + ";round=" + game["roundsplayed"] + "\n" );

	switch ( stage )
	{
		case 0: // a fresh match: the ruleset, then its first ready-up
			freshMatch( "match_start" );
			check( level.roundswitch == 12 && level.roundLimit == 24 && level.scoreLimit == 13, "mr12_limits_loaded" );
			check( game["PROMOD_MATCH_MODE"] == "match" && game["PROMOD_STRATTIME"] == 6 && !game["PROMOD_KNIFEROUND"], "match_mode_strat_no_knife" );
			check( isSubStr( game["PROMOD_MODE_HUD"], "MR12" ), "hud_mr12" );
			switchTable();
			finishReadyUp( 1 );
			break;
		case 1: // round 1, then halftime at 12 rounds
			check( !game["promod_do_readyup"] && game["promod_first_readyup_done"], "round_after_ready_up" );
			stratRan( "round_1" );
			endRound( 11, 6, 5, "allies", 2 );
			break;
		case 2: // regulation halftime: sides and scores swap, Promod's ready-up runs
			check( game["roundsplayed"] == 12 && switched(), "halftime_switched_sides" );
			check( game["teamScores"]["allies"] == 5 && game["teamScores"]["axis"] == 7, "halftime_swapped_scores" );
			check( game["promod_do_readyup"], "halftime_ready_up" );
			finishReadyUp( 3 );
			break;
		case 3: // round 13, then a 12-12 tie
			stratRan( "round_13" );
			endRound( 23, 11, 12, "allies", 4 );
			break;
		case 4: // overtime round 25: limits extended, same sides, no ready-up
			check( promod_ruleset\flex_snd::inOvertime() && game["roundsplayed"] == 24, "tie_starts_overtime" );
			check( getDvarInt( "scr_sd_roundlimit" ) == 30 && getDvarInt( "scr_sd_scorelimit" ) == 16 && level.roundLimit == 30 && level.scoreLimit == 16, "overtime_limits" );
			check( !switched(), "overtime_keeps_sides" );
			check( !game["promod_do_readyup"], "overtime_without_ready_up" );
			check( isSubStr( game["PROMOD_MODE_HUD"], "OT" ), "hud_overtime" );
			stratRan( "round_25" );
			endRound( 26, 13, 13, "allies", 5 );
			break;
		case 5: // overtime halftime after 27 rounds: sides swap without a ready-up, then a 15-15 tie after 30
			check( game["roundsplayed"] == 27 && switched(), "overtime_halftime_switched_sides" );
			check( game["teamScores"]["allies"] == 13 && game["teamScores"]["axis"] == 14, "overtime_halftime_swapped_scores" );
			check( !game["promod_do_readyup"], "overtime_halftime_without_ready_up" );
			stratRan( "round_28" );
			endRound( 29, 14, 15, "allies", 6 );
			check( maps\mp\gametypes\_globallogic::getWinningTeam() == "tie", "overtime_tie_has_no_winner" );
			wait 6;
			check( game["roundsplayed"] == 30 && level.roundLimit == 30 && game["state"] == "postgame", "overtime_tie_ends_match" );
			break;
		case 6: // the 15-15 match ended (no second overtime); the next match is back to MR12
			freshMatch( "after_overtime_tie" );
			finishReadyUp( 7 );
			break;
		case 7:
			stratRan( "match_2_round_1" );
			endRound( 23, 12, 11, "axis", 8 );
			break;
		case 8: // overtime won 16-13 ends the match on the score limit
			check( promod_ruleset\flex_snd::inOvertime(), "match_2_overtime" );
			stratRan( "match_2_round_25" );
			endRound( 28, 15, 13, "allies", 9 );
			break;
		case 9:
			freshMatch( "after_overtime_win" );
			finishReadyUp( 10 );
			break;
		case 10: // 13 rounds win regulation
			stratRan( "match_3_round_1" );
			endRound( 20, 12, 8, "allies", 11 );
			break;
		case 11:
			freshMatch( "after_regulation_win" );
			if ( !isDefined( level.flexSndSmokeFailed ) && getDvarInt( "cp_flexsnd_failed" ) == 0 )
				logPrint( "CP_FLEXSND;SMOKE_PASSED\n" );
			setDvar( "cp_flexsnd_stage", 12 );
			break;
	}
}

freshMatch( name )
{
	check( toLower( getDvar( "promod_mode" ) ) == "flex_snd12" && level.gametype == "sd", name + "_mode" );
	check( game["roundsplayed"] == 0 && !promod_ruleset\flex_snd::inOvertime(), name + "_fresh_match" );
	check( getDvarInt( "scr_sd_roundswitch" ) == 12 && getDvarInt( "scr_sd_roundlimit" ) == 24 && getDvarInt( "scr_sd_scorelimit" ) == 13, name + "_mr12_dvars" );
	check( game["promod_do_readyup"], name + "_ready_up" );
}

// isSwitchRound() over the whole match, outside of a round end.
switchTable()
{
	played = game["roundsplayed"];
	expected = [];
	expected[12] = true; expected[27] = true;
	ok = true;
	for ( n = 1; n <= 30; n++ )
	{
		game["roundsplayed"] = n;
		want = isDefined( expected[n] );
		if ( promod_ruleset\flex_snd::isSwitchRound() != want )
		{
			ok = false;
			logPrint( "CP_FLEXSND;SWITCH_MISMATCH;" + n + "\n" );
		}
	}
	game["roundsplayed"] = played;
	check( ok, "switch_rounds_12_and_27" );
}

// Promod's ready-up waits for players; with none connected the fixture releases it the way readyup::main() ends.
finishReadyUp( next )
{
	while ( !isDefined( level.ready_up_over ) )
		wait 0.05;
	setDvar( "cp_flexsnd_stage", next );
	level.ready_up_over = true;
}

stratRan( name )
{
	started = getTime();
	level waittill( "prematch_over" );
	check( isDefined( level.strat_over ) && level.strat_over && getTime() - started >= 5500, name + "_strat_time" );
}

endRound( played, allies, axis, winner, next )
{
	game["roundsplayed"] = played;
	game["teamScores"]["allies"] = allies;
	game["teamScores"]["axis"] = axis;
	game["allies_timeout_called"] = 1; // a side switch resets it
	setDvar( "cp_flexsnd_stage", next );
	maps\mp\gametypes\sd::sd_endGame( winner, game["strings"]["target_destroyed"] );
}

switched()
{
	return !game["allies_timeout_called"];
}

check( condition, name )
{
	if ( !condition )
	{
		level.flexSndSmokeFailed = true;
		setDvar( "cp_flexsnd_failed", 1 );
		logPrint( "CP_FLEXSND;SMOKE_FAILED;" + name + "\n" );
		return;
	}
	logPrint( "CP_FLEXSND;PASS;" + name + "\n" );
}
