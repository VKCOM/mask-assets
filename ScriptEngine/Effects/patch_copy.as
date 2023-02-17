#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

String VISIBLE_FACE = "face";
String VISIBLE_ALWAYS = "always";
String VISIBLE_ANIMATION = "animation";
String VISIBLE_MOUTH_OPEN = "mouth_open";

class patch_copy : BaseEffectImpl
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
    Array<VariantMap> poiData;
    BaseEffect@ animationVisible;
    String tag;
    Texture2D@ copy;

    patch_copy()
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

        tag = effect_desc.Get("tag").GetString();

        if(tag.empty) {
            
            return false;
        }  
        copy  = Texture2D();
        copy.name = tag;
        cache.AddManualResource(copy);

        

        // append render path
        if (!CustomAppendRenderPath())
        {
            return false;
        }

        _anchor = effect_desc.Get("anchor").GetString();
        if (_anchor.empty)
        {
            
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
           
            return false;
        }

        


        if(effect_desc.Contains("texture")) 
        {
            if (!_texture.Init(effect_desc.Get("texture"), this))
            {
              
                return false;
            }
        } else {
            JSONFile@ jsonFile = JSONFile();
            jsonFile.FromString("{}");
            _texture.Init(jsonFile.GetRoot(), this);
          
        }


        AddTags(effect_desc, _node);

        ScreenPatchAnchor@  screenAnchor = FindScreenAnchor(_anchor);

        if(effect_desc.Get("rotation").isArray) {
            JSONValue rotation = effect_desc.Get("rotation");
            Quaternion rotateOrigin;
            rotateOrigin.FromEulerAngles(rotation[0].GetFloat(), rotation[1].GetFloat(), rotation[2].GetFloat());
            _node.rotation = rotateOrigin;
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
                
                return false;
            }
            _node.parent = faceNode;
            _node.position = Vector3(0, 0, 0);

            FaceCameraMode  fc = FC_NONE;
            if (effect_desc.Get("allow_rotation").isBool && !effect_desc.Get("allow_rotation").GetBool())
            {
                fc = FC_LOOKAT_XYZ;
            }
            _bbSet.faceCameraMode = fc;

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
                    json = actions[i];
                }

                JSONFile@ jsonFile = JSONFile();
                jsonFile.FromString(json);

                if (!baseEvent.Init(jsonFile.GetRoot(), this))
                {
                    
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
             
                return false;
            }

            if (!animationVisible.Init(this))
            {
                
                return false;
            }
        }
        
        SubscribeToEvent("SrcFrameUpdate", "HandleSrcFrameUpdate");

        Array<String> reservedField = { "texture", "size", "offset", "rotation" };
        _inited = LoadAddons(effect_desc, reservedField);

        

        return _inited;
    }

    bool CustomAppendRenderPath() 
    {

        RenderPath@ defaultRP = renderer.viewports[0].renderPath;

        XMLFile@ customXMLFile = XMLFile();

        String customXMLString =
        "<renderpath>" + 
            "<command type=\"scenepass\" pass=\"viewportblend\" output=\"" + tag + "\" >" + 
                "<texture unit=\"diffuse\" name=\"viewport\" />" +
                "<texture unit=\"normal\" name=\"savedViewport\" />" +
            "</command>" + 
        "</renderpath>";

        // Print(customXMLFile.ToString());
        
        if(!customXMLFile.FromString(customXMLString)) 
        {
           
            return false;
        }   


        RenderPath customRP;
        if (!customRP.Load(customXMLFile))
        {
           
            return false;
        } 

        // increase render idx 
        int current_rp_idx = GetGlobalVar(CURRENT_RP_IDX).GetInt();
        _renderPassIdx = current_rp_idx;
        SetGlobalVar(CURRENT_RP_IDX, Variant(_renderPassIdx + 1));
        SetGlobalVar(PREVIOUS_RP_IDX, Variant(_renderPassIdx));
        String  suffix = _renderPassIdx >= 0 ? String(_renderPassIdx) : String("");


        // inserting commands to defaultRenderPath from customRP
        for (uint index = 0; index < customRP.numCommands; index++)
        {
            RenderPathCommand command = customRP.commands[index];
            command.pass = command.pass + suffix;
            command.tag = command.tag + suffix;
            defaultRP.AddCommand(command);
        }

        for (uint index = 0; index < customRP.numRenderTargets; index++)
        {
            defaultRP.AddRenderTarget(customRP.renderTargets[index]);
        }

        return true;
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
                bb.position = anchor_point + GetPositionValue3D(_offset, _lastSourceFrame);
                bb.size = GetPositionValue2D(_size, _lastRTSize);
                bb.enabled = true;
                _bbSet.Commit();
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
        
        if (_lastRTSize != size)
        {
            copy.SetSize(int(size.x), int(size.y), GetRGBAFormat(), TEXTURE_RENDERTARGET);
            copy.name = tag;
            cache.AddManualResource(copy);
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
           
        }
    }

    void Unload() override
    {
        BaseEffectImpl::Unload();
        @_texture = null;
    }
}

}