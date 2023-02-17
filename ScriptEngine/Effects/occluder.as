#include "ScriptEngine/Effects/model3d.as"


namespace MaskEngine
{

class occluder : model3d
{
    String _MATERIAL_PATH = "Materials/InvisibleOccluder.xml";
    String _DEBUG_MATERIAL_PATH = "Materials/GreenTransparent.xml";

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        // Add default material to effect description
        JSONValue model_desc = effect_desc;
        model_desc.Erase("material");
        model_desc.Set("material", JSONValue(
            (effect_desc.Contains("debug") && effect_desc.Get("debug").GetBool())
                ? _DEBUG_MATERIAL_PATH
                : _MATERIAL_PATH
        ));

        // Init base model3d
        return model3d::Init(model_desc, parent);
    }

    String GetName() override
    {
        return "occluder";
    }
}

}
