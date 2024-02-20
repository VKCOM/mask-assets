#include "ScriptEngine/Plugins/BasePlugin.as"
#include "ScriptEngine/Utils.as"


class maskswitching : BasePlugin
{   
    String pluginName = "maskswitching";

    Array<String> maskTags;
    uint current_mask = 0;
    bool random = false;
    String trigger = "directional_tap";
    bool faceLost = true;

    bool faceSensitive = true;
    bool usingFrontCamera = true;
    String targetCamera = "all";

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        // Use it to retrieve effects from mask
        // if (mask is null)
        // {
        //     log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
        //     return false;
        // }

        LoadSettings(plugin_config);

        // At least one set of tags should have elements
        if (maskTags.length == 0)
        {
            Print("Error: 'tags' length is zero.");
            return false;
        }

        SetRandomSeed(time.systemTime);
        if (random)
            current_mask = maskTags.length == 0 ? 0 : RandomInt(0, 98) % maskTags.length;

        if (trigger == "mouth") SubscribeToEvent("MouthTrigger", "HandleMouthTrigger");
        else if (trigger == "tap") SubscribeToEvent("MouseEvent", "HandleTapEvent");
        else if (trigger == "directional_tap") SubscribeToEvent("MouseEvent", "HandleDirectionalTapEvent");
        else if (MaskEngine::HAND_GESTURE_NAMES.Find(trigger) != -1) SubscribeToEvent("GestureEvent", "HandleGestureEvent");

        SubscribeToEvent("PostUpdate", "HandlePostUpdate");
        SubscribeToEvent("UpdateFaceDetected", "HandleUpdateFaceDetected");
        SubscribeToEvent("SrcFrameUpdate", "HandleSrcFrameUpdate");

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            // Random
            if (plugin_config.Contains("random"))
                random = plugin_config.Get("random").GetBool();

            // Trigger
            if (plugin_config.Contains("trigger"))
                trigger = plugin_config.Get("trigger").GetString();

            // Camera
            if (plugin_config.Contains("camera"))
                targetCamera = plugin_config.Get("camera").GetString();

            // Visible
            if (plugin_config.Contains("visible"))
                if (plugin_config.Get("visible").GetString() == "face")
                    faceSensitive = true;
                else if (plugin_config.Get("visible").GetString() == "always")
                    faceSensitive = false;

            // Initial
            if (plugin_config.Contains("initial"))
                current_mask = plugin_config.Get("initial").GetInt() > 0 ? plugin_config.Get("initial").GetInt() - 1 : 0;

            // Tags
            if (plugin_config.Contains("tags"))
            {
                JSONValue tags = plugin_config.Get("tags");
                if (tags.isArray)
                    for (uint i = 0; i < tags.size; i++)
                        maskTags.Push(tags[i].GetString());
            }
        }
    }

    void switchMask(int increment)
    {
        /*  Selects the next or previuos mask depending on the 'increment'
            at the current camera scene. Other camera scene's mask is not affected.
        */

        if (usingFrontCamera && targetCamera == "back")
            return;

        if (!usingFrontCamera && targetCamera == "front")
            return;

        current_mask = increment >= 0 ? current_mask + increment : current_mask == 0 ? maskTags.length - 1 : current_mask - 1;
    }

    void disableAllMasks(Array<String>& tags)
    {
        /*  For each tag of the plugin, finds all nodes in the current camera scene 
            and sets their 'enabled' property to false.
        */

        for (uint i = 0; i < tags.length; i++)
        {
            Array<Node@> nodes = scene.GetChildrenWithTag(tags[i], true);
            for (uint j = 0; j < nodes.length; j++)
                nodes[j].enabled = false;
        }
    }

    void disableAllMasksExcept(uint current, Array<String>& tags, bool faceTrackingSensitive)
    {
        /*  For each tag of the plugin, finds all nodes in the current camera scene 
            and sets their 'enabled' property to false, except the nodes that 
            belong to the tag with index 'current'.
            If 'faceLost' is true when 'faceTrackingSensitive' is true, 
            'current' mask is also disabled.
        */

        for (uint i = 0; i < tags.length; i++)
        {
            Array<Node@> nodes = scene.GetChildrenWithTag(tags[i], true);
            if (i == current % tags.length && !(faceLost && faceTrackingSensitive))
            {
                for (uint j = 0; j < nodes.length; j++)
                    nodes[j].enabled = true;
            }
            else
            {
                for (uint j = 0; j < nodes.length; j++)
                    nodes[j].enabled = false;
            }
        }
    }

    void HandleTapEvent(StringHash eventType, VariantMap& eventData)
    {
        /*  Switches the mask of the current camera scene forward.
        */

        if (eventData["Event"].GetString() == "tap")
            switchMask(1);
    }

    void HandleDirectionalTapEvent(StringHash eventType, VariantMap& eventData)
    {
        /*  Switches the mask of the current camera scene forward or backward
            depending on the tap position on the screen.
        */

        if (eventData["Event"].GetString() == "tap")
        {
            Vector2 position = eventData["Position"].GetVector2();
            if (position.x > 0.5f)
                switchMask(1);
            else
                switchMask(-1);
        }
    }

    void HandleMouthTrigger(StringHash eventType, VariantMap& eventData)
    {
        /*  Switches the mask of the current camera scene forward.
        */

        if (eventData["Opened"].GetBool())
            switchMask(1);
    }

    void HandleGestureEvent(StringHash eventType, VariantMap& eventData)
    {   
        VariantMap gestureMap = eventData["GestureFigures"]
            .GetVariantVector()[0]
            .GetVariantMap();
        if (trigger == gestureMap["Gesture"].GetString())
            switchMask(1);
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        /*  Disables all the masks on both camera scenes except the current mask
            on the current camera scenes.
        */

        if (usingFrontCamera && targetCamera == "back")
        {
            disableAllMasks(maskTags);
            return;
        }

        if (!usingFrontCamera && targetCamera == "front")
        {
            disableAllMasks(maskTags);
            return;
        }

        disableAllMasksExcept(current_mask, maskTags, faceSensitive);
    }

    void HandleUpdateFaceDetected(StringHash eventType, VariantMap& eventData)
    {
        faceLost = !eventData["Detected"].GetBool();
    }

    void HandleSrcFrameUpdate(StringHash eventType, VariantMap& eventData)
    {
        usingFrontCamera = eventData["IsFrontCamera"].GetBool();
    }
}
