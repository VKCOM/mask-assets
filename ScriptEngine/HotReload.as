#include "ScriptEngine/Src/Mask.as"

namespace MaskEngine
{
    FileWatcher @hotReloader = FileWatcher();
    // hotReloader.Attach();

    class FileWatcher
    {

        VariantMap checkSumMap = VariantMap();
        VariantMap lastModifiedMap = VariantMap();

        // FileWatcher()
        void Attach()
        {
            String platform = GetPlatform();
            bool runOnDesktop = (platform == "Windows" || platform == "Mac OS X");
            // no need to waste resources on mobile
            if (!runOnDesktop)
                return;

            SubscribeToEvent("Update", "CheckFilesUpdated");
        }

        void CheckFilesUpdated(StringHash eventType, VariantMap &eventData)
        {
            // return;
            /*
                todo : add all dirs = done
                todo : respect priority of dirs
                todo : add detatch
                todo : check which file fired event

            */
            bool needReload = false;
            for (uint dirIndex = 0; dirIndex < cache.resourceDirs.length; dirIndex++)
            {
                String resourceDir = cache.resourceDirs[dirIndex];
                Array<String> files = fileSystem.ScanDir(resourceDir, "*", SCAN_FILES, true);
                for (uint index = 0; index < files.length; index++)
                {

                    String fileName = files[index];
                    String fileNameFull = resourceDir + fileName;
                    uint modifiedTime = fileSystem.GetLastModifiedTime(fileNameFull);

                    if (lastModifiedMap.Contains(fileNameFull))
                    {

                        bool changed = (lastModifiedMap[fileNameFull].GetUInt() != modifiedTime);
                        if (changed && !fileName.EndsWith("HotReload.as"))
                        {
                            log.Error("File updated : " + fileName);

                            if (fileName.EndsWith(".as") || fileName.EndsWith(".json"))
                            {
                                needReload = true;
                                // ScriptFile @mainScript = cache.GetResource("ScriptFile", fileName);
                                // SendEvent("ReloadMask");
                                // lastModifiedMap[fileName] = Variant(modifiedTime);
                                lastModifiedMap[fileNameFull] = Variant(modifiedTime);

                                continue;
                            }

                            cache.ReloadResourceWithDependencies(fileName);
                        }
                    }

                    lastModifiedMap[fileNameFull] = Variant(modifiedTime);
                }
            }

            if (needReload)
                ReloadMask();
        }

        void ReloadMask()
        {

            // UnloadMask();
            // maskScene = null;

            log.Error("HotReload.as : handle file changed");
            log.Error(scriptFile.name);

            // bool res = scriptFile.Execute("void UnloadMask()");
            UnloadMask();

            CreateDefaultScene();

            @mask = Mask();

            // seems like I need to wait until mask complete unload
            // looks like some async functions called before destructor
            LoadMask("mask.json");
        }

        void CreateDefaultScene()
        {

            // !!! not 100% complete cleanup !!!

            scene.Clear();

            // Create the Octree component to the scene so that drawable objects can be rendered. Use default volume
            // (-1000, -1000, -1000) to (1000, 1000, 1000)
            scene.CreateComponent("Octree");

            Node @cameraNode = scene.CreateChild("Camera");
            Camera @camera = cameraNode.CreateComponent("Camera");
            cameraNode.position = Vector3(0.0f, 0.0f, 0.0f);
            camera.orthographic = true;
            camera.SetOrthoSize(Vector2(1280, 768));
            camera.nearClip = 0.0;
            camera.farClip = 10000.0; // !!! it should be 1000.0 but I get clipping with ortho camera
            // camera.SetFlipVertical(true);

            Node @zoneNode = scene.CreateChild("Zone");
            Zone @zone = zoneNode.CreateComponent("Zone");
            zone.ResetToDefault();
            zone.boundingBox = BoundingBox(-100000, 100000); // BBox for all scene.
            // Disable fog for our render.
            zone.fogStart = 100000;
            zone.fogEnd = 100000;

            // create face nodes (all of them, even if mask wouldn't use them all)
            for (uint faceIdx = 0; faceIdx < MAX_FACES; faceIdx++)
            {
                scene.CreateChild(FACE_NODE_NAME(faceIdx));
            }

            // // Disable fog for
            // renderer.GetDefaultZone().SetFogStart(100000);
            // renderer.GetDefaultZone().SetFogEnd(100000);
            // // Disable default ambient
            // renderer.GetDefaultZone().SetAmbientColor(Color(0, 0, 0, 0));

            XMLFile @initRenderPathXML = cache.GetResource("XMLFile", INIT_RENDER_PASS_FILE);
            if (initRenderPathXML is null)
            {
                log.Error("Failed to load RP file " + INIT_RENDER_PASS_FILE);
                return;
            }

            Viewport @viewport = Viewport(scene, camera);
            renderer.numViewports = 1;
            renderer.SetDefaultRenderPath(initRenderPathXML);
            viewport.renderPath = renderer.defaultRenderPath;
            renderer.viewports[0] = viewport;
        }

        void PrintDebugInfoRP()
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
    }

}
