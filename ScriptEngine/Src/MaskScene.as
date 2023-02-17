/**
 * Mask scene class, a singleton
 *
 */

#include "ScriptEngine/Src/Triggers/MouthOpenTrigger.as"
#include "ScriptEngine/Effects/light.as"

namespace MaskEngine
{

MaskScene maskScene;

class MaskScene
{
    String userScript;
    ScriptFile@ _userScriptFile;

    MouthOpenTrigger@ mouthOpenTrigger;
    Mask@ _mask;

    ~MaskScene()
    {
        @_mask = null;
        log.Info("~MaskScene()");
    }

    void StartLoadMask()
    {
        SetGlobalVar(CURRENT_RP_IDX, Variant(0));
        SetGlobalVar(PREVIOUS_RP_IDX, Variant(-1));
        SetGlobalVar(MAIN_PASS_ADDED, Variant(false));
    }

    void LoadMaskFinished(Mask& in mask)
    {
        InitDefaultLight(mask);
        @_mask = mask;
    }

    void SetUserScript(const String& userScript_)
    {
        userScript = userScript_;
    }

    bool Run()
    {
        if (!userScript.empty)
        {
            _userScriptFile = cache.GetResource("ScriptFile", userScript);
            if (_userScriptFile is null)
            {
                log.Error("Failed to load script file " + userScript);
                return false;
            }
            cache.ReloadResource(_userScriptFile);

            _userScriptFile.Execute("void Init()");

            Array<Variant> parameters;
            Array<Variant> effects;
            for (uint i = 0; i < _mask.effects.length; i++)
               effects.Push(Variant(_mask.effects[i]));

            VariantMap param;
            param["effects"] = Variant(effects);
            parameters.Push(Variant(param));

            _userScriptFile.Execute("void InitWithEffects(VariantMap dataMap)", parameters);
        }

        RunMouthOpenEvent();

        return true;
    }

    void InitDefaultLight(Mask@ mask)
    {
        // if we have no light descs, use default
        bool has_custom_lights = false;

        for (uint i = 0; i < mask.effects.length; i++)
        {
            if (mask.effects[i].GetName() == "light")
            {
                has_custom_lights = true;
                break;
            }
        }

        Scene@ scene = script.defaultScene;
        if (!has_custom_lights && scene !is null)
        {
            Node@ lightNode = scene.CreateChild("Light");

            // The direction vector does not need to be normalized
            lightNode.direction = Vector3(0.0f, 0.0f, 1.0f);

            Light@ light = lightNode.CreateComponent("Light");
            light.lightType = LIGHT_DIRECTIONAL;
        }
    }

    void RunMouthOpenEvent()
    {
        if (HasAnyObjectSubscribedToEvent(E_MOUTH_TRIGGER))
        {
            // Start mouth open trigger
            @mouthOpenTrigger = MouthOpenTrigger();
        }
    }
}

}