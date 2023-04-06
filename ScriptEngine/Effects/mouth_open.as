#include "ScriptEngine/Effects/Base/BaseMouthEvent.as"

namespace MaskEngine
{

class mouth_open : BaseMouthEvent
{
    bool NeedCall(bool bOpen) override
    {
        return bOpen == true;
    }

    String GetName() override
    {
        return "mouth_open";
    }
}

}