#include "ScriptEngine/Plugins/BasePlugin.as"


class spinner3d : BasePlugin
{
    String pluginName = "spinner3d";

    Node@ faceNode;
    // This node is created based on json file
    Node@ original;
    // Parent and child nodea are created in this plugin 
    Node@ parentNode;
    Array<Node@> childNodes;

    float radius, z, x, offset_y, speed;
    uint number;
    bool faceLost;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        // Use it to retrieve effects from mask
        // if (mask is null)
        // {
        //     log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
        //     return false;
        // }

        radius = 120.0f;
        number = 8;
        offset_y = 10.0f;
        speed = 25.0f;

        LoadSettings(plugin_config);
     
        Scene@ scene = script.defaultScene;
        original = scene.GetChildrenWithTag("spinner", true)[0];
        StaticModel@ originalMesh = original.GetComponent("StaticModel");
        faceNode = scene.GetChild("Face");
        parentNode = faceNode.CreateChild("Parent");
        parentNode.position = Vector3(faceNode.position.x, faceNode.position.y + 100.0f + offset_y, faceNode.position.z + 100.0f);
        parentNode.Rotate(Quaternion(12.0f, 0.0f, 0.0f));

        for (uint i = 0; i < number; i ++)
        {
            Node@ childNode = parentNode.CreateChild("Child");
            StaticModel@ childOblect = childNode.CreateComponent("StaticModel");
            childOblect.model = originalMesh.model;
            childOblect.material = originalMesh.materials[0];
            childNode.scale = original.scale;
            childNode.Rotate(Quaternion(original.rotation.eulerAngles.x, (360.0 / number) * float(i) + original.rotation.eulerAngles.y, original.rotation.eulerAngles.z));
            z = radius * Cos((360.0f / number) * float(i)) + faceNode.position.z;
            x = radius * Sin((360.0f / number) * float(i)) + faceNode.position.x;
            childNode.position = Vector3(x, faceNode.position.y, z);
            
            for (uint j = 0; j < original.tags.length; ++j)
                childNode.AddTag(original.tags[j]);

            childNodes.Push(childNode);
        }

        // Remove original node, because it's no longer needed,
        // and its existance conflicts with MaskSwitching.
        scene.RemoveChild(original);
   
        SubscribeToEvent("Update", "HandleUpdate"); 
        SubscribeToEvent("UpdateFacePOI", "HandleUpdateFacePOI");

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("radius"))
                radius = plugin_config.Get("radius").GetFloat();  

            if (plugin_config.Contains("number"))
                number = plugin_config.Get("number").GetUInt();

            if (plugin_config.Contains("offset_y"))
                offset_y = plugin_config.Get("offset_y").GetFloat();

            if (plugin_config.Contains("speed"))
                speed = plugin_config.Get("speed").GetFloat();
        }
    }

    void HandleUpdateFacePOI(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Detected"].GetBool())
            for (uint i = 0; i < childNodes.length; i++)
                childNodes[i].enabled = true;

        if (!eventData["Detected"].GetBool())
            for (uint i = 0; i < childNodes.length; i++)
                childNodes[i].enabled = false;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        parentNode.Rotate(Quaternion(0.0f, speed * timeStep, 0.0f));
    }
}