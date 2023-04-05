#include "ScriptEngine/Effects/Base/BaseMouthEvent.as"

namespace MaskEngine
{

class mouth_close : BaseMouthEvent
{
    bool NeedCall(bool bOpen) override
    {
        return bOpen == false;
    }

    String GetName() override
    {
        return "mouth_close";
    }
}

}