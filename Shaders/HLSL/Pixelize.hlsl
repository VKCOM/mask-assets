#include "TextureEffectBase.hlsl"
#line 4

#ifdef COMPILEPS

float mod(float x, float y)
{
  return x - y * floor(x/y);
}


float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{
    //float2 noise1 = abs(hash22(iScreenCoord.xy*500));

    float3  orig   = Sample2D( EnvMap, iScreenCoord).rgb;
    //const float2 inv_dot_size = 1/50.0*cGBufferInvSize;
    //const float2 screen_res = 1./cGBufferInvSize;
    const float  dot_size = cMatSpecColor.x;//DOT_SIZE;//cMatSpecColor.x;
    //float X = floor( iScreenCoord.x*640.0/dot_size)*dot_size+dot_size/2.0;
    //float Y = floor( iScreenCoord.y*480.0/dot_size)*dot_size+dot_size/2.0;
    float2 uv = floor( iScreenCoord*cFrameSizeInvSizePS.xy/dot_size )*dot_size + dot_size/2;
    uv *= cFrameSizeInvSizePS.zw;//cGBufferInvSize;

    float3  result = Sample2D( EnvMap, uv ).rgb;

    float4 diffColor = cMatDiffColor;
#ifdef DIFFMAP
    //diffColor *= Sample2D(DiffMap, iTexCoord);
    diffColor.a *= Sample2D(DiffMap, iTexCoord).r;
#endif    

    result *= diffColor.rgb;

    return float4( lerp(orig, result, diffColor.a), 1.0);
}

#endif
