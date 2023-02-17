#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

    enum LiquifiedWarpPointType
    {
        LPT_UNKNOWN = 0,
        LPT_ZOOM = 1,
        LPT_SHIFT = 2
    };

    class LiquifiedWarpPoint
    {
        String anchor;
        Vector2 offset;
        Vector2 radius;
        float scale;
        Vector2 direction; // in radian
        float angle;
        Vector2 uMinMax;
        LiquifiedWarpPointType type;
        int faceIndex;
        bool debug;
    }

    /*
      Change texture coords to new texture coords.
    */
    Model @CreateModelPlane(uint horizSeqment, uint verticalSeqment)
    {

        Model @modelPlane = Model();
        VertexBuffer @vb = VertexBuffer();
        IndexBuffer @ib = IndexBuffer();
        Geometry @geom = Geometry();

        // Shadowed buffer needed for raycasts to work, and so that data can be automatically restored on device loss
        vb.shadowed = true;
        // We could use the "legacy" element bitmask to define elements for more compact code, but let's demonstrate
        // defining the vertex elements explicitly to allow any element types and order
        Array<VertexElement> elements;
        elements.Push(VertexElement(TYPE_VECTOR3, SEM_POSITION));
        elements.Push(VertexElement(TYPE_VECTOR2, SEM_TEXCOORD));
        vb.SetSize((verticalSeqment + 1) * (horizSeqment + 1), elements);

        uint horizVertexNumber = horizSeqment + 1;

        VectorBuffer vertexBuffer;
        for (uint y = 0; y <= verticalSeqment; y++)
        {
            for (uint x = 0; x < horizVertexNumber; x++)
            {
                Vector3 v = Vector3(2.0 * float(x) / horizSeqment - 1.0, 2.0 * (float(y) / verticalSeqment) - 1.0, 0);
                // Vertex
                vertexBuffer.WriteVector3(v);
                // Texture Coords
                Vector2 tc = Vector2(float(x) / horizSeqment, 1.0 - float(y) / verticalSeqment);
                vertexBuffer.WriteVector2(tc);

                //    Print("(" + v.x + " " + v.y + " " + v.z + ") " + " (" + tc.x + " " + tc.y + ")");
            }
        }
        vb.SetData(vertexBuffer);

        ib.shadowed = true;
        uint indexNumbers = horizSeqment * verticalSeqment * 6;
        ib.SetSize(indexNumbers, false);

        VectorBuffer indexBuffer;
        for (uint y = 0; y < verticalSeqment; y++)
        {
            for (uint x = 0; x < horizSeqment; x++)
            {
                //            Print(y * horizVertexNumber + x + 1);
                indexBuffer.WriteUShort(y * horizVertexNumber + x + 1);
                //            Print(y * horizVertexNumber + x);
                indexBuffer.WriteUShort(y * horizVertexNumber + x);
                //            Print((y + 1) * horizVertexNumber + x);
                indexBuffer.WriteUShort((y + 1) * horizVertexNumber + x);

                //            Print(y * horizVertexNumber + x + 1);
                indexBuffer.WriteUShort(y * horizVertexNumber + x + 1);
                //            Print((y + 1) * horizVertexNumber + x);
                indexBuffer.WriteUShort((y + 1) * horizVertexNumber + x);
                //            Print((y + 1) * horizVertexNumber + x + 1);
                indexBuffer.WriteUShort((y + 1) * horizVertexNumber + x + 1);
            }
        }
        ib.SetData(indexBuffer);

        geom.SetVertexBuffer(0, vb);
        geom.SetIndexBuffer(ib);
        geom.SetDrawRange(TRIANGLE_LIST, 0, indexNumbers);

        modelPlane.numGeometries = 1;
        modelPlane.SetGeometry(0, 0, geom);
        modelPlane.boundingBox = BoundingBox(Vector3(-1, -1, -1), Vector3(1, 1, 1));

        return modelPlane;
    }

    class liquifiedwarp : BaseEffectImpl
    {
        Node @liquifiedwarpNode;
        StaticModel @object;
        Node @lenseScaleNode;
        Node @faceNode;
        VariantMap detectData;
        Array<LiquifiedWarpPoint> points;

        float aspect = 720.0f / 1280.0f;
        Vector2 sizeCamera;
        Vector2 sizeTarget;
        float progress = 0.3f;

        float angle = 0.0f;
        BaseEffect @patchEffectLiquify;

        uint MAXPOINTS = 15;

        bool debug = false;
        uint version = 0;

        /**
         * version 0 is old liquifiedwarp in 2d screen space
         * version 1 is improvement which moves points to 3d space
         * */

        bool Init(const JSONValue &effect_desc, BaseEffect @parent) override
        {
            if (!BaseEffectImpl::Init(effect_desc, parent))
            {
                return false;
            }

            if (!loadSetup(effect_desc))
            {
                log.Error("Liquify : unable to load points");
                return false;
            }

            String patchEffectString =
                "{" +
                "\"name\" : \"patch\"," +
                "\"anchor\" : \"fullscreen\"," +
                "\"texture\" : {" +
                "\"shader\" : \"LiquifiedWarp\"" +
                "}" +
                "}";

            @patchEffectLiquify = AddChildEffect("patch");
            if (patchEffectLiquify !is null)
            {
                JSONFile @jsonFile = JSONFile();
                jsonFile.FromString(patchEffectString);

                if (!patchEffectLiquify.Init(jsonFile.GetRoot(), parent))
                {

                    log.Error("liquify: Cannot init  patchEffectLiquify");
                    return false;
                }
            }

            liquifiedwarpNode = patchEffectLiquify.GetNode(0);
            BillboardSet @bbs = liquifiedwarpNode.GetComponent("BillboardSet");

            // ! need to adapth with aspect ratio
            Model @model = CreateModelPlane(100, 200);

            object = liquifiedwarpNode.CreateComponent("StaticModel");
            object.model = model;
            object.material = bbs.material.Clone();
            liquifiedwarpNode.RemoveComponent(bbs);
            liquifiedwarpNode.parent.RemoveChild(liquifiedwarpNode);
            scene.AddChild(liquifiedwarpNode);

            detectData = VariantMap();

            AddTags(effect_desc, liquifiedwarpNode);

            SubscribeToEvent("SrcFrameUpdate", "handleUpdateSrc");
            SubscribeToEvent("UpdateFacePOI", "UpdateFacePOI");

            faceNode = scene.GetChild(FACE_NODE_NAME(_faceIdx));

            if (version == 0)
            {
                // Create Node to recalculate scale.
                lenseScaleNode = faceNode.CreateChild("LiquifiedWarpUnit0");
                lenseScaleNode.position = Vector3(0.707, 0.707, 0.0);

                SubscribeToEvent("Update", "HandleUpdate_v0");
            }
            else if (version == 1)
            {
                SubscribeToEvent("Update", "HandleUpdate_v1");
            }

            String shaderDefines = (" VERSION_" + version) + (debug ? " DEBUG_MODE" : "");
            object.materials[0].techniques[0].passes[0].vertexShaderDefines = shaderDefines;
            object.materials[0].techniques[0].passes[0].pixelShaderDefines = shaderDefines;
            // log.Error(shaderDefines);

            _inited = true;

            return _inited;
        }

        bool loadSetup(const JSONValue &jsonSettigns)
        {

            if (jsonSettigns.Contains("progress"))
            {
                progress = jsonSettigns.Get("progress").GetFloat();
            }
            points.Clear();

            JSONValue jsonPoints = jsonSettigns.Get("points");

            if (jsonSettigns.Contains("version"))
            {
                version = jsonSettigns.Get("version").GetUInt();
            }

            if (jsonPoints.isArray)
            {
                if (jsonPoints.size == 0)
                {
                    log.Error("Liquify : requires at least 1 point");
                    return false;
                }
                if (jsonPoints.size > MAXPOINTS)
                {
                    log.Warning("Liquify : TOO many points, maximum is 15.");
                }
                for (int i = 0; i < Min(jsonPoints.size, MAXPOINTS); i++)
                {
                    LiquifiedWarpPoint point;
                    JSONValue jsonPoint = jsonPoints[i];

                    point.type = (jsonPoint.Get("type").GetString() == "shift" ? LPT_SHIFT : jsonPoint.Get("type").GetString() == "zoom" ? LPT_ZOOM
                                                                                                                                         : LPT_UNKNOWN);

                    if (point.type != LPT_UNKNOWN)
                    {
                        point.anchor = jsonPoint.Get("anchor").GetString();
                        point.offset = Vector2(
                            jsonPoint.Get("offset")[0].GetFloat(),
                            jsonPoint.Get("offset")[1].GetFloat());
                        point.radius = Vector2(
                            jsonPoint.Get("radius")[0].GetFloat(),
                            jsonPoint.Get("radius")[1].GetFloat());
                        float angle = jsonPoint.Get("angle").GetFloat();
                        point.direction = Vector2(Cos(angle), Sin(angle));
                        point.angle = angle * M_DEGTORAD;
                        point.scale = jsonPoint.Get("scale").GetFloat();

                        JSONValue minMax = jsonPoint.Get("minMax");
                        if (minMax.isArray && minMax.size == 2)
                        {
                            point.uMinMax = Vector2(
                                minMax[0].GetFloat(),
                                minMax[1].GetFloat());
                        }
                        else
                        {
                            point.uMinMax = Vector2(0, 1);
                        }
                        point.debug = jsonPoint.Contains("debug") ? jsonPoint.Get("debug").GetBool() : false;
                        debug = point.debug || debug;

                        points.Push(point);
                    }
                }
            }

            return true;
        }

        void handleUpdateSrc(StringHash eventType, VariantMap &eventData)
        {
            sizeCamera = eventData["Size"].GetVector2();
            angle = eventData["Angle"].GetFloat();
            sizeTarget = eventData["TargetSize"].GetVector2();

            if (angle == 90 || angle == 270)
            {
                sizeCamera = Vector2(sizeCamera.y, sizeCamera.x);
            }

            aspect = sizeTarget.x / sizeTarget.y;
            liquifiedwarpNode.scale = Vector3(sizeCamera.x / 2.0, sizeCamera.y / 2.0, 1.0);
        }

        void UpdateFacePOI(StringHash eventType, VariantMap &eventData)
        {
            int faceIndex = eventData["NFace"].GetUInt();
            if (faceIndex == _faceIdx)
            {
                detectData = eventData;
            }
        }

        void HandleUpdate_v0(StringHash eventType, VariantMap &eventData)
        {
            Camera @camera = scene.GetChild("Camera").GetComponent("Camera");

            // uniform float4 cCenter[MAXPOINTS];
            // uniform float4 cRadiusAndType[MAXPOINTS];       // We use only x and y, z for type
            // uniform float4 cScaleAngleDirection[MAXPOINTS];  //It is: Scale, Angel, UMin, UMax
            VectorBuffer centerBuffer;
            VectorBuffer radiusAndTypeAndDebug;
            VectorBuffer scaleAngleDirection;

            Vector2 aspectVector;
            if (aspect > 1.0)
            {
                aspectVector = Vector2(1.0, 1.0 / aspect);
            }
            else
            {
                aspectVector = Vector2(aspect, 1.0);
            }

            Vector3 deltaInGlobalSpace = lenseScaleNode.worldPosition - faceNode.worldPosition;

            Vector2 scaleInScreenSpace = camera.WorldToScreenPoint(Vector3(
                                             deltaInGlobalSpace.length * 0.707,
                                             deltaInGlobalSpace.length * 0.707,
                                             500.0)) -
                                         camera.WorldToScreenPoint(Vector3(
                                             0.0,
                                             0.0,
                                             500.0));

            float scaleFactor = scaleInScreenSpace.length;

            uint pointsCount = 0;
            for (uint i = 0; i < points.length; i++)
            {
                LiquifiedWarpPoint @point = points[i];
                if (detectData["PoiMap"].GetVariantMap().Contains(point.anchor))
                {
                    bool faceEnabled = detectData["Detected"].GetBool();

                    Vector3 centerLocal = detectData["PoiMap"].GetVariantMap()[point.anchor].GetVector3() + Vector3(point.offset.x, point.offset.y, 0.0);
                    Vector3 center = faceNode.LocalToWorld(centerLocal);
                    Vector2 centerInScreen = camera.WorldToScreenPoint(center);

                    Vector3 direction2 = Vector3(centerLocal.x, centerLocal.y, centerLocal.z) + Vector3(point.direction.x, point.direction.y, 0.0);
                    Vector3 direction2World = faceNode.LocalToWorld(direction2);
                    Vector2 directionInScreen2 = camera.WorldToScreenPoint(direction2World);
                    Vector2 directionInScreen = (directionInScreen2 - centerInScreen).Normalized();

                    centerBuffer.WriteVector4(
                        Vector4(
                            centerInScreen.x,
                            centerInScreen.y,
                            directionInScreen.x,
                            directionInScreen.y));

                    radiusAndTypeAndDebug.WriteVector4(
                        Vector4(
                            point.radius.x * scaleFactor,
                            point.radius.y * scaleFactor,
                            (faceEnabled ? float(point.type) : 0.0),
                            float(point.debug ? 1.0 : 0.0)));

                    scaleAngleDirection.WriteVector4(
                        Vector4(
                            point.scale * scaleFactor,
                            point.angle,
                            float(point.direction.x),
                            float(point.direction.y)));

                    pointsCount++;
                }
                else
                {
                    centerBuffer.WriteVector4(Vector4(0.0, 0.0, 0.0, 0.0));
                    radiusAndTypeAndDebug.WriteVector4(Vector4(0.0, 0.0, 0.0, 0.0));
                    scaleAngleDirection.WriteVector4(Vector4(0.0, 0.0, 0.0, 0.0));
                }
            }

            object.materials[0].shaderParameters["Center"] = Variant(centerBuffer);
            object.materials[0].shaderParameters["RadiusAndType"] = Variant(radiusAndTypeAndDebug);
            object.materials[0].shaderParameters["ScaleAngleDirection"] = Variant(scaleAngleDirection);

            object.materials[0].shaderParameters["AspectRatio"] = Variant(Vector2(1.0, 1.0) / aspectVector);
            object.materials[0].shaderParameters["Count"] = float(points.length);
            object.materials[0].shaderParameters["Progress"] = progress;

            Vector2 textCoordX;
            Vector2 textCoordY;
            Vector2 textCoordOffset = Vector2(0.0, 0.0);
            if (angle == 0.0)
            {
                textCoordX = Vector2(1.0, 0.0);
                textCoordY = Vector2(0.0, 1.0);
            }
            else if (angle == 90.0)
            {
                textCoordX = Vector2(0.0, 1.0);
                textCoordY = Vector2(-1.0, 0.0);
                textCoordOffset.y = 1.0;
            }
            else if (angle == 180.0)
            {
                textCoordX = Vector2(-1.0, 0.0);
                textCoordY = Vector2(0.0, -1.0);
                textCoordOffset.y = 1.0;
                textCoordOffset.x = 1.0;
            }
            else if (angle == 270.0)
            {
                textCoordX = Vector2(0.0, -1.0);
                textCoordY = Vector2(1.0, 0.0);
                textCoordOffset = Vector2(1.0, 0.0);
            }

            object.materials[0].shaderParameters["TexCoordX"] = Variant(textCoordX);
            object.materials[0].shaderParameters["TexCoordY"] = Variant(textCoordY);
            object.materials[0].shaderParameters["TexCoordOffset"] = Variant(textCoordOffset);
        }

        void HandleUpdate_v1(StringHash eventType, VariantMap &eventData)
        {

            Node @cameraNode = scene.GetChild("Camera");
            Camera @camera = cameraNode.GetComponent("Camera");

            Vector2 aspectVector;
            if (aspect > 1.0)
            {
                aspectVector = Vector2(1.0, 1.0 / aspect);
            }
            else
            {
                aspectVector = Vector2(aspect, 1.0);
            }

            Matrix4 faceMatrix = faceNode.worldTransform.ToMatrix4();
            Matrix4 faceInvMatrix = faceNode.worldTransform.Inverse().ToMatrix4();

            // uniform float4 cCenter[MAXPOINTS];
            // uniform float4 cRadiusAndType[MAXPOINTS];       // We use only x and y, z for type
            // uniform float4 cScaleAngleDirection[MAXPOINTS];  //It is: Scale, Angel, UMin, UMax
            VectorBuffer centerBuffer;
            VectorBuffer radiusAndTypeAndDebug;
            VectorBuffer scaleAngleDirection;

            uint pointsCount = 0;
            for (uint i = 0; i < points.length; i++)
            {
                LiquifiedWarpPoint @point = points[i];
                if (detectData["PoiMap"].GetVariantMap().Contains(point.anchor))
                {
                    bool faceEnabled = detectData["Detected"].GetBool();

                    Vector3 centerLocal = detectData["PoiMap"].GetVariantMap()[point.anchor].GetVector3() + Vector3(point.offset.x, point.offset.y, 0.0);

                    Vector3 centerWorld = faceNode.LocalToWorld(centerLocal);

                    // this is a hack to make a crude approximation between versions
                    float correctedScale = point.scale * 0.002;
                    correctedScale *= point.type == 2 ? 4.0 : 1.0;

                    Vector2 correctedRadius = point.radius * 2.0;


                    pointsCount++;

                    radiusAndTypeAndDebug.WriteVector4(
                        Vector4(
                            correctedRadius.x,
                            correctedRadius.y,
                            (faceEnabled ? float(point.type) : 0.0),
                            float(point.debug ? 1.0 : 0.0)));

                    centerBuffer.WriteVector4(Vector4(centerLocal.x, centerLocal.y, centerLocal.z, 0.0));

                    scaleAngleDirection.WriteVector4(
                        Vector4(
                            correctedScale,
                            point.angle,
                            float(point.direction.x),
                            float(point.direction.y)));
                }
                else
                {
                    centerBuffer.WriteVector4(Vector4(0.0, 0.0, 0.0, 0.0));
                    radiusAndTypeAndDebug.WriteVector4(Vector4(0.0, 0.0, 0.0, 0.0));
                    scaleAngleDirection.WriteVector4(Vector4(0.0, 0.0, 0.0, 0.0));
                }
            }

            object.materials[0].shaderParameters["Center"] = Variant(centerBuffer);
            object.materials[0].shaderParameters["RadiusAndType"] = Variant(radiusAndTypeAndDebug);
            object.materials[0].shaderParameters["ScaleAngleDirection"] = Variant(scaleAngleDirection);

            object.materials[0].shaderParameters["AspectRatio"] = Variant(Vector2(1.0, 1.0) / aspectVector);
            object.materials[0].shaderParameters["Count"] = float(points.length);
            object.materials[0].shaderParameters["Progress"] = progress;

            object.materials[0].shaderParameters["FaceMatrix"] = Variant(faceMatrix);
            object.materials[0].shaderParameters["FaceInvMatrix"] = Variant(faceInvMatrix);
        }

        // Show/Hide effect
        void SetVisible(bool visible_) override
        {
            liquifiedwarpNode.enabled = visible_;
        }

        // @return material, if effect has it.
        Material @GetMaterial() override
        {
            return object.materials[0];
        }

        int GetFaceIndex() override
        {
            return _faceIdx;
        }

        String GetName() override
        {
            return "liquifiedwarp";
        }
    }

}
