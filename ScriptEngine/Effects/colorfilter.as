#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Utils.as"


namespace MaskEngine
{

class colorfilter : BaseEffectImpl
{
    private BaseEffect@ _colorPatchEffect;

    private String texturePath = "ColorFilter/lookup.png";
    private JSONValue patchConfig;


    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        patchConfig = JSONValue();
        ReadConfiguration(effect_desc);

        if (!cache.Exists(texturePath))
        {
            log.Error("colorfilter: Texture file does not exist");
            return false;
        }

        @_colorPatchEffect = AddChildEffect("patch");
        if (_colorPatchEffect is null)
        {
            log.Error("colorfilter: patch effect is null");
            return false;
        }
        
        if (!_colorPatchEffect.Init(patchConfig, parent))
        {
            log.Error("colorfilter: Cannot init patch");
            return false;
        }

        AddTags(effect_desc, _colorPatchEffect.GetNode());
        
        _inited = true;
        return _inited;
    }

    private void ReadConfiguration(const JSONValue& effect_desc)
    {
        if (effect_desc.Contains("tag") && effect_desc.Get("tag").isString)
            patchConfig.Set("tag", effect_desc.Get("tag"));

        if (effect_desc.Contains("anchor") && effect_desc.Get("anchor").isString)
            patchConfig.Set("anchor", effect_desc.Get("anchor"));
        else
            patchConfig.Set("anchor", JSONValue("fullscreen"));

        JSONValue textureValue;
        if (effect_desc.Contains("lookup") && effect_desc.Get("lookup").isString)
            texturePath = effect_desc.Get("lookup").GetString();
        else
            log.Info("colorfilter: lookup not specified, using default \"" + texturePath +  "\"");
        textureValue.Set("texture", JSONValue(texturePath));
        JSONValue rgba; rgba.Push(JSONValue(0.0)); rgba.Push(JSONValue(0.0)); rgba.Push(JSONValue(0.0)); 
        if (effect_desc.Contains("intensity") && effect_desc.Get("intensity").isNumber)
            rgba.Push(effect_desc.Get("intensity"));
        else
            rgba.Push(JSONValue(0.75));
        textureValue.Set("color", rgba);
        textureValue.Set("shader", JSONValue("ColorFilter"));
        textureValue.Set("ps_shader_defs", JSONValue("INTENSITY_VALUE"));
        patchConfig.Set("texture", textureValue);

        if (effect_desc.Contains("allow_rotation") && effect_desc.Get("allow_rotation").isBool)
            patchConfig.Set("allow_rotation", effect_desc.Get("allow_rotation"));

        if (effect_desc.Contains("visible") && effect_desc.Get("visible").isString)
            patchConfig.Set("visible", effect_desc.Get("visible"));
        else
            patchConfig.Set("visible", JSONValue("always"));
            
        if (effect_desc.Contains("show_delay") && effect_desc.Get("show_delay").isNumber)
            patchConfig.Set("show_delay", effect_desc.Get("show_delay"));

        if (effect_desc.Contains("hide_delay") && effect_desc.Get("hide_delay").isNumber)
            patchConfig.Set("hide_delay", effect_desc.Get("hide_delay"));

        if (effect_desc.Contains("fit") && effect_desc.Get("fit").isString)
            patchConfig.Set("fit", effect_desc.Get("fit"));

        if (effect_desc.Contains("size") && effect_desc.Get("size").isArray)
            patchConfig.Set("size", effect_desc.Get("size"));

        if (effect_desc.Contains("offset") && effect_desc.Get("offset").isArray)
            patchConfig.Set("offset", effect_desc.Get("offset"));

        if (effect_desc.Contains("rotation") && effect_desc.Get("rotation").isArray)
            patchConfig.Set("rotation", effect_desc.Get("rotation"));
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
