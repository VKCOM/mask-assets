#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseAction.as"

namespace MaskEngine
{

class BaseVisibleAction : BaseAction
{
    private float _delay        = 0.0;
    private float _currentDelay = 0.0;
    private bool  _isRunning    = false;


    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseAction::Init(effect_desc, parent))
        {
            return false;
        }

        if (effect_desc.isObject)
        {
            _delay = effect_desc.Get("delay").GetFloat();

            if (_delay > 0.0)
            {
                SubscribeToEvent("Update", "HandleUpdate");
            }
        }

        return true;
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
            ChangeVisible();
        }
    }

    void ChangeVisible()
    {
        if (_ownerEffect !is null)
        {
            _ownerEffect.SetVisible(GetVisible());
        }
    }


    bool GetVisible()
    {
        log.Warning("Override this method in inherited class");
        return false;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (!_inited)
        {
            return;
        }

        if (_isRunning)
        {
            _currentDelay -= eventData["TimeStep"].GetFloat();

            if (_currentDelay <= 0.0)
            {
                _currentDelay = 0.0;
                _isRunning = false;
                ChangeVisible();
            }
        }
    }
}

}