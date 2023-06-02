#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseEvent.as"


namespace MaskEngine
{

/* Class for animating 2D diffuse texture.
 *
 * For 3D model and its textures animations,
 * see 'model3d.as'.
 */
class animation : BaseEffectImpl
{
    int atlasRows = 0;
    int atlasCols = 0;
    int lastAtlasFileIdx = -1;
    Array<String> atlasFiles;

    bool once = false;
    float _elapsedTime = 0.0;
    ValueAnimation frameAni;
    int currentFrame = 0;

    Material@ _material;
    BaseAnimationImpl@ baseAnimation;

    animation()
    {
        @baseAnimation = BaseAnimationImpl(this);
    }


    // Init from xml
    bool Init(const JSONValue& ani_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(ani_desc, parent))
            return false;

        if (!ani_desc.isObject)
        {
            log.Error("Invalid animation description");
            return false;
        }

        int num_atlas_files = 1;
        int atlas_frames = 0;

        if (ani_desc.Contains("rows") && ani_desc.Contains("cols")
            && ani_desc.Contains("frames"))
        {
            atlasRows = ani_desc.Get("rows").GetInt();
            atlasCols = ani_desc.Get("cols").GetInt();
            atlas_frames = ani_desc.Get("frames").GetInt();
            if (ani_desc.Contains("num_atlas_files")) {
                num_atlas_files = ani_desc.Get("num_atlas_files").GetInt();
            }
        }
        else
        {
            atlasRows = 1;
            atlasCols = 1;
            log.Warning("animation: Animation doen't contain rows/cols/frames");
        }

        String warp_type = ani_desc.Get("type").GetString();
        once = (warp_type == "once");

        lastAtlasFileIdx = -1;


        // Setup events for triggering animation to start and stop
        String triggerStart = ani_desc.Get("trigger_start").GetString();
        String triggerStop = ani_desc.Get("trigger_stop").GetString();

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
                    log.Error("model3d: Cannot init " + triggerStart);
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
                    log.Error("model3d: Cannot init " + triggerStart);
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

                    if (ani_desc.Contains("hide_delay"))
                        json = "{ \"name\" : \"stop_animation\"," +
                            "\"delay\":" + ani_desc.Get("hide_delay").GetFloat() + "}";
                    else
                        json = "{ \"name\" : \"stop_animation\"}";

                    JSONFile@ stopJsonFile = JSONFile();
                    stopJsonFile.FromString(json);

                    if (!stopEvent.Init(stopJsonFile.GetRoot(), this))
                    {
                        log.Error("model3d: Cannot init " + triggerStop);
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


        if (atlasRows == 0 || atlasCols == 0)
        {
            log.Error("Atlas dimensions not specified ('rows' and 'cols')");
            return false;
        }

        String diffuseFileName = parent.GetTextureFile();
        if (diffuseFileName.empty)
        {
            log.Error("Wrong texture parameter of parent object");
            return false;
        }

        // Load animation atlases or single texture files
        atlasFiles.Push(diffuseFileName);
        String path = GetPath(diffuseFileName);
        String file = GetFileName(diffuseFileName);
        String extension = GetExtension(diffuseFileName, false);

        // While there are files, load their filenames
        for (int a = 1; ; a++)
        {
            String fileName = path + file + String(a) + extension;
            if (cache.Exists(fileName))
            {
                Texture2D@ tex = cache.GetResource("Texture2D", fileName);
                if (tex !is null)
                    atlasFiles.Push(fileName);
                else
                    log.Error("Failed to load texture file '" + fileName + "'");
            }
            else
                break;
        }

        // Calculate number of atlas frames
        num_atlas_files = atlasFiles.length;
        if (atlas_frames <= 0)
        {
            atlas_frames = atlasRows * atlasCols * num_atlas_files;
        }
        else if (atlas_frames > atlasRows * atlasCols * num_atlas_files)
        {
            log.Error("Too many frames (" + atlas_frames + ") for " + atlasRows + "rows X " + atlasCols + "cols X " + num_atlas_files + "files atlas");
            return false;
        }

        // Create frame number animation
        frameAni.valueType = VAR_INT;
        frameAni.interpolationMethod = IM_NONE;

        if (ani_desc.Get("fps").isNumber)
        {
            float fps = ani_desc.Get("fps").GetFloat();

            if (fps < M_EPSILON)
                fps = 30.0f;

            double time_step = 1.0 / double(fps);

            for (int key = 0; key <= atlas_frames; key++)
            {
                int nFrame = key < atlas_frames ? key : atlas_frames - 1;
                frameAni.SetKeyFrame(float(key * time_step), nFrame);
            }
        }
        else if (ani_desc.Get("timeline").isArray)
        {
            JSONValue jAr = ani_desc.Get("timeline");
            const uint jArSize = jAr.size;
            if (jArSize < 1)
            {
                log.Error("Invalid timeline size in animation (" + jArSize + ")");
                return false;
            }

            double t = 0.0;
            for (int key = 0; key <= atlas_frames; key++)
            {
                int nFrame = key < atlas_frames ? key : atlas_frames - 1;

                frameAni.SetKeyFrame(float(t), nFrame);

                if (nFrame < int(jArSize))
                {
                    t += jAr[nFrame].GetDouble() / 1000.0;
                }
                else
                {
                    t += jAr[jArSize - 1].GetDouble() / 1000.0;
                }
            }
        }
        else if (ani_desc.Get("timeline_ex").isArray)
        {
            JSONValue jAr = ani_desc.Get("timeline_ex");
            const uint jArSize = jAr.size;
            if (jArSize < 1)
            {
                log.Error("Invalid timeline_ex size in animation (" + jArSize + ")");
                return false;
            }

            double t = 0.0;
            int curFrame = -1;  // fist frame will be 0 if not specified
            for (uint k = 0; k < jArSize; k++)
            {
                double curDelay = 0.0;
                if (jAr[k].isArray)
                {
                    JSONValue j = jAr[k];
                    if (j.size != 2)
                    {
                        log.Error("Invalid timeline_ex array element");
                        return false;
                    }
                    curFrame = j[0].GetInt();
                    curDelay = j[1].GetDouble() / 1000.0;
                }
                else if (jAr[k].isNumber)
                {
                    curDelay = jAr[k].GetDouble() / 1000.0;;
                    curFrame = curFrame + 1;
                }
                else
                {
                    log.Error("Invalid timeline_ex array element. It is not Number or Array");
                    return false;
                }

                if (curFrame >= atlas_frames || curFrame < 0)
                {
                    log.Error("Invalid timeline_ex: too big frame number");
                    return false;
                }

                frameAni.SetKeyFrame(float(t), curFrame);

                t += curDelay;
            }

            // Last keyframe
            frameAni.SetKeyFrame(float(t), curFrame);
        }
        else
        {
            log.Error("fps or timeline or timeline_ex must be specified for animation");
            return false;
        }

        _material = parent.GetMaterial();
        if (_material is null)
        {
            log.Error("Parent object has no material object");
            return false;
        }

        SubscribeToEvent("Update", "HandleUpdate");
        return true;
    }



    /* -------------------------------------------------------------------------- */
    /*                                Subscriptions                               */
    /* -------------------------------------------------------------------------- */

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (baseAnimation.IsPlaying())
        {
            _elapsedTime += eventData["TimeStep"].GetFloat();
            float animationDuration = frameAni.GetEndTime() - frameAni.GetBeginTime();

            if (animationDuration <= 0.0)
            {
                log.Error("Animation duration is zero");
                return;
            }

            if (_elapsedTime > animationDuration && once)
            {
                SetTime(0.0);
                baseAnimation.Stop();
                return;
            }

            float scaledTime = _elapsedTime - int(_elapsedTime / animationDuration) * animationDuration;
            currentFrame = frameAni.GetAnimationValue(scaledTime).GetInt();
        }
        else
        {
            SetTime(0.0);
        }
    }



    /* -------------------------------------------------------------------------- */
    /*                                  Interface                                 */
    /* -------------------------------------------------------------------------- */

    // Apply effect to parent
    void Apply() override
    {
        int framesPerAtlasFile = atlasRows * atlasCols;
        int nAtlasFile = currentFrame / framesPerAtlasFile;
        int nFrameInFile = currentFrame % framesPerAtlasFile;

        if (nAtlasFile >= int(atlasFiles.length))
        {
            log.Error("Invalid atlas number: " + String(nAtlasFile));
            nAtlasFile = 0;
        }

        // apply atlas file
        if (nAtlasFile != lastAtlasFileIdx)
        {
            Texture2D@ tex = cache.GetResource("Texture2D", atlasFiles[nAtlasFile]);
            if (tex !is null)
            {
                _material.textures[TU_DIFFUSE] = tex;
                lastAtlasFileIdx = nAtlasFile;
            }
            else
            {
                log.Error("Invalid animated atlas file: '" + atlasFiles[nAtlasFile] + "'");
                lastAtlasFileIdx = -1; // retry next frame
            }
        }

        double  dX = 1.0 / double(atlasCols);
        double  dY = 1.0 / double(atlasRows);

        Vector4 atlas_u_offset = Vector4(float(dX), 0.0, 0.0, float(dX*(nFrameInFile % atlasCols)));
        Vector4 atlas_v_offset = Vector4(0.0, float(dY), 0.0, float(dY*(nFrameInFile / atlasCols)));

        Vector4 vOffset = _material.shaderParameters["VOffset"].GetVector4();
        Vector4 uOffset = _material.shaderParameters["UOffset"].GetVector4();

        vOffset = Vector4(vOffset.x, vOffset.y, 0.0f, vOffset.w);

        Vector4 A = uOffset;
        Vector4 B = vOffset;
        Vector4 C = atlas_u_offset;
        Vector4 D = atlas_v_offset;
        // calc resulting transform
        uOffset = Vector4(
            A.x*C.x + B.x*C.y,
            A.y*C.x + B.y*C.y,
            0.0f,
            A.w*C.x + B.w*C.y + C.w);

        vOffset = Vector4(
            A.x*D.x + B.x*D.y,
            A.y*D.x + B.y*D.y,
            0.0f,
            A.w*D.x + B.w*D.y + D.w);

        _material.shaderParameters["UOffset"] = Variant(uOffset);
        _material.shaderParameters["VOffset"] = Variant(vOffset);
    }

    void SetTime(float localTime)
    {
        _elapsedTime = localTime;
        currentFrame = frameAni.GetAnimationValue(localTime).GetInt();
        baseAnimation.SetTime(localTime);
    }

    BaseAnimation@ GetAnimation() override
    {
        return baseAnimation;
    }

    BaseEffect@ CreateEvent(String& name)
    {
        BaseEffect@ baseEffect = AddChildEffect(name);
        if (!baseEffect.Init(this))
        {
            log.Error("Cannot init " + name + " for patch");
            return null;
        }

        return baseEffect;
    }

    bool NeedCallInUpdate() override
    {
        return true;
    }

    String GetName() override
    {
        return "animation";
    }
}

}
