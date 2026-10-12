// PromodFlex ranked Search and Destroy (promod_mode flex_snd12), applied over Promod's comp match rules.
// MR<format>: sides switch after <format> rounds, first to <format>+1 wins. A tie at <format>:<format> plays one
// MR3 overtime: sides stay for 3 rounds, then switch; first to 4 overtime rounds wins. A tie after it is not decided.
main( format )
{
	setDvar( "scr_sd_roundswitch", format );
	setDvar( "scr_sd_roundlimit", format * 2 );
	setDvar( "scr_sd_scorelimit", format + 1 );

	game["FLEX_SND_FORMAT"] = format;
	game["PROMOD_STRATTIME"] = 6; // [seconds] every round, from Promod match mode
	game["PROMOD_KNIFEROUND"] = 0;
	game["PROMOD_MODE_HUD"] = "^4PromodFlex ^3MR" + format;
}

active()
{
	return isDefined( game["FLEX_SND_FORMAT"] ) && level.gametype == "sd";
}

inOvertime()
{
	return active() && isDefined( game["FLEX_SND_OT"] ) && game["FLEX_SND_OT"];
}

// MR3 overtime: 6 rounds at most, halftime after 3.
overtimeRounds()
{
	return 6;
}

overtimeHalf()
{
	return 3;
}

// _globallogic::endGame(), right after game["roundsplayed"]++: a tie at the end of regulation starts overtime.
onRoundCounted()
{
	if ( !active() || inOvertime() )
		return;

	regulation = game["FLEX_SND_FORMAT"] * 2;
	if ( game["roundsplayed"] != regulation || game["teamScores"]["allies"] != game["teamScores"]["axis"] )
		return;

	game["FLEX_SND_OT"] = true;
	level.roundLimit = regulation + overtimeRounds();
	level.scoreLimit = game["FLEX_SND_FORMAT"] + overtimeHalf() + 1;
	// Rulesets load once per match; the next rounds read these back in _globallogic::init().
	setDvar( "scr_sd_roundlimit", level.roundLimit );
	setDvar( "scr_sd_scorelimit", level.scoreLimit );
	game["PROMOD_MODE_HUD"] += " ^1OT";
	promod\economy::resetHalf(); // overtime starts like a half
}

// Replaces the roundswitch modulo: regulation halftime, then the overtime halftime, never at the start of overtime.
isSwitchRound()
{
	played = game["roundsplayed"];
	if ( !isDefined( level.roundswitch ) || level.roundswitch <= 0 )
		return false;
	if ( !active() )
		return played % level.roundswitch == 0;

	regulation = game["FLEX_SND_FORMAT"] * 2;
	if ( played < regulation )
		return played % level.roundswitch == 0;
	return ( played - regulation ) % overtimeRounds() == overtimeHalf();
}
