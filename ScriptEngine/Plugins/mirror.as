#include "ScriptEngine/Plugins/BasePlugin.as"
#include "ScriptEngine/Effects/Base/BaseEffect.as"

class mirror : BasePlugin
{
    String pluginName = "mirror";

    bool isFrontCamera;
    bool enabled = true;
    bool debug = false;
    Node @faceNode;
    Node @faceNode1;
    RenderPath @defaultRP;
    RenderPath @lastRP;

    Matrix3x4 mirrorMatrix = Matrix3x4(
        Vector3(0.0, 0.0, 0.0),
        Quaternion(0.0, 0.0, 0.0),
        Vector3(-1.0, 1.0, 1.0));

    bool Init(const JSONValue &plugin_config, MaskEngine::Mask @mask) override
    {
        if (mask is null)
        {
            log.Error("mirror : Trying to initialise with a mask that is null.");
            return false;
        }

        LoadSettings(plugin_config);

        if (enabled)
        {
            SubscribeToEvent("SrcFrameUpdate", "HandleSrcFrameUpdate");
            SubscribeToEvent("Update", "ApplyMirror"); //  delayed execution
        }
        else
        {
            log.Info("mirror : enabled set to false");
        }

        return true;
    }

    void LoadSettings(const JSONValue &plugin_config) override
    {
        if (plugin_config.Get("name").GetString() == pluginName)
        {
            if (plugin_config.Contains("enabled"))
                enabled = plugin_config.Get("enabled").GetBool();
            if (plugin_config.Contains("debug"))
                debug = plugin_config.Get("debug").GetBool();
        }
    }

    void ApplyMirror()
    {
        faceNode = scene.GetChild("Face");
        faceNode1 = scene.GetChild("Face1");

        @defaultRP = renderer.viewports[0].renderPath;
        // if RP modifyed, then there is could be more that one RP. So appending commands at the very end of the pipeline.
        @lastRP = renderer.viewports[renderer.numViewports - 1].renderPath;

        // for some reason which require reading source code, pingponging does not seem to work if viewport don't used in scene pass
        // doing it manually
        String tempStringRP =
            "<renderpath>" +
            "<command type=\"quad\" vs=\"MirrorQuad\" ps=\"MirrorQuad\" tag=\"mirror_camera_fix\"  output=\"mirror_viewport\">" +
            "<texture unit=\"diffuse\" name=\"viewport\" />" +
            "</command>" +
            "<command type=\"quad\" vs=\"CopyFramebuffer\" ps=\"CopyFramebuffer\"  tag=\"mirror_camera_fix\" output=\"viewport\" >" +
            "<texture unit=\"diffuse\" name=\"mirror_viewport\" />" +
            "</command>" +
            "<rendertarget name=\"mirror_viewport\" sizedivisor=\"1 1\" format=\"rgba\"/>" +
            "</renderpath>";

        XMLFile @mirrorFileXML = XMLFile();
        mirrorFileXML.FromString(tempStringRP);

        lastRP.Append(mirrorFileXML);
        // RenderPathCommand mirrorCommand = lastRP.commands[lastRP.numCommands - 1];
        // defaultRP.InsertCommand(2, mirrorCommand);

        defaultRP.Append(mirrorFileXML);
        RenderPathCommand mirrorCommand = defaultRP.commands[defaultRP.numCommands - 1];
        defaultRP.InsertCommand(2, mirrorCommand);
        defaultRP.RemoveCommand(defaultRP.numCommands - 1);

        RenderPathCommand cullCommand = defaultRP.commands[defaultRP.numCommands - 1];
        defaultRP.InsertCommand(2, cullCommand);
        defaultRP.RemoveCommand(defaultRP.numCommands - 1);

        // check some info for development
        if (debug)
        {

            for (uint j = 0; j < renderer.numViewports; j++)
            {
                RenderPath @rp = renderer.viewports[j].renderPath;
                Print("renderPath " + j + " ====================================");
                Print("camera " + (renderer.viewports[j].camera.orthographic ? "ortho" : "persp"));
                for (uint i = 0; i < rp.numCommands; i++)
                {
                    RenderPathCommand command = rp.commands[i];
                    Print(command.pass.ToUpper() + " = " + Variant(i).ToString() + ", tag = " + command.tag + ", type = " + command.type);

                    for (TextureUnit k = TU_DIFFUSE; k < MAX_TEXTURE_UNITS; k++)
                    {
                        String textureUnitStr = GetTextureUnitName(k);
                        String name = command.get_textureNames(k);
                        if (name != "")
                            Print("  " + textureUnitStr + " = " + name);
                        // Print("  " + textureUnitStr);
                    }
                    Print("    psdef = " + command.pixelShaderDefines);
                    Print("    vsdef = " + command.vertexShaderDefines);
                }

                for (uint i = 0; i < rp.numRenderTargets; i++)
                {
                    RenderTargetInfo rt = rp.renderTargets[i];
                    Print("-- rt name = " + rt.name + ", tag = " + rt.tag);
                }
            }
            log.Error(" ");
        }

        // should fire only once
        UnsubscribeFromEvent("Update");
        SubscribeToEvent("Update", "HandleUpdate");
    }

    void HandleUpdate(StringHash eventType, VariantMap &eventData)
    {
        // not using post update because perspective plugin need updated transform
        // isFrontCamera = true;
        if (isFrontCamera)
        {
            // mirrorMatrix.Inverse will be the same, changing basis
            Matrix3x4 faceTransform = mirrorMatrix * faceNode.transform * mirrorMatrix;
            faceNode.SetTransform(faceTransform.Translation(), faceTransform.Rotation(), faceTransform.Scale());

            faceTransform = mirrorMatrix * faceNode1.transform * mirrorMatrix;
            faceNode1.SetTransform(faceTransform.Translation(), faceTransform.Rotation(), faceTransform.Scale());
        }
        defaultRP.SetEnabled("mirror_camera_fix", isFrontCamera);
        lastRP.SetEnabled("mirror_camera_fix", isFrontCamera);
    }

    void HandleSrcFrameUpdate(StringHash eventType, VariantMap &eventData)
    {
        isFrontCamera = (!eventData["IsFlipHorizontal"].empty) ? eventData["IsFlipHorizontal"].GetBool() :
                        eventData["IsFrontCamera"].GetBool();
    }
}
