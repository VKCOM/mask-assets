#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class ambientlight : BaseEffectImpl
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
            log.Error("ambientlight: light effect is null");
            return false;
        }

        if (!_lightEffect.Init(_lightConfig, parent))
        {
            log.Error("ambientlight: cannot init light");
            return false;
        }

        AddTags(effect_desc, _lightEffect.GetNode());

        return true;
    }

    private void ReadConfiguration(const JSONValue& effect_desc)
    {
        _lightConfig.Set("type", JSONValue("ambient"));

        if (effect_desc.Contains("color") && effect_desc.Get("color").isArray)
            _lightConfig.Set("color", effect_desc.Get("color"));

        if (effect_desc.Contains("tag") && effect_desc.Get("tag").isString)
            _lightConfig.Set("tag", effect_desc.Get("tag"));
    }

    void _SetVisible(bool visible) override
    {
        _lightEffect.SetVisible(visible);
    }

    String GetName() override
    {
        return "ambientlight";
    }
}

}
