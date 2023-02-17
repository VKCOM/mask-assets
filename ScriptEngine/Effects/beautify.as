#include "ScriptEngine/Effects/Base/BaseEffect.as"

namespace MaskEngine
{

    class beautify : BaseEffectImpl
    {
    private
        BaseEffect @facemodelBeauty;
    private
        float mix = 0.65;
    private
        String blurMaskTextureName = "\"Textures/Beautify/FaceBlurMask";

        Node @_node;

        bool Init(const JSONValue &effect_desc, BaseEffect @parent) override
        {
            if (!BaseEffectImpl::Init(effect_desc, parent))
            {
                return false;
            }

            // changing to new texture for facemodel1 UV coordinates
            JSONFile maskSettings;
            maskSettings.Load(cache.GetFile("mask.json"));
            JSONValue jsonMaskSettigns = maskSettings.GetRoot();


           // todo : FACEMODEL_VERSION works but NUM_FACES is returning 0 always.
           int facemodel_version = GetGlobalVar(FACEMODEL_VERSION).GetInt();
           log.Info("beautify : using facemodel_version = " + facemodel_version);

            blurMaskTextureName += (facemodel_version == 1 ? "1": "") + ".png\"";

            /*
            if(jsonMaskSettigns.Get("facemodel_version").isNumber){
                if(jsonMaskSettigns.Get("facemodel_version").GetUInt() == 1){
                    blurMaskTextureName = "\"Textures/Beautify/FaceBlurMask1.png\"";
                }
            }
            */


            uint nface = 0;
            uint num_faces = 1;
            if (effect_desc.Get("nface").isNumber)
            {
                nface = effect_desc.Get("nface").GetUInt();

                if (jsonMaskSettigns.Get("num_faces").isNumber)
                {
                    num_faces = jsonMaskSettigns.Get("num_faces").GetUInt();
                }
                else if (nface == 1)
                {
                    log.Error("beautify: num_faces must be specified with nface = 1.");
                    return false;
                }
                if (nface > num_faces - 1)
                {
                    log.Error("beautify:  nface greater that num_faces.");
                    return false;
                }
            }

            if (effect_desc.Get("mix").isNumber)
            {
                mix = effect_desc.Get("mix").GetFloat();
            }



            //  hint for shader params "MatSpecColor" : [SoftMix, RangeMultiplier, SharpStr, WhitenStr]"
            String beautifyFaceModelString = "{" +
                                             "\"name\" : \"facemodel\"," +
                                             "\"nface\" : " + nface + " ," +
                                             "\"texture\"  : {" +
                                             "\"shader\" : \"Beautify\", " +
                                             "\"technique\" : \"Techniques/TextureEffect.xml\"," +
                                             "\"diffuse\" : " + blurMaskTextureName + ", " +
                                             "\"specular\" : \"Textures/Beautify/SoftIntensity.png\"," +
                                             "\"MatSpecColor\" : [" + mix + ", 1.4, 1.005, 0.001]" +
                                             "}," +
                                             "\"eyes\" : true" +
                                             "}";

            facemodelBeauty = AddChildEffect("facemodel");
            if (facemodelBeauty !is null)
            {
                JSONFile @jsonFile = JSONFile();
                jsonFile.FromString(beautifyFaceModelString);

                if (!facemodelBeauty.Init(jsonFile.GetRoot(), parent))
                {
                    log.Error("beautify: Cannot init beauty facemodel" + nface);
                    return false;
                }
            }

            AddTags(effect_desc, facemodelBeauty.GetNode());

            _inited = true;

            return _inited;
        }

        void _SetVisible(bool visible) override
        {
            facemodelBeauty.SetVisible(visible);
        }

        String GetName() override
        {
            return "beautify";
        }
    }

}