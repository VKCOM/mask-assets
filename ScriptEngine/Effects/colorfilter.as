#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Utils.as"


namespace MaskEngine
{

class colorfilter : BaseEffectImpl
{
    private BaseEffect@ _colorPatchEffect;

    private String texturePath = "ColorFilter/lookup.png";
    private String patchConfigString = "";


    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        ReadConfiguration(effect_desc);

        if (!cache.Exists(texturePath))
        {
            log.Error("colorfilter: Texture file does not exist");
            return false;
        }

        @_colorPatchEffect = AddChildEffect("patch");
        if (_colorPatchEffect !is null)
        {
            JSONFile@ jsonFile = JSONFile();
            jsonFile.FromString(patchConfigString);

            if (!_colorPatchEffect.Init(jsonFile.GetRoot(), parent))
            {
                log.Error("colorfilter: Cannot init patch");
                return false;
            }
        }

        AddTags(effect_desc, _colorPatchEffect.GetNode());
        
        _inited = true;
        return _inited;
    }

    private void ReadConfiguration(const JSONValue& effect_desc)
    {
        patchConfigString     += "{\n  \"name\": \"patch\"";

        if (effect_desc.Contains("tag") && effect_desc.Get("tag").isString)
            patchConfigString += ",\n  \"tag\": \"" + effect_desc.Get("tag").GetString() + "\"";

        if (effect_desc.Contains("anchor") && effect_desc.Get("anchor").isString)
            patchConfigString += ",\n  \"anchor\": \"" + effect_desc.Get("anchor").GetString() + "\"";
        else
            patchConfigString += ",\n  \"anchor\": \"fullscreen\"";

        patchConfigString     += ",\n  \"texture\": {";

        if (effect_desc.Contains("lookup") && effect_desc.Get("lookup").isString)
        {
            texturePath = effect_desc.Get("lookup").GetString();
            patchConfigString += "\n    \"texture\": \"" + texturePath + "\"";
        }
        else
        {
            log.Info("colorfilter: lookup not specified, using default \"" + texturePath +  "\"");
            patchConfigString += "\n    \"texture\": \"" + texturePath + "\"";
        }

        if (effect_desc.Contains("intensity") && effect_desc.Get("intensity").isNumber)
            patchConfigString += ",\n    \"color\": [0.0, 0.0, 0.0, " + effect_desc.Get("intensity").GetFloat() + "]";
        else
            patchConfigString += ",\n    \"color\": [0.0, 0.0, 0.0, " + 1.0 + "]";

        patchConfigString     += ",\n    \"shader\": \"ColorFilter\""
                              +  ",\n    \"ps_shader_defs\": \"INTENSITY_VALUE\""
                              +  "\n  }";

        if (effect_desc.Contains("allow_rotation") && effect_desc.Get("allow_rotation").isBool)
            patchConfigString += ",\n  \"allow_rotation\": " + effect_desc.Get("allow_rotation").GetBool();

        if (effect_desc.Contains("visible") && effect_desc.Get("visible").isString)
            patchConfigString += ",\n  \"visible\": \"" + effect_desc.Get("visible").GetString() + "\"";

        if (effect_desc.Contains("show_delay") && effect_desc.Get("show_delay").isNumber)
            patchConfigString += ",\n  \"show_delay\": " + effect_desc.Get("show_delay").GetFloat();

        if (effect_desc.Contains("hide_delay") && effect_desc.Get("hide_delay").isNumber)
            patchConfigString += ",\n  \"hide_delay\": " + effect_desc.Get("hide_delay").GetFloat();

        if (effect_desc.Contains("fit") && effect_desc.Get("fit").isString)
            patchConfigString += ",\n  \"fit\": \"" + effect_desc.Get("fit").GetString() + "\"";

        if (effect_desc.Contains("size") && effect_desc.Get("size").isArray)
        {
            Vector2 size;
            ReadVector2(effect_desc.Get("size"), size);
            patchConfigString += ",\n  \"size\": [" + size.x + ", " + size.y + "]";
        }

        if (effect_desc.Contains("offset") && effect_desc.Get("offset").isArray)
        {
            Vector3 offset;
            ReadVector3(effect_desc.Get("offset"), offset);
            patchConfigString += ",\n  \"offset\": [" + offset.x + ", " + offset.y + ", " + offset.z + "]";
        }

        if (effect_desc.Contains("rotation") && effect_desc.Get("rotation").isArray)
        {
            Vector3 rotation;
            ReadVector3(effect_desc.Get("rotation"), rotation);
            patchConfigString += ",\n  \"rotation\": [" + rotation.x + ", " + rotation.y + ", " + rotation.z + "]";
        }

        patchConfigString     += "\n}";
    }

    void _SetVisible(bool visible) override
    {
        _colorPatchEffect.SetVisible(visible);
    }

    String GetName() override
    {
        return "colorfilter";
    }
}

}
