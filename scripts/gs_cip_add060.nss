#include "inc_common"
#include "inc_craft"
#include "inc_iprop"

const int GS_LIMIT_COST = 10000;

int StartingConditional()
{
    object oItem = GetFirstItemInInventory();

    if (GetIsObjectValid(oItem))
    {
        int nPropertyID = GetLocalInt(OBJECT_SELF, "GS_PROPERTY_ID");
        int nSubTypeID  = GetLocalInt(OBJECT_SELF, "GS_SUBTYPE_ID");
        int nCostID     = GetLocalInt(OBJECT_SELF, "GS_COST_ID");
        int nParamID    = GetLocalInt(OBJECT_SELF, "GS_PARAM_ID");
        int bStaticLevel = GetLocalInt(GetModule(), "STATIC_LEVEL");

        itemproperty ipProperty = gsIPGetItemProperty(nPropertyID, nSubTypeID, nCostID, nParamID);

        if (GetIsItemPropertyValid(ipProperty))
        {
            object oSpeaker      = GetPCSpeaker();
            int nCost            = gsIPGetCost(oItem, ipProperty);
            int nBaseCost        = nCost;
            int nChance          = 5;
            int nPropertyStrRef  = GetLocalInt(OBJECT_SELF, "GS_PROPERTY_STRREF");
            string sPropertyName = GetStringByStrRef(nPropertyStrRef);

            if ( (gsCMGetItemValue(oItem) + nBaseCost - gsCRGetMaterialBaseValue(oItem)) > GS_CR_FL_MAX_ITEM_VALUE)
            {
                // Max item value reached.
                nCost = 0;
                nChance = 100;
            }
            else
            {
                nCost = FloatToInt(IntToFloat(nCost) * gsCRGetCraftingCostMultiplier(oSpeaker, oItem, ipProperty));
            }
			
            int nBaseItemValue = FloatToInt(gsCRGetCraftingCostMultiplier(oSpeaker, oItem, ipProperty)
                                                * IntToFloat(gsCMGetItemValue(oItem) - gsCRGetMaterialBaseValue(oItem)));
			
            if (nCost)
            {
                // Impose a min cost to avoid abusing merchants.  Max possible
                // merchant buy price is 75% of base value so make this the min
                // for items under 400g.
                if ( ((gsCMGetItemValue(oItem) + nBaseCost) < 400) && (gsCRGetCraftingCostMultiplier(oSpeaker, oItem, ipProperty) < 0.75) )
                {
                  nCost = FloatToInt(IntToFloat(nBaseCost) * 0.75);
                }

                nChance = ((nBaseItemValue + nCost) * 100) / GS_LIMIT_COST;
                if (nChance < 5)        nChance =   5;
                else if (nChance > 95) nChance = 95;
            }

            // Debug content!
			if (GetPCPlayerName(oSpeaker) == "Mithreas")
			{
			  SendMessageToPC(oSpeaker, "Multiplier: " + FloatToString(gsCRGetCraftingCostMultiplier(oSpeaker, oItem, ipProperty)));
			  SendMessageToPC(oSpeaker, "Property base cost: " + IntToString(nBaseCost));
			  SendMessageToPC(oSpeaker, "Base item value adjusted for skill and base cost: " + IntToString(nBaseItemValue));			  
			}

            SetCustomToken(818, GetName(oItem));
            SetCustomToken(819, sPropertyName);
            SetCustomToken(820, IntToString(nCost));
            SetCustomToken(821, IntToString(100 - nChance));
            SetCustomToken(822, IntToString(bStaticLevel ? 0 : nCost / 10));

            return TRUE;
        }
    }

    return FALSE;
}
