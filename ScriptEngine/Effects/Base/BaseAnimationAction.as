#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseAction.as"


namespace MaskEngine
{

class BaseAnimationAction : BaseAction
{
    BaseAnimation@ _animationEffect;
    float _delay = 0.0;
    float _currentDelay = 0.0;
    // True if delay has ended
    bool _isRunning = false;


    // init object from code.
    bool Init(BaseEffect@ baseEffect) override
    {
        BaseEffectImpl::Init(baseEffect);

        if (_ownerEffect !is null)
           @_animationEffect = _ownerEffect.GetAnimation();

        _inited = _animationEffect !is null;
        return _inited;
    }

    void Apply() override
    {
        if (_delay > 0.0)
        {
            if (!_isRunning)
            {
                _currentDelay = _delay;
                _isRunning = true;
            }
        }
        else
        {
            Action();
        }
    }

    void Action()
    {
        log.Warning("Method Action should be override");
    }

    void SetParameter(String& name, Variant& value)
    {
        if (name == "delay")
        {
            _delay = value.GetFloat();
            if (_delay > 0.0)
                SubscribeToEvent("Update", "HandleUpdate");
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (!_inited)
            return;

        if (_isRunning)
        {
            _currentDelay -= eventData["TimeStep"].GetFloat();

            if (_currentDelay <= 0.0)
            {
                _currentDelay = 0.0;
                _isRunning = false;
                Action();
            }
        }
    }
}

}
