#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class colorfilter : BaseEffectImpl
{
    private BaseEffect@ _colorPatchEffect;
    // private 

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        float intensity = effect_desc.Get("intensity").isNumber ? effect_desc.Get("intensity").GetFloat() : 1.0; 
        String lookup = "ColorFilter/lookup.png";
        if (effect_desc.Get("lookup").isString) {
            lookup = effect_desc.Get("lookup").GetString();
        }
        else {
            log.Info("colorfilter : lookup not specified, using default \"" + lookup +  "\"" );
        }

        String patchConfigString = " {  \"name\" : \"patch\" , \"anchor\" : \"fullscreen\", \"visible\" : \"always\", \"texture\" : { \"color\" : [0.0, 0.0, 0.0, " + intensity + "], \"texture\" :  \""  +  lookup + "\", \"shader\" : \"ColorFilter\", \"ps_shader_defs\" : \"INTENSITY_VALUE\" } } ";

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