/**
 * Mask class
 *
 */

namespace MaskEngine
{

const String E_MOUTH_TRIGGER = "MouthTrigger";
const String P_NFACE  = "NFace";
const String P_OPENED = "Opened";

class MouthOpenTrigger
{
    Scene@ scene;
    Array<VariantMap> poiData;
    Array<bool> mouthOpen;

    MouthOpenTrigger()
    {
        poiData.Resize(MAX_FACES);
        mouthOpen.Resize(MAX_FACES);
        for (uint i = 0; i < mouthOpen.length; i++)
        {
            mouthOpen[i] = false;
        }

        scene = script.defaultScene;

        SubscribeToEvent("UpdateFacePOI", "UpdateFacePOIHandler");
        SubscribeToEvent("UpdateFaceLandmarks", "CheckMouthOpen");
    }

    void UpdateFacePOIHandler(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Detected"].GetBool())
        {
            uint faceIndex = eventData["NFace"].GetUInt();
            poiData[faceIndex] = eventData["PoiMap"].GetVariantMap();
        }
    }

    void CheckMouthOpen(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Detected"].GetBool())
        {
            uint faceIndex = eventData["NFace"].GetUInt();
            VariantMap poiMap = poiData[faceIndex];
            if (poiMap.Contains("upper_lip") && poiMap.Contains("lower_lip")
                && poiMap.Contains("nose"))
            {
                Vector3 upperLip = poiMap["upper_lip"].GetVector3();
                Vector3 lowerLip = poiMap["lower_lip"].GetVector3();
                Vector3 nose = poiMap["nose"].GetVector3();

                float normValue = Abs(nose.y - upperLip.y);
                float disnatceLips = Abs(upperLip.y - lowerLip.y);

                bool isOpen = (disnatceLips > normValue / 2.5f) && eventData["rawConfidence"].GetFloat() > 0.75 &&
                    Abs(eventData["PoseRotation"].GetVector3().x) < 0.35;

                if (mouthOpen[faceIndex] != isOpen)
                {
                    VariantMap eventDataMO;
                    eventDataMO[P_NFACE]  = faceIndex;
                    eventDataMO[P_OPENED] = isOpen;
                    ::SendEvent(E_MOUTH_TRIGGER, eventDataMO);
                }
                mouthOpen[faceIndex] = isOpen;
            }
        }
    }
}

}