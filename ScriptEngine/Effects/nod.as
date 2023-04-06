#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseAction.as"
#include "ScriptEngine/Effects/Base/BaseEvent.as"

namespace MaskEngine
{

class nod : BaseEvent
{
    float minValue = 0.0;
    float maxValue = 0.0;
    float timeForNod = 0.7; // half second
    bool nodStarted = false;
    float nodSpeed = 0.65;

    float deltaTime = 0.05;

    float startNodTime = 0.0;
    float currentTime = 0.0;

    float nodeDist = 0.12;
    float startEndMaxDelta = 0.15;

    bool skipFirstFrame = false;
    //bool isAnimationPlaying = false;
    bool moveDown = false;

    // Init from code.
    bool Init(BaseEffect@ parent) override
    {
        bool res = BaseEvent::Init(parent);

        if (@_ownerEffect !is null)
        {
            SubscribeToEvent("UpdateFaceLandmarks", "HandleFaceLandmarks");
            SubscribeToEvent("Update", "HandleUpdate");
        }

        return res && (_ownerEffect !is null);
    }


    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        deltaTime = Min(eventData["TimeStep"].GetFloat(), 0.05);
        currentTime += deltaTime;
    }

    void HandleFaceLandmarks(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Detected"].GetBool() && deltaTime > 0.0)
        {
            Vector3 rotation = eventData["PoseRotation"].GetVector3();
            if (!skipFirstFrame)
            {
                minValue = rotation.x;
                skipFirstFrame = true;
                return;
            }

            if (!nodStarted)
            {
                float moveSpeed = (rotation.x - minValue) / deltaTime;
                minValue = rotation.x;
                // Detect start nod.
                if (Abs(moveSpeed) > nodSpeed /*&& !isAnimationPlaying*/)
                {
                    moveDown = moveSpeed > 0.0;
                    nodStarted = true;
                    startNodTime = currentTime;
                    maxValue = moveDown ? -1E6 : 1E6;
                }
            }
            else if (moveDown)
            {
                maxValue = Max(maxValue, rotation.x);

                if (maxValue - minValue > nodeDist &&  Abs(rotation.x - minValue) < startEndMaxDelta)
                {
                    // Nod happens
                    ApplyChildren();
                    nodStarted = false;
                }

                if (currentTime - startNodTime > timeForNod)
                {
                    nodStarted = false;
                }
            }
            else if (!moveDown)
            {
                maxValue = Min(maxValue, rotation.x);

                if (minValue - maxValue > nodeDist &&  Abs(rotation.x - minValue) < startEndMaxDelta)
                {
                    // Nod happens
                    ApplyChildren();
                    nodStarted = false;
                }

                if (currentTime - startNodTime > timeForNod)
                {
                    nodStarted = false;
                }
            }

            minValue = rotation.x;
        }
    }

    String GetName() override
    {
        return "nod";
    }
}

}