#include "ScriptEngine/Effects/Base/BaseGestureEvent.as"


namespace MaskEngine
{

class gesture_cross : BaseGestureEvent
{
    private const String name = "CROSS";

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