#include "ScriptEngine/Plugins/BasePlugin.as"


class BokehPoint
{
    Vector2 pos;
    float rad;
    Vector4 speed;
    Vector4 color;
    float calculatedAlpha;
}


class particles : BasePlugin
{
    String pluginName = "particles";

    Node@ bokehNode;
    String bokehNodeTag = "";

    BillboardSet@ object;
    Scene@ scene;
    float elapsedTime = 0;
    
    Vector2 targetSize;
    Vector2 srcSize;
    float targetAngle;
    Array<bool> faceDetected;
    float sizeFactor = 0.20;

    Vector4 minSpeed;
    Vector4 maxSpeed;
    String lookup = "";

    Array<Node@> particlesNodes; 
    Array<BokehPoint> points;

    uint particlesCount = 30;
    float minParticleRadius = 0.010634;
    float maxParticleRadius = 0.051593;

    bool Init(const JSONValue& plugin_config, MaskEngine::Mask@ mask) override
    {
        // Use it to retrieve effects from mask
        // if (mask is null)
        // {
        //     log.Error("RandomTestPlugin: Trying to initialise with a mask that is null.");
        //     return false;
        // }

        LoadSettings(plugin_config);

        SetRandomSeed(time.systemTime + time.systemTime);
        // SetRandomSeed(GetRandomSeed());

        faceDetected.Push(false);
        faceDetected.Push(false);

        scene = script.defaultScene;

        bokehNode = scene.GetChildrenWithTag(bokehNodeTag, true)[0];
        object = bokehNode.GetComponent("BillboardSet");
        generateParticles();

        SubscribeToEvent("Update", "HandleUpdate");
        SubscribeToEvent("SrcFrameUpdate", "HandleUpdateSrc");

        return true;
    }

    void LoadSettings(const JSONValue& plugin_config) override
    {
        if (plugin_config.Get("name").GetString().ToLower() == pluginName)
        {
            if (plugin_config.Contains("tag"))
                bokehNodeTag = plugin_config.Get("tag").GetString();

            if (plugin_config.Contains("min_speed"))
                minSpeed = Vector4(plugin_config.Get("min_speed")[0].GetFloat(), 
                                plugin_config.Get("min_speed")[1].GetFloat(),
                                plugin_config.Get("min_speed")[2].GetFloat(),
                                plugin_config.Get("min_speed")[3].GetFloat());

            if (plugin_config.Contains("max_speed"))
                maxSpeed = Vector4(plugin_config.Get("max_speed")[0].GetFloat(), 
                                plugin_config.Get("max_speed")[1].GetFloat(), 
                                plugin_config.Get("max_speed")[2].GetFloat(), 
                                plugin_config.Get("max_speed")[3].GetFloat());

            // ИСПОЛЬЗОВАТЬ, ЧТОБЫ МЕНЯЛСЯ ОТТЕНОК ЧАСТИЦ. 
            // НЕОБХОДИМО ДОБАВИТЬ ПАРАМЕТР "texture" : "Textures/lookupBokeh.png" В 'PluginConfiguration.json'.
            // texture for changing the particle tints
            // if (plugin_config.Contains("texture"))
            //     lookup = plugin_config.Get("texture").GetString();

            if (plugin_config.Contains("size"))
                sizeFactor = plugin_config.Get("size").GetFloat();

            if (plugin_config.Contains("count"))
                particlesCount = plugin_config.Get("count").GetInt();

            if (plugin_config.Contains("min_radius"))
                minParticleRadius = plugin_config.Get("min_radius").GetFloat();

            if (plugin_config.Contains("max_radius"))
                maxParticleRadius = plugin_config.Get("max_radius").GetFloat();
        }
    }

    void generateParticles()
    {
        // ИСПОЛЬЗОВАТЬ, ЧТОБЫ МЕНЯЛСЯ ОТТЕНОК ЧАСТИЦ
        // Image@ lookupImage = cache.GetResource("Image", lookup);
        
        points.Clear();

        if (particlesCount > 0)
        {
            for (uint i = 0; i < particlesCount; i++)
            {
                particlesNodes.Push(bokehNode.Clone());
                BillboardSet@ bbs = particlesNodes[i].GetComponent("BillboardSet");
                bbs.material = object.material.Clone();

                BokehPoint point;

                point.pos   = Vector2(Random(0.0, 1.0), Random(0.0, 1.0));
                point.rad   = sizeFactor * Random(minParticleRadius, maxParticleRadius);
                point.speed = Vector4((Random(0.0, 1.0) > 0.5 ? 1.0 : -1.0) * Random(minSpeed.x, maxSpeed.x), 
                                        Random(minSpeed.y, maxSpeed.y), 
                                        Random(minSpeed.z, maxSpeed.z), 
                                        Random(minSpeed.w, maxSpeed.w));

                point.color = Vector4(1.0, 1.0, 1.0, 1.0);

                // ИСПОЛЬЗОВАТЬ ВМЕСТО ПРЕДЫДУШЕЙ СТРОКИ, ЧТОБЫ МЕНЯЛСЯ ОТТЕНОК ЧАСТИЦ
                // use this instead of previous line to change particle tints
                // Color pixelColor = lookupImage.GetPixel(int(Random(0.0, lookupImage.width - 1)), 0);
                // point.color = Vector4(pixelColor.r, pixelColor.g, pixelColor.b, pixelColor.a);

                point.calculatedAlpha = point.color.w;
                points.Push(point);
            }

            // make the initial node from 'maks.json' in the centre invisible
            BillboardSet@ bbs = bokehNode.GetComponent("BillboardSet");
            bbs.material.shaderParameters["MatDiffColor"] = Variant(Vector4(1.0, 1.0, 1.0, 0.0));
            
        }
    }

    void applySetup()
    {
        VectorBuffer buf;
        VectorBuffer posAndRadius;
        VectorBuffer color;

        uint pointsCount = 0;

        for (uint i = 0; i < points.length; i++)
        {
            BokehPoint p = points[i];
            Node@ node = particlesNodes[i];
            node.position = Vector3(p.pos.x * srcSize.x - srcSize.x / 2.0,  p.pos.y * srcSize.y - srcSize.y / 2.0, node.position.z);
            node.scale    = Vector3(p.rad * srcSize.x, p.rad * srcSize.x, p.rad * srcSize.x);
            BillboardSet@ bbs = node.GetComponent("BillboardSet");
            bbs.material.shaderParameters["MatDiffColor"]  = Variant(Vector4(p.color.x, p.color.y, p.color.z, p.calculatedAlpha));
            bbs.material.shaderParameters["UOffset"] = object.material.shaderParameters["UOffset"];
            bbs.material.shaderParameters["VOffset"] = object.material.shaderParameters["VOffset"];
        }
    }
     
    void updatePoints(float deltaTime)
    {
        for (uint i = 0; i < points.length; i ++)
	    {
            float calculatedAlpha = 1.0;

            calculatedAlpha = Min(calculatedAlpha, points[i].color.w);

            points[i].calculatedAlpha = calculatedAlpha;

            Vector2 xy;
            xy.y = points[i].pos.y + deltaTime * points[i].speed.y;
            xy.x = points[i].pos.x + Sin(xy.y * points[i].speed.z * M_PI / 180.0) * points[i].speed.w + deltaTime * points[i].speed.x;

            xy.x = Mod(xy.x, 1.0);                
            xy.y = Mod(xy.y, 1.0);

            xy.x = xy.x < 0.0 ? 1.0 : xy.x;
            xy.y = xy.y < 0.0 ? 1.0 : xy.y;

            points[i].pos = xy;
            
            if (xy.x > 0.9)
                points[i].calculatedAlpha = Min(points[i].calculatedAlpha, Max((1.0 - xy.x) / 0.1, 0.0));

            if (xy.y > 0.9)
                points[i].calculatedAlpha = Min(points[i].calculatedAlpha, Max((1.0 - xy.y) / 0.1, 0.0));

            if (xy.x < 0.1)
                points[i].calculatedAlpha = Min(points[i].calculatedAlpha, Max(xy.x / 0.1, 0.0));

            if (xy.y < 0.1)
                points[i].calculatedAlpha = Min(points[i].calculatedAlpha, Max(xy.y / 0.1, 0.0));
	    }
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        elapsedTime += eventData["TimeStep"].GetFloat();
        updatePoints(eventData["TimeStep"].GetFloat());
        applySetup();
    }

    void HandleUpdateSrc(StringHash eventType, VariantMap& eventData)
    {
        Vector2 size = eventData["TargetSize"].GetVector2();
        float angle = eventData["Angle"].GetFloat();
        srcSize = eventData["Size"].GetVector2();

        if (size.x == 0 || size.y == 0)
            size = eventData["Size"].GetVector2();

        if (angle == 90 || angle == 270)
            srcSize = Vector2(srcSize.y, srcSize.x);
    
        targetAngle = angle;
        targetSize = size;
    }
}
