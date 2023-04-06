#include "ScriptEngine/Effects/Base/BaseGestureEvent.as"


namespace MaskEngine
{

class gesture_not_hand : BaseGestureEvent
{
    private const String name = "NOT_HAND";

    bool NeedCall(const String& gestureName) override
    {
        return name == gestureName;
    }

    String GetName() override
    {
        return "gesture_" + name.ToLower();
    }
}

}
