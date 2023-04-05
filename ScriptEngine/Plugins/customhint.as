#include "ScriptEngine/Plugins/BasePlugin.as"
#include "ScriptEngine/Utils.as"


class customhint : BasePlugin
{
    String pluginName = "customhint";

    Node@ _node;
    bool tap = false;
    float transparent = 0.0f;
    float speed = 5.0f;
    float last_time = 0.0f;
    float delay = 0.4;
    float life_time = 3.0f;
    String trigger = "mouth";
    String hint_tag = "";
	Vector4 initColor;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {

        SetRandomSeed(time.systemTime + time.systemTime);

        // reset parameters to avoid false-start bug
        tap = false;
        transparent = 0.0f;
        speed = 5.0f;
        last_time = 0.0f;
        delay = 0.4;
        life_time = 3.0f;

        
        LoadSettings(plugin_config);

        last_time -= delay;

        _node = scene.GetChildrenWithTag(hint_tag, true)[0];
		BillboardSet@ bbs = _node.GetComponent("BillboardSet");
        Material@ materialPat = bbs.material;
		initColor = materialPat.shaderParameters["MatDiffColor"].GetVector4();

        TransparentPatch(_node, 0.0f);

        SubscribeToEvent("Update", "HandleUpdate");

        if (trigger == "mouth")
            SubscribeToEvent("MouthTrigger", "HandleMouthTrigger");
        else if (trigger.Contains("tap"))
            SubscribeToEvent("MouseEvent", "HandleMouseEvent");
        else if (HAND_GESTURE_NAMES.Fin(gesture) != -1)
            SubscribeToEvent("GestureEvent", "HandleGestureEvent");

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("tag"))
                hint_tag = plugin_config.Get("tag").GetString();

            if (plugin_config.Contains("delay"))
                delay = plugin_config.Get("delay").GetFloat();

            if (plugin_config.Contains("speed"))
                speed = plugin_config.Get("speed").GetFloat();

            if (plugin_config.Contains("life_time"))
                life_time = plugin_config.Get("life_time").GetFloat();

            if (plugin_config.Contains("trigger"))
                trigger = plugin_config.Get("trigger").GetString();
        }
    }

    void TransparentPatch(Node@ node, float t)
    {
        if (t < 0.0f) t = 0.0f;
        if (t > initColor.w) t = initColor.w;

        transparent = t;

        BillboardSet@ bbsPatch = node.GetComponent("BillboardSet");
        Material@ materialPatch = bbsPatch.material;
		
        materialPatch.shaderParameters["MatDiffColor"]  = Variant(Vector4(initColor.x, initColor.y, initColor.z, t));
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();

        last_time += timeStep;

        if (last_time >= 0.0f)
        {
            if (!tap && last_time < life_time)
                transparent += timeStep * speed;

            if (tap || last_time > life_time )
                transparent -= timeStep * speed;
        }

        TransparentPatch(_node, transparent);

        if (tap && transparent < 0.0f)
        {
            UnsubscribeFromEvent("MouseEvent");
            UnsubscribeFromEvent("Update");
        }
    }

    void HandleMouseEvent(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Event"].GetString() == "tap")
            tap = true;
    }

    void HandleMouthTrigger(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Opened"].GetBool())
            tap = true;
    }

    void HandleGestureEvent(StringHash eventType, VariantMap& eventData)
    {   
        if (trigger == eventData["Gesture"].GetString())
            tap = true;
    }
}
