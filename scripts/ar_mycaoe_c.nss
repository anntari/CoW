/*
    Myconid Death AoE
    Will damage targets on HB, Fort Save.
*/

#include "inc_spellmatrix"

void main()
{
    object oCaster  = GetAreaOfEffectCreator();
    object oTarget  = GetFirstInPersistentObject();
    int nDC         = 10 + GetHitDice(oCaster) / 2;
    int nDmg        = d6(2);

    effect eSpellVFX = EffectVisualEffect(VFX_IMP_ACID_S);
    effect eDamage   = EffectDamage(nDmg, DAMAGE_TYPE_ACID);


    while(GetIsObjectValid(oTarget))
    {
        if ( GetIsReactionTypeHostile(oTarget) && !MySavingThrow(SAVING_THROW_FORT, oTarget, nDC, SAVING_THROW_TYPE_POISON, GetAreaOfEffectCreator()) ) {
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectLinkEffects(eSpellVFX, eDamage), oTarget);
        }

        oTarget = GetNextInPersistentObject();
    }
}
