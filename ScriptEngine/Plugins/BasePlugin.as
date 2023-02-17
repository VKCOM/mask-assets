// Import this file to provide acces to 'mask' for all plugins
#include "ScriptEngine/Src/Mask.as"


shared interface BasePlugin : ScriptObject
{
    // Initialise with plugin configuration as JSON Value, 
    // and a mask handler to get access to loaded effects
    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask);

    // Load plugin settings from JSON Value passed from 'mask.json'
    void LoadSettings(const JSONValue& plugin_config);
}


BasePlugin@ CreatePlugin(const String& name)
{
    if (name.empty || name.StartsWith("-") || name.Contains("..") || name.Contains("/") || name.Contains("~"))
        return null;

    log.Info("CreatePlugin: Creating \'" + name + "\'' plugin");

    // User plugin is prioritized over standart plugin, so:
    //  - first, try to create a plugin from one of the user plugin files,
    //    (do not convert `name` to lowercase here, bc user may have named it with capital letters)
    String pluginPath = "Plugins/" + name + ".as";
    if (cache.Exists(pluginPath))
    {
        ScriptObject@ userPlugin = scene.CreateScriptObject(pluginPath, /* "MaskEngine::" + */ name);
        // ScriptObject@ userPlugin = scene.CreateScriptObject(pluginPath, "MaskEngine::" + name + "Plugin");
        if (userPlugin !is null)
            return cast<BasePlugin>(userPlugin);
    }

    //  - for compatibility with older plugins, may be removed later
    //    (if the file ends with '..Plugin.as', but in 'mask.json' the declaration is without  '..Plugin')
    String compatibilityPath = "Plugins/" + name + "Plugin.as";
    if (cache.Exists(compatibilityPath))
    {
        ScriptObject@ userPlugin = scene.CreateScriptObject(compatibilityPath, /* "MaskEngine::" + */ name);
        // ScriptObject@ userPlugin = scene.CreateScriptObject(pluginPath, "MaskEngine::" + name + "Plugin");
        if (userPlugin !is null)
            return cast<BasePlugin>(userPlugin);
    }

    //  - then, try to create a plugin with the same name from one of the standart plugin files
    //    convert `name` to lowercase here
    String lowerName = name.ToLower();
    pluginPath = "ScriptEngine/Plugins/" + lowerName + ".as";
    if (cache.Exists(pluginPath))
    {
        ScriptObject@ standartPlugin = scene.CreateScriptObject(pluginPath, /* "MaskEngine::" + */ lowerName);
        // ScriptObject@ standartPlugin = scene.CreateScriptObject(pluginPath, "MaskEngine::" + name + "Plugin");
        if (standartPlugin !is null)
            return cast<BasePlugin>(standartPlugin);
    }
    
    //  - and log an error if none of the plugins were created
    log.Error("CreatePlugin: Cannot create object '" + name + "'");
    return null;
}
