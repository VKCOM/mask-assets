#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseAction.as"

namespace MaskEngine
{

class animation_visible : BaseAction
{
    bool _isVisible = false;

    animation_visible()
    {
        SubscribeToEvent(START_ANIMATION_EVENT, "HandleStartAnimation");
        SubscribeToEvent(STOP_ANIMATION_EVENT, "HandleFinishAnimation");
    }

    // init object from code. 
    bool Init(BaseEffect@ baseEffect)
    {
        if (baseEffect !is null)
        {
            @_ownerEffect = baseEffect;
        }

        _inited = _ownerEffect !is null;
        return _inited;
    }

    void Apply() override
    {
        if (_ownerEffect !is null)
        {
            _ownerEffect.SetVisible(_isVisible);
        }
    }

    void HandleStartAnimation(StringHash eventType, VariantMap& eventData)
    {
        BaseEffect@ baseRootEffect = cast<BaseEffect>(eventData["RootEffect"].GetScriptObject());

        if (GetRootEffect().GetEffectId() == baseRootEffect.GetEffectId())
        {
            _isVisible = true;
        }
    }

    void HandleFinishAnimation(StringHash eventType, VariantMap& eventData)
    {
        BaseEffect@ baseRootEffect = cast<BaseEffect>(eventData["RootEffect"].GetScriptObject());

        if (GetRootEffect().GetEffectId() == baseRootEffect.GetEffectId())
        {
            _isVisible = false;
        }
    }

    String GetName() override
    {
        return "animation_visible";
    }
}

}