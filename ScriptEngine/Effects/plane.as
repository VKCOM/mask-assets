#include "ScriptEngine/Effects/model3d.as"

namespace MaskEngine
{
    class plane : model3d
    {
        String _MODEL_PATH = "Models/DefaultPlane.mdl";

        bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
        {
            // Add default model to effect description
            JSONValue model_desc = effect_desc;
            model_desc.Erase("model");
            model_desc.Set("model", JSONValue(_MODEL_PATH));

            // Init base model3d
            return model3d::Init(model_desc, parent);
        }

        String GetName() override
        {
            return "plane";
        }
    }
}