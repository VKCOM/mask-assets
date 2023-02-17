#include "TextureEffectBase.hlsl"
#line 2

#ifdef COMPILEPS

float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{
    float2 uv = (iScreenCoord * cFrameSizeInvSizePS.xy);   // UV
    uv *= cFrameSizeInvSizePS.zw;
    float4 mask = Sample2D(DiffMap,uv);
    
    float r = Sample2D(EnvMap, uv-mask.r*cMatSpecColor.x * 0.007).r;
    float g = Sample2D(EnvMap, uv).g;
    float b = Sample2D(EnvMap, uv+mask.r*cMatSpecColor.x * 0.010).b;

    return float4(r, g, b, 1.);
    
    
}

#endif
