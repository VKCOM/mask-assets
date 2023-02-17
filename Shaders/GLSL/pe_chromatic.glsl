#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS

vec4 TextureEffectMain()
{
    vec2 uv = (vScreenPos * cFrameSizeInvSizePS.xy);   // UV
    uv *= cFrameSizeInvSizePS.zw;
    vec4 mask = texture2D(sDiffMap,uv);
    
    float r = texture2D(sEnvMap, uv-mask.r*cMatSpecColor.x * 0.007).r;
    float g = texture2D(sEnvMap, uv).g;
    float b = texture2D(sEnvMap, uv+mask.r*cMatSpecColor.x * 0.010).b;

    return vec4(r, g, b, 1.);
    
    
}

#endif
