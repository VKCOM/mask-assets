#include "TextureEffectBase.glsl"
#line 2

#ifdef COMPILEPS

#if 0
float mod(float x, float y)
{
  return x - y * floor(x/y);
}
#endif

vec4 TextureEffectMain()
{
    //float2 noise1 = abs(hash22(vScreenPos.xy*500));

    vec3  orig   = texture2D( sEnvMap, vScreenPos).rgb;
    float  dot_size = cMatSpecColor.x;
    vec2 uv = floor( vScreenPos*cFrameSizeInvSizePS.xy/dot_size )*dot_size + dot_size / 2.0;
    uv *= cFrameSizeInvSizePS.zw;//cGBufferInvSize;

    vec3  result = texture2D( sEnvMap, uv ).rgb;

    vec4 diffColor = cMatDiffColor;
#ifdef DIFFMAP
    //diffColor *= Sample2D(DiffMaMp, vTexCoord);
    diffColor.a *= texture2D(sDiffMap, vTexCoord).r;
#endif    

    result *= diffColor.rgb;

    return vec4( mix(orig, result, diffColor.a), 1.0);
}

#endif
