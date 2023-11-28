#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Load.as"

namespace MaskEngine
{

class sub_mask : BaseEffectImpl
{
    Array<BaseEffect@> subEffects;
    String settingsFile    = "sub_mask.json";
    String resource_folder = "";
    String tag = "";

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        if (effect_desc.Get("dir").isString)
            resource_folder = effect_desc.Get("dir").GetString();

        if (effect_desc.Get("tag").isString)
            tag = effect_desc.Get("tag").GetString();

        if (!resource_folder.empty) {
            maskengine.AddResourceSubDir(resource_folder);
        }

        if (effect_desc.Get("settings").isString)
            settingsFile = effect_desc.Get("settings").GetString();

        // Load 'mask.json' file of sub mask.
        JSONFile maskJsonFile;
        if (!maskJsonFile.Load(cache.GetFile(settingsFile)))
        {
            log.Error("sub_mask: cannot load " + settingsFile);
            return false;
        }

        // Root object in JSON file
        JSONValue maskJson = maskJsonFile.GetRoot();
        JSONValue effects = maskJson.Get("effects");

        // If effects is not an array, 'mask.json' is invalid
        if (effects.isArray)
        {
            subEffects = LoadSubMaskEffects(effects);
        } else {
            log.Error("sub_mask: cannot find any effects");
        }

        if (!tag.empty) {
            for (uint i = 0; i < subEffects.length; i++)
            {
                Node@ effectNode = subEffects[i].GetNode(0);
                if (effectNode !is null)
                    effectNode.AddTag(tag);
            }
        }

        return true;
    }

    void Unload() override
    {
        BaseEffectImpl::Unload();

        if (!resource_folder.empty) {
            maskengine.RemoveResourceSubDir(resource_folder);
        }
    }

    String GetName() override
    {
        return "sub_mask";
    }
}

}