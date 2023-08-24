#include "ScriptEngine/Effects/Base/BaseEvent.as"


namespace MaskEngine
{

class BaseGestureEvent : BaseEvent
{
    private const String name;

    // Init from code
    bool Init(BaseEffect@ parent) override
    {
        bool res = BaseEvent::Init(parent);

        if (@_ownerEffect !is null)
            SubscribeToEvent("GestureEvent", "HandleGestureEvent");

        return res && (_ownerEffect !is null);
    }

    void HandleGestureEvent(StringHash eventType, VariantMap& eventData)
    {
        const String gesture = eventData["Gesture"].GetsString().ToUpper();
        
        if (gesture == "OTHER" || gesture == "UNDEFINED_GESTURE")
            return;

        if (name == gesture)
            ApplyChildren();
    }

    String GetName() override
    {
        return "gesture_" + name.ToLower();
    }
}

}
