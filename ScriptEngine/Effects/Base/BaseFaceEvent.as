#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseEvent.as"


namespace MaskEngine
{

class BaseFaceEvent : BaseEvent
{
    private bool prevFaceState = false;

    // Init from code
    bool Init(BaseEffect@ parent)
    {
        BaseEvent::Init(parent);

        if (_ownerEffect !is null)
            SubscribeToEvent("UpdateFaceDetected", "HandleFaceDetectedTrigger");

        return _ownerEffect !is null;
    }

    void Apply() override
    {
        for (uint i = 0; i < _children.length; i++)
            _children[i].Apply();
    }

    // Called for each frame
    void HandleFaceDetectedTrigger(StringHash eventType, VariantMap& eventData)
    {
        bool detected = eventData["Detected"].GetBool();
        if (detected != prevFaceState)
        {
            if (NeedCall(detected))
                Apply();
        }

        prevFaceState = detected;
    }

    bool NeedCall(bool bFound)
    {
        log.Warning("Override this method in inherited class");
        return false;
    }
}

}
