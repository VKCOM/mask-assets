#include "ScriptEngine/Plugins/BasePlugin.as"


float clamp(float value, float lo, float hi)
{
    return value < lo ? lo : value > hi ? hi : value;
}

float bihFilter(float new, float old, float k)
{
    return k * new + (1 - k) * old;
}


class Face
{
    Node@ _face;

    Vector3 _oldPos;
    Vector3 _oldRot;

    float k_rot_l = 1.55f;
    float k_rot_r = 1.5f;
    float k_rot_u = 1.0f;
    float k_rot_d = 1.0f;
    float offset = 0.7f;

    float last_rot_x = 0.0;

    Face(String face_tag)
    {
        _face = scene.GetChild(face_tag);
        SubscribeToEvent("Update", "HandleUpdate");
    }

    void SetRotationParameters(Array<float> parameters)
    {
        if (parameters.length == 4)
        {
            for (uint i = 0; i < 4; i++)
                parameters[i] = clamp(parameters[i], 0.0, 1.0);
            
            k_rot_l = parameters[0] + 1.0;
            k_rot_r = parameters[1] + 1.0;
            k_rot_u = parameters[2] + 1.0;
            k_rot_d = parameters[3] + 1.0;
        }
    }

    void SetOffset(float value)
    {
        offset = clamp(value, 0.01, 1.0);
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        // Position smoothing
        _face.position = Vector3(
            bihFilter(_face.position.x, _oldPos.x, offset), 
            bihFilter(_face.position.y, _oldPos.y, offset), 
            bihFilter(_face.position.z, _oldPos.z, offset)
        );
        _oldPos = _face.position;

        float rotX = _face.rotation.eulerAngles.x;
        float rotY = _face.rotation.eulerAngles.y;
        float rotZ = _face.rotation.eulerAngles.z;

        // Rotation amplification factors
        float k_x = rotX > 0 ? k_rot_u : k_rot_d;
        float k_y = rotY > 0 ? k_rot_l : k_rot_r;

        // Rotation corections
        float _corr_x = 0.0;
        float _corr_z = 0.0;
        if (Abs(rotY) > 15.0)
        {
            _corr_x = 3.5 * rotX * 0.1;
            _corr_z = 1.5 * Sign(_face.rotation.y)
                    + (Abs(rotY) - 15.0)
                    * Abs(rotX)
                    * Sign(_face.rotation.y)
                    * -0.03;
        }
        _face.rotation = Quaternion(
            rotX - _corr_x,
            rotY,
            rotZ - _corr_z
        );

        // Rotation smoothing
        _face.rotation = Quaternion(
            bihFilter(_face.rotation.eulerAngles.x * k_x,   _oldRot.x, 0.25), 
            bihFilter(_face.rotation.eulerAngles.y * k_y,   _oldRot.y, 0.40), 
            bihFilter(_face.rotation.eulerAngles.z,         _oldRot.z, 0.65)
        );
        _oldRot = _face.rotation.eulerAngles;
    }
}


class fixeddetection : BasePlugin
{
    String pluginName = "fixeddetection";

    uint nr_faces;
    Face@ face0;
    Face@ face1;

    Array<float> rotationConfiguration;
    float offsetConfiguration;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        // Use it to retrieve effects from mask
        // if (mask is null)
        // {
        //     log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
        //     return false;
        // }

        // Disable for face model 2 and more
        if (GetGlobalVar("facemodel_version").GetInt() >= 2) {
            return true;
        }

        LoadSettings(plugin_config);

        if (nr_faces != 0)
        {
            face0 = Face("Face");
            face0.SetRotationParameters(rotationConfiguration);
            face0.SetOffset(offsetConfiguration);
            
            if (nr_faces == 2)
            {
                face1 = Face("Face1");
                face1.SetRotationParameters(rotationConfiguration);
                face1.SetOffset(offsetConfiguration);
            }
        }

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
         // Number of faces from 'mask.json'
        JSONFile maskJson;
        maskJson.Load(cache.GetFile("mask.json"));  
        JSONValue jsonRoot = maskJson.GetRoot();
        if (jsonRoot.Contains("num_faces"))
            nr_faces = jsonRoot.Get("num_faces").GetInt();
        else
            nr_faces = 99;

        // Other parameters from 'PluginConfiguration.json'
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            // Rotation
            if (plugin_config.Contains("rotation"))
            {
                JSONValue rotation = plugin_config.Get("rotation");
                if (rotation.isArray && rotation.size == 4)
                    for (uint i = 0; i < 4; i++)
                        rotationConfiguration.Push(rotation[i].GetFloat());
            }

            // Offset
            if (plugin_config.Contains("offset"))
            {
                offsetConfiguration = plugin_config.Get("offset").GetFloat();
            }
        }
    }
    
}
