#include "inc_boss"
#include "inc_log"

void main()
{
    gsBOSaveArea(GetArea(OBJECT_SELF));
    DMLog(OBJECT_SELF, OBJECT_INVALID, "EditBossEncounters(ApplySettingsPermanently)");
}
