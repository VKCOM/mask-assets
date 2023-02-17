#include "ScriptEngine/Plugins/BasePlugin.as"


class ParallaxLayer
{
    String tag;
    float strength;
}

class parallax : BasePlugin
{
    String pluginName = "parallax";

    Array<ParallaxLayer> parallaxLayer;
    float strength;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        // Use it to retrieve effects from mask
        // if (mask is null)
        // {
        //     log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
        //     return false;
        // }

        strength = 1.0f;

        LoadSettings(plugin_config);

        SubscribeToEvent("UpdateFacePOI", "HandleUpdateFacePOI");

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("strength"))
                strength = plugin_config.Get("strength").GetFloat();

            if (plugin_config.Contains("layers"))
            {
                JSONValue jsonLayers = plugin_config.Get("layers");   

                if (jsonLayers.isArray)
                    for (uint i = 0; i < jsonLayers.size; i++)
                    {
                        ParallaxLayer tempPL;

                        if (jsonLayers[i].Contains("tag"))
                            tempPL.tag = jsonLayers[i].Get("tag").GetString();

                        if (jsonLayers[i].Contains("strength"))
                        {
                            tempPL.strength = jsonLayers[i].Get("strength").GetFloat();
                            if (tempPL.strength <= 0.0f)
                                tempPL.strength = 0.01f;
                        }

                        parallaxLayer.Push(tempPL);
                    }
            }
        }
    }

    void HandleUpdateFacePOI(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Detected"].GetBool()) {
            Node@ faceNode = scene.GetChild("Face"); 

            for (uint i = 0; i < parallaxLayer.length; i++)
                ParallaxF(scene.GetChildrenWithTag(parallaxLayer[i].tag, true), faceNode, parallaxLayer[i].strength * strength);
        }
    }

    void ParallaxF(Array<Node@> nodes, Node@ faceNode, float k)
    {
        for (uint i = 0; i < nodes.length; i++)
            nodes[i].position = Vector3(faceNode.position.x * k,faceNode.position.y * k, 0.0f);
    }
}
