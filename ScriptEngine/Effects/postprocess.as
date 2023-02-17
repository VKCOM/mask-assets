#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class postprocess : BaseEffectImpl
{
    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        if (effect_desc.Get("pass").GetString().empty)
        {
            log.Error("postprocess: Pass file not specified");
        }

        if (!InitRenderPass(effect_desc.Get("pass"), effect_desc.Get("pass").GetString()))
        {
            return false;
        }

        Array<String> reservedField;
        _inited = LoadAddons(effect_desc, reservedField);

        return true;
    }

    String GetName() override
    {
        return "postprocess";
    }
}

}