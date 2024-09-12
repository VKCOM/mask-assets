#include "ScriptEngine/Effects/Base/BaseEffect.as"
#include "ScriptEngine/Effects/Base/BaseAnimation.as"
#include "ScriptEngine/Utils.as"


namespace MaskEngine
{

/* Class for animating 3D model's textures.
 */
class model_texture_animation
{
    // Handler to material that has ONE type of texture that should be animated 
    Material@ material;
    // All paths to texture files for animation
    Array<String> texturePaths;
    // A type of texture from Urho3D AngelScript API
    TextureUnit texture_type;
    // Either 'once' or 'loop'
    String animation_type;
    // Either `Texture2D` for *.png or `TextureCube` for *.xml
    String texture_resource;

    // From artist's settings in 'mask.json'
    String trigger_start = "";
    String trigger_stop = "";
    float fps = 30.0;

    // Runtime variables
    private bool hasTimeline = false;
    private bool isWaitingForTrigger = true;
    private bool running = false;
    private float elapsedTime = 0.0;
    private float duration;
    private ValueAnimation animation;

    // Construct with neccessary parameters
    model_texture_animation(Material@ mat, String& type, JSONValue& texture_desc)
    {
        material = mat;

        if (type == "diffuse")
            texture_type = TU_DIFFUSE;
        else if (type == "normal")
            texture_type = TU_NORMAL;
        else if (type == "specular")
            texture_type = TU_SPECULAR;
        else if (type == "environment")
            texture_type = TU_ENVIRONMENT;
        else if (type == "emissive")
            texture_type = TU_EMISSIVE;
        else
            log.Error("model3d: Unexpected material type for texture animation.");

        // Parse animation parameters from 'mask.json'
        if (!parse_description(texture_desc))
            log.Error("model3d: Could not parse material textures.");

        if (hasTimeline)
            duration = animation.GetEndTime() - animation.GetBeginTime();
        else if (fps > 0.0)
            duration = texturePaths.length / fps;
        else
        {
            log.Error("model3d: Unexpected fps value for material texture animation.");
            return;
        }

        if (texture_desc.Contains("animation") && trigger_start == "")
            start();

        if (trigger_start == "tap" || trigger_stop == "tap")
            SubscribeToEvent("MouseEvent", "HandleTapEvent");

        if (trigger_start == "face_found" || trigger_stop == "face_lost")
            SubscribeToEvent("UpdateFaceDetected", "HandleFaceDetected");

        if (trigger_start == "mouth_open")
            SubscribeToEvent("MouthTrigger", "HandleMouthTrigger");

        if (HAND_GESTURE_NAMES.Find(trigger_start) != -1 || HAND_GESTURE_NAMES.Find(trigger_stop) != -1)
            SubscribeToEvent("UpdateHandGesture", "HandleUpdateHandGesture");

        SubscribeToEvent("Update", "HandleUpdate");
    }

    private void HandleMouthTrigger(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["NFace"].GetUInt() != 0 || !eventData["Opened"].GetBool())
            return;

        if (!running)
            start();
    }

    private bool parse_description(JSONValue& texture_desc)
    {
        if (texture_desc.Contains("texture"))
        {
            String pathToFirst = texture_desc.Get("texture").GetString();
            String path = GetPath(pathToFirst);
            String file = GetFileName(pathToFirst);
            String extension = GetExtension(pathToFirst, false);
            texture_resource = extension == ".xml" ? "TextureCube" : "Texture2D";

            if (cache.Exists(pathToFirst))
                if (cache.GetResource(texture_resource, pathToFirst) !is null)
                {
                    texturePaths.Push(pathToFirst);
                }
                else
                {
                    log.Error("model3d: Failed to load texture file '" + pathToFirst + "'");
                    return false;
                }

            for (int a = 1; ; a++)
            {
                String fileName = path + file + String(a) + extension;
                if (cache.Exists(fileName))
                    if (cache.GetResource(texture_resource, fileName) !is null)
                    {
                        texturePaths.Push(fileName);
                    }
                    else
                    {
                        log.Error("model3d: Failed to load texture file '" + fileName + "'");
                        return false;
                    }
                else
                    break;
            }

            if (texture_desc.Contains("animation"))
            {
                JSONValue animation_parameters = texture_desc.Get("animation");

                if (animation_parameters.Contains("type"))
                    animation_type = animation_parameters.Get("type").GetString();
                
                if (animation_parameters.Contains("trigger_start"))
                    trigger_start = animation_parameters.Get("trigger_start").GetString();

                if (animation_parameters.Contains("trigger_stop"))
                    trigger_stop = animation_parameters.Get("trigger_stop").GetString();
                
                if (animation_parameters.Contains("fps"))
                {
                    fps = animation_parameters.Get("fps").GetFloat();
                }
                else if (animation_parameters.Contains("timeline"))
                {
                    JSONValue timeline = animation_parameters.Get("timeline");
                    if (timeline.isArray && timeline.size > 0)
                    {
                        animation.valueType = VAR_INT;
                        animation.interpolationMethod = IM_NONE;
                        float time = 0.0;

                        uint frame = 0;
                        float lastDuration = 0.0;
                        while (frame < timeline.size)
                        {
                            animation.SetKeyFrame(time * 0.001, frame);
                            lastDuration = timeline[frame].GetInt();
                            time += lastDuration;
                            frame += 1;
                        }

                        if (texturePaths.length == timeline.size)
                        {
                            animation.SetKeyFrame(time * 0.001, frame);
                        }
                        else if (texturePaths.length > timeline.size)
                        {
                            uint remaining = texturePaths.length - timeline.size;
                            for (uint i = 0; i < remaining; ++i)
                            {
                                animation.SetKeyFrame(time * 0.001, texturePaths.length - remaining + i);
                                time += lastDuration;
                            }
                            animation.SetKeyFrame((time + lastDuration) * 0.001, texturePaths.length - 1);
                        }
                    }
                    else
                    {
                        log.Error("Invalid timeline value in model3d animation");
                        return false;
                    }
                    hasTimeline = true;
                }
                else if (animation_parameters.Contains("timeline_ex"))
                {
                    JSONValue timeline_ex = animation_parameters.Get("timeline_ex");
                    if (timeline_ex.isArray && timeline_ex.size > 0)
                    {
                        animation.valueType = VAR_INT;
                        animation.interpolationMethod = IM_NONE;
                        float time = 0.0;
                        uint frame = 0;

                        for (uint i = 0; i < timeline_ex.size; ++i)
                        {
                            if (timeline_ex[i].isArray && timeline_ex[i].size == 2)
                            {
                                frame = timeline_ex[i][0].GetInt();
                                animation.SetKeyFrame(time * 0.001, frame);
                                time += timeline_ex[i][1].GetInt();
                            }
                            else
                            {
                                animation.SetKeyFrame(time * 0.001, frame);
                                time += timeline_ex[i].GetInt();
                            }
                            frame += 1;
                        }
                        animation.SetKeyFrame(time * 0.001, frame - 1);
                    }
                    else
                    {
                        log.Error("Invalid timeline_ex value in model3d animation");
                        return false;
                    }
                    hasTimeline = true;
                }
            }

            return true;
        }

        return false;
    }

    void start()
    {
        // if (animation_type == "once" && !isWaitingForTrigger)
        if (!isWaitingForTrigger)
            return;

        running = true;
        elapsedTime = 0.0;
    }

    void stop(bool waitForTrigger)
    {
        running = false;
        isWaitingForTrigger = waitForTrigger;
    }

    private void HandleTapEvent(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Event"].GetString() == "tap")
        {
            if (trigger_start == "tap" && !running)
                start();
            
            else if (trigger_stop == "tap" && running)
                stop(trigger_start != "face_found");
        }
    }

    private void HandleFaceDetected(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Detected"].GetBool())
        {
            if (trigger_start == "face_found" && !running)
                start();
        }
        else
        {
            if (trigger_stop == "face_lost" || trigger_start == "face_found" && !running)
                stop(true);
        }
    }

    private void HandleUpdateHandGesture(StringHash eventType, VariantMap& eventData)
    {
        String gesture = eventData["Gesture"].GetString().ToUpper();
        
        if (!running && trigger_start == gesture)
            start();

        if (running && trigger_stop == gesture)
            stop(trigger_start != "face_found");
    }

    private void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (running)
        {
            float dt = eventData["TimeStep"].GetFloat();
            elapsedTime += dt;

            uint frame;
            if (!hasTimeline)
            {
                frame = uint((elapsedTime * fps) % texturePaths.length);
            }
            else
            {
                float scaledTime = elapsedTime - uint(elapsedTime / duration) * duration;
                frame = animation.GetAnimationValue(scaledTime).GetInt();
            }

            if (animation_type == "once" && elapsedTime >= duration)
            // if (animation_type == "once" && frame >= texturePaths.length)
            {
                stop(trigger_start == "tap" || trigger_start == "mouth_open");
                return;
            }

            String texture_path = texturePaths[frame];
            Texture@ texture = cache.GetResource(texture_resource, texture_path);
            if (texture !is null)
            {
                if (texture_path.EndsWith(".xml"))
                    material.textures[texture_type] = cast<TextureCube>(texture);
                else
                    material.textures[texture_type] = cast<Texture2D>(texture);
            }
        }
    }

}


class model3d : BaseEffectImpl
{
    String _anchor;
    Node@ _node;
    Node@ _anchorNode;
    bool _created = false;
    Array<VariantMap> poiData;
    VariantMap handGestureData;
    Vector3 _node_initial_scale;
    Vector3 _anchor_node_initial_scale;

    // Child wiggle effect
    BaseEffect@ _wiggly;
    // Array of "materials" from mask.json
    Array<Material@> materials;
    // Texture animations for specified materials
    Array<model_texture_animation@> textureAnimations;

    AnimationController@ _animCtrl;
    BaseAnimationImpl@ baseAnimation;
    String _animFileName;
    float _animSpeed;

    Vector2 _screenSize;


    model3d()
    {
        poiData.Resize(MAX_FACES);
        @baseAnimation = BaseAnimationImpl(this);
    }

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent)
    {
        if (!BaseEffectImpl::Init(effect_desc, parent))
            return false;

        Node@ faceNode = scene.GetChild(_faceNodeName);
        if (faceNode is null)
        {
            log.Error(GetName() + ": Cannot find face node.");
            return false;
        }

        // Append render path
        if (!InitRenderPass(effect_desc.Get("pass"), MAIN_RENDER_PASS_FILE))
            return false;

        // Setup Model Anchor Node
        _anchor = effect_desc.Get("anchor").GetString();
        if (_anchor == "ar_background")
        {
            _anchorNode = scene.GetChild("ar_background");
        }
        else if (_anchor == "ar_obj")
        {
            // _anchorNode = _scene->CreateChild("ar_3d");
            _anchorNode = scene.GetChild("ar_3d");
            _anchorNode.position = Vector3(0, 0, 0);
        }
        else if (_anchor == "free")
        {
            // _anchorNode = _scene->CreateChild("ar_3d");
            _anchorNode = scene;
            _anchorNode.position = Vector3(0, 0, 0);
        }
        else if (_anchor == "palm")
        {
            _anchorNode = scene.CreateChild("palm_node");
            _anchorNode.position = Vector3(0, 0, 0);
            SubscribeToEvent("SrcFrameUpdate", "HandleSrcFrameUpdate");
            SubscribeToEvent("UpdateHandGesture", "HandleUpdateHandGesture");
        }
        else
        {
            _anchorNode = faceNode.CreateChild("anchor_model3d");
            SubscribeToEvent("UpdateFacePOI", "HandleUpdateFacePOI");
        }

        // Create Model Node
        _node = _anchorNode.CreateChild(GetName());

        // Add tags to Model Node
        AddTags(effect_desc, _node);

        // Create Model
        if (!CreateModel(effect_desc))
        {
            log.Error(GetName() + ": Failed to init Model");
            return false;
        }

        // Create Model Animation
        if (effect_desc.Contains("animation")) 
            if (!CreateAnimationModel(effect_desc.Get("animation")))
            {
                log.Error(GetName() + ": Failed to init animation");
                return false;
            }

        // Visibility Triggers
        String visibleTrigger = effect_desc.Get("visible").GetString();
        if (visibleTrigger == "mouth_open" || visibleTrigger == "mouth_close")
        {
            Array<String> events     = { "mouth_open"  , "mouth_close" };
            Array<String> actions    = { "show_action" , "hide_action" };
            Array<String> delayParam = { "show_delay"  , "hide_delay"  };
            
            if (visibleTrigger == "mouth_close")
                events.Reverse();

            for (uint i = 0; i < events.length; i++)
            {
                // Added mouth events / actions
                BaseEffect@ mouthOpen = AddChildEffect(events[i]);

                if (mouthOpen is null)
                {
                    log.Error("Cannot init mouth_open for model3d");
                    return false;
                }

                String json;

                if (effect_desc.Contains(delayParam[i]))
                    json = "{ \"name\": \"" + actions[i] + "\"," +
                        "\"delay\":" + effect_desc.Get(delayParam[i]).GetFloat() + "}";
                else
                    json = "{ \"name\": \"" + actions[i] + "\" }";

                JSONFile@ jsonFile = JSONFile();
                jsonFile.FromString(json);

                if (!mouthOpen.Init(jsonFile.GetRoot(), this))
                {
                    log.Error("Cannot init mouth_open for model3d");
                    return false;
                }
            }
            _visible = visibleTrigger == "mouth_close";
        }

        // Init position / rotation / scale
        Vector3 pos(0.0f, 0.0f, 0.0f);
        ReadVector3(effect_desc.Get("position"), pos);

        if (_anchor == "ar_background")
            _node.worldPosition = pos;
        else
            _node.position = pos;

        Vector3 rot(0.0f, 0.0f, 0.0f);
        ReadVector3(effect_desc.Get("rotation"), rot);
        if (_anchor == "palm")
            _anchorNode.rotation = Quaternion(rot.x, rot.y, rot.z);
        else
            _node.rotation = Quaternion(rot.x, rot.y, rot.z);


        Vector3 scale(1.0f, 1.0f, 1.0f);
        ReadVector3(effect_desc.Get("scale"), scale);
        _node.scale = scale;

        if (_anchor == "palm")
        {
            _node_initial_scale = _node.scale;
            _anchor_node_initial_scale = _anchorNode.scale;
        }

        _SetVisible(false);

        Array<String> reservedField;
        reservedField.Push("animation");
        reservedField.Push("material");
        
        // Wiggle injection point
        if (effect_desc.Contains("wiggle"))
        {
            @_wiggly = AddChildEffect("wiggle");
            _wiggly.Init(effect_desc, this);
        }

        _inited = LoadAddons(effect_desc, reservedField);

        return _inited;
    }

    /* Creates a `StaticModel` instance from specified file, 
     * parses materials and adds them to `materials`.
     */
    bool CreateModel(const JSONValue& effect_desc)
    {
        // Load path to model file
        String modelFilePath = effect_desc.Get("model").GetString();
        if (modelFilePath.empty)
        {
            log.Error(GetName() + ": Model file not specified");
            return false;
        }

        Model@ model = cache.GetResource("Model", modelFilePath);
        if (model is null)
        {
            log.Error(GetName() + ": Failed to load model: " + modelFilePath);
            return false;
        }

        StaticModel@ static_model = _node.CreateComponent("StaticModel");
        static_model.model = model;

        /*
            features : 
                get mats from xml file DONE
                get mats from json file DONE
                get mats from mask.jsom file DONE
                    change tequniqes to array DONE
                    change shader params to strings DONE
                apply mat to one geom DONE
                apply mat to many geoms DONE
                apply mats to same amount of geoms DONE
                    for different show error DONE
                
                material could be a string, Array<string>, object, Array<object>, mixed Array<String, object> DONE
                string path could lead to xml or json file - looks like it's not a problem at all DONE

                rewrite getMaterial -> add materials to globals DONE
                if no material specified use default one NoTexture.xml for everything DONE
                add error messages if something goes wrong DONE
                check Unload      
        */
        


        // Parse single or multiple materials
        if (effect_desc.Get("material").isArray)
        {
            for (uint i = 0; i < effect_desc.Get("material").size; i++)
            {
                Material@ mat = ParseMaterial(effect_desc.Get("material")[i]); 
                if (mat is null)
                {
                    log.Error("Could not parse one or more materials.");
                    return false;
                }
                materials.Push(mat);
            }
        }
        else
        {
            Material@ mat = ParseMaterial(effect_desc.Get("material"));
            if (mat is null)
            {
                log.Error("Could not parse one or more materials.");
                return false;
            }
            materials.Push(mat);
        }
        


        // Amount of materials should be the same as the amount of
        // geometries in the model loaded previously
        uint numGeometries = static_model.numGeometries;
        uint numMaterials = materials.length;
        if (numMaterials > 1 && numGeometries != numMaterials)
        {
            log.Error(GetName() + ": Invalid number of materials for 3d model '" + modelFilePath
                + "' (it has " + numGeometries + " and you specify "
                + numMaterials + ")");
            return false;
        }

        // Apply materials to model's geometries
        for (uint m = 0; m < numGeometries; m++)
        {
            Material@ material;
            if (numMaterials > 1)
                material = materials[m];
            else
                // applying one mat or fallback NoTexutre.xml for every geometry 
                material = materials[0];

            // apply render pass idx
            if (_renderPassIdx >= 0)
            {
                material = material.Clone();
                for (uint i = 0; i < material.numTechniques; i++)
                {
                    Technique@ orig_t = material.techniques[i];
                    Technique@ tech_clone = orig_t.ClonePrefix("", String(_renderPassIdx));
                    material.SetTechnique(i, tech_clone);
                }
            }

            static_model.materials[m] = material;
        }

        _created = true;
        return true;
    }

    /* Parses `parameters` and `techniquies` of a material.
     */
    Material@ ParseMaterial(JSONValue material_desc)
    {
        Material@ material;
        if (material_desc.isObject)
        {
            /* --------------------------------------------------------- */
            /*  The next block is required, to make material settings    */
            /*  look the same as everithing else in mask.json.           */

            material = Material();

            // 1. Parsing parameters
            JSONValue parameters = material_desc.Get("parameters");

            // Erase parameters from JSON object to replace their values
            // with `String` representations of `Vector4`, and
            // add back to `material_desc` as 'shaderParameters'.
            material_desc.Erase("parameters");

            Array<String> keys = parameters.GetFields();
            for (uint i = 0; i < keys.length; i++)
            {
                // TO-DO or default behavior ???
                // Could be the case when length is zero, ex - Metallic 

                String key = keys[i];
                JSONValue value = parameters.Get(key);
                String valueString = "";

                if (value.isArray) 
                {
                    // Make string from array ("aka Vector4" - rgba)
                    for (uint j = 0; j < value.size; j++)
                        valueString += value[j].GetFloat() + " ";

                } 
                else if (value.isNumber)
                {
                    valueString += value.GetFloat() + "";

                } else 
                {
                    log.Warning("model3d : material parameter \"" + key + "\" unsupported type.");
                }

                // Replace `Vector4` with string
                parameters.Set(key, JSONValue(valueString));
                
            }

            material_desc.Set("shaderParameters", parameters);

            // 2. Parsing techinques
            JSONFile techniquesFile;
            techniquesFile.FromString("{\"techniques\": [{\"name\": \"" + material_desc.Get("technique").GetString() + "\"}]}");
            material_desc.Set("techniques", techniquesFile.GetRoot().Get("techniques"));
            material_desc.Erase("technique");

            // 3. Parse textures and make them compatible with Urho3D
            JSONValue textures = material_desc.Get("textures");
            material_desc.Erase("textures");

            // `keys` are texture types - diffuse, normal, specular, environment or emissive.
            keys = textures.GetFields();
            for (uint i = 0; i < keys.length; i++)
            {
                String key = keys[i];
                JSONValue value = textures.Get(key);
                String valueString;


                // Animation is NOT specified for this texture
                if (value.isString) {
                    valueString = value.GetString();
                }
                // Animation IS specified for this texture
                else if (value.isObject)
                {
                    if (value.Contains("texture"))
                    {
                        valueString = value.Get("texture").GetString();
    
                        textureAnimations.Push(
                            model_texture_animation(material, key, value)
                        );
                    }
                }

                // will not support animation_textures for now ...
                if (key == "environment") 
                {
                    valueString = PreprocessEnvTexture(valueString);
                } 

                textures.Set(key, JSONValue(valueString));
            }

            // Reset 'textures' with JSON value compatible with Urho3D
            material_desc.Set("textures", textures);

            // 4. Load material from JSON description that now includes:
            //  - shaderParameters,
            //  - techniques and
            //  - textures.
            material.Load(material_desc);
        }
        else if (material_desc.isString)
        {
            material = cache.GetResource("Material", material_desc.GetString());
        } 

        return material;
    }

    /* Will do something good)))
    */
    String PreprocessEnvTexture(String envTexture) {

        //  if xml file exist then use it 
        //  else will create 
        // if need to disable use xml with Texture2D type
        String extension = GetExtension(envTexture, false);
        if (extension == ".xml" || !cache.Exists(envTexture) ) return envTexture;

        String path = GetPath(envTexture);
        String xmlFileFullPath = ReplaceExtension(envTexture, ".xml"); // ??? will do cross platform ???
        String xmlFileName = GetFileName(xmlFileFullPath);

        // does support vertical layout?
        String envTextureXMLString = 
        "<cubemap>" +
            "<image name=\"" + xmlFileName + extension + "\" layout=\"horizontal\" />" +
        "</cubemap>";

        XMLFile envXMLFile;
        envXMLFile.FromString(envTextureXMLString);
        
        File@ file = File(xmlFileFullPath, FILE_WRITE);

        envXMLFile.Save(file);
        log.Error(file.name);
        file.Close(); // NOTE! always close files

        return xmlFileFullPath;
    }

    /* Parses `animation` of a model description, creates `AnimationModel`
     * instead of `StaticModel`, copying all of its materials to it.
     */
    bool CreateAnimationModel(const JSONValue& ani_desc)
    {
        // Parse parameters from mask.json
        if (!ani_desc.Get("file").isString)
        {
            log.Error(GetName() + ": Animation file should be a the path to animation file");
            return false;
        }

        _animFileName = ani_desc.Get("file").GetString();
        _animSpeed = ani_desc.Get("speed").isNumber ? ani_desc.Get("speed").GetFloat() : 1.0;
        String type = ani_desc.Get("type").isString ? ani_desc.Get("type").GetString() : "once";
        bool loop = (type == "loop");
        float fadeInTime = 0.0;

        // Setup Urho3D `AnimationModel`
        StaticModel@ staticModel = _node.GetComponent("StaticModel");
        AnimatedModel@ animatedModel = _node.CreateComponent("AnimatedModel");
        animatedModel.updateInvisible = true;
        animatedModel.model = staticModel.model;
        animatedModel.lightMask = staticModel.lightMask;

        for (uint i = 0; i < staticModel.numGeometries; i++)
            animatedModel.materials[i] = staticModel.materials[i];

        _node.RemoveComponent("StaticModel");

        // Setup Urho3D `AnimationController`
        _animCtrl = _node.CreateComponent("AnimationController");
        _animCtrl.PlayExclusive(_animFileName, 0, loop, fadeInTime);
        _animCtrl.SetTime(_animFileName, 0.0);
        _animCtrl.SetSpeed(_animFileName, 0.0);

        String triggerStart = ani_desc.Get("trigger_start").GetString();
        String triggerStop = ani_desc.Get("trigger_stop").GetString();


        SubscribeToEvent(START_ANIMATION_EVENT, "HandleStartAnimation");
        SubscribeToEvent(STOP_ANIMATION_EVENT, "HandleStopAnimation");
        SubscribeToEvent(SET_TIME_ANIMATION_EVENT, "HandleSetTimeAnimation");

        // Create events for start and stop triggers
        if (!triggerStart.empty)
        {
            // Create only one event with 'switch_animation' if
            // 'triggerStart' not empty and equal to 'triggerStop'
            if (triggerStart == triggerStop)
            {
                BaseEffect@ binaryEvent = AddChildEffect(triggerStart);
                if (binaryEvent is null)
                    return false;

                String json;
                if (ani_desc.Contains("show_delay"))
                    json = "{ \"name\" : \"switch_animation\"," +
                        "\"delay\":" + ani_desc.Get("show_delay").GetFloat() + "}";
                else
                    json = "{ \"name\" : \"switch_animation\"}";

                JSONFile@ jsonFile = JSONFile();
                jsonFile.FromString(json);

                // Call `Init` method of `BaseEvent` class
                if (!binaryEvent.Init(jsonFile.GetRoot(), this))
                {
                    log.Error(GetName() + ": Cannot init " + triggerStart);
                    return false;
                }
            }

            // Create event for start action and, possibly, 
            // event for stop action, if 'triggerStop' is not empty
            else
            {
                // 1. Start event
                // Create instance of one of the `BaseEvent` subclasses
                BaseEffect@ startEvent = AddChildEffect(triggerStart);
                if (startEvent is null)
                    return false;

                String json;
                if (ani_desc.Contains("show_delay"))
                    json = "{ \"name\" : \"start_animation\"," +
                        "\"delay\":" + ani_desc.Get("show_delay").GetFloat() + "}";
                else
                    json = "{ \"name\" : \"start_animation\"}";

                JSONFile@ startJsonFile = JSONFile();
                startJsonFile.FromString(json);

                // Call `Init` method of `BaseEvent` class
                if (!startEvent.Init(startJsonFile.GetRoot(), this))
                {
                    log.Error(GetName() + ": Cannot init " + triggerStart);
                    return false;
                }

                // This instance of `model3d` is now DIRECT parent for both
                // 'startEvent' and its child action.

                // 2. Stop event
                if (!triggerStop.empty)
                {
                    BaseEffect@ stopEvent = AddChildEffect(triggerStop);
                    if (stopEvent is null)
                        return false;

                    json;
                    if (ani_desc.Contains("hide_delay"))
                        json = "{ \"name\" : \"stop_animation\"," +
                            "\"delay\":" + ani_desc.Get("hide_delay").GetFloat() + "}";
                    else
                        json = "{ \"name\" : \"stop_animation\"}";

                    JSONFile@ stopJsonFile = JSONFile();
                    stopJsonFile.FromString(json);

                    if (!stopEvent.Init(stopJsonFile.GetRoot(), this))
                    {
                        log.Error(GetName() + ": Cannot init " + triggerStop);
                        return false;
                    }
                }
            }
        }

        // Start animation without any controlling events
        else
        {
            baseAnimation.Play();
        }

        // Just to ask Urho3D if animation has performed once.
        // Without it, there's no way Urho3D animation controller
        // can notify our 'BaseAnimation' that it is not playing.
        // 'BaseAnimationAction's cannot do that either.
        SubscribeToEvent("PostUpdate", "HandlePostUpdate");

        return true;
    }



    /* -------------------------------------------------------------------------- */
    /*                                Subscriptions                               */
    /* -------------------------------------------------------------------------- */

    void HandleStartAnimation(StringHash eventType, VariantMap& eventData)
    {
        BaseEffect@ baseRootEffect = cast<BaseEffect>(eventData["RootEffect"].GetScriptObject());

        if (GetRootEffect().GetEffectId() == baseRootEffect.GetEffectId())
        {
            // Kind of resetting - without it, it won't start again
            // after being played once.  Strange, because this method
            // is called in `HandleSetTimeAnimation`, which is called right 
            // after `Stop()` of `BaseAnimation` is called.
            _animCtrl.SetTime(_animFileName, 0.0);
            // Actual start
            _animCtrl.SetSpeed(_animFileName, _animSpeed);
        }
    }

    void HandleStopAnimation(StringHash eventType, VariantMap& eventData)
    {
        BaseEffect@ baseRootEffect = cast<BaseEffect>(eventData["RootEffect"].GetScriptObject());

        if (GetRootEffect().GetEffectId() == baseRootEffect.GetEffectId())
        {
            // Actual stop
            _animCtrl.SetSpeed(_animFileName, 0.0);
            _animCtrl.SetTime(_animFileName, 0.0);
        }
    }

    void HandleSetTimeAnimation(StringHash eventType, VariantMap& eventData)
    {
        BaseEffect@ baseRootEffect = cast<BaseEffect>(eventData["RootEffect"].GetScriptObject());

        if (GetRootEffect().GetEffectId() == baseRootEffect.GetEffectId())
        {
            _animCtrl.SetTime(_animFileName, _animCtrl.GetLength(_animFileName) * eventData["localTime"].GetFloat());
        }
    }

    void HandlePostUpdate(StringHash eventType, VariantMap& eventData)
    {
        // Don't make it a one-liner - animation won't start!
        if (_animCtrl.IsAtEnd(_animFileName))
        {
            // For animation actions to know that it is played once
            baseAnimation._isPlaying = false;
            // Set it to the first frame
            _animCtrl.SetSpeed(_animFileName, 0.0);
            _animCtrl.SetTime(_animFileName, 0.0);
        }
    }

    void HandleUpdateFacePOI(StringHash eventType, VariantMap& eventData)
    {
        uint faceIndex = eventData["NFace"].GetUInt();
        poiData[faceIndex] = eventData;
    }

    void HandleUpdateHandGesture(StringHash eventType, VariantMap &eventData)
    {
        handGestureData = eventData;
    }

    void HandleSrcFrameUpdate(StringHash eventType, VariantMap& eventData)
    {
        _screenSize = eventData["TargetSize"].GetVector2();
    }



    /* -------------------------------------------------------------------------- */
    /*                                  Interface                                 */
    /* -------------------------------------------------------------------------- */

    void Update(float timeDelta)
    {
        if (!_inited)
            return;

        if (!_anchor.empty && (_anchor == "free" || _anchor == "ar_background" || _anchor == "ar_obj"))
        {
            _node.enabled = true;
            return;
        }

        if (!maskengine.IsFaceDetected(_faceIdx) &&
            (IsValidPointOfInterestName(_anchor) || _anchor == "face")
        ) {
            _SetVisible(false);
            return;
        }

        if (_created)
        {
            _SetVisible(_visible);

            if (_anchor.empty)
                return;

            if (_anchor == "face")
            {
                if (poiData[_faceIdx]["Detected"].GetBool() &&
                    poiData[_faceIdx]["PoiMap"].GetVariantMap().Contains(FACE_CENTER_OFFSET)
                ) {
                	Vector3 anchor_point = poiData[_faceIdx]["PoiMap"].GetVariantMap()[FACE_CENTER_OFFSET].GetVector3();
                	_anchorNode.position = anchor_point;
                }
            }
            else if (_anchor == "palm")
            {
                if (handGestureData["Detected"].GetBool() &&
                    handGestureData["Gesture"].GetString().ToUpper() == "PALM"
                ) {
                    Vector2 palmPosition = handGestureData["Position"].GetVector2();
                    float angle = handGestureData["AngleDegrees"].GetFloat();
                    float size = handGestureData["Size"].GetFloat();

                    Camera @camera = scene.GetChild("Camera").GetComponent("Camera");
                    _anchorNode.worldPosition = camera.ScreenToWorldPoint(
                        Vector3(
                            palmPosition.x / _screenSize.x + 0.5,
                            palmPosition.y / _screenSize.y + 0.5,
                            2500
                        )
                    );
                    _anchorNode.rotation2D = angle;
                    _anchorNode.scale = _anchor_node_initial_scale * 3.0 * size;
                    _node.scale = _node_initial_scale * 3.0 * size;
                }
                else
                {
                    _SetVisible(false);
                }
            }
            else
            {
                if (poiData[_faceIdx]["Detected"].GetBool() &&
                    poiData[_faceIdx]["PoiMap"].GetVariantMap().Contains(_anchor)
                ) {
                    Vector3 anchor_point = poiData[_faceIdx]["PoiMap"].GetVariantMap()[_anchor].GetVector3();
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
        return "model3d";
    }

    void Unload() override
    {
        BaseEffectImpl::Unload();

        if (_node !is null)
            _node.RemoveComponent("StaticModel");
    }
    
    Array<Material@> GetMaterials() 
    {
        return materials;
    }

    Material@ GetMaterial() override
    {
        if (!materials.empty)
            return materials[0];
        return null;
    }

    BaseAnimation@ GetAnimation() override
    {
        return baseAnimation;
    }
}

}
