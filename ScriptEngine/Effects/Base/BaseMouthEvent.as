#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Effects/Base/BaseEvent.as"


namespace MaskEngine
{

class BaseMouthEvent : BaseEvent
{
    private Material@ _material;  // What for???

    // Init from code
    bool Init(BaseEffect@ parent) override
    {
        bool res = BaseEvent::Init(parent);

        if (@_ownerEffect !is null)
            SubscribeToEvent("MouthTrigger", "HandleMouthTrigger");

        return res && (_ownerEffect !is null);
    }

    // Called when mouth was opened or closed
    void HandleMouthTrigger(StringHash eventType, VariantMap& eventData)
    {
        if (NeedCall(eventData["Opened"].GetBool()))
            ApplyChildren();
    }

    bool NeedCall(bool bOpen)
    {
        log.Warning("Override this method in inherited class");
        return false;
    }
}

}
