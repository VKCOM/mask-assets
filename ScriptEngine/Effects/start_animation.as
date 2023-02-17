#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseAnimationAction.as"


namespace MaskEngine
{

class start_animation : BaseAnimationAction
{
    void Action() override
    {
        _animationEffect.Play();
    }

    String GetName() override
    {
        return "start_animation";
    }
}

}
