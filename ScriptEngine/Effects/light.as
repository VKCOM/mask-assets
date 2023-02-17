#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class light : BaseEffectImpl
{
    Node@ _node;
    Node@ _anchorNode;
    Array<VariantMap> poiData;
    String _anchor;

    light()
    {
        poiData.Resize(MAX_FACES);
    }

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
        {
            return false;
        }

        String type = effect_desc.Get("type").GetString();

        LightType   light_type = LIGHT_DIRECTIONAL;

        if (type == "direct")
            light_type = LIGHT_DIRECTIONAL;
        else if (type == "spot")
            light_type = LIGHT_SPOT;
        else if (type == "point")
            light_type = LIGHT_POINT;
        else if (type == "ambient")
            return InitAmbientLight(effect_desc);
        else {
            log.Error("Invalid light type '" + type + "'");
            return false;
        }

        if (light_type == LIGHT_DIRECTIONAL)
        {
            _node = scene.CreateChild("Light");
        }
        else
        {
            _anchor = effect_desc.Get("anchor").GetString();

            if (_anchor.empty)
            {
                _node = scene.CreateChild("Light");
            }
            else
            {
                Node@ faceNode = scene.GetChild(_faceNodeName);
                if (faceNode !is null)
                {
                    return false;
                }
                _anchorNode = faceNode.CreateChild("Light_anchor");
                _node = _anchorNode.CreateChild("Light");

                SubscribeToEvent("UpdateFacePOI", "UpdateFacePOI");
            }
        }


        // Init position/rotation/direction/scale
        {
            Vector3 pos(0.0f, 0.0f, 0.0f);
            ReadVector3(effect_desc.Get("position"), pos);
            _node.worldPosition = pos;
        }

        {
            Vector3 rot(0.0f, 0.0f, 0.0f);
            if (ReadVector3(effect_desc.Get("rotation"), rot))
            {
                _node.rotation = Quaternion(rot.x, rot.y, rot.z);
            }
        }


        {
            Vector3 dir(0.0f, 0.0f, 1.0f);
            if (ReadVector3(effect_desc.Get("direction"), dir))
            {
                _node.direction = dir;
            }
        }

        {
            Vector3 scale(1.0f, 1.0f, 1.0f);
            ReadVector3(effect_desc.Get("scale"), scale);
            _node.scale = scale;
        }


        AddTags(effect_desc, _node);


        Light@ light = _node.CreateComponent("Light");
        light.lightType = light_type;
        light.range = 500.0f;

        {
            Vector3 color;
            if (ReadVector3(effect_desc.Get("color"), color))
            {
                light.color = Color(color.x, color.y, color.z);
            }
        }

        if (effect_desc.Get("specular_intensity").isNumber)
        {
            light.specularIntensity = effect_desc.Get("specular_intensity").GetFloat();
        }

        if (effect_desc.Get("brightness").isNumber)
        {
            light.brightness = effect_desc.Get("brightness").GetFloat();
        }

        if (effect_desc.Get("range").isNumber)
        {
            light.range = effect_desc.Get("range").GetFloat();
        }

        if (effect_desc.Get("fov").isNumber)
        {
            light.fov = effect_desc.Get("fov").GetFloat();
        }

        Array<String> reservedField;
        _inited = LoadAddons(effect_desc, reservedField);


        return _inited;
    }

    bool InitAmbientLight(const JSONValue& effect_desc)
    {
        Node@ zoneNode = scene.GetChild("Zone");
        if (zoneNode is null)
        {
            log.Error("light: cannot find Zone node");
            return false;
        }

        Zone@ zone = zoneNode.GetComponent("Zone");
        if (zone is null)
        {
            log.Error("light: cannot find Zone component");
            return false;
        }

        Vector3 color;
        if (ReadVector3(effect_desc.Get("color"), color))
        {
            zone.ambientColor = Color(color.x, color.y, color.z);
        }

        return true;
    }

    void Update(float timeDelta)
    {
        if (!_inited)
        {
            return;
        }

        if (!_anchor.empty && _anchorNode !is null)
        {
            bool faceDetected = maskengine.IsFaceDetected(_faceIdx);
            _SetVisible(faceDetected);
            if (!faceDetected)
            {
                return;
            }

            if (_anchor != "face")
            {
                if (poiData[_faceIdx]["PoiMap"].GetVariantMap().Contains(_anchor) &&
                    poiData[_faceIdx]["Detected"].GetBool())
                {
                    Vector3     anchor_point = poiData[_faceIdx]["PoiMap"].GetVariantMap()[_anchor].GetVector3();

                    _anchorNode.position = anchor_point;
                }
                else
                {
                    _SetVisible(false);
                }
            }
        }
    }

    Node@ GetNode(uint index) override
    {
        return index == 0 ? _node : null;
    }

    void _SetVisible(bool visible) override
    {
        _node.enabled = visible;
    }

    String GetName() override
    {
        return "light";
    }

    void UpdateFacePOI(StringHash eventType, VariantMap& eventData)
    {
        uint faceIndex = eventData["NFace"].GetUInt();
        poiData[faceIndex] = eventData;
    }
}

}