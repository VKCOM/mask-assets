#include "ScriptEngine/Plugins/BasePlugin.as"


class template : BasePlugin
{
    String pluginName = "template";

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        // Используйте объект `mask` для получения эффектов текущей маски.
        // if (mask is null)
        // {
        //     log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
        //     return false;
        // }

        LoadSettings(plugin_config);

        // Ваш код для инициализации. Возвращайте false в критических для инициализации плагина случаях.
        // ...

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            // Прочтение настроек плагина.
            // ...

            // if (pluginRoot.Contains("ИМЯ ПАРАМЕТРА"))
            //     ПЕРЕМЕННАЯ = pluginRoot.Get("ИМЯ ПАРАМЕТРА").GetString();
        }
    }
}
