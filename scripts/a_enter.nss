#include "inc_adv_xp"
#include "inc_boss"
#include "inc_caravan"
#include "inc_citizen"
#include "inc_class"
#include "inc_common"
#include "inc_customspells"
#include "inc_disguise"
#include "inc_divination"
#include "inc_encounter"
#include "inc_location"
#include "inc_log"
#include "inc_fixture"
#include "inc_flag"
#include "inc_pc"
#include "inc_placeable"
#include "inc_quarter"
#include "inc_quest"
#include "inc_randomquest"
#include "inc_seeds"
#include "inc_sequencer"
#include "inc_subdual"
#include "inc_text"
#include "inc_time"
#include "inc_tracks"
#include "inc_traps"
#include "inc_worship"
#include "inc_weather"
#include "inc_xfer"
#include "inc_xp"
#include "x3_inc_horse"
#include "inc_zdlg"

const int GS_TIMEOUT   = 2400;  // 4 RT minutes (40 game minutes)
const string ENTER = "ENTER"; // For logging


// Added by Mithreas
void DoRandomTraps()
{
  object oPC = GetEnteringObject();
  if (!GetLocalInt(OBJECT_SELF, "MI_RANDOM_TRAPS") || !GetIsPC(oPC)) return;

  ExecuteScript("mi_dorandomtraps", oPC);
}
//----------------------------------------------------------------
void DoRandomTrees()
{
  int nCount = d6();

  for (nCount; nCount < 9; nCount++)
  {
    int nSizeX       = FloatToInt(gsARGetSizeX(OBJECT_SELF)) - 1;
    int nSizeY       = FloatToInt(gsARGetSizeY(OBJECT_SELF)) - 1;
    vector vPosition = GetPosition(GetEnteringObject());

    vPosition.x = IntToFloat(Random(nSizeX) + 1);
    vPosition.y = IntToFloat(Random(nSizeY) + 1);

    float fFacing = IntToFloat(Random(360));

    string sResRef = "x3_plc_tree";

    switch (d3())
    {
      case 1:
        sResRef += "s";
        break;
      case 2:
        sResRef += "m";
        break;
      case 3:
        sResRef += "l";
        break;
    }

    sResRef += "00" + IntToString(Random(10));

    location lLoc = guENFindNearestWalkable(Location(OBJECT_SELF, vPosition, fFacing));
    vPosition     = GetPositionFromLocation(lLoc);
    vPosition.z   = vPosition.z - 0.05;

    CreateObject(OBJECT_TYPE_PLACEABLE, sResRef, Location(OBJECT_SELF, vPosition, fFacing));
  }
}
//----------------------------------------------------------------
void DoWeatherEffects()
{
  int nWeather = miWHGetWeather();

  if (nWeather == WEATHER_FOGGY)
  {
    int nCount = d6();

    for (nCount; nCount < 9; nCount++)
    {
      int nSizeX       = FloatToInt(gsARGetSizeX(OBJECT_SELF)) - 1;
      int nSizeY       = FloatToInt(gsARGetSizeY(OBJECT_SELF)) - 1;
      vector vPosition = GetPosition(GetEnteringObject());

      vPosition.x = IntToFloat(Random(nSizeX) + 1);
      vPosition.y = IntToFloat(Random(nSizeY) + 1);

      float fFacing = IntToFloat(Random(360));

      string sResRef = "x3_plc_mist";

      CreateObject(OBJECT_TYPE_PLACEABLE, sResRef, Location(OBJECT_SELF, vPosition, fFacing));
    }
  }
  else if (nWeather == WEATHER_RAIN || nWeather == WEATHER_SNOW)
  {
    int nCount = d6();

    for (nCount; nCount < 9; nCount++)
    {
      int nSizeX       = FloatToInt(gsARGetSizeX(OBJECT_SELF)) - 1;
      int nSizeY       = FloatToInt(gsARGetSizeY(OBJECT_SELF)) - 1;
      vector vPosition = GetPosition(GetEnteringObject());

      vPosition.x = IntToFloat(Random(nSizeX) + 1);
      vPosition.y = IntToFloat(Random(nSizeY) + 1);
      // Septire - Offset +0.01 Z to prevent texture overlap.
      vPosition.z += 0.01;

      float fFacing = IntToFloat(Random(360));

      string sResRef = (nWeather == WEATHER_RAIN ? (d2() == 1 ? "nw_plc_puddle2" : "nw_plc_puddle1") : "x0_snowdrift");

      location lLoc = guENFindNearestWalkable(Location(OBJECT_SELF, vPosition, fFacing));

      // EE server - removed, this doesn't work well with the tileset.  
	  // CreateObject(OBJECT_TYPE_PLACEABLE, sResRef, lLoc);
    }
  }
}
//----------------------------------------------------------------
void DoDeadPeople()
{
  object oPC = GetEnteringObject();
  if (GetIsObjectValid(GetLocalObject(oPC, GetTag(OBJECT_SELF) + "_dead"))) return;

  vector vPosition = GetPosition(oPC);
  int nSizeX       = FloatToInt(gsARGetSizeX(OBJECT_SELF)) - 1;
  int nSizeY       = FloatToInt(gsARGetSizeY(OBJECT_SELF)) - 1;

  vPosition.x = IntToFloat(Random(nSizeX) + 1);
  vPosition.y = IntToFloat(Random(nSizeY) + 1);

  float fFacing = IntToFloat(Random(360));

  object oCopy = CopyObject(oPC, Location(OBJECT_SELF, vPosition, fFacing));
  effect eEffect = GetFirstEffect(oCopy);

  while (GetIsEffectValid(eEffect))
  {
    RemoveEffect(oCopy, eEffect);
    eEffect = GetNextEffect(oCopy);
  }

  AssignCommand(oCopy, SetIsDestroyable(FALSE, FALSE, FALSE));
  ApplyEffectToObject(DURATION_TYPE_PERMANENT, EffectDeath(), oCopy);
  SetAILevel(oCopy, AI_LEVEL_VERY_LOW);
  SetPlotFlag(oCopy, TRUE);

  SetLocalObject(oPC, GetTag(OBJECT_SELF) + "_dead", oCopy);
}

void gsActivateRecreator(object oRecreator)
{
    object oObject = CreateObject(GetLocalInt(oRecreator, "GS_TYPE"),
                                  GetLocalString(oRecreator, "GS_TEMPLATE"),
                                  GetLocation(oRecreator));

    if (GetIsObjectValid(oObject))
    {
      //::  Set additional variables from Ore Veins, if any.
      if ( GetLocalString(oRecreator, "ORE_TEMPLATE") != "" ) {
        SetLocalString(oObject, "ORE_TEMPLATE", GetLocalString(oRecreator, "ORE_TEMPLATE"));
        SetLocalInt(oObject, "ORE_EXPIRE", GetLocalInt(oRecreator, "ORE_EXPIRE"));
        SetLocalInt(oObject, "GVD_PLACEABLE_ID", GetLocalInt(oRecreator, "GVD_PLACEABLE_ID"));
      }

      SetLocalInt(oObject, "GS_STATIC", TRUE);
      if(!GetLocalInt(GetModule(), "STATIC_LEVEL") && ( GetStringLeft(GetTag(oObject), 11) == "GS_TREASURE" ||
                GetStringLeft(GetTag(oObject), 8) == "GS_ARMOR" ||
                GetStringLeft(GetTag(oObject), 9) == "GS_WEAPON" ||
                GetStringLeft(GetTag(oObject), 7) == "GS_GOLD"))
      {
                int nChance;
                if(GetStringRight(GetTag(oObject), 4) == "_LOW")
                    nChance = 25;
                else if(GetStringRight(GetTag(oObject), 5) == "_HIGH")
                    nChance = 75;
                else if(GetStringRight(GetTag(oObject), 7) == "_MEDIUM")
                    nChance = 50;

                if(nChance > 0)
                {
                    SetLocalInt(oObject, "md_lockcontrolled", 1);
                    if(d100() > nChance)
                        SetLocked(oObject, FALSE);
                    if(d100() > nChance)
                    {
                        SetTrapActive(oObject, FALSE);
                        SetTrapDetectable(oObject, FALSE);
                    }
                }
      }
    }
    DestroyObject(oRecreator);
}
//----------------------------------------------------------------
void gsActivateActivator(object oObject)
{
    ExecuteScript(GetLocalString(oObject, "GS_SCRIPT"), oObject);
}
//----------------------------------------------------------------
void _gsENSetUpArea(object oPC)
{
    if (GetLocalInt(oPC, "GS_ENABLED") == -1)
    {
        // If a player has only just [re]connected to the server, then prevent
        // an ambush right on top of them.
        object oWaypoint = guENCreateSafeZone(GetLocation(oPC));
        gsENSetUpArea();
        DestroyObject(oWaypoint);
    } else {
        gsENSetUpArea();
    }
}
//----------------------------------------------------------------
void _arCreateDynamicMerchant(string sResRef, object oSpawnWP) {
    location lSpawnLoc  = GetLocation(oSpawnWP);
    object oMerchant    = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lSpawnLoc);

    if ( !GetIsObjectValid(oMerchant) )  return;
    //::  TODO:  Customize appereance here?
    DelayCommand(0.4, AssignCommand(oMerchant, SetFacing(GetFacing(oSpawnWP))));
    DelayCommand(2.0, AssignCommand(oMerchant, PlayVoiceChat(VOICE_CHAT_HELLO)));
    DelayCommand(3.0, AssignCommand(oMerchant, ActionSpeakString("Welcome!  I am " + GetName(oMerchant) + " and my store is open for business!")));
}


//----------------------------------------------------------------


void main()
{
    object oEntering   = GetEnteringObject();
    if (! GetIsPC(oEntering)) return;
    object oModule     = GetModule();
    object oArea       = OBJECT_SELF;
    string sString     = "";
	
	// check if there is an area specific time-out
	int iAreaTimeout = GetLocalInt(oArea, "GVD_AREA_TIMEOUT");
	if (iAreaTimeout <= 0) {
	  // nope, use default constant
	  iAreaTimeout = GS_TIMEOUT;
	} else {
	  // yep, area timeout variable is in RT minutes, so convert to gametime seconds
	  iAreaTimeout = gsTIGetGameTimestamp(iAreaTimeout * 60);
	}
	// randomness (range = -1 to +1 RT minute, so -600 to + 600 seconds gametime)
	iAreaTimeout = iAreaTimeout -600 + Random(1200) + 1;
	// sanitize, minimum of 2 minutes at all times
	if (iAreaTimeout < 1200) {
	  iAreaTimeout = 1200;
	}
	
    int nTimestamp     = GetLocalInt(oModule, "GS_TIMESTAMP");
    int nTimestampArea = GetLocalInt(OBJECT_SELF, "GS_TIMESTAMP");
    int nTimeout       = nTimestamp - nTimestampArea > iAreaTimeout;
    int nDayTime       = gsTIGetCurrentDayTime();
    int nEnabled       = GetLocalInt(OBJECT_SELF, "GS_ENABLED");
    int nOverrideDeath = gsFLGetAreaFlag("OVERRIDE_DEATH", oEntering);
    int bStaticLevel   = GetLocalInt(GetModule(), "STATIC_LEVEL");
    int bNoCommands    = FALSE;

    //ambience
    if (nDayTime != gsTIGetDayTime()) gsSEAdd("gs_run_ambience", oArea);

    //area flags
    if (gsFLGetAreaFlag("EXPLORE_MAP", oEntering) || GetLocalInt(oArea, "explore"))  ExploreAreaForPlayer(OBJECT_SELF, oEntering);
    if (gsFLGetAreaFlag("PVP", oEntering))                 sString += " [" + GS_T_16777291 + "]";
    if (gsFLGetAreaFlag("REST", oEntering))                sString += " [" + GS_T_16777292 + "]";
    if (! gsFLGetAreaFlag("OVERRIDE_MAGIC", oEntering))    sString += " [" + GS_T_16777446 + "]";
    if (! gsFLGetAreaFlag("OVERRIDE_STATE", oEntering))    sString += " [" + GS_T_16777293 + "]";
    if (! gsFLGetAreaFlag("OVERRIDE_TELEPORT", oEntering)) sString += " [" + GS_T_16777294 + "]";
    if (! gsFLGetAreaFlag("OVERRIDE_TRANSFER", oEntering)) sString += " [" + GS_T_16777444 + "]";
    if (! nOverrideDeath)                                  sString += " [" + GS_T_16777295 + "]";
    if (sString != "")                                     SendMessageToPC(oEntering, GS_T_16777296 + ":" + sString);

    // Dismount horses
    if (GetIsAreaInterior(oArea) || !GetIsAreaAboveGround(oArea))
    {
      // dunshine: check for plot flag here, since the gs_m_death script triggers first for PCs that died and sets plot to true,
      // we don't want this code to execute here for death PCs, since it will clear the action queue of the PC, and that queue has the removal of the plot flag on a 6 second delay,
      // which will get canceled, resulting in immortality for the PC when it respawns. Added the dismount stuff to gs_m_death instead.
      if (!GetPlotFlag(oEntering)) {
        int bAnim=!GetLocalInt(OBJECT_SELF,"bDismountFast");
        if (HorseGetIsMounted(oEntering)&&!HorseGetIsAMount(oEntering))
        { // is mounted
          AssignCommand(oEntering,ClearAllActions(TRUE));
          AssignCommand(oEntering,HORSE_SupportDismountWrapper(bAnim,TRUE));
        } // is mounted
      }
    }
		
    // Clear PC state if they've been using the training/research/praying widgets
    // and logged off unexpectedly, or changed areas.
    DeleteLocalInt(oEntering, "training_time");
    DeleteLocalInt(oEntering, "is_training");
    DeleteLocalLocation(oEntering, "pray_location");
    DeleteLocalInt(oEntering, "praying_time");
    DeleteLocalLocation(oEntering, "research_location");
    DeleteLocalInt(oEntering, "research_time");
		
    // Hook into the quest scripts.
    CheckIfOnPatrol(oEntering, OBJECT_SELF);
	
	// CoW addition - reset reputation to 50 with the following factions
	// - animal faction (faction 17)
	// - plot faction (faction 12)
	// - merc factions (13,14,15,16,18)
	// - imperial commoners and merchants (1,2)
	object oNPC = GetObjectByTag("factionexample17");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample12");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample13");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample14");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample15");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample16");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample17");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample1");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
    oNPC        = GetObjectByTag("factionexample2");
    AdjustReputation(oEntering, oNPC, 50-GetFactionAverageReputation(oNPC, oEntering));
	
    UpdateRangerHiPS(oEntering);

    if (GetLocalInt(OBJECT_SELF, "MI_DEAD_PEOPLE")) DoDeadPeople();

    //remove caravan variable - PC has elected to stay here
    if (GetTag(OBJECT_SELF) != "OnTheRoad")
    {
      int nTravelling = GetLocalInt(oEntering, MICA_TRAVELLING);
      if (nTravelling == 2)
      {
        miSCRemoveInvis(oEntering);
        // Repeat as an assigned command
        AssignCommand(oEntering, miSCRemoveInvis(oEntering));
        SetLocalInt(oEntering, MICA_TRAVELLING, TRUE);
      }
      else if (nTravelling) DeleteLocalInt(oEntering, MICA_TRAVELLING);
    }

    //clean up area
    if (nTimestampArea != nTimestamp && GetLocalInt(OBJECT_SELF, "DM_FORCE_ACTIVE") != 1)
    {
        object oObject = GetFirstObjectInArea(OBJECT_SELF);
        object oItem   = OBJECT_INVALID;
        string sString = "";

        while (GetIsObjectValid(oObject))
        {
            sString = GetTag(oObject);

            switch (GetObjectType(oObject))
            {
            case OBJECT_TYPE_AREA_OF_EFFECT:

                break;

            case OBJECT_TYPE_CREATURE:

                //dead creature
                if (GetIsDead(oObject))
                {
                    if (!GetIsPC(oObject)) {

                      //resurrect creature
                      if (! gsFLGetFlag(GS_FL_MORTAL, oObject) &&
                        GetLocalInt(oObject, "GS_TIMEOUT") < nTimestamp)
                      {
                        gsCMResurrect(oObject);
                      }
                    }

                    break;
                }

                //activate ai
                if (!GetIsPC(GetMaster(oObject)))
                {
                  SetAILevel(oObject, AI_LEVEL_LOW);
                }
                break;

            case OBJECT_TYPE_DOOR:

                //close door
                if (GetIsOpen(oObject))
                {
                      // addition by Dunshine: check for the GVD_NO_AUTO_CLOSE variable to prevent certain doors from closing
                      if (GetLocalInt(oObject, "GVD_NO_AUTO_CLOSE") != 1) {
                        AssignCommand(oObject, ActionCloseDoor(oObject));
                      }
                }

                //lock door, unless it's a haunted door that will lock when interacted with.
                if (GetLockLockable(oObject) && 
				    !GetLocalInt(oObject, "GVD_NO_AUTO_LOCK") && 
				    GetEventScript(oObject, EVENT_SCRIPT_DOOR_ON_OPEN)!= "cow_haunteddoor")
                {
                    SetLocked(oObject, TRUE);
                }

                break;

            case OBJECT_TYPE_ENCOUNTER:

            case OBJECT_TYPE_ITEM:

            case OBJECT_TYPE_PLACEABLE:

                //static
                if (! nEnabled)
                {
                    SetLocalInt(oObject, "GS_STATIC", TRUE);
                }

                //close placeable
                if (GetIsOpen(oObject))
                {
                    AssignCommand(oObject, ActionCloseDoor(oObject));
                }

                //lock placeable
                if (GetLockLockable(oObject))
                {
                    if ((!bStaticLevel && (!GetLocalInt(oObject, "md_lockcontrolled") || GetLocalInt(oObject, "md_lockme")))  || (bStaticLevel && d6() > 4))
                    {
                       DeleteLocalInt(oObject, "md_lockme");
                       SetLocked(oObject, TRUE);
                    }
                }

                //recreator
                if (sString == "GS_RECREATOR")
                {
                    if (GetLocalInt(oObject, "GS_TIMEOUT") < nTimestamp)
                    {
                        DelayCommand(0.5, gsActivateRecreator(oObject));
                    }
                }

                //activator
                else if (sString == "GS_ACTIVATOR")
                {
                    DelayCommand(0.5, gsActivateActivator(oObject));
                }

                // Initialise quarters and shops; pay tax.
                else if (GetLocalString(oObject, "GS_CLASS") != "")
                {
                  DelayCommand(0.5, gsQUPayTax(oObject));
                }

                break;

            case OBJECT_TYPE_STORE:

                oItem = GetFirstItemInInventory(oObject);

                //clean store
                if (GetLocalInt(oObject, "GS_ENABLED"))
                {
                    while (GetIsObjectValid(oItem))
                    {
                        if (! GetLocalInt(oItem, "GS_STORE"))
                        {
                            DestroyObject(oItem);
                        }

                        oItem = GetNextItemInInventory(oObject);
                    }
                }

                //initialize store
                else
                {
                    SetLocalInt(oObject, "GS_ENABLED", TRUE);

                    while (GetIsObjectValid(oItem))
                    {
                        if (gvd_ItemAllowedInStores(oItem) == 1) {
                          SetLocalInt(oItem, "GS_STORE", TRUE);
                        } else {
                          // item is not allowed in stores
                          WriteTimestampedLogEntry("STORES: Item " + GetName(oItem) + " with resref " + GetResRef(oItem) + " is excluded from store " + GetName(oObject) + " with tag " + GetTag(oObject) + " in area " + GetName(oArea) + " with tag " + GetTag(oArea));
                          DestroyObject(oItem);
                        }
                        oItem = GetNextItemInInventory(oObject);
                    }
                }

                break;

            case OBJECT_TYPE_TRIGGER:

                break;

            case OBJECT_TYPE_WAYPOINT:

                //::------------------------------------------------------------
                //::  Added by ActionReplay
                //::  Dynamic Merchants
                //::------------------------------------------------------------
                if ( sString == "AR_DYN_MERCHANT" ) {
                    int iTimeStampMerchant = GetLocalInt(oObject, "GS_TIMESTAMP");

                    //::  Change Merchant every 2nd Day
                    if ( (nTimestamp - iTimeStampMerchant) > (86400*2) ) {
                    //if ( (nTimestamp - iTimeStampMerchant) > 0 ) {
                        SetLocalInt(oObject, "GS_TIMESTAMP", nTimestamp);

                        int nPrevMerchantId     = GetLocalInt(oObject, "AR_DYN_MER_PREV");
                        string sPrevMerchantTag = "AR_DYN_MER_" + IntToString(nPrevMerchantId);
                        object oPrevMerchant    = GetNearestObjectByTag(sPrevMerchantTag, oObject);

                        //::  Previous merchant leaves
                        if ( GetIsObjectValid(oPrevMerchant) ) {
                            AssignCommand(oPrevMerchant, PlayVoiceChat(VOICE_CHAT_GOODBYE));
                            AssignCommand(oPrevMerchant, ActionSpeakString("That's it folks!  I'm closing my shop."));
                            AssignCommand(oPrevMerchant, ActionPlayAnimation(ANIMATION_FIREFORGET_BOW));
                            DelayCommand(2.0, AssignCommand(oPrevMerchant, ActionMoveAwayFromObject(oObject)));
                            DelayCommand(2.2, AssignCommand(oPrevMerchant, SetCommandable(FALSE)));
                            DelayCommand(6.0, DestroyObject(oPrevMerchant));
                        }

                        //::  New Merchant arrives
                        int nNewMerchant = d4();
                        //::  Same merchant?  Adjust it
                        if (nNewMerchant == nPrevMerchantId) {
                            nNewMerchant++; if (nNewMerchant > 4) nNewMerchant = 1;
                        }
                        SetLocalInt(oObject, "AR_DYN_MER_PREV", nNewMerchant);

                        string sResRef  = GetLocalString(oObject, "AR_RESREF_" + IntToString(nNewMerchant));
                        DelayCommand(6.0, _arCreateDynamicMerchant(sResRef, oObject));
                    }
                }
                //::------------------------------------------------------------

                // added by Dunshine, check for Tinker Locations
                if (sString == "WP_gvd_tinker") {

                  // only check once a day (gametime)
                  int iTimeStampTinker = GetLocalInt(oObject,"GS_TIMESTAMP");
                  // use for easy testing: if ((nTimestamp - iTimeStampTinker) > 0) {
                  if ((nTimestamp - iTimeStampTinker) > 86400) {
                  // use for live, ingame day: if ((nTimestamp - iTimeStampTinker) > 86400) {

                    // already a Tinker there?
                    if (GetLocalInt(oObject,"iTinker") == 0) {

                      // nope, 10% of one appearing every day
                      // for testing 100% chance: if (d10(1) < 11) {
                      if (d10(1) == 1) {
                      // for live 10% chance: if (d10(1) == 1) {
                        // a Tinker arrives

                        // check how many Tinkers are available (not occupied elsewhere)
                        object oTinkerTracker = GetObjectByTag("gvd_tinker_tracker");
                        int iAvailable = GetLocalInt(oTinkerTracker,"iAvailable");

                        // pick one randomly
                        int iTinker = Random(iAvailable);

                        // determine the actual tinker
                        string sAvailable;
                        if (iAvailable != 7) {
                          sAvailable = GetLocalString(oTinkerTracker,"sAvailable");
                          while (GetSubString(sAvailable,iTinker,1) != "1") {
                            iTinker = iTinker + 1;
                          }
                          iTinker = iTinker + 1;
                        } else {
                          // all tinkers are available, so tinker is always available
                          sAvailable = "1111111";
                          iTinker = iTinker + 1;
                        }

                        // make selected Tinker unavailable
                        SetLocalInt(oTinkerTracker, "iAvailable", iAvailable-1);
                        sAvailable = GetStringLeft(sAvailable,iTinker-1) + "0" + GetStringRight(sAvailable,7-iTinker);
                        SetLocalString(oTinkerTracker, "sAvailable", sAvailable);

                        // store selected Tinker on waypoint and create the Tinker and his bag
                        SetLocalInt(oObject,"iTinker",iTinker);
                        object oTinker = GetObjectByTag("gvd_tinker_template"+IntToString(iTinker));
                        location locTinker = GetLocation(oObject);
                        oTinker = CopyObject(oTinker,locTinker,OBJECT_INVALID,"gvd_tinker"+IntToString(iTinker));
                        SetLocalInt(oTinker,"iTinker",iTinker);
                        SetLocalString(oTinker,"dialog","zdlg_gvd_tinker");

                        // place bag a bit to the side of the Tinker
                        float fTinkerDirection = GetFacing(oObject);
                        vector vTinkerPosition = GetPosition(oObject);
                        location locBag = Location(GetArea(oObject), vTinkerPosition + AngleToVector(fTinkerDirection + 90) * 0.5, fTinkerDirection);

                        object oTinkerBag = CreateObject(OBJECT_TYPE_PLACEABLE,"gvd_tinker_bag",locBag);

                        // make it static, so it doesn't get cleaned up later by gs_run_cleanarea
                        SetLocalInt(oTinkerBag, "GS_STATIC", TRUE);

                        // create a daypost waypoint for the Tinker so he doesn't move away from his location
                        CreateObject(OBJECT_TYPE_WAYPOINT,"gvd_tinker_loc",locTinker,FALSE,"GS_WP_DPOST_gvd_tinker"+IntToString(iTinker));

                      }

                      // next check in 24 hours
                      SetLocalInt(oObject,"GS_TIMESTAMP", nTimestamp);

                    } else {
                      // if no one in the area Tinker leaves
                      if (!gsARGetIsAreaActive(OBJECT_SELF)) {
                        int iTinker = GetLocalInt(oObject,"iTinker");
                        object oTinker = GetObjectByTag("gvd_tinker"+IntToString(iTinker));
                        object oTinkerBag = GetNearestObjectByTag("gvd_tinker_bag", oTinker);
                        if (oTinkerBag != OBJECT_INVALID) DestroyObject(oTinkerBag);
                        if (oTinker != OBJECT_INVALID) DestroyObject(oTinker);

                        // remove daypost waypoint as well
                        oTinker = GetObjectByTag("GS_WP_DPOST_gvd_tinker"+IntToString(iTinker));
                        if (oTinker != OBJECT_INVALID) DestroyObject(oTinker);

                        // remove variable, so the waypoint is available for another tinker again
                        DeleteLocalInt(oObject,"iTinker");

                        // update availibity on the tinker tracker as well
                        object oTinkerTracker = GetObjectByTag("gvd_tinker_tracker");
                        int iAvailable = GetLocalInt(oTinkerTracker,"iAvailable");
                        SetLocalInt(oTinkerTracker, "iAvailable", iAvailable-1);
                        string sAvailable = GetLocalString(oTinkerTracker,"sAvailable");
                        sAvailable = GetStringLeft(sAvailable,iTinker-1) + "1" + GetStringRight(sAvailable,7-iTinker);
                        SetLocalString(oTinkerTracker, "sAvailable", sAvailable);

                        // next check in 24 hours
                        SetLocalInt(oObject,"GS_TIMESTAMP", nTimestamp);

                      } else {
                        // still people in area, we leave the timestamp unchanged, so the clean-up will happen when all PC have left the area
                      }
                    }
                  }
                }

                break;
            }

            oObject = GetNextObjectInArea(OBJECT_SELF);
        }

        if (nTimeout && GetLocalInt(OBJECT_SELF, "DM_FORCE_ACTIVE") != 1)
            ExecuteScript("gs_run_cleanarea", oArea);
        gsARRegisterArea(OBJECT_SELF);
    }

    //load area
    if (! nEnabled)
    {
        // Dunshine: load area id and any variables here
        gvd_LoadAreaVars(OBJECT_SELF);

        gsENLoadArea(OBJECT_SELF, FALSE);
        gsBOLoadArea();
        gsPLLoadArea();
        gsFXLoadFixture(GetTag(OBJECT_SELF));

        // after fixtures are loaded, all pc created plants will be flagged as exhausted to deal with existing plants outside the designated trigger areas
        // we remove the exhausted flag from the plants inside those triggers now:
        gvd_ActivateCropAreas(OBJECT_SELF);

        SetLocalInt(OBJECT_SELF, "GS_ENABLED", TRUE);
    }

    // Only update the timestamp if the area is not force-active.
    if (GetLocalInt(OBJECT_SELF, "DM_FORCE_ACTIVE") != 1)
    {
        SetLocalInt(OBJECT_SELF, "GS_TIMESTAMP", nTimestamp);
    }

    // Batra: Notify DMs of character entry if DM_NOTIFY is active.
    if (GetLocalInt(OBJECT_SELF, "DM_NOTIFY") == 1)
    {
      SendMessageToAllDMs(GetName(oEntering) + " entering " + GetName(OBJECT_SELF));
    }

    if (GetLocalString(OBJECT_SELF, "GS_TEXT") != "")
    {
      string sAreaText = GetLocalString(OBJECT_SELF, "GS_TEXT");

      DelayCommand(2.5, SendMessageToPC(oEntering, sAreaText));
    }

    //encounter
    if (nTimeout)
    {
        // NO_SPAWNS_NIGHT prevents spawns in this area at night, whereas NO_SPAWNS_DAY does the same for day.
        int spawnsAllowedDuringDay = !GetLocalInt(OBJECT_SELF, "NO_SPAWNS_DAY");
        int spawnsAllowedDuringNight = !GetLocalInt(OBJECT_SELF, "NO_SPAWNS_NIGHT");

        int spawnBecauseDay = GetIsDay() && spawnsAllowedDuringDay;
        int spawnBecauseNight = GetIsNight() && spawnsAllowedDuringNight;

        // During hours 6 and 20 it is neither night nor day, so we want to spawn.
        // If spawns are disallowed during day *and* night, then don't spawn.
        int spawnBecauseNeitherNightNorDay = !GetIsDay() && !GetIsNight() && (spawnsAllowedDuringDay || spawnsAllowedDuringNight);

        if (spawnBecauseDay || spawnBecauseNight || spawnBecauseNeitherNightNorDay)
        {
            gsBOSetUpArea();  // Do this first, so the encounters can avoid boss spawns
            _gsENSetUpArea(oEntering);
        }

        DoRandomTraps();

        // Random trees in forest and woodland areas.
        // Removed - may be causing crashes.
        /*
        if (!GetIsAreaInterior(oArea) &&
          (FindSubString(GetName(OBJECT_SELF), "Forest") >= 0 ||
           FindSubString(GetName(OBJECT_SELF), "Wood") >=0))
        {
            DoRandomTrees();
        }*/

        DoWeatherEffects();
    }

    // weather
    if (ALLOW_WEATHER)
    {
        miWHSetWeather();
    }

    if (GetIsPossessedFamiliar(oEntering)) return;
    if (GetIsDMPossessed(oEntering))       return;

    if (GetIsDM(oEntering))
    {
        if (! GetLocalInt(oEntering, "GS_ENABLED"))
        {
            object oTarget = GetObjectByTag("GS_TARGET_DM");

            if (GetIsObjectValid(oTarget))
                AssignCommand(oEntering, JumpToLocation(GetLocation(oTarget)));
            SetLocalInt(oEntering, "GS_ENABLED", TRUE);
        }

        return;
    }

    // Clear PC traps near entering player, to avoid issues with transition trapping.
    trapClearTrapsNear(oEntering);

    //mortality
    SetImmortal(oEntering, nOverrideDeath);

    location lLocationExit = GetLocalLocation(oEntering, "GS_LOCATION");

    int nEnterState = GetLocalInt(oEntering, "GS_ENABLED");
    switch (nEnterState)
    {
    case TRUE:
    {

        Log(ENTER, GetName(oEntering) + " entering " + GetTag(OBJECT_SELF) +
         ", currently GS_ENABLED = 1.");
        int bSave = FALSE;

        // verify deity - moved to before we save the PC as that re-applies
        // polymorph & may be the cause of polymorphed PCs not getting
        // checked correctly.
        string sDeity = GetDeity(oEntering);

        if (sDeity != "" && !gsC2GetHasEffect(EFFECT_TYPE_POLYMORPH, oEntering))
        {
            int nDeity = gsWOGetDeityByName(sDeity);

            if (nDeity) nDeity = gsWOGetIsDeityAvailable(nDeity, oEntering);

            if (! nDeity)
            {
                SetDeity(oEntering, "");
                SendMessageToPC(oEntering, GS_T_16777297);
            }
        }

        //export character
        if (GetPCPublicCDKey(oEntering) != "")
        {
            ExportSingleCharacter(oEntering);

            miDVSavePoints(oEntering);
            bSave = TRUE;
        }

        //----------------------------------------------------------------------
        // save player location as long as:
        // The override location flag is not set,
        // and,
        // we're saving the character or this is an area people aren't allowed
        // to escape from (e.g. a jail).
        //
        // We could just save every time but that's bad for performance.
        //----------------------------------------------------------------------
        if ((bSave || !gsFLGetAreaFlag("OVERRIDE_TELEPORT", oEntering)) &&
            !gsFLGetAreaFlag("OVERRIDE_LOCATION", oEntering))
        {
            gsPCSavePCLocation(oEntering, GetLocation(oEntering));
        }

        SetLocalLocation(oEntering, "GS_LOCATION", GetLocation(oEntering));

        // Apply weather effects.
        if (ALLOW_WEATHER) {
            miWHDoWeatherEffects(oEntering);
        }

        // Tracks.
        miTRDoTracks(oEntering);

        // Dunshine: Handle area exploration XP
        gvd_AdventuringXP_ForArea(oEntering, oArea);

        //subrace selection
        if (! GetIsObjectValid(gsPCGetCreatureHide(oEntering)))
            AssignCommand(oEntering, ActionStartConversation(oEntering, "gs_su_select", TRUE, FALSE));
        else if (GetLevelByClass(CLASS_TYPE_PURPLE_DRAGON_KNIGHT, oEntering) && !GetLocalInt(gsPCGetCreatureHide(oEntering), VAR_PDK))
            StartDlg(oEntering, oEntering, "zdlg_pdkclass", TRUE, FALSE);

        break;
    }
    case -1:
        //initialisation
        Log(ENTER, GetName(oEntering) + " entering " + GetTag(OBJECT_SELF) +
         ", currently GS_ENABLED = -1.");

        // Added by Mithreas - override PRC requirements if needed
        miCLOverridePRC(oEntering);

        AssignCommand(oEntering, ExecuteScript("gs_run_pc_init", oEntering));
        bNoCommands = TRUE;
        break;

    default:

        Log(ENTER, GetName(oEntering) + " entering " + GetTag(OBJECT_SELF) +
         ", currently GS_ENABLED = " + (nEnterState ? "-2." : "0."));

        // Touch the character file.  This ensures that when we portal, we use
        // the most recent file.
        ExportSingleCharacter(oEntering);

        //load player location
        location lLocation;
        if (nEnterState)
        {
          lLocation = GetLocation(GetObjectByTag("GS_TARGET_START"));
        }
        else
        {
          lLocation = gsPCGetSavedLocation(oEntering);
        }
        // Check whether our creature skin has a waypoint tag saved on it. If
        // so, jump to that waypoint and delete the var.
        string sWaypoint = GetLocalString(gsPCGetCreatureHide(oEntering),
                                          "DEST_WP");
        if (sWaypoint != "")
        {
          Log(ENTER, "Portalling from another server to: " + sWaypoint);
          lLocation = GetLocation(GetObjectByTag(sWaypoint));
          DeleteLocalString(gsPCGetCreatureHide(oEntering), "DEST_WP");

          // Dunshine: Handle area exploration XP for cross server area entering here
          gvd_AdventuringXP_ForArea(oEntering, oArea);
        }
        else
        {
          // Check if we're logging into the wrong server.
          string sID = gsPCGetPlayerID(oEntering);
          SQLExecStatement("SELECT s.sid, s.state FROM gs_pc_data AS p INNER JOIN " +
           "nwn.web_server AS s ON p.modified_server=s.sid WHERE p.id=?", sID);
          if (SQLFetch())
          {
            // If we should be on another server which is up, portal there.
            string sServerID = SQLGetData(1);
            if (sServerID != miXFGetCurrentServer() && StringToInt(SQLGetData(2)) == MI_XF_STATE_UP)
            {
              miXFDoPortal(oEntering, sServerID);
              return;
            }
          }
          // Nothing found at all - new character, set to current server.
          else
          {
            miDASetKeyedValue("gs_pc_data", sID, "modified_server", miXFGetCurrentServer());
          }
        }

        //----------------------------------------------------------------------
        // If position is the 0,0,0 vector then we don't have a stored location
        // and this is a new character.  In this case, go to the starting
        // location for this module.
        //
        // Next, check whether the position is (0.1, 0.1, 0.1).  We use
        // this special location to indicate that we're portalling from another
        // server and therefore that the other server shouldn't try and jump
        // this PC anywhere.
        //
        // If it's neither of these special cases, check whether the location
        // is valid - if not, it's on the other server and we should send the
        // PC across (but not set position to 1/1/1 as we want them to go to
        // the actual saved location once they get there).
        //
        // Finally, if the location is valid, jump to it.
        //----------------------------------------------------------------------
        if (GetHitDice(oEntering) == 1 ||
            GetPositionFromLocation(lLocation) == Vector(0.0,0.0,0.0))
        {
          lLocation = GetLocation(GetObjectByTag("GS_TARGET_START"));
        }

        if (GetIsObjectValid(GetAreaFromLocation(lLocation)))
        {
          Log(ENTER, "Jumping " + GetName(oEntering) + " to location: " +
            APSLocationToString(lLocation));
          AssignCommand(oEntering, ActionJumpToLocation(lLocation));
        }

        //initialize player state
        AssignCommand(oEntering, gsSTSetInitialState());

        if (GetLocalInt(GetModule(), "STATIC_LEVEL") &&
            !GetIsObjectValid(GetItemPossessedBy(oEntering, "mi_mark_destiny")))
        {
          // On FL, everyone is marked,
          CreateItemOnObject("mi_mark_destiny", oEntering);
        }

        SetLocalInt(oEntering, "GS_ENABLED", -1);
        break;
    }

    //give base experience
    if (GetXP(oEntering) < GS_EXPERIENCE_BASE) GiveXPToCreature(oEntering, GS_EXPERIENCE_BASE);


    //banishment
    string sNationName = GetLocalString(oArea, VAR_NATION);
    string sNation     = miCZGetBestNationMatch(sNationName);
    int nNoBanishment  = GetLocalInt(oArea, "MI_CZ_NO_BANISHMENT");

    if (!nNoBanishment && sNation != "")
    {
      if (!miSCIsScrying(oEntering) && miCZGetIsExiled(oEntering, sNation))
      {
        Trace(CITIZENSHIP, GetName(oEntering) + " is exiled from " + sNationName);

        // Check whether the PC manages to evade the attentions of the guards.
        int nPerform = GetSkillRank(SKILL_PERFORM, oEntering);
        int nBluff   = GetSkillRank(SKILL_BLUFF,   oEntering);
        int nSkillRank;

        if (nPerform > nBluff) nSkillRank = nPerform;
        else nSkillRank = nBluff;

        int nRoll = d20();
        if (!GetIsPCDisguised(oEntering) || (nRoll <6 || nRoll + nSkillRank < 40))
        {
          Trace(CITIZENSHIP, GetName(oEntering) + " failed to evade the guards.");
          object oAreaExit = GetAreaFromLocation(lLocationExit);

          if (GetIsObjectValid(oAreaExit) &&
              oAreaExit != oArea &&
              GetLocalString(oAreaExit, VAR_NATION) != GetLocalString(oArea, VAR_NATION) &&
              GetTag(oAreaExit) != "GS_AREA_DEATH")
          {
            Trace(CITIZENSHIP, "Sending back to where they came in.");
            AssignCommand(oEntering, ClearAllActions());
            AssignCommand(oEntering, JumpToLocation(lLocationExit));
            SendMessageToPC(oEntering, GS_T_16777524);
          }
          else
          {
            object oTargetExit = gsCMGetObject("GS_TARGET_" + GetStringUpperCase(sNationName));

            if (GetIsObjectValid(oTargetExit))
            {
              Trace(CITIZENSHIP, "Sending to standard exit point.");
              lLocationExit = GetLocation(oTargetExit);
              oAreaExit     = GetAreaFromLocation(lLocationExit);

              if (oAreaExit != oArea &&
                  GetLocalString(oAreaExit, VAR_NATION) != sNationName)
              {
                 AssignCommand(oEntering, ClearAllActions());
                 AssignCommand(oEntering, JumpToLocation(lLocationExit));
                 SendMessageToPC(oEntering, GS_T_16777525);
              }
            }
          }
        }
        else
        {
          Trace(CITIZENSHIP, GetName(oEntering) + " evaded the guards.");
          SendMessageToPC(oEntering, "You successfully deceive the guards.");
        }
      }
    }



    // Moved to the bottom of the script because it broke exile.
    if (bNoCommands)
        SetCommandable(FALSE, oEntering);
}


