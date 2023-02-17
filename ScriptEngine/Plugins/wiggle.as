#include "ScriptEngine/Plugins/BasePlugin.as"


class wiggle : BasePlugin
{
    String pluginName = "wiggle";

    Node@ original;
    float wiggleSpeed;
    float wiggleAmplitude;
    float wiggleRollSpeed;
    float timeZtep;
    bool isWiggled;
    String patchTag;
    ValueAnimation@ posAni = ValueAnimation();

    void WiggleThis(Node@ node, float delta, float duration)
    {
        Vector3 oldPos = node.position;
       
        if (delta > 0.0 && duration > 0.0) {
            posAni.SetKeyFrame(0.0, Variant(oldPos));
            posAni.SetKeyFrame(duration * 0.1, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.2, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.3, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.4, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.5, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.6, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.7, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.8, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration * 0.9, Variant(Vector3(oldPos.x + Random(delta * -0.5, delta * 0.5), oldPos.y + Random(delta * -0.5, delta * 0.5), oldPos.z)));
            posAni.SetKeyFrame(duration, Variant(oldPos));
            node.SetAttributeAnimation("Position", posAni, WM_LOOP);
        }
    }

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        LoadSettings(plugin_config);
        Scene@ scene = script.defaultScene;
        original = scene.GetChildrenWithTag(patchTag, true)[0];
        WiggleThis(original, wiggleAmplitude, wiggleSpeed);
        SubscribeToEvent("Update", "HandleUpdate");
        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName || plugin_config.Get("name").GetString() == pluginName)
        {
            if (plugin_config.Contains("tag"))
                patchTag = plugin_config.Get("tag").GetString();
            if (plugin_config.Contains("speed")) {
                wiggleSpeed = plugin_config.Get("speed").GetFloat();
                wiggleSpeed = SmoothStep(0.0, 1.0, wiggleSpeed);
                if (wiggleSpeed == 0.0) {wiggleSpeed = 0.0;} else {wiggleSpeed = 50.0 / (wiggleSpeed * 70.0);}
            }
            if (plugin_config.Contains("amplitude")) {wiggleAmplitude = plugin_config.Get("amplitude").GetFloat();}
            if (plugin_config.Contains("rotation")) {
                wiggleRollSpeed = plugin_config.Get("rotation").GetFloat();
                wiggleRollSpeed = Clamp(wiggleRollSpeed, -360.0, 360.0) * 3.0;
            }
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        original.Rotate(Quaternion(0.0, 0.0, timeStep * wiggleRollSpeed));
    }
}