#include "ScriptEngine/Effects/Base/BaseEffect.as"

String START_AR_RENDER_PASS_FILE = "RenderPaths/start_ar.xml";
String FINISH_AR_RENDER_PASS_FILE = "RenderPaths/finish_ar.xml";

namespace MaskEngine
{

class BaseAr : BaseEffectImpl
{
    bool isShowOnFront = true;
    bool isShowOnBack  = true;

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        if (effect_desc.Get("camera").isString) {
            String camerasType = effect_desc.Get("camera").GetString();
            if (camerasType == "front") {
                isShowOnFront = true;
                isShowOnBack  = false;
            } else if (camerasType == "back") {
                isShowOnFront = false;
                isShowOnBack  = true;
            }
        }

        Node@ nodeAr3D = scene.GetChild("ar_3d");
        if (nodeAr3D is null)
        {
            scene.CreateChild("ar_3d");
        }
        
        Node@ nodeArBackground = scene.GetChild("ar_background");
        if (nodeArBackground is null)
        {
            scene.CreateChild("ar_background");
        }
        
        JSONValue jEffects = effect_desc.Get("effects");

        if (jEffects.isArray)
        {
            if (!AddStartRenderARCommands())
            {
                return false;
            }

            for (uint effIdx = 0; effIdx < jEffects.size; effIdx++)
            {
                JSONValue desc = jEffects[effIdx];
                if (desc.Get("disabled").GetBool() || desc.Get("name").isNull)
                    continue;

                BaseEffect@ effect = AddChildEffect(desc.Get("name").GetString());

                if (effect is null)
                {
                    log.Error("ar_background: cannot create " + desc.Get("name").GetString());
                    AddFinishRenderARCommands();
                    return false;
                }

                if (!effect.Init(desc, this))
                {
                    log.Error("ar_background: cannot init " + desc.Get("name").GetString());
                    return false;
                }
            }

            AddFinishRenderARCommands();

            Array<String> reservedField = { "effects"};
            _inited = LoadAddons(effect_desc, reservedField);

            SubscribeToEvent("Update", "HandleUpdate");

            return true;
        }
        else if (jEffects.isNull)
        {
            return true;
        }

        return false;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        //Print ("HandleUpdate");
        Init();
        UnsubscribeFromEvent("Update");
    }

    bool AddStartRenderARCommands()
    {
        return AddRenderPatchCommands(START_AR_RENDER_PASS_FILE);
    }

    bool AddFinishRenderARCommands()
    {
        return AddRenderPatchCommands(FINISH_AR_RENDER_PASS_FILE);
    }

    bool AddRenderPatchCommands(const String& fileName)
    {
        RenderPath@ defaultRP = renderer.defaultRenderPath;

        XMLFile@ orig_rp = cache.GetResource("XMLFile", fileName);
        if (orig_rp is null)
        {
            log.Error("ar_background: Failed to load RP file " + fileName);
            return false;
        }
        //Print ("Render " + fileName);
        return defaultRP.Append(orig_rp);
    }

    void SetVisible(bool visible) override
    {
        BaseEffectImpl::SetVisible(visible);

        for (uint i = 0; i < _children.length; i++)
        {
            _children[i].SetVisible(visible);
        }
    }

    void Init()
    {
    }
}

}