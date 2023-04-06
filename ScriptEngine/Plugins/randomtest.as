#include "ScriptEngine/Plugins/BasePlugin.as"
#include "ScriptEngine/Effects/Base/BaseAnimation.as"
#include "ScriptEngine/Utils.as"


class randomtest : BasePlugin
{
    String pluginName = "randomtest";

    // Read / reread from JSON Configuration
    String trigger = "tap+recording";
    String question_tag = "question";
    String question_texture = "";
    String answer_tag = "answer";
    String answer_texture = "";
    String animation_tag = "animation";
    bool slow_down_mode = true;
    bool using_animation = false;
    float answer_time = 5.0;
    float start_delay = 0.0;

    // Read from assets
    Array<String> answerTextureFileNames;
    Material@ answerMaterial;
    Material@ questionMaterial;
    Material@ animationMaterial;
    MaskEngine::BaseAnimation@ animation;
    MaskEngine::BaseEffect@ animationEffect;

    // Run-time variables
    Node@ questionNode;
    Node@ answerNode;
    int randomOffset = 0;
    int framesCount = 0;
    uint counter = 0;
    uint finalCounter = 0;
    float elapsedTime = 0.0;
    float answer_delay = 0.1;
    bool receiveInteractions = true;

    // Parameters for bounce animation
    float animation_duration = 0.2;
    float animation_timer = 0.0;
    Vector2 default_scale;
    float TAU = 2.0 * M_PI;

    // Flags
    bool onQuestion = true;
    bool onAnswer = false;
    bool onWait = false;
    bool onAnimation = false;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        if (mask is null)
        {
            log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
            return false;
        }

        SetRandomSeed(time.systemTime);
        
        LoadSettings(plugin_config);

        // Setup question node, material and texture
        questionNode = scene.GetChildrenWithTag(question_tag, true)[0];
        BillboardSet@ bbs = questionNode.GetComponent("BillboardSet");
        questionMaterial = bbs.material;
        if (mask.GetEffectsByTag(question_tag).length == 0)
        {
            log.Error("RandomTestPlugin: Could not get any effects with tag '" + question_tag + "' to init plugin.");
            return false;
        }
        else
        {
            MaskEngine::BaseEffect@ questionEffect = mask.GetEffectsByTag(question_tag)[0];

            // Get texture
            question_texture = questionEffect.GetTextureFile();
            log.Info("question_texture is " + question_texture);
            Texture2D@ tex = cache.GetResource("Texture2D", question_texture);
            if (tex !is null)
                questionMaterial.textures[TU_DIFFUSE] = tex;
            else
                log.Error("Failed to load texture file '" + question_texture + "'");
        }

        // Setup answer node, material and first texture
        answerNode = scene.GetChildrenWithTag(answer_tag, true)[0];
        bbs = answerNode.GetComponent("BillboardSet");
        answerMaterial = bbs.material;
        default_scale = answerNode.scale2D;
        if (mask.GetEffectsByTag(answer_tag).length == 0)
        {
            log.Error("RandomTestPlugin: Could not get any effects with tag '" + question_tag + "' to init plugin.");
            return false;
        }
        else
        {
            MaskEngine::BaseEffect@ answerEffect = mask.GetEffectsByTag(answer_tag)[0];

            // Get texture
            answer_texture = answerEffect.GetTextureFile();
            log.Info("answer_texture is " + answer_texture);
            Texture2D@ tex = cache.GetResource("Texture2D", answer_texture);
            if (tex !is null)
            {
                answerTextureFileNames.Push(answer_texture);
                ++framesCount;
            }
            else
                log.Error("Failed to load texture file '" + answer_texture + "'");
        }

        // Read paths to all other answer textures
        String path = GetPath(answer_texture);
        String file = GetFileName(answer_texture);
        String extension = GetExtension(answer_texture, false);
        for (int a = 1; ; a++)
        {
            String fileName = path + file + String(a) + extension;

            if (cache.Exists(fileName))
            {
                Texture2D@ tex = cache.GetResource("Texture2D", fileName);
                if (tex !is null)
                {
                    answerTextureFileNames.Push(fileName);
                    ++framesCount;
                }
                else
                    log.Error("Failed to load texture file '" + fileName + "'");
            }
            else
                break;
        }

        // Setup animation and its material
        if (using_animation)
        {
            Node@ animationNode = scene.GetChildrenWithTag(animation_tag, true)[0];
            bbs = animationNode.GetComponent("BillboardSet");
            animationMaterial = bbs.material;

            // Animation effect
            animationEffect = mask.GetEffectsByTag(animation_tag)[0];
            animation = animationEffect.GetAnimation();
            congratulationOff();
        }

        // Subscriptions
        SubscribeToEvent("Update", "HandleUpdate");
        if (trigger == "mouth")
            SubscribeToEvent("MouthTrigger", "HandleMouthTrigger");
        else if (trigger.Contains("tap"))
            SubscribeToEvent("MouseEvent", "HandleMouseEvent");
        else if (HAND_GESTURE_NAMES.Find(gesture) != -1)
            SubscribeToEvent("GestureEvent", "HandleGestureEvent");

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("trigger"))
                trigger = plugin_config.Get("trigger").GetString();

            if (plugin_config.Contains("delay"))
                start_delay = plugin_config.Get("delay").GetFloat();

            if (plugin_config.Contains("question"))
            {
                JSONValue pluginRoot_question = plugin_config.Get("question");

                if (pluginRoot_question.Contains("tag"))
                    question_tag = pluginRoot_question.Get("tag").GetString();

                // if (pluginRoot_question.Contains("texture"))
                //     question_texture = pluginRoot_question.Get("texture").GetString();
            }

            if (plugin_config.Contains("answer"))
            {
                JSONValue pluginRoot_answer = plugin_config.Get("answer");

                if (pluginRoot_answer.Contains("tag"))
                    answer_tag = pluginRoot_answer.Get("tag").GetString();

                // if (pluginRoot_answer.Contains("texture"))
                //     answer_texture = pluginRoot_answer.Get("texture").GetString();

                if (pluginRoot_answer.Contains("slow_down"))
                    slow_down_mode = pluginRoot_answer.Get("slow_down").GetBool();

                if (pluginRoot_answer.Contains("time"))
                    answer_time = pluginRoot_answer.Get("time").GetFloat();
                
                if (pluginRoot_answer.Contains("jump"))
                    if (!pluginRoot_answer.Get("jump").GetBool())
                        animation_duration = 0.0;
            }

            if (plugin_config.Contains("animation"))
            {
                JSONValue pluginRoot_animation = plugin_config.Get("animation");

                if (pluginRoot_animation.Contains("tag"))
                {
                    animation_tag = pluginRoot_animation.Get("tag").GetString();
                    using_animation = true;
                }
            }
        }
    }

    void setFrame(int index) 
    {
        Texture2D@ tex = cache.GetResource("Texture2D", answerTextureFileNames[index]);
        if (tex !is null)
            answerMaterial.textures[TU_DIFFUSE] = tex;
    }

    void setRandom() 
    {
        SetRandomSeed(time.systemTime);
        randomOffset = RandomInt(framesCount);
    }

    // Call to start the roulette when displaying the question
    void start()
    {
        receiveInteractions = true;
        setRandom();

        float correction = 0.0;

        // Get the value of counter in Update handler that will affect the final frame
        if (slow_down_mode)
        {
            finalCounter = uint((slowDownFrame(answer_time)));

            float left = answer_time - timeOfSlowDownFrame(finalCounter);
            float right = timeOfSlowDownFrame(finalCounter + 1) - answer_time;
            if (left <= right)
                correction = -left;
            else
                correction = right;

            // Compensate negative frame values
            randomOffset += slowDownFrame(Abs(correction));
        }

        elapsedTime = correction;

        onQuestion = false;
        onAnswer = true;
        onAnimation = false;
        onWait = false;
    }

    // Call to perform bounce animation of the final frame
    void animate()
    {
        onQuestion = false;
        onAnswer = false;
        onAnimation = true;
        onWait = false;

        animation_timer = 0.0;
    }

    // Call to pause on the final answer frame after the roulette
    void wait()
    {
        onQuestion = false;
        onAnswer = false;
        onAnimation = false;
        onWait = true;

        answerNode.SetScale2D(default_scale.x, default_scale.y);

        // Turn congratimation on
        congratulationOn();
    }

    // Call to reset to the question state
    void stop()
    {
        onQuestion = true;
        onAnswer = false;
        onAnimation = false;
        onWait = false;

        // Turn congratimation off
        congratulationOff();
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        if (!onQuestion)
        {
            float dt = eventData["TimeStep"].GetFloat();
            elapsedTime += dt;

            if (onAnswer)
            {
                if (slow_down_mode)
                {
                    // Increment every 'answer_time / 10' seconds as a function of arctangent
                    counter = slowDownFrame(elapsedTime);

                    // Stop when the frame won't change even if the elapsed time is still less than 'answer_time'
                    if (counter == finalCounter)
                        animate();
                }
                else
                {
                    // Increment every 'answer_delay' seconds
                    counter = uint(elapsedTime / answer_delay);
                }
                
                if (elapsedTime <= answer_time)
                    setFrame(uint((counter + randomOffset) % framesCount));
                else
                    animate();
            }

            if (onAnimation)
            {
                animation_timer += dt;
                if (animation_timer <= animation_duration)
                {
                    float scaleFactor = 1.0 + cubicBallistic(animation_timer / animation_duration) * 0.5;
                    answerNode.SetScale2D(
                        default_scale.x * scaleFactor,
                        default_scale.y * scaleFactor
                    );
                }
                else
                {
                    wait();
                }
            }

            answerMaterial.shaderParameters["MatDiffColor"] = Variant(Vector4(1.0f, 1.0f, 1.0f, 1.0f));
            questionMaterial.shaderParameters["MatDiffColor"] = Variant(Vector4(1.0f, 1.0f, 1.0f, 0.0f));
        }
        else
        {
            answerMaterial.shaderParameters["MatDiffColor"] = Variant(Vector4(1.0f, 1.0f, 1.0f, 0.0f));
            questionMaterial.shaderParameters["MatDiffColor"] = Variant(Vector4(1.0f, 1.0f, 1.0f, 1.0f));
        }
    }

    void checkState(bool rec)
    {
        if (!receiveInteractions)
            return;

        if (onQuestion)
        {
            DelayedExecute(start_delay, false, "void start()");
            receiveInteractions = false;
        }

        // if (onAnswer)
        // {
        // }

        if (onWait && !rec)
            stop();
    }

    // Calculates the number of frame (not normalized) given the time
    uint slowDownFrame(float time)
    {
        float factor = answer_time / 10.0;
        return uint(Atan(time / factor) * factor * 2.0);  // Atan returns degrees, not radians
    }

    // Calculates time of the given frame
    float timeOfSlowDownFrame(uint frame)
    {
        float factor = answer_time / 10.0;
        return Tan(frame / (2.0 * factor)) * factor;  // Atan takes degrees, not radians
    }

    void congratulationOn()
    {
        if (using_animation)
        {
            animationMaterial.shaderParameters["MatDiffColor"] = Variant(Vector4(1.0f, 1.0f, 1.0f, 1.0f));
            animation.Play();
        }
    }

    void congratulationOff()
    {
        if (using_animation)
        {
            animationMaterial.shaderParameters["MatDiffColor"] = Variant(Vector4(1.0f, 1.0f, 1.0f, 0.0f));
            animation.Stop();
        }
    }

    float cubicBallistic(float proress)
    {
        return proress - proress * proress * proress;
    }

    void HandleMouthTrigger(StringHash eventType, VariantMap& eventData)
    {
        if (eventData["Opened"].GetBool())
            checkState(false);
    }

    void HandleMouseEvent(StringHash eventType, VariantMap& eventData)
    {
        /*  Tap can start the plugin if the `trigger` is 'tap%',
            or reset the plugin after the roulette phase in any case.
        */
        if (eventData["Event"].GetString() == "tap")
        {
            if (trigger == "tap+recording" || trigger == "tap")
                checkState(false);

            if (trigger == "recording" && onWait)
                stop();
        }
        
        /*  Recording button only can start the plugin
            if the `trigger` is '%recording'.
        */
        if (eventData["Event"].GetString() == "doubletap")
        {
            if (trigger == "tap+recording" || trigger == "recording")
                checkState(true);
        }
    }

    void HandleGestureEvent(StringHash eventType, VariantMap& eventData)
    {   
        if (trigger == eventData["Gesture"].GetString())
            checkState(false);
    }
}
