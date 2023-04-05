/**
 * Load mask
 *
 * This is the starting point of loading the user resources from
 * the mask folder.  The `LoadMask` method is called from C++ engine.
 */

#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Plugins/BasePlugin.as"
#include "ScriptEngine/Plugins/mirror.as"

#include "ScriptEngine/Src/Mask.as"
#include "ScriptEngine/Src/MaskScene.as"

#include "ScriptEngine/HotReload.as"

namespace MaskEngine
{

    /**
     * Call to this function "turns on" the ScriptEngine.
     * `filepath` is the path to 'mask.json' file, and is passed from
     * C++ engine.
     */
    void LoadMask(String filepath)
    {
        log.Info("Loading mask: " + filepath);

        AUTO_INCRIMENT_EFFECT_ID = 0;
        // PrintDebugInfoRP();

        Loader loader(filepath);
        loader.Load(mask);

        if (mask is null)
        {
            maskengine.LoadFailed();
            return;
        }

        if (!maskScene.Run())
        {
            maskengine.LoadFailed();
            return;
        }

        // injectStart
        hotReloader.Attach();
        // injectEnd
    }

    void UnloadMask()
    {
        log.Info("Unload mask");
        if (mask !is null)
        {
            mask.Unload();
            @mask = null;
        }
    }

    class Loader
    {
        // Path to user 'mask.json'
    private
        String _filepath;

        // Path to folder with engine effects
    private
        String effectsDir = "ScriptEngine/Effects/";

        Loader(String filepath)
        {
            _filepath = filepath;
        }

        void Load(Mask @mask)
        {
            // Load 'mask.json' file
            JSONFile maskJsonFile;
            if (!maskJsonFile.Load(cache.GetFile(_filepath)))
            {
                log.Error("Loader: cannot load " + _filepath);
                return;
            }

            // Root object in JSON file
            JSONValue maskJson = maskJsonFile.GetRoot();

            // Trying to fix front camera mirror issue
            AddMirrorCameraPlugin(maskJson);

            // All effects are added to the mask after this call
            LoadEffects(maskJson, mask);

            // Safe to load plugins now
            LoadPlugins(maskJson, mask);

            if (mask is null)
            {
                log.Error("Loader : Could not initialize mask!");
                return;
            }

            maskScene.LoadMaskFinished(mask);

            // Run user script
            String scriptFileName = maskJson.Get("script").GetString();
            maskScene.SetUserScript(scriptFileName);
        }

        // Load effects of mask
        void LoadEffects(JSONValue maskJson, Mask @mask)
        {
            JSONValue effects = maskJson.Get("effects");

            // If effects is not an array, 'mask.json' is invalid
            if (effects.isArray)
            {
                Scene @scene = script.defaultScene; // What for?

                maskScene.StartLoadMask();

                for (uint i = 0; i < effects.size; i++)
                {
                    JSONValue effect = effects[i];
                    String name = effect.Get("name").GetString();

                    // Todo security paches
                    if (!effect.Get("disabled").GetBool())
                    {
                        bool wasSkip = false;

                        BaseEffect @baseEffect = CreateEffect(name, wasSkip);
                        if (baseEffect !is null)
                        {
                            baseEffect.Init(effect, null);
                            mask.AddEffect(baseEffect);
                        }
                        // If it should not be skipped and couldn't be loaded
                        else if (!wasSkip)
                        {
                            log.Error("Loader: Cannot create " + name);
                            return;
                        }
                    }
                    else
                    {
                        log.Info("Loader: Skip effect " + name);
                    }
                }
            }
        }

        // Load plugins of mask
        void LoadPlugins(JSONValue maskJson, Mask @mask)
        {
            if (!maskJson.Contains("plugins"))
                return;

            JSONValue plugins = maskJson.Get("plugins");
            if (plugins.isArray)
            {

                for (uint i = 0; i < plugins.size; i++)
                {
                    JSONValue pluginConfig = plugins[i];

                    if (!pluginConfig.Contains("name"))
                        continue;

                    String pluginName = pluginConfig.Get("name").GetString();
                    BasePlugin @basePlugin = CreatePlugin(pluginName);

                    if (basePlugin is null)
                    {
                        log.Error("Loader : unable to create plugin " + pluginName);
                        continue;
                    }

                    basePlugin.Init(pluginConfig, mask);
                    mask.AddPlugin(basePlugin);
                }
            }
        }

        void FixYUV()
        {
            // change shader program for input video stream
            String platform = GetPlatform();
            bool runOnDesktop = (platform == "Windows" || platform == "Mac OS X");

            RenderPath @defaultRP = renderer.viewports[0].renderPath;

            String yuvShaderName = runOnDesktop ? "Yuv2Rgb" : "CopyFramebuffer";
            for (uint index = 0; index < defaultRP.numCommands; index++)
            {
                RenderPathCommand command = defaultRP.commands[index];

                if (command.tag == "Yuv2Rgb")
                {
                    command.pixelShaderName = yuvShaderName;
                    command.vertexShaderName = yuvShaderName;

                    defaultRP.RemoveCommand(index);
                    defaultRP.InsertCommand(index, command);
                }
            }
        }

        void AddMirrorCameraPlugin(JSONValue &maskJson)
        {
            // check if used auto_mirror
            JSONValue effects = maskJson.Get("effects");
            if (effects.isArray)
            {
                for (uint i = 0; i < effects.size; i++)
                {
                    JSONValue effect = effects[i];
                    String effectName = effect.Get("name").GetString();
                    if (effectName == "patch")
                    {
                        JSONValue texture = effect.Get("texture");
                        if (!texture.isObject)
                            continue;
                        if (texture.Contains("auto_mirror"))
                            return;
                    }
                }
            }

            // check if mirror added manually
            JSONValue plugins = maskJson.Get("plugins");
            if (plugins.isArray)
            {
                for (uint i = 0; i < plugins.size; i++)
                {
                    String pluginName = plugins[i].Get("name").GetString();
                    if (pluginName == "mirror")
                        return;
                }
            }

            JSONValue mirrorJSON = JSONValue();
            mirrorJSON.Set("name", JSONValue("mirror"));
            plugins.Push(mirrorJSON);
            maskJson.Set("plugins", plugins);

            log.Info("Loader : auto added mirror plugin");
        }
    }

}
