#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Effects/Base/BaseEvent.as"


namespace MaskEngine
{

class tap : BaseEvent
{
    bool Init(BaseEffect@ parent) override
    {
        bool res = BaseEvent::Init(parent);

        if (@_ownerEffect !is null)
            SubscribeToEvent("MouseEvent", "HandleMouseEvent");

        return res && (_ownerEffect !is null);
    }

    void HandleMouseEvent(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Event"].GetString() == "tap")
            ApplyChildren();
    }

    String GetName() override
    {
        return "tap";
    }
}

}
