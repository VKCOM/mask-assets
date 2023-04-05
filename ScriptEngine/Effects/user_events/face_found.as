#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseFaceEvent.as"

namespace MaskEngine
{

class face_found : BaseFaceEvent
{
    bool NeedCall(bool bFound) override
    {
        return bFound == true;
    }

    String GetName() override
    {
        return "face_found";
    }
}

}