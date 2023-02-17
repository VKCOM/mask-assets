#include "TextureEffectBase.glsl"
#include "BlendMath.glsl"
#line 2

#ifdef COMPILEPS

vec4 TextureEffectMain()
{

    vec2 uv = floor(vScreenPos * cFrameSizeInvSizePS.xy);   // UV
    uv *= cFrameSizeInvSizePS.zw;

    vec2 tileRatio = cFrameSizeInvSizePS.xy / vec2(256.0,256.0);
    vec2 tiledUv = fract(tileRatio * uv);

    vec4 noise = texture2D (sDiffMap,tiledUv);
    vec4 original = texture2D( sEnvMap, uv);
 
    float mask = cMatSpecColor.x;
    
    noise.rgb = BF_SoftLight(original.rgb, noise.rgb);
    
    return vec4(mix(original.rgb,noise.rgb,mask),1.0);

}

#endif

