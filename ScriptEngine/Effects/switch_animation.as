#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseAnimationAction.as"


namespace MaskEngine
{

class switch_animation : BaseAnimationAction
{
    void Action() override
    {
        if (!_animationEffect.IsPlaying())
        {
            _animationEffect.Play();
        }
        else
        {
            _animationEffect.Stop();
            _animationEffect.SetTime(0.0);
        }
    }

    String GetName() override
    {
        return "switch_animation";
    }
}

}
