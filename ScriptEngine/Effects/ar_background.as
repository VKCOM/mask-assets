#include "ScriptEngine/Effects/Base/BaseAr.as"

namespace MaskEngine
{

class ar_background : BaseAr
{
    Quaternion rotation;
    bool wasFirstCall = false;
    bool isFront = false;

    Vector3 oldCameraPosition;
    Quaternion oldCameraRotation;
    float frameRotation = 0;

    Node@ arCameraNode;
    Node@ arCameraTransfromNode;

    void Init() override
    {
        //Print("ArPlugin init");

        //scene = script.defaultScene;

        // Create AR camera
        arCameraTransfromNode = scene.CreateChild("CameraARTransform");
        arCameraNode = arCameraTransfromNode.CreateChild("CameraAR");

        Camera@ cameraAR = arCameraNode.CreateComponent("Camera");
        arCameraNode.position = Vector3(0.0f, 0.0f, 0.0f);
        //arCameraNode.scale = Vector3(1.0f, -1.0f, 1.0f); 
        cameraAR.orthographic = false;
        cameraAR.SetOrthoSize(Vector2(640, 480));
        cameraAR.nearClip = 0.0;
        cameraAR.farClip = 1000;

        // Edit render patch.
        RenderPath@ defaultAR = renderer.viewports[0].renderPath;
        RenderPath@ renderPathMaskBeforeAr = RenderPath();// = defaultAR.Clone();
        RenderPath@ renderPathAr = RenderPath();//           = defaultAR.Clone();
        RenderPath@ renderPathMaskAfterAr = RenderPath();//  = defaultAR.Clone();

                                                         // RenderPath before AR.
        uint j = 0;
        uint i = 0;

        for (j = 0; j < defaultAR.numCommands; j++)
        {
            RenderPathCommand command = defaultAR.commands[j];
            if (command.tag == "start_ar")
            {
                renderPathMaskBeforeAr.Append(cache.GetResource("XMLFile", "RenderPaths/copy_texture.xml"));
                renderPathMaskBeforeAr.Append(cache.GetResource("XMLFile", "RenderPaths/copy_viewport_to_texture.xml"));
                renderPathAr.AddCommand(command);
                renderPathAr.Append(cache.GetResource("XMLFile", "RenderPaths/copy_texture.xml"));
                renderPathAr.Append(cache.GetResource("XMLFile", "RenderPaths/copy_texture_to_viewport.xml"));
                break;
            }
            renderPathMaskBeforeAr.AddCommand(command);
        }

        // AR render path.
        for (i = j + 1; i < defaultAR.numCommands; i++)
        {
            RenderPathCommand command = defaultAR.commands[i];
            //Print (command.tag);
            if (command.tag == "finish_ar")
            {
                renderPathAr.Append(cache.GetResource("XMLFile", "RenderPaths/copy_viewport_to_texture.xml"));
                renderPathAr.AddCommand(command);

                renderPathMaskAfterAr.Append(cache.GetResource("XMLFile", "RenderPaths/copy_texture.xml"));
                renderPathMaskAfterAr.Append(cache.GetResource("XMLFile", "RenderPaths/copy_texture_to_viewport.xml"));
                break;
            }
            renderPathAr.AddCommand(command);
        }

        for (j = i + 1; j < defaultAR.numCommands; j++)
        {
            RenderPathCommand command = defaultAR.commands[j];
            renderPathMaskAfterAr.AddCommand(command);
        }

        Viewport@     viewportAfterAr = Viewport(scene, scene.GetChild("Camera").GetComponent("Camera"));
        Viewport@     viewportAr = Viewport(scene, arCameraNode.GetComponent("Camera"));

        viewportAfterAr.renderPath = renderPathMaskAfterAr;
        viewportAr.renderPath = renderPathAr;

        renderer.numViewports = 3;
        renderer.viewports[0].renderPath = renderPathMaskBeforeAr;
        renderer.viewports[1] = viewportAr;
        renderer.viewports[2] = viewportAfterAr;

        SubscribeToEvent("SrcFrameUpdate", "HandleUpdateSrc");
        SubscribeToEvent("PostUpdate", "HandlePostUpdate");
        SubscribeToEvent("ArUpdate", "HandleArUpdate");
    }

    String GetName() override
    {
        return "ar_background";
    }

    void HandleArUpdate(StringHash eventType, VariantMap& eventData)
    {
        //Print("HandleArUpdate");

        Vector3 gravity = eventData["gravity"].GetVector3();
        rotation = eventData["rotation"].GetQuaternion();
        ApplyArCamera();
    }

    bool savedStart = false;
    void ApplyArCamera()
    {
        Node@ nodeCamera = arCameraTransfromNode;
        Camera@ camera = arCameraNode.GetComponent("Camera");

        camera.orthographic = false;

        Quaternion currentRotation = rotation;
        arCameraNode.rotation = Quaternion(0, 0, 90);
        //camera.useReflection = camera.useReflection;

        if (!savedStart)
        {
            //scene.GetChild("ar_background").rotation = currentRotation * Quaternion(0, 0, ((frameRotation == 0) ? 90 : frameRotation == 180 ? -90 : 180));
            if (frameRotation == 0 || frameRotation == 180)
            {
                scene.GetChild("ar_background").rotation = Quaternion(0, 0, -90);
            }

            savedStart = true;

            // Fix path orientations for patches.
            Node@ arBackground = scene.GetChild("ar_background");

            Array < Node@> allBackgroundNodes = arBackground.GetChildren(true);
            Matrix3x4 view = camera.view;

            for (uint i = 0; i < allBackgroundNodes.length; i++)
            {
                BillboardSet@ bbs = allBackgroundNodes[i].GetComponent("BillboardSet");
                if (bbs !is null)
                {
                    bbs.faceCameraMode = FC_DIRECTION;

                    for (uint j = 0; j < bbs.numBillboards; j++)
                    {
                        Billboard@ billboard = bbs.billboards[j];

                        billboard.rotation = 90;

                        Vector3 toCenter = (allBackgroundNodes[i].LocalToWorld(billboard.position)).Normalized();
                        Vector3 axe = (Vector3(0.0, 0.0, 1.0));
                        billboard.direction = axe.CrossProduct(toCenter);
                        if (billboard.direction.length < 1e-3)
                        {
                            Vector3 axe2 = (Vector3(0.0, 1.0, 0.0));
                            billboard.direction = axe2.CrossProduct(toCenter);
                        }
                    }
                }
            }
        }

        currentRotation.Normalize();

        Quaternion old_rotation = nodeCamera.rotation;

        oldCameraPosition = nodeCamera.position;
        nodeCamera.position = Vector3(0, 0, 0);

        nodeCamera.rotation = currentRotation;
    }

    void HandleUpdateSrc(StringHash eventType, VariantMap& eventData)
    {
        Vector2 srcSize = eventData["Size"].GetVector2();
        Camera@ arCamera = arCameraNode.GetComponent("Camera");
        arCamera.SetOrthoSize(srcSize);
        frameRotation = eventData["Angle"].GetFloat();
        isFront = eventData["IsFrontCamera"].GetBool();

        if (isFront)
        {
            UnsubscribeFromEvent("ArUpdate");
        }
        else
        {
            SubscribeToEvent("ArUpdate", "HandleArUpdate");
        }

    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        scene.GetChild("ar_background").SetEnabledRecursive(!isFront);
        //Print(isFront);
    }
}

}