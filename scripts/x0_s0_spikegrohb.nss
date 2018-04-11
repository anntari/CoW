//::///////////////////////////////////////////////
//:: Spike Growth: On Heartbeat
//:: x0_s0_spikegroHB.nss
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    All creatures within the AoE take 1d4 acid damage
    per round
*/
//:://////////////////////////////////////////////
//:: Created By: Brent Knowles
//:: Created On: September 6, 2002
//:://////////////////////////////////////////////
#include "x0_i0_spells"
#include "x2_inc_spellhook"

void main()
{
    object oTarget;

    //Start cycling through the AOE Object for viable targets including doors and placable objects.
    oTarget = GetFirstInPersistentObject(OBJECT_SELF);
    while( GetIsObjectValid(oTarget) )
    {
        DoSpikeGrowthEffect(oTarget);
        oTarget = GetNextInPersistentObject(OBJECT_SELF);
    }
}
