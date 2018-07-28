// zzdlg_check_14
//
// Original filename under Z-Dialog: zdlg_check_13 (I copied 13 to extend)
// Copyright (c) 2004 Paul Speed - BSD licensed.
//  NWN Tools - http://nwntools.sf.net/
//
// Additions and changes from original copyright (c) 2005-2006 Greyhawk0

#include "zzdlg_tools_inc"

const int ENTRY_NUM = 14;

int StartingConditional()
{
    object oSpeaker = _dlgGetPcSpeaker();
    return( _SetupDlgResponse( ENTRY_NUM - 1, oSpeaker ) );
}
