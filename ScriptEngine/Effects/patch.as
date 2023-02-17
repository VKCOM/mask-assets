#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

String VISIBLE_FACE = "face";
String VISIBLE_ALWAYS = "always";
String VISIBLE_ANIMATION = "animation";
String VISIBLE_MOUTH_OPEN = "mouth_open";

class patch : BaseEffectImpl
{
    Array<BillboardPosition> _size;
    Array<BillboardPosition> _offset;
    String _visibleType;
    Node@ _node;
    BillboardSet@ _bbSet;
    BaseEffect@ _texture;
    String _anchor;
    String _fitMode;
    Vector2 _lastRTSize;
    Vector2 _lastSourceFrame;
    bool _face_anchor = false;
    bool _allow_rotation = true;
    Array<VariantMap> poiData;
    BaseEffect@ animationVisible;
    Quaternion _rotateOrigin;

    float time = 0;

    patch()
    {
        _size.Resize(2);
        _offset.Resize(3);
        poiData.Resize(MAX_FACES);
    }

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {

        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        // append render path
        if (!InitRenderPass(effect_desc.Get("pass"), UNLIT_RENDER_PASS_FILE))
        {
            return false;
        }

        _anchor = effect_desc.Get("anchor").GetString();
        if (_anchor.empty)
        {
            log.Info("patch : anchor not specified, using \"free\"");
            _anchor = "free";
        }
        if(effect_desc.Get("size").isArray) 
        {
            ReadPosition2D(effect_desc.Get("size"), _size[0], _size[1]);
        } 
        else 
        {
            String sizeDefault = "{\"size\" : [100.0, 100.0]}";
            JSONFile@ jsonFile = JSONFile();
            jsonFile.FromString(sizeDefault);
            ReadPosition2D(jsonFile.GetRoot().Get("size"), _size[0], _size[1]);
            log.Info("patch : size not specified, set to 100pix");
        }
        ReadPosition3D(effect_desc.Get("offset"), _offset[0], _offset[1], _offset[2], true);

        _visibleType = effect_desc.Get("visible").GetString();
        if (_visibleType.empty)
        {
            _visibleType = VISIBLE_FACE;
        }

        _node = scene.CreateChild();
        _bbSet = _node.CreateComponent("BillboardSet");
        _bbSet.numBillboards = 1;
        _bbSet.sorted = false;


        @_texture = AddChildEffect("texture");
        if (_texture is null)
        {
            log.Error("Failed to create texture effect");
            return false;
        }

        if(effect_desc.Contains("texture")) 
        {
            if (!_texture.Init(effect_desc.Get("texture"), this))
            {
                log.Error("Failed to init texture effect");
                return false;
            }

        } else {
            JSONFile@ jsonFile = JSONFile();
            jsonFile.FromString("{}");
            _texture.Init(jsonFile.GetRoot(), this);
            log.Info("patch : texture not specified, using white color");

        }


        AddTags(effect_desc, _node);

        ScreenPatchAnchor@ screenAnchor = FindScreenAnchor(_anchor);

        if (effect_desc.Get("rotation").isArray)
        {
            JSONValue rotation = effect_desc.Get("rotation");
            _rotateOrigin.FromEulerAngles(rotation[0].GetFloat(), rotation[1].GetFloat(), rotation[2].GetFloat());
            _node.rotation = _rotateOrigin;
        }
        else
        {
            // _rotateOrigin.FromEulerAngles(0.0, 0.0, 0.0, 0.0);
            _rotateOrigin = _node.rotation;
        }


        if (_anchor == "fullscreen")
        {
            _node.position = Vector3(0, 0, 10);
            _bbSet.fixedScreenSize = true;
            _bbSet.faceCameraMode = FC_NONE;
            _fitMode = effect_desc.Get("fit").GetString();

            Billboard@ bb = _bbSet.billboards[0];

            bb.position = Vector3(0, 0, _offset[2].pix);
            bb.size = Vector2(10, 10);
            bb.enabled = true;
            _bbSet.Commit();

            SubscribeToEvent("SrcFrameUpdate", "HandleSrcFrameUpdate");
        }
        else if (screenAnchor !is null)
        {
            _node.position = Vector3(0, 0, 10);
            _bbSet.fixedScreenSize = false;
            _bbSet.faceCameraMode = FC_NONE;
            _fitMode = effect_desc.Get("fit").GetString();

            Billboard@ bb = _bbSet.billboards[0];

            bb.position = Vector3(_offset[0].pix, _offset[1].pix, _offset[2].pix);
            bb.size = Vector2(_size[0].pix, _size[1].pix);
            bb.enabled = true;

            _bbSet.Commit();

            SubscribeToEvent("SrcFrameUpdate", "HandleSrcFrameUpdate");
        }
        else if (IsValidPointOfInterestName(_anchor))
        {
            _face_anchor = true;

            //_visible_always = false;
            if (_visibleType == VISIBLE_ALWAYS)
            {
                _visibleType = VISIBLE_FACE;
            }

            Node@ faceNode = scene.GetChild(_faceNodeName);
            if (faceNode is null)
            {
                log.Error("Failed to find face node");
                return false;
            }
            _node.parent = faceNode;
            _node.position = Vector3(0, 0, 0);

            FaceCameraMode  fc = FC_NONE;
            _bbSet.faceCameraMode = fc;
            if (effect_desc.Get("allow_rotation").isBool)
            {
                // fc = FC_LOOKAT_XYZ;
                _allow_rotation = effect_desc.Get("allow_rotation").GetBool();
            }


            if (HasRelativeValue(_size) || HasRelativeValue(_offset))
            {
                SubscribeToEvent("SrcFrameUpdate", "HandleSrcFrameUpdate");
            }
            SubscribeToEvent("UpdateFacePOI", "UpdateFacePOI");
        }
        else if (_anchor == "ar_background")
        {
            Node@ ar_node = scene.GetChild("ar_background");

            _node.parent = ar_node;
            Billboard@ bb = _bbSet.billboards[0];

            bb.position = Vector3(_offset[0].pix, _offset[1].pix, _offset[2].pix);
            bb.size = Vector2(_size[0].pix, _size[1].pix);

            bb.enabled = true;
            _bbSet.Commit();

            //SubscribeToEvent(E_SRCFRAMEUPDATE, URHO3D_HANDLER(PatchEffect, HandleSrcFrameUpdate));
        }
        else
        {
            log.Error("Invalid anchor name: " + _anchor);
            return false;
        }

        if (_visibleType == VISIBLE_MOUTH_OPEN)
        {
            _SetVisible(false);

            Array<String> events = { "mouth_open" , "mouth_close" };
            Array<String> actions = { "show_action" , "hide_action" };
            Array<String> delayParam = { "show_delay", "hide_delay" };

            for (uint i = 0; i < events.length; i++)
            {
                // Added mouth events/actions.
                BaseEffect@ baseEvent = AddChildEffect(events[i]);

                if (baseEvent is null)
                {
                    log.Error("patch: Cannot create " + events[i]);
                    return false;
                }

                String json;

                if (effect_desc.Contains(delayParam[i]))
                {
                    json = "{ \"name\" : \"" + actions[i] + "\"," +
                        "\"delay\":" + effect_desc.Get(delayParam[i]).GetFloat() + "}";
                }
                else
                {
                    json = "{ \"name\" : \"" + actions[i] + "\" }";
                }


                JSONFile@ jsonFile = JSONFile();

                jsonFile.FromString(json);

                if (!baseEvent.Init(jsonFile.GetRoot(), this))
                {
                    log.Error("Cannot init mouthOpen for patch");
                    return false;
                }

                //hideAction.SetParameter("delay", Variant(effect_desc.Get(delayParam[i]).GetFloat()));
            }

        }
        else if (_visibleType == VISIBLE_ANIMATION)
        {
            animationVisible = AddChildEffect("animation_visible");

            if (animationVisible is null)
            {
                log.Error("patch: Cannot create animation_visible for patch");
                return false;
            }

            if (!animationVisible.Init(this))
            {
                log.Error("patch: Cannot init animation_visible for patch");
                return false;
            }
        }
        

        Array<String> reservedField = { "texture", "size", "offset", "rotation" };
        _inited = LoadAddons(effect_desc, reservedField);

        return _inited;
    }

    String GetName() override
    {
        return "patch";
    }

    void Update(float timeDelta)
    {
        if (!_inited)
        {
            return;
        }

        if (_visibleType == VISIBLE_ALWAYS)
        {
            _SetVisible(_visible);
        }
        else if (_visibleType == VISIBLE_FACE)
        {
            _SetVisible(maskengine.IsFaceDetected(_faceIdx) && _visible);
        }
        else if (_visibleType == VISIBLE_ANIMATION)
        {
            if (_face_anchor)
                _SetVisible(maskengine.IsFaceDetected(_faceIdx) && _visible);
            else
                _SetVisible(_visible);

            animationVisible.Apply();
        }

        if (!_node.enabled)
        {
            return;
        }

        if (_anchor == "fullscreen")
        {
            return;
        }
        if (_anchor == "ar_background")
        {
            return;
        }

        if (_face_anchor)
        {
            if (poiData[_faceIdx]["PoiMap"].GetVariantMap().Contains(_anchor) &&
                poiData[_faceIdx]["Detected"].GetBool())
            {
                Vector3     anchor_point = poiData[_faceIdx]["PoiMap"].GetVariantMap()[_anchor].GetVector3();

                Billboard@ bb = _bbSet.billboards[0];
                bb.size = GetPositionValue2D(_size, _lastRTSize);
                _node.position = anchor_point + GetPositionValue3D(_offset, _lastSourceFrame);
                // bb.position = anchor_point + GetPositionValue3D(_offset, _lastSourceFrame);
                bb.enabled = true;
                _bbSet.Commit();
                
                if (!_allow_rotation) 
                {
                    _node.rotation = _node.parent.rotation.Inverse() * _rotateOrigin;
                }
            }
            else
            {
                _SetVisible(false);
            }
        }
    }

    void HandleSrcFrameUpdate(StringHash eventType, VariantMap& eventData)
    {
        Vector2 size = eventData["TargetSize"].GetVector2();
        Vector2 sourceFrame = eventData["Size"].GetVector2();

        int   angle = int(0.5 + eventData["Angle"].GetFloat());

        if (angle == 90 || angle == 270)
        {
            size = Vector2(size.y, size.x);
            sourceFrame = Vector2(sourceFrame.y, sourceFrame.x);
        }

        _lastRTSize = size;
        _lastSourceFrame = sourceFrame;

        if (_anchor == "fullscreen")
        {
            _bbSet.billboards[0].size = GetFullscreenSize(size, sourceFrame);

            ApplyFitMode(_bbSet.billboards[0], size);

            _bbSet.Commit();
        }
        else
        {
            ScreenPatchAnchor@ screenAnchor = FindScreenAnchor(_anchor);
            if (screenAnchor !is null)
            {
                Billboard@ bb = _bbSet.billboards[0];
                bb.position = Vector3(sourceFrame * screenAnchor.position, 0.0f) + GetPositionValue3D(_offset, sourceFrame);
                bb.size = GetPositionValue2D(_size, sourceFrame / 2.0);
            }

            _bbSet.Commit();
        }
    }

    void UpdateFacePOI(StringHash eventType, VariantMap& eventData)
    {
        uint faceIndex = eventData["NFace"].GetUInt();
        poiData[faceIndex] = eventData;
    }


    Node@ GetNode(uint index) override
    {
        return index == 0 ? _node : null;
    }

    void _SetVisible(bool visible) override
    {
        _node.enabled = visible;
    }

    Vector2 GetFullscreenSize(const Vector2& renderTargetSize, const Vector2& sourceFrame)
    {
        Vector2 fullScreenSize = renderTargetSize;
        if (renderTargetSize.y > 0.0f && sourceFrame.y > 0.0f && renderTargetSize.x > 0.0f && sourceFrame.x > 0.0f)
        {
            float rtAspect = renderTargetSize.x / renderTargetSize.y;
            float sfAspect = sourceFrame.x / sourceFrame.y;

            // We can have different aspect of render target and projection.
            // Fix fullscreen size to cover whole screen.
            if (rtAspect < sfAspect)
            {
                fullScreenSize = Vector2(fullScreenSize.y * sfAspect, fullScreenSize.y);
            }
            else
            {
                fullScreenSize = Vector2(fullScreenSize.x, fullScreenSize.x / sfAspect);
            }
        }

        return fullScreenSize;
    }

    bool HasRelativeValue(const Array<BillboardPosition> position)
    {
        bool res = false;
        for (uint i = 0; i < position.length; ++i)
        {
            res = res || position[i].w != 0.0f || position[i].h != 0.0f || position[i].max != 0.0f || position[i].min != 0.0f;
        }
        return res;
    }

    Vector2 GetPositionValue2D(Array<BillboardPosition>& position, const Vector2& frameSize)
    {
        return Vector2(GetPositionValue1D(position[0], frameSize), GetPositionValue1D(position[1], frameSize));
    }

    Vector3 GetPositionValue3D(Array<BillboardPosition>& position, const Vector2& frameSize)
    {
        return Vector3(GetPositionValue2D(position, frameSize), GetPositionValue1D(position[2], frameSize));
    }

    float GetPositionValue1D(BillboardPosition& position, const Vector2& frameSize)
    {
        return position.w * frameSize.x + position.h * frameSize.y + position.pix +
            position.max * Max(frameSize.x, frameSize.y) + position.min * Min(frameSize.x, frameSize.y);
    }

    void ApplyFitMode(Billboard@ billboard, const Vector2& frameSize)
    {
        Vector2 pixelSize(_size[0].pix, _size[1].pix);

        if (!_fitMode.empty && _anchor == "fullscreen" && pixelSize.x > 0.0 && pixelSize.y > 0.0)
        {
            float screenAspect = frameSize.x / frameSize.y;
            float imageAspect = pixelSize.x / pixelSize.y;

            if (_fitMode == "crop")
            {
                if (screenAspect > imageAspect)
                {
                    // Crop by Y.
                    float delta = (1.0f - imageAspect / screenAspect);
                    float borderSize = delta / 2.0f;
                    billboard.uv = Rect(0.0f, borderSize, 1.0f, 1.0f - borderSize);
                }
                else
                {
                    // Crop by X.
                    float delta = (1.0f - screenAspect / imageAspect);
                    float borderSize = delta / 2.0f;

                    billboard.uv = Rect(borderSize, 0.0f, 1.0f - borderSize, 1.0f);
                }
            }
            else if (_fitMode == "pad")
            {
                if (screenAspect > imageAspect)
                {
                    // Pad X.
                    billboard.size = Vector2(frameSize.y * imageAspect, frameSize.y);
                }
                else
                {
                    // Pad Y.
                    billboard.size = Vector2(frameSize.x, frameSize.x / imageAspect);
                }
            }
        }
        else if ((_fitMode == "crop" || _fitMode == "pad") && (pixelSize.x <= 0.0 || pixelSize.y <= 0.0))
        {
            log.Error("Path has fit mode: " + _fitMode + ", but size is not set. Fit Mode does not work!");
        }
    }

    void Unload() override
    {
        BaseEffectImpl::Unload();
        @_texture = null;
    }

    BaseAnimation@ GetAnimation() override
    {
        if (_texture is null)
            return null;

        BaseAnimation@ animation = _texture.GetAnimation();
        if (animation is null)
            return null;

        return animation;
    }

    String GetTextureFile() override
    {
        if (_texture is null)
            return "";
        
        return _texture.GetTextureFile();
    }
}

}