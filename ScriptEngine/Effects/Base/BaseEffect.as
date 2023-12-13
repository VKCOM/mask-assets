#include "ScriptEngine/Effects/Base/BaseAnimation.as"

namespace MaskEngine
{

/**
 * Interface of BaseEffect object.
 *
 */
shared interface BaseEffect : ScriptObject
{
    void Unload();

    // Init from json
    bool Init(const JSONValue& effect_desc, BaseEffect@ parent);
    // Init without json
    bool Init(BaseEffect@ parent);

    // Method to get nodes of effect.
    Node@ GetNode(uint index = 0);
    // Method to get number of nodes.
    uint GetNodeNumber();
    // Apply effect to parent
    void Apply();
    // Show/Hide effect
    void SetVisible(bool visible);
    // @return material, if effect has it.
    Material@ GetMaterial();
    // @return animation, if effect has it.
    BaseAnimation@ GetAnimation();
    // @return texture filename.
    String GetTextureFile();
    BaseEffect@ GetRootEffect();
    // Some effects should be called in Update by parent.
    bool NeedCallInUpdate();

    void ApplyChildren();
    int GetRenderPassId();
    int GetFaceIndex();
    int GetEffectId();

    // Return effect name
    String GetName();
}


String INIT_RENDER_PASS_FILE     = "RenderPaths/init_pass.xml";
String UNLIT_RENDER_PASS_FILE    = "RenderPaths/unlit_pass.xml";
String MAIN_RENDER_PASS_FILE     = "RenderPaths/main_pass.xml";
String VIEWPORT_RENDER_PASS_FILE = "RenderPaths/viewport_pass.xml";

// Context's global vars
String CURRENT_RP_IDX    = "current_rp_idx";        // int
String PREVIOUS_RP_IDX   = "prev_rp_idx";           // int (used to set "same" render path idx
String MAIN_PASS_ADDED   = "main_rp_added";         // bool
String FACEMODEL_VERSION = "facemodel_version";


// Create effect by name
BaseEffect@ CreateEffect(String name, bool& wasSkip)
{
    if (name.empty || name.StartsWith("-") || name.Contains("..") || name.Contains("/") || name.Contains("~"))
    {
        log.Info("Skip " + name);
        wasSkip = true;
        return null;
    }

    wasSkip = false;
    log.Info("Start create " + name);
    String moduleName = "ScriptEngine/Effects/" + name + ".as";
    ScriptObject@ obj = scene.CreateScriptObject(moduleName, "MaskEngine::" + name);

    if (obj is null)
    {
        log.Error("CreateEffect: Cannot create object: " + name);
        return null;
    }
    return cast<BaseEffect>(obj);
}


// note: this should correspond to face_recognizer's setup
uint MAX_FACES = 2;
// 1st (default) face node name
String MAIN_FACE_NODE_NAME = "Face";


String FACE_NODE_NAME(uint face_idx)
{
    return face_idx == 0 ? String(MAIN_FACE_NODE_NAME) : String(MAIN_FACE_NODE_NAME) + String(face_idx);
}


uint AUTO_INCRIMENT_EFFECT_ID = 0;


class BaseEffectImpl : BaseEffect
{
    Scene@ scene;
    // Parent effect
    BaseEffect@ _ownerEffect;
    int _renderPassIdx = -1;
    int _faceIdx = -1;
    String  _faceNodeName;
    Array <BaseEffect@> _children;
    bool _inited = false;
    uint effectId = 0;
    bool _visible = true;
    bool _userBinaryProcessState = false;
    String _binaryStartEvent = "";
    String _binaryStopEvent = "";

    BaseEffectImpl()
    {
        scene = script.defaultScene;
        effectId = ++AUTO_INCRIMENT_EFFECT_ID;
    }

    ~BaseEffectImpl()
    {
        log.Info("~" + GetName());
    }

    // Method to get nodes of effect.
    Node@ GetNode(uint index = 0) override
    {
        return null;
    }

    // Method to get number of nodes.
    uint GetNodeNumber() override
    {
        return 0;
    }

    // Apply effect to parent
    void Apply() override
    {
    }

    // Show/Hide effect
    void SetVisible(bool visible_) override
    {
        _visible = visible_;
        _SetVisible(visible_);
    }

    void _SetVisible(bool visible_)
    {
    }

    // @return material, if effect has it.
    Material@ GetMaterial() override
    {
        return null;
    }

    // @return animation, if effect has it.
    BaseAnimation@ GetAnimation() override
    {
        return null;
    }

    // @return texture filename.
    String GetTextureFile() override
    {
        return "";
    }

    BaseEffect@ GetRootEffect() override
    {
        return (_ownerEffect is null) ? cast<BaseEffect>(this) : _ownerEffect.GetRootEffect();
    }

    void ApplyChildren() override
    {
        // Apply child objects
        for (uint i = 0; i < _children.length; i++)
            _children[i].Apply();
    }

    int GetRenderPassId() override
    {
        return _renderPassIdx;
    }

    int GetFaceIndex() override
    {
        return _faceIdx;
    }

    bool Init(const JSONValue& effect_desc, BaseEffect@ parent) override
    {
        _faceIdx = effect_desc.Get("nface").GetInt();
        if (_faceIdx >= int(MAX_FACES))
        {
            log.Error("Failed to init effect: nface (" + _faceIdx + ") is out of range");
            return false;
        }

        return Init(parent);
    }

    bool Init(BaseEffect@ parent) override
    {
        if (_faceIdx < 0 && (parent !is null))
            _faceIdx = parent.GetFaceIndex();

        if (_faceIdx < 0)
            _faceIdx = 0;

        _faceNodeName = FACE_NODE_NAME(_faceIdx);
        _inited = true;

        if (parent !is null)
            @_ownerEffect = parent;

        return true;
    }

    void Unload() override
    {
        log.Info("Unload " + GetName());
        UnsubscribeFromAllEvents();

        for (uint i = 0; i < _children.length; i++)
        {
            _children[i].Unload();
        }
        _children.Clear();
        @_ownerEffect = null;
        @scene = null;
    }

    int GetEffectId() override
    {
        return effectId;
    }

    bool NeedCallInUpdate() override
    {
        return false;
    }

    String GetName() override
    {
        return "BaseEffect";
    }

    bool CheckCallInUpdate()
    {
        bool res = false;

        for (uint i = 0; i < _children.length; i++)
        {
            res = res || _children[i].NeedCallInUpdate();
        }

        return res;
    }

    // Try to load addons dynamical.
    protected bool LoadAddons(const JSONValue& json, const Array<String>& reservedField)
    {
        Array<String> fields = json.GetFields();

        for (uint i = 0; i < fields.length; i++)
        {
            String name = fields[i];

            if (reservedField.Find(name) < 0 && json.Get(name).isObject)
            {
                BaseEffect@ baseEffect = AddChildEffect(name);
                if (baseEffect !is null)
                {
                    if (!baseEffect.Init(json.Get(name), this))
                    {
                        log.Error("BaseEffect: Cannot init " + name);
                        return false;
                    }
                }
                else
                {
                    log.Warning("BaseEffect: Cannot create " + name);
                }
            }
        }

        return true;
    }

    protected bool InitRenderPass(const JSONValue& rp_desc, const String &default_rpass_file)
    {
        //ResourceCache  *cache = GetSubsystem<ResourceCache>();

        String fileName = default_rpass_file;
        if (rp_desc.isString)
        {
            fileName = rp_desc.GetString();
        }

        if (fileName.empty)
        {
            return false;
        }

        int current_rp_idx = GetGlobalVar(CURRENT_RP_IDX).GetInt();

        bool same_rp = false;
        // detect main render path, so we don't use suffix for it
        if (fileName == MAIN_RENDER_PASS_FILE)
        {
            _renderPassIdx = -1;
        }
        else if (fileName == "same")
        {
            // re-use previous render path idx
            _renderPassIdx = GetGlobalVar(PREVIOUS_RP_IDX).GetInt();
            same_rp = true;
        }
        else
        {
            // set up next render pass
            _renderPassIdx = current_rp_idx;
            SetGlobalVar(CURRENT_RP_IDX, Variant(_renderPassIdx + 1));
        }

        SetGlobalVar(PREVIOUS_RP_IDX, Variant(_renderPassIdx));

        if (same_rp && _renderPassIdx >= 0)
        {
            return true; //render path was already added
        }

        if (_renderPassIdx < 0)
        {
            // check if we've already added main path
            if (GetGlobalVar(MAIN_PASS_ADDED).GetBool())
            {
                return true;
            }

            SetGlobalVar(MAIN_PASS_ADDED, Variant(true));
        }

        String  suffix = _renderPassIdx >= 0 ? String(_renderPassIdx) : String("");

        // treat as .xml file name
        XMLFile@ orig_rp = cache.GetResource("XMLFile", fileName);
        if (orig_rp is null)
        {
            log.Error("Failed to load RP file " + fileName);
            return false;
        }

        RenderPath rp;
        if (!rp.Load(orig_rp))
        {
            log.Error("Failed to load RP file " + fileName);
            return false;
        }

        RenderPath@ defaultRP = renderer.defaultRenderPath;

        // append to default render path, modifying passes names/tags
        for (uint i = 0; i < rp.numCommands; i++)
        {
            RenderPathCommand c = rp.commands[i];
            c.pass = c.pass + suffix;
            c.tag = c.tag + suffix;
            defaultRP.AddCommand(c);
        }

        for (uint i = 0; i < rp.numRenderTargets; i++)
        {
            defaultRP.AddRenderTarget(rp.renderTargets[i]);
        }
        return true;
    }

    void AddTags(const JSONValue& effect_desc, Node@ node)
    {
        String tags = effect_desc.Get("tag").GetString();
        if (!tags.empty)
        {
            Array<String> tagArray = tags.Split(';');
            for (uint i = 0; i < tagArray.length; i++)
            {
                node.AddTag(tagArray[i]);
            }
        }
    }

    BaseEffect@ AddChildEffect(String name)
    {
        bool wasSkip = false;

        BaseEffect@ effect = MaskEngine::CreateEffect(name, wasSkip);
        if (effect !is null)
            _children.Push(effect);

        return effect;
    }
}

}
