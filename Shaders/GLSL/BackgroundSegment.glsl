#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS


vec4 TextureEffectMain()
{
    vec4 backColor         = texture2D(sDiffMap, vScreenPos);
    backColor.rgb *= cMatDiffColor.rgb;
    vec4 textureColor      = texture2D(sEnvMap, vScreenPos);
    vec4 segmentationColor = texture2D(sSegmMap, vScreenPos);

    return vec4(mix(textureColor.rgb, backColor.rgb, (1.0 - clamp(0.0,1.0,segmentationColor.a + (1.0 - backColor.a))) * cMatDiffColor.a), 1.0);
}

#endif


