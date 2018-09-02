//::///////////////////////////////////////////////
//:: Vine Mine, Entangle C
//:: X2_S0_VineMEntC
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    Upon entering the AOE the target must make
    a reflex save or be entangled by vegitation
*/
//:://////////////////////////////////////////////
//:: Created By: Andrew Nobbs
//:: Created On: Nov 25, 2002
//:://////////////////////////////////////////////
//:: Last Updated By: Georg Zoeller, 14/08/2003

#include "nw_i0_spells"
#include "x0_i0_spells"
#include "inc_customspells"
#include "inc_state"

int GetIsEntangled(object oCreature);

void main()
{

    //Declare major variables
    effect eHold = EffectEntangle();
    effect eEntangle = EffectVisualEffect(VFX_DUR_ENTANGLE);
    //Link Entangle and Hold effects
    effect eLink = EffectLinkEffects(eHold, eEntangle);

    //--------------------------------------------------------------------------
    // GZ 2003-Oct-15
    // When the caster is no longer there, all functions calling
    // GetAreaOfEffectCreator will fail. Its better to remove the barrier then
    //--------------------------------------------------------------------------
    if (!GetIsObjectValid(GetAreaOfEffectCreator()))
    {
        DestroyObject(OBJECT_SELF);
        return;
    }



    object oTarget = GetFirstInPersistentObject();
    
    // Escape for DMs
    if(GetIsDM(oTarget) == TRUE && GetIsDMPossessed(oTarget) == FALSE)
    {
        return;
    }
    
    while(GetIsObjectValid(oTarget))
    {  // SpawnScriptDebugger();
        if(!GetHasFeat(FEAT_WOODLAND_STRIDE, oTarget) &&(GetCreatureFlag(oTarget, CREATURE_VAR_IS_INCORPOREAL) != TRUE) )
         {
            if (spellsIsTarget(oTarget, SPELL_TARGET_STANDARDHOSTILE, GetAreaOfEffectCreator()))
            {
                //Fire cast spell at event for the specified target
                SignalEvent(oTarget, EventSpellCastAt(GetAreaOfEffectCreator(), 529));
                //Make SR check
                if(!GetIsEntangled(oTarget))
                {
                    //if(!MyResistSpell(GetAreaOfEffectCreator(), oTarget))
                    //{
                        //Make reflex save
                        int n =   MySavingThrow(SAVING_THROW_REFLEX, oTarget, GetSpellSaveDC(),SAVING_THROW_TYPE_NONE,GetAreaOfEffectCreator() );
                        if(n == 0)
                        {
                           //Apply linked effects
                           ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oTarget, RoundsToSeconds(2));
                        }
                    //}
                }
				
				gsSTAdjustState(GS_ST_STAMINA, -5.0f, oTarget);
            }
        }
        //Get next target in the AOE
        oTarget = GetNextInPersistentObject();
    }
}

int GetIsEntangled(object oCreature)
{
    effect eEffect = GetFirstEffect(oCreature);

    while(GetIsEffectValid(eEffect))
    {
        if(GetEffectType(eEffect) == EFFECT_TYPE_ENTANGLE && GetEffectSpellId(eEffect) == 530)
            return TRUE;
         eEffect = GetNextEffect(oCreature);
    }
    return FALSE;
}
