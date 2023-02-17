#include "ScriptEngine/Effects/Base/BaseAr.as"

namespace MaskEngine
{

class ar_object : BaseAr
{
    //    Scene@  scene;
    Quaternion rotation;
    bool wasFirstCall = false;
    bool isFront = false;
    Matrix3 arObjectTransformation;
    int     arObjectTransformationError = 0;

    Vector3 oldCameraPosition;
    Quaternion oldCameraRotation;
    float frameRotation = 0;

    Node@ arCameraNode;
    Node@ arCameraTransfromNode;

    Vector3 ar_pos_at_screen = Vector3(0.7, 0.5, 100);

    float objectScale = 1;

    Vector2 srcSize;
    float _depth;

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

        _depth = ar_pos_at_screen.z;

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

        SubscribeToEvent("ArUpdate", "HandleArUpdate");
        SubscribeToEvent("SrcFrameUpdate", "HandleUpdateSrc");
        SubscribeToEvent("PostUpdate", "HandlePostUpdate");
    }

    String GetName() override
    {
        return "ar_object";
    }

    void HandleArUpdate(StringHash eventType, VariantMap& eventData)
    {
        arObjectTransformation = eventData["Matrix"].GetMatrix3();
        arObjectTransformationError = eventData["MatrixError"].GetInt();

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

        Node@ nodeArObject = scene.GetChild("ar_3d");

        Quaternion currentRotation = rotation;
        arCameraNode.rotation = Quaternion(0, 0, 90);
        //camera.useReflection = camera.useReflection;

        currentRotation.Normalize();

        Quaternion old_rotation = nodeCamera.rotation;

        oldCameraPosition = nodeCamera.position;
        nodeCamera.position = Vector3(0, 0, 0);

        Vector3 arObjectPosition = nodeArObject.worldPosition;

        if (!wasFirstCall)
        {
            oldCameraRotation = nodeCamera.rotation;
            nodeCamera.rotation = currentRotation;
            wasFirstCall = true;

            if (frameRotation == 0 || frameRotation == 180)
            {
                nodeArObject.rotation = Quaternion(0, 0, -90);
            }

            arObjectPosition = camera.ScreenToWorldPoint(Vector3(ar_pos_at_screen.x, ar_pos_at_screen.y, _depth));//(0.7, 0.5, 100)
            nodeArObject.worldPosition = arObjectPosition;
        }
        else
        {
            //!!! important!! before rotation
            Vector2 screen_pos = camera.WorldToScreenPoint(arObjectPosition);

            oldCameraRotation = nodeCamera.rotation;
            nodeCamera.rotation = currentRotation;

            Quaternion delta_rotation = oldCameraRotation - nodeCamera.rotation;

            float d = delta_rotation.LengthSquared(); //not correctly, but better visual work

            Vector2 screen_pos_rot = camera.WorldToScreenPoint(arObjectPosition);
            Vector2 delta_rot = screen_pos_rot - screen_pos;
            Vector2 move(arObjectTransformation.m02 / float(srcSize.x), arObjectTransformation.m12 / float(srcSize.y));
            Vector3 delta;
            delta.x = screen_pos.x - arObjectTransformation.m02 / float(srcSize.x);
            delta.y = screen_pos.y - arObjectTransformation.m12 / float(srcSize.y);
            float scale = get_average_scale(arObjectTransformation);
            bool  update = false;
            update = arObjectTransformationError < 20; //good prediction
            update = update && d < 0.001;

            if (update)
            {
                if (move.length < 0.01)
                {
                    _depth *= scale;
                }
                delta.z = _depth;
                objectScale *= scale;

                Vector3 obj_positionW_N = camera.ScreenToWorldPoint(delta);
                //obj_positionW = obj_positionW *0.1 + obj_positionW_N *0.9;
                arObjectPosition = obj_positionW_N;
                nodeArObject.worldPosition = arObjectPosition;
            }
        }
    }

    void HandleUpdateSrc(StringHash eventType, VariantMap& eventData)
    {
        srcSize = eventData["Size"].GetVector2();
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
        scene.GetChild("ar_3d").SetEnabledRecursive(!isFront);
    }


    float get_average_scale(Matrix3 matrix)
    {
        float norm1 = matrix.m00 * matrix.m00 + matrix.m10 * matrix.m10;
        float norm2 = matrix.m01 * matrix.m01 + matrix.m11 * matrix.m11;
        return (Sqrt(norm1) + Sqrt(norm2)) * 0.5f;
    }
}

}