/* inc_reputation

  Design: Mithreas & SeaWraith

  Database tables
  rep_pcRep - this table ties player.charname to one (or more) groups, and holds
  the actual reputation score for that entry. Value names are
                   'pcid.groupnumber'

  rep_repRankText - holds all of the rank "titles" for all of the groups, the
  associated GroupID, and the minimum / maximum reputation score for each
  "title".

  rep_factionRep - holds the scores for the factions.

*/
#include "inc_crime"
// inc_crime includes inc_log
#include "inc_database"
#include "inc_pc"
const string REP = "REPUTATION"; // for tracing
const string RANKS = "RANKS"; // for tracing

/* Database names */
const string DB_VALUES     = "rep_pcrep";
const string DB_FACTIONREP = "rep_factionrep";
const string DB_RANKS      = "rep_pcranks";
/* faction/rank(number)/(min)score/name */

/* Faction definitions */
const int FACTION_GLOBAL   = 0;   // Global reputation
const int FACTION_IMPERIAL = NATION_DEFAULT; // 1
const int FACTION_MIGHT    = NATION_DRANNIS; // 2
const int FACTION_SPIRIT   = NATION_ERENIA;  // 3
const int FACTION_VOICE    = NATION_RENERRIN; // 4
const int FACTION_SHADOW   = NATION_SHADOW;  // 5

/* function prototypes */
// Get the name of this faction from its number.
string GetFactionName(int nFaction);

// Get the number of this faction from its name. Defaults to FACTION_GLOBAL
int GetFactionFromName(string sFactionName);

// Helper function to construct the database variable name.
string GetRepVarName(object oPC, int nFaction);

// displays reputation score of target PC. Returns 0 if oPC is not a valid PC.
// bAddGlobal - true if you want faction rep + global rep
int GetRepScore(object oPC, int nFaction = 0, int bAddGlobal = 0);

// displays reputation score for all PCs currently logged in to the person who
// used the calling item.
void DisplayAllRepScores();

// increments reputation score of target PC and optionally party  by '1'
void GiveRepPoint(object oPC, int nFaction = 0, int bParty = 0);

// Reduces reputation score of target PC and optionally party by 1.
void TakeRepPoint(object oPC, int nFaction = 0, int bParty = 0);

// increments reputation score of target PC and optionally party by nAmount.
// If a PC has reached a new rank, they get a message telling them so.
void GiveRepPoints(object oPC, int nAmount, int nFaction = 0, int bParty = 0);

// Directly set a PC's reputation score.
void SetRepScore(object oPC, int nNewScore, int nFaction = 0);

// Give points to the specified faction.
void GivePointsToFaction(int nAmount, int nFaction);

// Get the faction's current score.
int GetFactionScore(int nFaction);

// Get a PC's faction.
int GetPCFaction(object oPC);

// Set a PC's faction.
void SetPCFaction(object oPC, int nFaction);

// Return the number of reputation points a PC needs to hit the next level.
int GetRepPointsNeededToLevel(object oPC);

// Return the name of the PC's current rank
string GetPCFactionRank(object oPC);

// Get the PC's rank number based on their rep score.
int GetPCRank(string sFaction, int nRepScore);

// Get the name of the PC's current rank.
string GetRankName(string sFaction, int nRank);

// Get the score needed for this rank.
int GetRepNeededForRank(string sFaction, int nRank);

/* Function implementation */
// Get the PC's rank number based on their rep score.
int GetPCRank (string sFaction, int nRepScore)
{
  string sSQL = "SELECT rank FROM "+DB_RANKS+" WHERE score <= '"+IntToString(nRepScore)+
                 "' ORDER BY score DESC LIMIT 1";

  Trace(RANKS, "Submitting query " + sSQL);
  SQLExecDirect(sSQL);

  if (SQLFetch() == SQL_SUCCESS)
  {
    string sCurrentRankScoreAsString = SQLGetData(1);
    Trace(RANKS, "Got current rank score: " +sCurrentRankScoreAsString);
    return StringToInt(sCurrentRankScoreAsString);
  }
  else
  {
    Trace(RANKS, "Error querying database. No data returned.");
    return 0;
  }
}

// Get the name of the PC's current rank.
string GetRankName(string sFaction, int nRank)
{
  string sSQL = "SELECT name FROM "+DB_RANKS+" WHERE faction='"+sFaction+
                "' AND rank='"+IntToString(nRank)+"'";
  Trace(RANKS, "Submitting query " + sSQL);
  SQLExecDirect(sSQL);

  if (SQLFetch() == SQL_SUCCESS)
  {
    string sRankName = SQLGetData(1);
    Trace(RANKS, "Got rank name: " +sRankName);
    return sRankName;
  }
  else
  {
    Trace(RANKS, "Error querying database. No data returned.");
    return "";
  }
}

// Get the score needed for this rank.
int GetRepNeededForRank(string sFaction, int nRank)
{
  string sSQL = "SELECT score FROM "+DB_RANKS+" WHERE faction='"+sFaction+
                "' AND rank='"+IntToString(nRank)+"'";
  Trace(RANKS, "Submitting query " + sSQL);
  SQLExecDirect(sSQL);

  if (SQLFetch() == SQL_SUCCESS)
  {
    string sScoreAsString = SQLGetData(1);
    Trace(RANKS, "Got rank score: " +sScoreAsString);
    return StringToInt(sScoreAsString);
  }
  else
  {
    Trace(RANKS, "Error querying database. No data returned.");
    return 0;
  }
}

// Return the number of reputation points a PC needs to hit the next level.
int GetRepPointsNeededToLevel(object oPC)
{
  // Get PC current rep score
  string sSubRace = GetSubRace(oPC);
  int nRepScore   = GetRepScore(oPC, GetFactionFromName(sSubRace));
  Trace(RANKS, "PC current rep score: " + IntToString(nRepScore));

  // Get PC current rank number
  int nRank = GetPCRank(sSubRace, nRepScore);
  Trace(RANKS, "PC current rank: " + IntToString(nRank));

  // Get score needed for next rep score.
  int nCurrentRankScore = GetRepNeededForRank(sSubRace, nRank);
  int nNextRankScore    = GetRepNeededForRank(sSubRace, nRank + 1);
  Trace(RANKS, "PC current rank score needed: " + IntToString(nCurrentRankScore));
  Trace(RANKS, "PC next rank score needed: " + IntToString(nNextRankScore));

  return (nNextRankScore - nCurrentRankScore);
}

// Return the name of the PC's current rank
string GetPCFactionRank(object oPC)
{
  // Get PC current rep score
  string sSubRace = GetSubRace(oPC);
  int nRepScore   = GetRepScore(oPC, GetFactionFromName(sSubRace));
  Trace(RANKS, "PC current rep score: " + IntToString(nRepScore));

  // Get PC current rank number
  int nRank = GetPCRank(sSubRace, nRepScore);
  Trace(RANKS, "PC current rank number: " + IntToString(nRank));

  // Get rank name of current rank.
  string sRank = GetRankName(sSubRace, nRank);
  Trace(RANKS, "PC current rank name: " + sRank);
  return sRank;
}

string GetFactionName(int nFaction)
{
  switch (nFaction)
  {
    case FACTION_GLOBAL:
      return "Global";
    case FACTION_IMPERIAL:
      return "Imperial";
    case FACTION_MIGHT:
      return "House Drannis";
    case FACTION_SPIRIT:
      return "House Erenia";
    case FACTION_VOICE:
      return "House Renerrin";
    case FACTION_SHADOW:
      return "The Shadow";
  }

  return "";
}

int GetFactionFromName(string sFactionName)
{
  Trace(REP, "Getting faction for name "+sFactionName);

  if (sFactionName == "Imperial")
      return FACTION_IMPERIAL;
  else if (sFactionName == "House Drannis")
      return FACTION_MIGHT;
  else if (sFactionName == "House Erenia")
      return FACTION_SPIRIT;
  else if (sFactionName == "House Renerrin")
      return FACTION_VOICE;
  else if (sFactionName == "The Shadow")
      return FACTION_SHADOW;

  return FACTION_GLOBAL;
}

string GetRepVarName(object oPC, int nFaction)
{
  string sPlayerName = GetPCPlayerName(oPC);
  string sCharName   = GetName (oPC);
  string sVarName    = sPlayerName + sCharName + IntToString(nFaction);

  Trace(REP, "Using varname " + sVarName);
  return sVarName;
}

// displays reputation score of target PC.
// bAddGlobal - true if you want faction rep + global rep
int GetRepScore(object oPC, int nFaction = 0, int bAddGlobal = 0)
{
  Trace(REP, "Getting rep score for " + GetName(oPC) + " with faction " +
             GetFactionName(nFaction));
  int nRepScore = 0;
  if (!GetIsPC(oPC)) return nRepScore;

  string sVarName = GetRepVarName(oPC, nFaction);
  nRepScore = GetPersistentInt(oPC, sVarName, DB_VALUES);

  if (bAddGlobal)
  {
    sVarName = GetRepVarName(oPC, 0);
    nRepScore += GetPersistentInt(oPC, sVarName, DB_VALUES);
  }

  return nRepScore;
}

// Directly set a PC's reputation score.
void SetRepScore(object oPC, int nNewScore, int nFaction = 0)
{
  string sVarName = GetRepVarName(oPC, nFaction);

  SetPersistentInt(oPC, sVarName, nNewScore,0, DB_VALUES);
}

// displays reputation score for all PCs currently logged in
void DisplayAllRepScores()
{
  object oDM = GetItemActivator();
  SendMessageToPC(oDM, "Reputation scores: ");

  string sMessage;
  object oPC = GetFirstPC();

  while (GetIsObjectValid(oPC))
  {
    sMessage = GetName(oPC) + ". Global reputation: ";
    sMessage += IntToString(GetRepScore(oPC));
    sMessage += ", House Drannis reputation: ";
    sMessage += IntToString(GetRepScore(oPC, 1));
    sMessage += ", House Erenia reputation: ";
    sMessage += IntToString(GetRepScore(oPC, 2));
    sMessage += ", House Renerren reputation: ";
    sMessage += IntToString(GetRepScore(oPC, 3));
    sMessage += ", Shadow reputation: ";
    sMessage += IntToString(GetRepScore(oPC, 4));

    SendMessageToPC(oDM, sMessage);
    oPC = GetNextPC();
  }
}

// increments reputation score of target PC and optionally party  by '1'
void GiveRepPoint(object oPC, int nFaction = 0, int bParty = 0)
{
  GiveRepPoints (oPC, 1, nFaction, bParty);
}

void TakeRepPoint(object oPC, int nFaction = 0, int bParty = 0)
{
  GiveRepPoints (oPC, -1, nFaction, bParty);
}

// increments reputation score of target PC and optionally party by nAmount
void GiveRepPoints(object oPC, int nAmount, int nFaction = 0, int bParty = 0)
{
  int nRepScore;

  if (bParty)
  {
    object oPCInParty = GetFirstFactionMember(oPC, TRUE);

    while (GetIsObjectValid(oPCInParty))
    {
      if (GetArea(oPCInParty) == GetArea(oPC))
      {
        nRepScore = GetRepScore(oPCInParty, nFaction);
        SetRepScore(oPC, nRepScore + nAmount, nFaction);
        Trace(REP, "Increased rep score for char " + GetName(oPCInParty) +
                   " with" + " faction " + GetFactionName(nFaction));
        SendMessageToPC(oPCInParty, "Gained rep points with "+
                        GetFactionName(nFaction) + ": " + IntToString(nAmount));
      }

      oPCInParty = GetNextFactionMember(oPC, TRUE);
    }
  }
  else
  {
    nRepScore = GetRepScore(oPC, nFaction);
    SetRepScore(oPC, nRepScore + nAmount, nFaction);
    Trace(REP, "Increased rep score for char " + GetName(oPC) + " with" +
               " faction " + GetFactionName(nFaction));
    SendMessageToPC(oPC, "Gained rep points with "+GetFactionName(nFaction)+": "
                                                        + IntToString(nAmount));
  }

  string sCurrentRank = GetPCFactionRank(oPC);
  SendMessageToPC(oPC, "Your current rank is "+sCurrentRank);
}

void GivePointsToFaction(int nAmount, int nFaction)
{
  Trace(REP, "Giving "+IntToString(nAmount)+" points to "+GetFactionName(nFaction));
  int nScore = GetPersistentInt(OBJECT_INVALID, GetFactionName(nFaction), DB_FACTIONREP);
  SetPersistentInt(OBJECT_INVALID, GetFactionName(nFaction), nScore+nAmount, 0, DB_FACTIONREP);
}

int GetFactionScore(int nFaction)
{
  Trace(REP, "Getting rep score for "+GetFactionName(nFaction));
  int nScore = GetPersistentInt(OBJECT_INVALID, GetFactionName(nFaction), DB_FACTIONREP);
  Trace(REP, "Returning "+IntToString(nScore));
  return nScore;
}

int GetPCFaction(object oPC)
{
  string sSubRace = GetSubRace(oPC);
  return (GetFactionFromName(sSubRace));
}

void SetPCFaction(object oPC, int nFaction)
{
  SetSubRace (oPC, GetFactionName(nFaction));
}

//void main() {}

