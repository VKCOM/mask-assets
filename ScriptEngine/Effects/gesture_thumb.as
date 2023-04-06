#include "ScriptEngine/Effects/Base/BaseGestureEvent.as"


namespace MaskEngine
{

class gesture_thumb : BaseGestureEvent
{
    private const String name = "THUMB";

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
