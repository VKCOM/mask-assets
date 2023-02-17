#include "ScriptEngine/Plugins/BasePlugin.as"


class perspective : BasePlugin
{
    String pluginName = "perspective";

    // persp camera parameters
    float _fov = 35;
    float _nearClip = 0.1; // if set to 0.0 then z-fight 
    float _farClip = 3000.0;

    Vector2 _srcSize = Vector2(1280, 720);

    Camera@ _camera;
    Node@ _cameraNode;
    Camera@ _cameraPersp;
    Node@ _cameraNodePersp;

    Scene@ _scene;
    Node@ _faceNode;
    Node@ _faceNode1;
    Node@ _faceNodePersp;
    Node@ _faceNodePersp1;

    
    /*
    How it works: 
        here I make two cameras : persp and ortho
        sort all object according to their render commmand : 
            3d obj to perpective
            2d obj to ortho
        copy rendertaregets 
        create perp face node and add 3d obj as childs
        calculate persp face transform to account persp camera
        apply parameters for perp camera

    */

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        if (mask is null)
        {
            log.Error("PerspectivePlugin: Trying to initialise with a mask that is null.");
            return false;
        }

        _scene = script.defaultScene;

        LoadSettings(plugin_config);
        if(!ApplySettings()) 
        {
            log.Error("PerspectivePlugin:  Unable to apply settings.");
            return false;
        }
        if(!ModifyRenderPath())
        {
            log.Error("PerspectivePlugin:  Unable to modify render path.");
            return false;
        }
        
        SubscribeToEvent("PostUpdate", "HandlePostUpdate");
        SubscribeToEvent("SrcFrameUpdate", "HandleUpdateSrc");

        return true;
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        // Here face node transformation should be recalculated
        // to account for perspective

        // this one is crucial, orthoCamera asect ratio was 1.3333 instead of 1.7777 on Desktop
        _cameraPersp.aspectRatio = _srcSize.x / _srcSize.y; 
        _camera.aspectRatio = _srcSize.x / _srcSize.y; 

        {
        // fov is the vertical angle!
        Vector2 frustrumSize = _srcSize / Vector2(_faceNode.scale.x, _faceNode.scale.y);
        float d = 0.5 * _srcSize.y / _faceNode.scale.x / Tan(_cameraPersp.fov / 2.0);

        // all depth data is in the scale of faceNode 
        _faceNodePersp.position = Vector3(
            _faceNode.position.x / _faceNode.scale.x, 
            _faceNode.position.y / _faceNode.scale.y,
            d
        );

        _faceNodePersp.rotation = _faceNode.rotation;
        _faceNodePersp.scale = Vector3(1,1,1);
        _faceNodePersp.enabled = _faceNode.enabled;

        }

        if(_faceNode1 !is null) { 
            Vector2 frustrumSize = _srcSize / Vector2(_faceNode1.scale.x, _faceNode1.scale.y);
            float d = 0.5 * _srcSize.y / _faceNode1.scale.x / Tan(_cameraPersp.fov / 2.0);

            _faceNodePersp1.position = Vector3(
                _faceNode1.position.x / _faceNode1.scale.x, 
                _faceNode1.position.y / _faceNode1.scale.y,
                d
            );
            _faceNodePersp1.rotation = _faceNode1.rotation;

            _faceNodePersp1.scale = Vector3(1,1,1);
            _faceNodePersp1.enabled = _faceNode1.enabled;

        }

    }


    void HandleUpdateSrc(StringHash eventType, VariantMap& eventData)
    {
        _srcSize = eventData["Size"].GetVector2(); 
    }


    bool ModifyRenderPath() 
    {
        // creating render paths  from string
        // this way effect is self contained
        // could lead to some nasty bugs!
        // for example if  PerspectiveTempRT renderTarget will be used anywhere else

        String tempStringRP = "<renderpath>" +
            "<command type=\"quad\" vs=\"CopyFramebuffer\" ps=\"CopyFramebuffer\" output=\"PerspectiveTempRT\" tag=\"copy_viewport_to_texture\">" +
                "<texture unit=\"diffuse\" name=\"viewport\" />" +
            "</command>" +
        "</renderpath>";


        XMLFile@ copyViewportToTexture = XMLFile();
        if(!copyViewportToTexture.FromString(tempStringRP)) 
        {
            log.Error("Failed parse copyViewportToTexture");
            return false;
        }   

        tempStringRP = "<renderpath>" + 
            "<rendertarget name=\"PerspectiveTempRT\" sizedivisor=\"1 1\" format=\"rgba\"/>" + 
        "</renderpath>";

        XMLFile@ copyTexture = XMLFile();
        if(!copyTexture.FromString(tempStringRP)) 
        {
            log.Error("Failed parse copyTexture");
            return false;
        }   

        tempStringRP = "<renderpath>" +
            "<command type=\"quad\" vs=\"CopyFramebuffer\" ps=\"CopyFramebuffer\" output=\"viewport\" tag=\"copy_texture_to_viewport\">" +
                "<texture unit=\"diffuse\" name=\"PerspectiveTempRT\" />" +
            "</command>" +
        "</renderpath>";

        XMLFile@ copyTextureToViewport = XMLFile();
        if(!copyTextureToViewport.FromString(tempStringRP)) 
        {
            log.Error("Failed parse copyTextureToViewport");
            return false;
        }   


        RenderPath@ defaultRP = renderer.viewports[0].renderPath;

        RenderPath@ currentRP = RenderPath();
        bool isCurrent3D = (defaultRP.commands[0].tag == "3dStart"); 

        currentRP.Append(copyTexture);
        currentRP.AddCommand(defaultRP.commands[0]);

        Array<RenderPath@>  renderPaths;
        Array<bool>  renderPathsCamera;

        for (uint i = 1; i < defaultRP.numCommands; i++)
        {

            RenderPathCommand command = defaultRP.commands[i];

        
            // 3dStart is from mainPass.xml the default render path for 3d objects first command
            // 3dFinish last command for default 3d objects
            if (
                (isCurrent3D && ( command.tag == "3dFinish" || command.pass =="viewportblend")) ||
                (!isCurrent3D && (command.tag == "3dStart" || command.pass =="cull"))
            )
            {
                if (isCurrent3D)
                {
                    currentRP.AddCommand(command);
                }

                currentRP.Append(copyViewportToTexture);
                renderPaths.Push(currentRP);                
                renderPathsCamera.Push(isCurrent3D);

                @currentRP = RenderPath();
                currentRP.Append(copyTexture);
                currentRP.Append(copyTextureToViewport);


                if (!isCurrent3D)
                {
                  currentRP.AddCommand(command);
                }
                isCurrent3D = !isCurrent3D;
                continue;
            }
            // 3dStartFinish used for custom 3d pasees
            else if (!isCurrent3D && command.tag.StartsWith("3dStartFinish"))
            {
               // Push old
               currentRP.Append(copyViewportToTexture);
               renderPaths.Push(currentRP);                
               renderPathsCamera.Push(isCurrent3D);

               // Push one command
               @currentRP = RenderPath();
               currentRP.Append(copyTexture);
               currentRP.Append(copyTextureToViewport);
               currentRP.AddCommand(command);
               currentRP.Append(copyViewportToTexture);
               renderPaths.Push(currentRP);                
               renderPathsCamera.Push(true);

               // Push new
               @currentRP = RenderPath();
               currentRP.Append(copyTexture);
               currentRP.Append(copyTextureToViewport);
               continue;
            } 

            currentRP.AddCommand(command);
        }


        renderPaths.Push(currentRP);
        renderPathsCamera.Push(isCurrent3D);
        renderer.numViewports = renderPaths.length;  


        for (uint i = 0; i < renderer.numViewports; i++)
        {
            Viewport@ viewport  = renderer.viewports[i] is null ? Viewport(_scene, renderPathsCamera[i] ? _cameraPersp : _camera) : renderer.viewports[i];

            for (uint j = 0; j < defaultRP.numRenderTargets; j++)
            {
                RenderTargetInfo rt = defaultRP.renderTargets[j];
                // Print("rt name = " + rt.name + ", tag = "  + rt.tag);
                // todo : don't add if not used in current render path. Will require to loop through all commands?
                renderPaths[i].AddRenderTarget(rt);
            }   

            viewport.renderPath  = renderPaths[i];
            renderer.viewports[i] = viewport;
        }



        // only for debug purpose
        if (false) {
            for (uint j = 0; j < renderPaths.length; j++)
            {
                RenderPath@ rp = renderPaths[j];
                Print("rt " + j + "====================================");
                for (uint i = 0; i < rp.numCommands; i++)
                {
                    RenderPathCommand command = rp.commands[i];
                    Print(command.pass + " = " + Variant(i).ToString() + ", tag = " + command.tag);

                    for (TextureUnit k = TU_DIFFUSE; k < MAX_TEXTURE_UNITS; k++)
                    {
                        String textureUnitStr = GetTextureUnitName(k);
                        String name = command.get_textureNames(k);
                        if (name != "") Print("  " + textureUnitStr + " = " + name);
                        // Print("  " + textureUnitStr);
                    }
                    Print("psdef = " + command.pixelShaderDefines);
                    Print("vsdef = " + command.vertexShaderDefines);

                }

                for (uint i = 0; i < rp.numRenderTargets; i++)
                {
                    RenderTargetInfo rt = rp.renderTargets[i];
                    Print("rt name = " + rt.name + ", tag = "  + rt.tag);
                }  
            }
        }

        return true;
    }

    bool ApplySettings() 
    {
        _cameraNode = _scene.GetChild("Camera");
        if (_cameraNode is null) {
            log.Error("camera effect : Failed to init. Camera node is null");
            return false;
        }
        _camera = _cameraNode.GetComponent("Camera");
        if (_cameraNode is null) {
            log.Error("camera effect : Failed to init. Camera component is null");
            return false;
        }

        _cameraNodePersp = _scene.CreateChild("CameraPersp"); 
        if (_cameraNodePersp is null) {
            log.Error("camera effect : Failed to init. Camera node persp is null");
            return false;
        }
        _cameraPersp = _cameraNodePersp.CreateComponent("Camera");
        if (_cameraPersp is null) {
            log.Error("camera effect : Failed to init. Camera persp Component is null");
            return false;
        }

        _cameraPersp.orthographic = false;
        _cameraPersp.fov = _fov;
        _cameraPersp.nearClip = _nearClip;
        _cameraPersp.farClip = _farClip;

        /*
            Moving all children from original faces
            to perspective versions
        */

        _faceNode = scene.GetChild("Face");
        _faceNode1 = scene.GetChild("Face1");

        _faceNodePersp = scene.CreateChild("FacePersp");
        _faceNodePersp1 = scene.CreateChild("FacePersp1");

        Array<Node@> children =  _faceNode.GetChildren();
        for (uint i = 0; i < children.length; i ++)
        {
            Node@ child = children[i];
            if (child.name == "anchor_model3d")
            {
                child.parent = _faceNodePersp;
            }
        }

        if (_faceNode1 !is null) { 
            children =  _faceNode1.GetChildren();
            for (uint i = 0; i < children.length; i ++)
            {
                Node@ child = children[i];
                if (child.name == "anchor_model3d")
                {
                    child.parent = _faceNodePersp1;
                }
            }
        }

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("near_clip")) 
            {
                _nearClip = plugin_config.Get("near_clip").GetFloat();
            }

            if (plugin_config.Contains("far_clip")) 
            {
                _farClip = plugin_config.Get("far_clip").GetFloat();
            }

            if (plugin_config.Contains("fov")) 
            {
                _fov = plugin_config.Get("fov").GetFloat();
            }
        }
    }
}
