#include "ScriptEngine/Plugins/BasePlugin.as"


class animatedrotation : BasePlugin
{
    String pluginName = "animatedrotation";

    String __effect_tag = "";
    float __speed = 1.0;

    Node@ m_faceNode;
    Node@ m_cylinderNode;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        LoadSettings(plugin_config);

        if (__effect_tag.empty)
        {
            log.Error(pluginName + ": 'tag' must have a string value");
            return false;
        }

        Array<Node@> nodes = scene.GetChildrenWithTag(__effect_tag, true);
        if (nodes.empty)
        {
            log.Error(pluginName + ": unable to find at least one node with tag '" + __effect_tag + "'");
            return false;
        }
        m_cylinderNode = nodes[0];

        float direction = -Sign(__speed);

        ValueAnimation@ rotation = ValueAnimation();
        rotation.SetKeyFrame(0.0, Variant(QuatY(0.0)));
        rotation.SetKeyFrame(0.5, Variant(QuatY(180.0 * direction)));
        rotation.SetKeyFrame(1.0, Variant(QuatY(360.0 * direction)));
        m_cylinderNode.SetAttributeAnimation("Rotation", rotation, WM_LOOP, 0.05 * Abs(__speed));

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("tag"))
                __effect_tag = plugin_config.Get("tag").GetString();

            if (plugin_config.Contains("speed"))
                __speed = plugin_config.Get("speed").GetFloat();
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        m_faceNode = scene.GetChild("Face");
        if (m_faceNode is null) {
            return;
        }
        m_faceNode.rotation = QuatZero();
    }

    Quaternion QuatZero()
    {
        Quaternion q = Quaternion();
        q.FromEulerAngles(0.0, 0.0, 0.0);
        return q;
    }

    Quaternion QuatY(float angle)
    {
        Quaternion q = Quaternion();
        q.FromEulerAngles(0.0, angle, 0.0);
        return q;
    }
}
