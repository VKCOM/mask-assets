#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS


vec4 TextureEffectMain()
{
    vec4 backColor         = texture2D(sDiffMap, vScreenPos);
    vec4 textureColor      = texture2D(sEnvMap, vScreenPos);
    vec4 segmentationColor = texture2D(sSegmMap, vScreenPos);
    return vec4(mix(backColor.rgb, textureColor.rgb, segmentationColor.a), textureColor.a);
}

#endif