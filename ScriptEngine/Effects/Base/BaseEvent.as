#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseEffect.as"


namespace MaskEngine
{

class BaseEvent : BaseEffectImpl
{
    // Initialise with JSONValue with some BaseAction
    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
            return false;

        if (effect_desc.isString)
        {
            String actionName = effect_desc.GetString();
            BaseEffect@ action = AddChildEffect(actionName);

            // Adopt action to creator parent, not to event!
            // But action is also among `_childern` of event...
            if (!action.Init(parent))
            {
                log.Error("BaseEvent: Cannot init " + actionName  + " for patch");
                return false;
            }

            // mouthOpen.AddAction(showAction);
        }
        else if (effect_desc.isObject)
        {
            String actionName = effect_desc.Get("name").GetString();
            if (!actionName.empty)
            {
                BaseEffect@ action = AddChildEffect(actionName);
                if (!action.Init(effect_desc, parent))
                {
                    log.Error("BaseEvent: Cannot init " + actionName + " for patch");
                    return false;
                }
            }
            else
            {
                log.Error("BaseEvent: action name is empty");
                return false;
            }
        }

        // Adopt this event to a creator parent
        return Init(parent);
    }
}

}
