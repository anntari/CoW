#include "gs_inc_spell"

void main()
{
    gsSPRemoveEffect(
        GetExitingObject(),
        530,
        GetAreaOfEffectCreator());
}

