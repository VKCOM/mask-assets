#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class pointlight : BaseEffectImpl
{
    private BaseEffect@ _lightEffect;
    private JSONValue _lightConfig;

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        _lightConfig = JSONValue();
        ReadConfiguration(effect_desc);

        @_lightEffect = AddChildEffect("light");
        if (_lightEffect is null)
        {
            log.Error("pointlight: light effect is null");
            return false;
        }

        if (!_lightEffect.Init(_lightConfig, parent))
        {
            log.Error("pointlight: cannot init light");
            return false;
        }

        AddTags(effect_desc, _lightEffect.GetNode());

        return true;
    }

    private void ReadConfiguration(const JSONValue& effect_desc)
    {
        _lightConfig.Set("type", JSONValue("point"));

        if (effect_desc.Contains("color") && effect_desc.Get("color").isArray)
            _lightConfig.Set("color", effect_desc.Get("color"));

        if (effect_desc.Contains("tag") && effect_desc.Get("tag").isString)
            _lightConfig.Set("tag", effect_desc.Get("tag"));

        if (effect_desc.Contains("anchor") && effect_desc.Get("anchor").isString)
            _lightConfig.Set("anchor", effect_desc.Get("anchor"));

        if (effect_desc.Contains("position") && effect_desc.Get("position").isArray)
            _lightConfig.Set("position", effect_desc.Get("position"));

        if (effect_desc.Contains("range") && effect_desc.Get("range").isNumber)
            _lightConfig.Set("range", effect_desc.Get("range"));

        if (effect_desc.Contains("brightness") && effect_desc.Get("brightness").isNumber)
            _lightConfig.Set("brightness", effect_desc.Get("brightness"));

        if (effect_desc.Contains("specular_intensity") && effect_desc.Get("specular_intensity").isNumber)
            _lightConfig.Set("specular_intensity", effect_desc.Get("specular_intensity"));
    }

    void _SetVisible(bool visible) override
    {
        _lightEffect.SetVisible(visible);
    }

    String GetName() override
    {
        return "pointlight";
    }
}

}
