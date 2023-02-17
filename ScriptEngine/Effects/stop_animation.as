#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseAnimationAction.as"

namespace MaskEngine
{

class stop_animation : BaseAnimationAction
{
    void Action() override
    {
        _animationEffect.Stop();
        _animationEffect.SetTime(0.0);
    }

    String GetName() override
    {
        return "stop_animation";
    }
}

}
