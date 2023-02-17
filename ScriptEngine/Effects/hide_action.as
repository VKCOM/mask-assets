#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseVisibleAction.as"

namespace MaskEngine
{

class hide_action : BaseVisibleAction
{
    bool GetVisible()
    {
        return false;
    }

    String GetName() override
    {
        return "hide_action";
    }
}

}