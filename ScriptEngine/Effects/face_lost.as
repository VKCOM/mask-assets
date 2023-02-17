#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseFaceEvent.as"

namespace MaskEngine
{

class face_lost : BaseFaceEvent
{
    bool NeedCall(bool bFound) override
    {
        return bFound == false;
    }

    String GetName() override
    {
        return "face_lost";
    }
}

}