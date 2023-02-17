#include "TextureEffectBase.hlsl"
#line 2

#ifdef COMPILEPS


float4 TextureEffectMain(float2 iTexCoord, float2 iScreenCoord)
{

    float2 uv = iScreenCoord;   // UV


    float2 step = 2.0 / cFrameSizeInvSizePS.yx;
    //float2 step = 1.0 / float2(750.0,1334.0);

    float3 texA = Sample2D( EnvMap, uv + float2(-step.x, -step.y)).rgb;
    float3 texB = Sample2D( EnvMap, uv + float2( step.x, -step.y)).rgb;
    float3 texC = Sample2D( EnvMap, uv + float2(-step.x,  step.y)).rgb;
    float3 texD = Sample2D( EnvMap, uv + float2( step.x,  step.y)).rgb;

    float3 around = 0.25* (texA + texB + texC + texD);
    float3 center  = Sample2D( EnvMap, uv ).rgb;

    float sharpness = 2.5;
    
  
    float3 col = center + (center - around) * sharpness;


   return float4(lerp(Sample2D(EnvMap,uv).rgb,col.rgb,cMatSpecColor.x),1.0);
    //return float4(1.0,0.0,0.0,1.0);
}

#endif
