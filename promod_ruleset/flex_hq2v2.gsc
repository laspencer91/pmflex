main()
{
	// PromodFlex ranked 2v2 Headquarters (promod_mode flex_hq2v2), applied over Promod's comp match rules.
	// Classic HQ: the holding team waits to respawn until its HQ is destroyed or expires.
	setDvar( "koth_kothmode", 0 );
	setDvar( "koth_autodestroytime", 60 ); // [seconds] an HQ stays online this long once captured
	setDvar( "koth_spawntime", 10 ); // [seconds] before the next HQ becomes capturable
	setDvar( "koth_capturetime", 10 );
	setDvar( "koth_destroytime", 5 );
	// Respawn delay applies to the holding team only; at the HQ lifetime it holds them until the HQ is gone.
	setDvar( "koth_spawnDelay", 60 );
	setDvar( "koth_delayPlayer", 0 );
	setDvar( "scr_koth_numlives", 0 );
	setDvar( "scr_koth_playerrespawndelay", 0 );
	setDvar( "scr_koth_waverespawndelay", 0 );
	setDvar( "scr_koth_timelimit", 10 ); // [minutes] per half
	setDvar( "scr_koth_roundlimit", 2 );
	setDvar( "scr_koth_roundswitch", 1 );
	setDvar( "scr_koth_scorelimit", 0 );

	// The class limits Promod's 2v2 token sets, for two players a side.
	setDvar( "class_assault_limit", 2 );
	setDvar( "class_specops_limit", 2 );
	setDvar( "class_demolitions_limit", 0 );
	setDvar( "class_sniper_limit", 0 );

	game["PROMOD_MODE_HUD"] = "^4PromodFlex ^3HQ 2v2";
}
