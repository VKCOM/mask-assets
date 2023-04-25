#include "ScriptEngine/Utils.as"
#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

class texture : BaseEffectImpl
{
    private Material@ _material;
    private bool _should_mirror_current_frame = false;
    private Vector4 _u_transform;
    private Vector4 _v_transform;
    private String  _diff_texture;
    private BaseEffect@ _animationEffect;

    bool Init(const JSONValue& texture_desc, BaseEffect@ parent) override
    {
        if (!BaseEffectImpl::Init(texture_desc, parent))
        {
            return false;
        }

        // defaults
        //String      diffuse_file;
        Array<String> texture_name;
        texture_name.Resize(MAX_TEXTURE_UNITS);

        String      blend_mode("alpha");
        bool        lit = false;
        int         render_order = 0;

        String      shader_name;
        String      shader_defs_vs, shader_defs_ps;

        if (texture_desc.isString)
        {
            texture_name[TU_DIFFUSE] = texture_desc.GetString();
        }
        else if (texture_desc.isObject)
        {
            if (texture_desc.Get("texture").isString)
            {
                texture_name[TU_DIFFUSE] = texture_desc.Get("texture").GetString();
            }

            for (TextureUnit i = TU_DIFFUSE; i < MAX_TEXTURE_UNITS; i++)
            {
                String textureUnitStr = GetTextureUnitName(i);
                if (texture_desc.Get(textureUnitStr).isString)
                {
                    texture_name[i] = texture_desc.Get(textureUnitStr).GetString();
                }
            }

            if (texture_desc.Get("lit").isBool)
                lit = texture_desc.Get("lit").GetBool();

            if (texture_desc.Get("blend_mode").isString)
                blend_mode = texture_desc.Get("blend_mode").GetString();
            if (texture_desc.Get("blend").isString)  // make 'blend' synonym to 'blend_mode'
                blend_mode = texture_desc.Get("blend").GetString();

            if (texture_desc.Get("render_order").isNumber)
            {
                render_order = texture_desc.Get("render_order").GetInt();
                render_order = Min(100, Max(-100, render_order));
            }

            shader_name = texture_desc.Get("shader").GetString();

            String shader_defs = texture_desc.Get("shader_defs").GetString();
            shader_defs_vs = (shader_defs.empty ? "" : shader_defs + " ") + texture_desc.Get("vs_shader_defs").GetString();
            shader_defs_ps = (shader_defs.empty ? "" : shader_defs + " ") + texture_desc.Get("ps_shader_defs").GetString();
        }
        else
        {
            // texture_desc is Null or invalid type
            log.Error("texture_desc is Null or invalid type");
            return false;
        }

        bool           has_diffuse = !texture_name[TU_DIFFUSE].empty;
        //ResourceCache  *cache = GetSubsystem<ResourceCache>();

        Material@     mat = Material();
        String       tech_name;

        // create material & find tech name

        if (texture_desc.Get("material_file").isString)
        {
            Material@ file_mat = cache.GetResource("Material", texture_desc.Get("material_file").GetString());
            if (file_mat is null)
            {
                log.Error("Failed to load Material: " + texture_desc.Get("material_file").GetString());
                return false;
            }
            @mat = file_mat.Clone();
        }

        // Use special technique for facemodel to fix artifacts on rotation.
        bool disableFacemodelTechnique = false;
        if (texture_desc.Get("DisableFacemodelTechnique").isBool)
            disableFacemodelTechnique = texture_desc.Get("DisableFacemodelTechnique").GetBool();
        // Disable facemodel technique for old recognition.
        if (GetGlobalVar("facemodel_version").GetInt() < 2) {
            disableFacemodelTechnique = true;
        }
        String facemodelPrefix = _ownerEffect.GetName() == "facemodel" && !disableFacemodelTechnique ? "Facemodel" : "";

        // apply blend mode
        if (!blend_mode.empty)
        {
            // calc appropriate technique name
            bool can_be_lit = blend_mode == "replace" || blend_mode == "alpha";

            String not_a_basic_blend = "_invalid_blend_mode_";

            String blendTechSuffix = blend_mode == "replace" ? ""
                : blend_mode == "alpha" ? "Alpha"
                : blend_mode == "add" ? "Add"
                : blend_mode == "addalpha" ? "AddAlpha"
                : blend_mode == "multiply" ? "Multiply"
                : not_a_basic_blend;

            if (blendTechSuffix != not_a_basic_blend)
            {
                tech_name = String("Techniques/")
                    + String(has_diffuse ? "Diff" : "NoTexture")
                    + String(can_be_lit && !lit ? "Unlit" : "")
                    + blendTechSuffix
                    + ".xml";
            }
            else
            {
                // complex blend
                tech_name = "Techniques/TextureEffect" + facemodelPrefix + ".xml";
                shader_name = shader_name.empty ? "ComplexBlend" : shader_name;
                shader_defs_ps += " BLEND_FN=BF_" + blend_mode;
                if (texture_desc.Get("UseAlphaMask").GetBool())
                {
                    shader_defs_ps += " ALPHA_MASK";
                }
                if (texture_desc.Get("UseAlphaTexture").GetBool())
                {
                    shader_defs_ps += " ALPHA_TEXTURE";
                }
            }
        }

        if (!shader_name.empty)
        {
            tech_name = "Techniques/TextureEffect" + facemodelPrefix + ".xml";
        }

        // check for tech name override
        if (texture_desc.Get("technique").isString)
        {
            tech_name = texture_desc.Get("technique").GetString();
        }

        if (!tech_name.empty)
        {
            Technique@ tech = cache.GetResource("Technique", tech_name);
            if (tech is null)
            {
                log.Error("Failed to load Technique: " + tech_name);
                return false;
            }

            mat.SetTechnique(0, tech);
        }


        // apply render pass idx
        if (_ownerEffect !is null && _ownerEffect.GetRenderPassId() >= 0)
        {
            for (uint i = 0; i < mat.numTechniques; i++)
            {
                Technique@ orig_t = mat.techniques[i];
                Technique@ tech_clone = orig_t.ClonePrefix("", String(_ownerEffect.GetRenderPassId()));
                mat.SetTechnique(i, tech_clone);
            }
        }

        // apply shader defs

        if (!shader_name.empty || !shader_defs_vs.empty || !shader_defs_ps.empty)
        {
            for (uint t = 0; t < mat.numTechniques; t++)
            {
                Technique@ orig_t = mat.techniques[t];
                Technique@ tech_clone = orig_t.Clone();

                Array < Pass@> passes = tech_clone.passes;
                for (uint i = 0; i < passes.length; i++)
                {
                    if (!shader_name.empty)
                    {
                        passes[i].vertexShader = shader_name;
                        passes[i].pixelShader = shader_name;
                    }

                    if (!shader_defs_vs.empty || !shader_defs_ps.empty)
                    {
                        passes[i].vertexShaderDefines = shader_defs_vs;
                        passes[i].pixelShaderDefines = shader_defs_ps;
                    }
                }
                mat.SetTechnique(t, tech_clone);
            }
        }


        for (uint i = 0; i < MAX_TEXTURE_UNITS; i++)
        {
            if (!texture_name[i].empty)
            {
                Texture2D@ tex = cache.GetResource("Texture2D", texture_name[i]);
                if (tex is null)
                {
                    log.Error("Failed to load texture: " + texture_name[i]);
                    return false;
                }
                mat.textures[TextureUnit(i)] = tex;
            }
        }

        {
            {
                Vector4     color = one_vector;
                if (ReadVector4(texture_desc.Get("color"), color, true))
                    mat.shaderParameters["MatDiffColor"] = Variant(color);
            }

            Array<String> colors = { "MatDiffColor", "FogColor", "LightColor", "MatEmissiveColor", "MatEnvMapColor", "MatSpecColor" };
            for (uint i = 0; i < colors.length; i++)
            {
                Vector4     color = one_vector;
                if (ReadVector4(texture_desc.Get(colors[i]), color, true))
                    mat.shaderParameters[colors[i]] = Variant(color);
            }
        }
        if (render_order > 0)
        {
            mat.renderOrder = 128 + render_order;
        }

        _material = mat;


        bool auto_mirror = texture_desc.Get("auto_mirror").GetBool();

        if (auto_mirror)
        {
            BaseEffect@ mirror = AddChildEffect("mirror_texture");
            if (mirror is null)
            {
                log.Error("texture: Failed to create mirror_texture effect");
                return false;
            }

            if (!mirror.Init(this))
            {
                log.Error("texture: Failed to init mirror_texture effect");
                return false;
            }
        }

        Vector3 uTrans(1.0, 0.0, 0.0);
        ReadVector3(texture_desc.Get("u_transform"), uTrans);
        _u_transform = Vector4(uTrans.x, uTrans.y, 0.0, uTrans.z);

        Vector3 vTrans(0.0, 1.0, 0.0);
        ReadVector3(texture_desc.Get("v_transform"), vTrans);
        _v_transform = Vector4(vTrans.x, vTrans.y, 0.0, vTrans.z);

        _diff_texture = texture_name[TU_DIFFUSE];

        if (has_diffuse && texture_desc.Get("animation").isObject)
        {
            @_animationEffect = AddChildEffect("animation");
            if (@_animationEffect is null)
            {
                log.Error("texture: Failed to create animation effect");
                return false;
            }

            if (!_animationEffect.Init(texture_desc.Get("animation"), this))
            {
                log.Error("texture: Failed to init texture effect");
                return false;
            }
        }
        else
        {
            if (texture_desc.Get("animation").isObject)
            {
                log.Warning("texture: Texture has animation, but has no diff texture");
            }
        }

        Array<String> reservedField = { "animation" };
        _inited = LoadAddons(texture_desc, reservedField);

        if (CheckCallInUpdate())
        {
            SubscribeToEvent("Update", "HandleUpdate");
        }

        Apply();

        return true;
    }

    String GetName() override
    {
        return "texture";
    }

    // Apply effect to parent
    void Apply() override
    {
        BillboardSet@ billboardSet = _ownerEffect.GetNode(0).GetComponent("BillboardSet");

        if (billboardSet !is null)
        {
            billboardSet.material = _material;
            billboardSet.Commit();
        }

        StaticModel@ staticModel = _ownerEffect.GetNode(0).GetComponent("StaticModel");

        if (staticModel !is null)
        {
            staticModel.material = _material;
        }

        ApplyChildren();
    }

    void ApplyChildren() override
    {
        _material.shaderParameters["UOffset"] = Variant(_u_transform);
        _material.shaderParameters["VOffset"] = Variant(_v_transform);

        BaseEffectImpl::ApplyChildren();
    }

    Material@ GetMaterial() override
    {
        return _material;
    }

    BaseAnimation@ GetAnimation() override
    {
        return _animationEffect.GetAnimation();
    }

    String GetTextureFile() override
    {
        return _diff_texture;
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        ApplyChildren();
    }

    void Unload() override
    {
        BaseEffectImpl::Unload();
        @_material = null;
    }

}

}