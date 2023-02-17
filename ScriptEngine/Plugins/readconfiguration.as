#include "ScriptEngine/Plugins/BasePlugin.as"


class readconfiguration : BasePlugin
{
    String pluginName = "readconfiguration";

    bool vBool;
    double vDouble;
    float vFloat;
    int vInt;
    uint vUInt;
    String vString;
    
    float x;
    float y;
    float z;
    
    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        // Use it to retrieve effects from mask
        // if (mask is null)
        // {
        //     log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
        //     return false;
        // }

        vBool = false;
        vDouble = 0.0;
        vFloat = 1.0f;
        vInt = 0;
        vUInt = 1;
        vString = "Hello!";
        x = 1.0f;
        y = 2.0f;
        z = 3.0f;

        LoadSettings(plugin_config);

        log.Info("ReadConfigurationPlugin: vBool = " + vBool);
        log.Info("ReadConfigurationPlugin: vDouble = " + vDouble);
        log.Info("ReadConfigurationPlugin: vFloat = " + vFloat);
        log.Info("ReadConfigurationPlugin: vInt = " + vUInt);
        log.Info("ReadConfigurationPlugin: vUInt = " + vUInt);
        log.Info("ReadConfigurationPlugin: vString = " + vString);
        log.Info("ReadConfigurationPlugin: ArrayParameter = [" + x + ", " + y + ", " + z + "]");

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("BoolParameter"))
                vBool = plugin_config.Get("BoolParameter").GetBool();

            if (plugin_config.Contains("DoubleParameter"))
                vDouble = plugin_config.Get("DoubleParameter").GetDouble();

            if (plugin_config.Contains("FloatParameter"))
                vFloat = plugin_config.Get("FloatParameter").GetFloat();

            if (plugin_config.Contains("IntParameter"))
                vInt = plugin_config.Get("IntParameter").GetInt();

            if (plugin_config.Contains("UIntParameter"))
                vUInt = plugin_config.Get("UIntParameter").GetUInt();

            if (plugin_config.Contains("StringParameter"))
                vString = plugin_config.Get("StringParameter").GetString();

            if (plugin_config.Contains("ArrayParameter"))
            {
                x = plugin_config.Get("ArrayParameter")[0].GetFloat();
                y = plugin_config.Get("ArrayParameter")[1].GetFloat();
                z = plugin_config.Get("ArrayParameter")[2].GetFloat();
            }
        }
    }
}
