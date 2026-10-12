// See LICENSE.md.

onSpawn()
{
	self.economyKillPaid = false;
	self.economyAssistPaid = [];
}

enemyVictim( victim )
{
	return promod\economy::realRound() && level.economyLive && self promod\economy::hasTeam() &&
		isDefined(victim) && isPlayer(victim) && victim != self && victim.sessionstate == "dead" &&
		victim promod\economy::hasTeam() && victim.pers["team"] != self.pers["team"];
}

awardKill( victim )
{
	if (!self enemyVictim(victim) || victim.economyKillPaid)
		return false;
	victim.economyKillPaid = true;
	return self promod\economy::awardReward("kill");
}

awardAssist( victim, killer )
{
	if (!self enemyVictim(victim) || !isDefined(killer) || !isPlayer(killer) || killer == self ||
		killer.pers["team"] != self.pers["team"])
		return false;
	entry = self promod\economy::account();
	id = self.pers["economy_id"];
	if (isDefined(victim.economyAssistPaid[id]))
		return false;
	victim.economyAssistPaid[id] = true;
	return self promod\economy::awardReward("assist");
}
