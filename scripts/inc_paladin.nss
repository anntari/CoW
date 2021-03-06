//::///////////////////////////////////////////////
//:: inc_paladin
//:: Library: Paladin
//:://////////////////////////////////////////////
/*
    Library with functions for Paladin mechanics.
    +1 WIS per 7 levels
*/
//:://////////////////////////////////////////////
//:: Created By:
//:: Created On:
//:://////////////////////////////////////////////

#include "inc_common"
#include "inc_list"
#include "nwnx_creature"
#include "nwnx_object"
#include "nwnx_alts"
#include "nwnx_admin"
#include "nwnx_alts"
#include "inc_pc"
#include "inc_iprop"
#include "x2_inc_itemprop"
#include "inc_effecttags"


/**********************************************************************
 * PUBLIC FUNCTION PROTOTYPES
 **********************************************************************/

// Called by gs_m_level_up.
void palOnLevelCheck(object oPC = OBJECT_SELF);

// Paladins with the horse-riding gift get their summon mount at lvl 1
void palHorseGiftCheck(object oPC = OBJECT_SELF);

// Check WIS Scaling for Paladin.
void palCheckWIS(object oPC = OBJECT_SELF);

// Check bonus Divine Might damage on new equip.  Called by gs_m_equip.
void palDivineMightCheck(object oEquip, object oPC = OBJECT_SELF);


/**********************************************************************
 * PUBLIC FUNCTION DEFINITIONS
 **********************************************************************/

 //------------------------------------------------------------------------------


void palOnLevelCheck(object oPC = OBJECT_SELF)
{
    // Separating individual level-up scripts for simplicity.
    palHorseGiftCheck(oPC);
    palCheckWIS(oPC);
}

 //------------------------------------------------------------------------------

void palHorseGiftCheck(object oPC = OBJECT_SELF)
{
    // We already know this feat
    if (GetKnowsFeat(FEAT_PALADIN_SUMMON_MOUNT ,oPC))
        return;

    // No horse-riding gift
    if (!GetLocalInt(gsPCGetCreatureHide(oPC), "MAY_RIDE_HORSE"))
        return;

    AddKnownFeat(oPC, FEAT_PALADIN_SUMMON_MOUNT, GetLevelByClassLevel(oPC, CLASS_TYPE_PALADIN, 1));
}

 //------------------------------------------------------------------------------

void palCheckWIS(object oPC = OBJECT_SELF)
{
    // Paladins get +1 hard WIS every 7 levels

    // This function checks (via PC hide object) if the bonuses have been applied.
    // If not, and the bonuses do apply, then the bonuses are applied.
    // If so, and the bonuses no longer apply, then the bonuses are removed.

    int nNeededBonus = GetLevelByClass(CLASS_TYPE_PALADIN, oPC) / 7;

    object oHide = gsPCGetCreatureHide(oPC);
    int nApplied = GetLocalInt(oHide, "PALADIN_WIS_APPLIED");

    if (nApplied != nNeededBonus) {
        ModifyAbilityScore(oPC, ABILITY_WISDOM, nNeededBonus - nApplied);
        SetLocalInt(oHide, "PALADIN_WIS_APPLIED", nNeededBonus);
    }
}

 //------------------------------------------------------------------------------

void palDivineMightCheck(object oEquip, object oPC = OBJECT_SELF)
{
  // retired.
}
