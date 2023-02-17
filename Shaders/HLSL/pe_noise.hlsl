#include "TextureEffectBase.hlsl"
#include "BlendMath.hlsl"
#line 2

#ifdef COMPILEPS

float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{

    float2 uv = floor(iScreenCoord * cFrameSizeInvSizePS.xy);   // UV
    uv *= cFrameSizeInvSizePS.zw;

    float2 tileRatio = cFrameSizeInvSizePS.xy / float2(256.0,256.0);
    float2 tiledUv = frac(tileRatio * uv);

    float4 noise = Sample2D (DiffMap,tiledUv);
    float4 original = Sample2D( EnvMap, uv);
 
    float mask = cMatSpecColor.x;
    
    noise.rgb = BF_SoftLight(original.rgb, noise.rgb);
    
    return float4(lerp(original.rgb,noise.rgb,mask),1.0);

}

#endif

