#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class mirror_texture : BaseEffectImpl
{
    private bool _should_mirror_current_frame = false;

    // Init from code.
    bool Init(BaseEffect@ parent)
    {
        BaseEffectImpl::Init(parent);

        SubscribeToEvent("SrcFrameUpdate", "HandleUpdate");

        return _ownerEffect !is null;
    }

    // Init from xml.
    bool Init(const JSONValue& texture_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(texture_desc, parent))
        {
            return false;
        }

        SubscribeToEvent("SrcFrameUpdate", "HandleUpdate");

        return true;
    }

    // Apply effect to parent
    void Apply() override
    {
        if (_should_mirror_current_frame && _ownerEffect !is null)
        {
            if (_ownerEffect !is null)
            {
                Material@ material = _ownerEffect.GetMaterial();
                if (material !is null)
                {
                    int index = material.shaderParameterNames.Find("UOffset");
                    if (index >= 0)
                    {
                        Vector4 uOffset = material.shaderParameters["UOffset"].GetVector4();
                        material.shaderParameters["UOffset"] = Variant(Vector4(-uOffset.x, uOffset.y, uOffset.z, uOffset.x + uOffset.w));
                    }
                }
            }
        }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        _should_mirror_current_frame = (!eventData["IsFlipHorizontal"].empty) ? eventData["IsFlipHorizontal"].GetBool() :
                                       eventData["IsFrontCamera"].GetBool();
    }

    bool NeedCallInUpdate() override
    {
        return true;
    }

    String GetName() override
    {
        return "mirror_texture";
    }
}

}