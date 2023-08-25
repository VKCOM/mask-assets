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
        VariantMap gestureMap = eventData["GestureFigures"]
            .GetVariantVector()[0]
            .GetVariantMap();
        String gesture = gestureMap["Gesture"].GetsString().ToUpper();
        
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
