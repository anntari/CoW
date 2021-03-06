/*
  Name: mi_reward2
  Author: Mithreas
  Version: 1.0
  Date: 29 May 06

  Description: Gives the PC speaker the rewards stored in the NPC as reward2xp,
  reward2gold and reward2item.

  See the Guide Valshera Conversation Scripts doc for more instructions.
*/
int StartingConditional()
{
  string sNum = "2";
  object oPC  = GetPCSpeaker();
  int nGold   = GetLocalInt(OBJECT_SELF, "reward"+sNum+"gold");
  int nXP     = GetLocalInt(OBJECT_SELF, "reward"+sNum+"xp");
  string sTag = GetLocalString(OBJECT_SELF, "reward"+sNum+"item");

  if (nGold > 0) GiveGoldToCreature(oPC, nGold);
  if (nXP > 0) GiveXPToCreature(oPC, nXP);
  if (sTag != "") CreateItemOnObject(sTag, oPC);

  return 1;
}
