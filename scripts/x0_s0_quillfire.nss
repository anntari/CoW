//::///////////////////////////////////////////////
//:: Quillfire
//:: [x0_s0_quillfire.nss]
//:: Copyright (c) 2002 Bioware Corp.
//:://////////////////////////////////////////////
/*
    Fires a cluster of quills at a target. Ranged Attack.
    2d8 + 1 point /2 levels (max 5)
    
*/
//:://////////////////////////////////////////////
//:: Created By: Brent
//:: Created On: July 17 2002
//:://////////////////////////////////////////////
//:: Last Updated By: Andrew Nobbs May 02, 2003

#include "nw_i0_spells"
#include "inc_customspells" 

void main()
{

/* 
  Spellcast Hook Code 
  Added 2003-06-20 by Georg
  If you want to make changes to all spells,
  check inc_customspells.nss to find out more
  
*/

    if (!X2PreSpellCastCode())
    {
	// If code within the PreSpellCastHook (i.e. UMD) reports FALSE, do not run this spell
        return;
    }

// End of Spell Cast Hook


    //Declare major variables  ( fDist / (3.0f * log( fDist ) + 2.0f) )
    object oTarget = GetSpellTargetObject();
    int nCasterLvl = AR_GetCasterLevel(OBJECT_SELF);
    int nDamage = 0;
    int nMetaMagic = AR_GetMetaMagicFeat();
    int nCnt;
    effect eVis = EffectVisualEffect(VFX_IMP_ACID_S);

	if(!GetIsReactionTypeFriendly(oTarget))
	{
        //Fire cast spell at event for the specified target
        SignalEvent(oTarget, EventSpellCastAt(OBJECT_SELF, SPELL_QUILLFIRE));
        //Apply a single damage hit for each missile instead of as a single mass
        //Make SR Check
        {
			// BK: No spell resistance for quillfire
            //if(!MyResistSpell(OBJECT_SELF, oTarget, fDelay))
            {
                //eMissile = EffectVisualEffect(VFX_IMP_MIRV_FLAME);
                //Roll damage
                int nDam = d8(1);
     	        //Enter Metamagic conditions
    	        if (nMetaMagic == METAMAGIC_MAXIMIZE)
    	        {
    		          nDam = 8;//Damage is at max
    	        }
    	        if (nMetaMagic == METAMAGIC_EMPOWER)
    	        {
    		          nDam = nDam + nDam/2; //Damage/Healing is +50%
    	        }
                //* apply bonus damage for level
                int nBonus = AR_GetCasterLevel(OBJECT_SELF) / 2;
                if (nBonus > 5)
                {
                    nBonus = 5;
                }
                nDam = nDam + nBonus;
                effect eDam = EffectDamage(nDam, DAMAGE_TYPE_MAGICAL);
                ApplyEffectToObject(DURATION_TYPE_INSTANT, eDam, oTarget);
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eVis, oTarget);
                // * also applies poison damage
                effect ePoison = EffectPoison(POISON_LARGE_SCORPION_VENOM);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, ePoison, oTarget);
                
                //Apply the MIRV and damage effect
                //ApplyEffectToObject(DURATION_TYPE_INSTANT, eMissile, oTarget);
            }

        }
    }
}



