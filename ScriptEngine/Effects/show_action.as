#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseVisibleAction.as"

namespace MaskEngine
{

class show_action : BaseVisibleAction
{
    bool GetVisible()
    {
        return true;
    }

    String GetName() override
    {
        return "show_action";
    }
}

}