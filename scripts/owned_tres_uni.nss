/*
  Name: owned_tres_uni
  Author: Mithreas
  Date: 17 Apr 06
  Description: This script belongs on the OnDestroy and OnOpen slot of a chest
  owned by an NPC. If an NPC is nearby when it is opened/destroyed and the
  NPC can see the PC who did the deed, then the PC gets their bounty increased
  and all objects generated by the chest are marked as stolen.
*/
#include "mi_crimcommon"
void main()
{
  int nCount = 1;
  object oPC  = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR, PLAYER_CHAR_IS_PC);
  object oNPC = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR,
                                   PLAYER_CHAR_NOT_PC,
                                   OBJECT_SELF,
                                   nCount);
  float fDistance = GetDistanceBetween(OBJECT_SELF, oNPC);

  while (fDistance < 20.0 && GetIsObjectValid(oNPC))
  {
    int nNation = CheckFactionNation(oNPC);
    if (GetCanSeeParticularPC(oPC, oNPC) && (nNation != NATION_INVALID))
    {
      AddToBounty(nNation, FINE_THEFT, oPC);
    }

    nCount++;
    oNPC = GetNearestCreature(CREATURE_TYPE_PLAYER_CHAR,
                              PLAYER_CHAR_NOT_PC,
                              OBJECT_SELF,
                              nCount);
    fDistance = GetDistanceBetween(OBJECT_SELF, oNPC);
  }

  ExecuteScript("treasure_unique", OBJECT_SELF);
  MarkAllItemsAsStolen(OBJECT_SELF);
}
